import 'package:flutter/material.dart';
import 'package:punch_list_app/services/admob.dart';
import '../../domain/punchlist_element.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../model/punchlist_model.dart';
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
    String createDate = selectedPunchListElement.createDate;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("パンチリスト編集", style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        child: ChangeForm(selectedPunchListElement, createDate),
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
  String createDate;
  ChangeForm(this.selectedPunchListElement, this.createDate);
  _ChangeFormState createState() =>
      _ChangeFormState(selectedPunchListElement, createDate);
}

class _ChangeFormState extends State<ChangeForm> {
  PunchlistElement selectedPunchListElement;
  _ChangeFormState(this.selectedPunchListElement, this.createDate);
  final _formKey = GlobalKey<FormState>();
  String punchlistName = '';
  String createDate;
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
                        if ('\n'.allMatches(value).length > 7) {
                          return '７行以内で入力してください';
                        }
                        if (value.isEmpty) {
                          return '必須項目です';
                        }
                        return null;
                      },
                      onSaved: (String value) {
                        punchlistName = value;
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
                            child: Text(createDate),
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
                      maxLines: 7,
                      maxLength: 190,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        labelText: 'パンチリスト概要',
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
      explanationPunchlist: explanationPunchlist,
    );
    await punchlistModel.update(punchlistElement);
  }
}
