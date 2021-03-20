import 'dart:io';
import 'package:flutter/material.dart';
import 'package:punch_list_app/domain/item.dart';
import 'package:punch_list_app/control/db_provider.dart';
import 'package:punch_list_app/model/item_model.dart';
import 'package:punch_list_app/services/admob.dart';
import '../../domain/punchlist_element.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:punch_list_app/control/file_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:admob_flutter/admob_flutter.dart';

class AddItemPageState extends StatefulWidget {
  @override
  _AddItemPageState createState() => _AddItemPageState();
}

class _AddItemPageState extends State {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("アイテム追加", style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        child: ChangeForm(),
      ),
      bottomNavigationBar: AdmobBanner(
        adUnitId: AdMobService().getBannerAdUnitId(),
        adSize: AdmobBannerSize(
          width: MediaQuery.of(context).size.width.toInt(),
          height: AdMobService().getHeight(context).toInt(),
          name: 'SMART_BANNER',
        ),
      ),
    );
  }
}

class ChangeForm extends StatefulWidget {
  @override
  _ChangeFormState createState() {
    return _ChangeFormState();
  }
}

class _ChangeFormState extends State<ChangeForm> {
  final _formKey = GlobalKey<FormState>();
  String itemId = Uuid().v4();
  File imageFile;
  String imgName = '';
  String itemName = '';
  String itemExplanation = '';
  String itemStatus = '0';
  bool _active = false;
  PermissionStatus _permissionStatusCamera = PermissionStatus.undetermined;
  PermissionStatus _permissionStatusGallery = PermissionStatus.undetermined;
  FileController fc = new FileController();

  void _changeSwitch(bool e) => setState(() => _active = e);

  Widget build(BuildContext context) {
    PunchlistElement selectedPunchlistElement =
        ModalRoute.of(context).settings.arguments;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
          key: _formKey,
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: <Widget>[
                  (imageFile == null)
                      ? Icon(Icons.no_sim)
                      : Image.memory(
                          imageFile.readAsBytesSync(),
                          height: 200.0,
                          width: 200.0,
                        ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                          child: RaisedButton(
                        child: Text('撮影'),
                        onPressed: () {
                          _checkCameraPermissionStatus(ImageSource.camera);
                        },
                      )),
                      Container(
                          child: RaisedButton(
                        child: Text('アルバム'),
                        onPressed: () {
                          _checkPermissionStatusGallery(ImageSource.gallery);
                        },
                      )),
                    ],
                  ),
                  TextFormField(
                    enabled: true,
                    maxLength: 20,
                    maxLengthEnforced: false,
                    obscureText: false,
                    decoration: const InputDecoration(
                      labelText: 'アイテム名 *',
                    ),
                    validator: (String value) {
                      return value.isEmpty ? '必須入力です' : null;
                    },
                    onSaved: (String value) {
                      itemName = value;
                    },
                  ),
                  TextFormField(
                    maxLines: 7,
                    maxLength: 200,
                    maxLengthEnforced: true,
                    decoration: const InputDecoration(
                      labelText: 'アイテム概要',
                    ),
                    validator: (String value) {
                      if ('\n'.allMatches(value).length > 7) {
                        return '７行以内で入力してください';
                      }
                      if (value.isEmpty) {
                        return '必須項目です';
                      }
                      return null;
                    },
                    onSaved: (String value) {
                      itemExplanation = value;
                    },
                  ),
                  SwitchListTile(
                    value: _active,
                    activeColor: Colors.blue,
                    activeTrackColor: Colors.green,
                    inactiveThumbColor: Colors.blue,
                    inactiveTrackColor: Colors.grey,
                    onChanged: _changeSwitch,
                    title: Text('対応完了'),
                  ),
                  RaisedButton(
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        await _formKey.currentState.save();
                        await _submission(selectedPunchlistElement);
                        await Navigator.pushNamedAndRemoveUntil(
                            context, '/itemMain', ModalRoute.withName('/'),
                            arguments: selectedPunchlistElement);
                      }
                    },
                    child: Text('保存'),
                  )
                ],
              ))),
    );
  }

  _checkCameraPermissionStatus(ImageSource source) async {
    if (_permissionStatusCamera == PermissionStatus.undetermined) {
      print('カメラの使用許可/不許可が未選択');
      _permissionStatusCamera = await Permission.camera.request();
    }
    switch (_permissionStatusCamera) {
      case PermissionStatus.permanentlyDenied:
        print('カメラの権限が手動で設定しない限り不許可');
        return _showDialog();
      case PermissionStatus.restricted:
        print('カメラの使用制限');
        return _showDialog();
      case PermissionStatus.denied:
        print('カメラの使用不許可');
        return _showDialog();
      case PermissionStatus.granted:
        print('カメラの使用許可');
        _saveAndGetFromDevice(source);
        break;
      default:
        return _showDialog();
    }
  }

  _checkPermissionStatusGallery(ImageSource source) async {
    if (_permissionStatusGallery == PermissionStatus.undetermined) {
      print('ギャラリーの使用許可/不許可が未選択');
      _permissionStatusGallery = await Permission.photos.request();
    }
    switch (_permissionStatusGallery) {
      case PermissionStatus.permanentlyDenied:
        print('ギャラリーの権限が手動で設定しない限り不許可');
        return _showDialog();
      case PermissionStatus.restricted:
        print('ギャラリーの使用制限');
        return _showDialog();
      case PermissionStatus.denied:
        print('ギャラリーの使用不許可');
        return _showDialog();
      case PermissionStatus.granted:
        print('ギャラリーの使用許可');
        _getFromDevice(source);
        break;
      default:
        return _showDialog();
    }
  }

  _showDialog() {
    showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("カメラ/アルバムが許可されていません。"),
            content: Text("このアプリではカメラ/アルバムを使用します。"),
            actions: <Widget>[
              FlatButton(
                child: Text("キャンセル"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                  child: Text("設定"),
                  onPressed: () {
                    openAppSettings(); // 設定アプリに遷移
                  }),
            ],
          );
        });
  }

  void _saveAndGetFromDevice(ImageSource source) async {
    var imageFile = await ImagePicker.pickImage(source: source);
    if (imageFile == null) {
      return;
    }
    await fc.saveImageGallery(imageFile);
    this.imageFile = imageFile;
    setState(() {
      this.imageFile = imageFile;
    });
  }

  void _getFromDevice(ImageSource source) async {
    var imageFile = await ImagePicker.pickImage(source: source);
    if (imageFile == null) {
      return;
    }
    this.imageFile = imageFile;
    setState(() {
      this.imageFile = imageFile;
    });
  }

  Future<void> _submission(PunchlistElement selectedPunchlistElement) async {
    Item item;
    ItemModel itemModel = new ItemModel(selectedPunchlistElement.punchlistId);
    this.itemStatus = this._active ? '1' : '0';
    if (this.imageFile != null) {
      this.imgName = await fc.saveLocalImage(imageFile);
    }
    item = Item(
      punchlistId: selectedPunchlistElement.punchlistId,
      itemId: this.itemId,
      imgName: this.imgName,
      itemName: this.itemName,
      itemExplanation: this.itemExplanation,
      itemStatus: this.itemStatus,
    );
    await itemModel.create(item);
  }
}
