import 'dart:io';
import 'package:flutter/material.dart';
import 'package:punch_list_app/domain/item.dart';
import 'package:punch_list_app/domain/punchlist_element.dart';
import 'package:punch_list_app/presentation/control/db_provider.dart';
import 'package:punch_list_app/presentation/model/item_model.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:punch_list_app/presentation/control/file_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:punch_list_app/services/admob.dart';

class EditItemPageState extends StatefulWidget {
  @override
  _EditItemPageState createState() => _EditItemPageState();
}

class _EditItemPageState extends State {
  @override
  Widget build(BuildContext context) {
    final Map args = ModalRoute.of(context).settings.arguments;
    Item selectedItem = args["selectedItem"];
    PunchlistElement selectedPunchListElement =
        args["selectedPunchListElement"];
    String itemStatus = selectedItem.itemStatus;
    String itemId = selectedItem.itemId;
    String imgName = selectedItem.imgName;
    bool _active = itemStatus == '1' ? true : false;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("アイテム編集", style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        child: ChangeForm(selectedPunchListElement, selectedItem, itemId,
            imgName, itemStatus, _active),
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
  PunchlistElement selectedPunchlistElement;
  Item selectedItem;
  File imageFile;
  String itemId;
  String imgName;
  String itemStatus;
  bool _active;

  ChangeForm(this.selectedPunchlistElement, this.selectedItem, this.itemId,
      this.imgName, this.itemStatus, this._active);

  _ChangeFormState createState() {
    if (imgName != "") {
      imageFile = File(DBProvider.documentsDirectory.path + "/" + imgName);
    }

    return _ChangeFormState(selectedPunchlistElement, selectedItem, itemId,
        imageFile, imgName, itemStatus, _active);
  }
}

class _ChangeFormState extends State<ChangeForm> {
  _ChangeFormState(this.selectedPunchlistElement, this.selectedItem,
      this.itemId, this.imageFile, this.imgName, this.itemStatus, this._active);

  final _formKey = GlobalKey<FormState>();
  PunchlistElement selectedPunchlistElement;
  Item selectedItem;
  String itemId;
  File imageFile;
  String imgName;
  String itemName = '';
  String itemExplanation = '';
  String itemStatus;
  bool _active;
  PermissionStatus _permissionStatus = PermissionStatus.undetermined;
  FileController fc = new FileController();

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
          key: _formKey,
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(50.0),
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
                          _checkPermissionStatus(ImageSource.camera);
                        },
                      )),
                      Container(
                          child: RaisedButton(
                        child: Text('アルバム'),
                        onPressed: () {
                          _checkGalleryPermissionStatus(ImageSource.gallery);
                        },
                      )),
                    ],
                  ),
                  TextFormField(
                    initialValue: selectedItem.itemName,
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
                    initialValue: selectedItem.itemExplanation,
                    maxLines: 7,
                    maxLength: 200,
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
                    onPressed: () {
                      if (_formKey.currentState.validate()) {
                        _formKey.currentState.save();
                        _submission(selectedItem);
                        Navigator.pushNamedAndRemoveUntil(
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

  _checkPermissionStatus(ImageSource source) async {
    if (_permissionStatus == PermissionStatus.undetermined) {
      print('カメラの使用許可/不許可が未選択');
      _permissionStatus = await Permission.camera.request();
    }
    switch (_permissionStatus) {
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
        _getFromDevice(source);
        break;
      default:
        return _showDialog();
    }
  }

  _checkGalleryPermissionStatus(ImageSource source) async {
    if (_permissionStatus == PermissionStatus.undetermined) {
      print('ギャラリーの使用許可/不許可が未選択');
      _permissionStatus = await Permission.photos.request();
    }
    switch (_permissionStatus) {
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
        _saveAndGetFromDevice(source);
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
                    openAppSettings();
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
    imgName = await fc.saveLocalImage(imageFile);
    setState(() {
      this.imageFile = imageFile;
    });
  }

  void _getFromDevice(ImageSource source) async {
    var imageFile = await ImagePicker.pickImage(source: source);
    if (imageFile == null) {
      return;
    }
    imgName = await fc.saveLocalImage(imageFile);
    setState(() {
      this.imageFile = imageFile;
    });
  }

  void _changeSwitch(bool e) => setState(() {
        _active = e;
        itemStatus = _active ? '1' : '0';
      });

  Future<void> _submission(Item selectedItem) async {
    Item item;
    ItemModel itemModel = new ItemModel(selectedItem.punchlistId);
    item = Item(
      punchlistId: selectedItem.punchlistId,
      itemId: itemId,
      imgName: imgName,
      itemName: itemName,
      itemExplanation: itemExplanation,
      itemStatus: itemStatus,
    );
    await itemModel.update(item);
  }
}
