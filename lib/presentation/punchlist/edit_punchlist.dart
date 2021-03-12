import 'package:flutter/material.dart';
import 'package:punch_list_app/services/admob.dart';
import '../../domain/punchlist_element.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../model/punchlist_model.dart';
import 'package:admob_flutter/admob_flutter.dart';

class EditPunchlistPageState extends StatefulWidget {
  @override
  PunchlistElement selectedPunchListElement;
  EditPunchlistPageState(this.selectedPunchListElement);
  _EditPunchlistPageState createState() =>
      _EditPunchlistPageState(selectedPunchListElement);
}

class _EditPunchlistPageState extends State {
  @override
  PunchlistElement selectedPunchListElement;
  _EditPunchlistPageState(this.selectedPunchListElement);
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.grey[50],
        brightness: Brightness.light,
        iconTheme: IconThemeData(color: Colors.black87),
        title: Text("パンチリスト編集", style: TextStyle(color: Colors.black87)),
      ),
      body: Container(
        child: ChangeForm(selectedPunchListElement),
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
  PunchlistElement selectedPunchListElement;
  ChangeForm(this.selectedPunchListElement);
  _ChangeFormState createState() => _ChangeFormState(selectedPunchListElement);
}

class _ChangeFormState extends State<ChangeForm> {
  PunchlistElement selectedPunchListElement;
  _ChangeFormState(this.selectedPunchListElement);
  final _formKey = GlobalKey<FormState>();
  String punchlistName = '';
  String createDate = '';
  String createUser = '';
  String explanationPunchlist = '';

  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Form(
            key: _formKey,
            child: Container(
                padding: const EdgeInsets.all(50.0),
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      initialValue: selectedPunchListElement.punchlistName,
                      enabled: true,
                      maxLength: 20,
                      maxLengthEnforced: false,
                      obscureText: false,
                      decoration: const InputDecoration(
                        labelText: 'パンチリスト名 *',
                      ),
                      validator: (String value) {
                        return value.isEmpty ? '必須入力です' : null;
                      },
                      onSaved: (String value) {
                        punchlistName = value;
                      },
                    ),
                    TextFormField(
                      initialValue: selectedPunchListElement.createUser,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: '作成者名 *',
                      ),
                      validator: (String value) {
                        return value.isEmpty ? '必須入力です' : null;
                        return '\n'.allMatches(value).length > 8
                            ? '７行以内で入力してください'
                            : null;
                      },
                      onSaved: (String value) {
                        createUser = value;
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: const Border(
                          bottom: const BorderSide(
                            color: Colors.black,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Text(createDate =
                                selectedPunchListElement.createDate),
                          ),
                          Expanded(
                            child: Container(
                              child: IconButton(
                                icon: Icon(Icons.date_range),
                                onPressed: () => _selectDate(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextFormField(
                      initialValue:
                          selectedPunchListElement.explanationPunchlist,
                      maxLines: 4,
                      maxLength: 200,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        labelText: 'パンチリスト概要',
                      ),
                      validator: (String value) {
                        return '\n'.allMatches(value).length > 7
                            ? '７行以内で入力してください'
                            : null;
                      },
                      onSaved: (String value) {
                        explanationPunchlist = value;
                      },
                    ),
                    RaisedButton(
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          _formKey.currentState.save();
                          _submission();
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/', ModalRoute.withName('/'));
                        }
                      },
                      child: Text('保存'),
                    )
                  ],
                )),
          )),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2030),
    );
    if (selected != null) {
      setState(() {
        createDate = (DateFormat.yMMMd()).format(selected);
      });
    }
  }

  Future<void> _submission() async {
    PunchlistElement punchlistElement;
    PunchlistModel punchlistModel = new PunchlistModel();
    punchlistElement = new PunchlistElement(
      punchlistId: selectedPunchListElement.punchlistId,
      punchlistName: punchlistName,
      createDate: createDate,
      createUser: createUser,
      explanationPunchlist: explanationPunchlist,
    );
    await punchlistModel.update(punchlistElement);
  }
}
