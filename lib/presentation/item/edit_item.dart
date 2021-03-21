import 'dart:io';
import 'package:flutter/material.dart';
import 'package:punch_list_app/domain/item.dart';
import 'package:punch_list_app/domain/punchlist_element.dart';
import 'package:punch_list_app/control/db_provider.dart';
import 'package:punch_list_app/model/item_model.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:punch_list_app/control/file_controller.dart';
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
    double _value = double.parse(selectedItem.itemStatus);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("アイテム編集", style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        child: ChangeForm(selectedPunchListElement, selectedItem, itemId,
            imgName, itemStatus, _value),
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
  double _value;

  ChangeForm(this.selectedPunchlistElement, this.selectedItem, this.itemId,
      this.imgName, this.itemStatus, this._value);

  _ChangeFormState createState() {
    if (imgName != "") {
      imageFile = File(DBProvider.documentsDirectory.path + "/" + imgName);
    }

    return _ChangeFormState(selectedPunchlistElement, selectedItem, itemId,
        imageFile, imgName, imgName, itemStatus, _value);
  }
}

class _ChangeFormState extends State<ChangeForm> {
  _ChangeFormState(
    this.selectedPunchlistElement,
    this.selectedItem,
    this.itemId,
    this.imageFile,
    this.imgName,
    this._imgName,
    this.itemStatus,
    this._value,
  );

  final _formKey = GlobalKey<FormState>();
  PunchlistElement selectedPunchlistElement;
  Item selectedItem;
  String itemId;
  File imageFile;
  String imgName;
  final String _imgName;
  String itemName = '';
  String itemExplanation = '';
  String itemStatus;
  double _value;
  double _startValue;
  double _endValue;
  PermissionStatus _permissionStatusCamera = PermissionStatus.undetermined;
  PermissionStatus _permissionStatusGallery = PermissionStatus.undetermined;
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
                    maxLength: 190,
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
                  Text('進捗率', style: TextStyle(fontSize: 16)),
                  Slider(
                    label: convertProgress(),
                    min: 0,
                    max: 4,
                    value: _value,
                    activeColor: Colors.green,
                    inactiveColor: Colors.grey,
                    onChanged: _changeSlider,
                    onChangeStart: _startSlider,
                    onChangeEnd: _endSlider,
                    divisions: 4,
                  ),
                  RaisedButton(
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        await _formKey.currentState.save();
                        await _submission(selectedItem);
                        await deleteOldFile();
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
    this.imageFile = imageFile;
    this.imgName = 'changed';
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
    this.imgName = 'changed';
    setState(() {
      this.imageFile = imageFile;
    });
  }

  void _changeSlider(double e) => setState(() {
        _value = e;
      });
  void _startSlider(double e) => setState(() {
        _startValue = e;
      });
  void _endSlider(double e) => setState(() {
        _endValue = e;
      });
  String convertProgress() {
    String progress = _value.toInt().toString();
    switch (progress) {
      case '0':
        return '0%';
        break;
      case '1':
        return '25%';
        break;
      case '2':
        return '50%';
        break;
      case '3':
        return '75%';
        break;
      case '4':
        return '100%';
        break;
      default:
        return '0%';
        break;
    }
  }

  void _submission(Item selectedItem) async {
    Item item;
    ItemModel itemModel = new ItemModel(selectedItem.punchlistId);
    this.itemStatus = _value.toInt().toString();
    if (this.imageFile != null && this._imgName != this.imgName) {
      this.imgName = await fc.saveLocalImage(imageFile);
    }
    item = Item(
      punchlistId: selectedItem.punchlistId,
      itemId: this.itemId,
      imgName: this.imgName,
      itemName: this.itemName,
      itemExplanation: this.itemExplanation,
      itemStatus: this.itemStatus,
    );
    await itemModel.update(item);
  }

  void deleteOldFile() async {
    if (this._imgName != this.imgName && this._imgName != '') {
      final path = await DBProvider.documentsDirectory.path;
      final dir = Directory('$path/$_imgName');
      await dir.deleteSync(recursive: true);
    }
  }
}
