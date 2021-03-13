import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:punch_list_app/domain/item.dart';
import 'package:punch_list_app/domain/punchlist_element.dart';
import 'package:punch_list_app/presentation/model/punchlist_model.dart';
import 'package:punch_list_app/presentation/punchlist/edit_punchlist.dart';
import 'package:punch_list_app/services/admob.dart';
import 'package:punch_list_app/tutorial/tutorialPage.dart';
import 'add_punchlist.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:punch_list_app/presentation/control/db_provider.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopPunchlistPageState extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TopPunchlistPageState();
}

class _TopPunchlistPageState extends State {
  Email email;
  @override
  initState() {
    super.initState();
    _showTutorial(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.help_outline_sharp),
          onPressed: () => setState(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TutorialPage(),
                fullscreenDialog: true,
              ),
            );
          }),
        ),
        title: Text(
          "パンチリスト",
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
      ),
      body: WillPopScope(
          onWillPop: () async => false,
          child: Container(
            color: Colors.grey[50],
            child: StreamBuilder(
                stream: PunchlistModel().punchlistStream,
                builder: (context, snapshot) {
                  //読み込み中
                  if (snapshot.data == null) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  //該当データなし
                  if (snapshot.data.length == 0) {
                    return Center(
                      child: Text('パンチリストがありません'),
                    );
                  }
                  //該当データあり
                  return ListView.builder(
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, int index) {
                      return Slidable(
                        actionPane: SlidableScrollActionPane(),
                        actions: <Widget>[
                          IconSlideAction(
                            caption: '共有',
                            color: Colors.blue,
                            icon: Icons.mail,
                            onTap: () async {
                              String pdfPath;
                              await getPdfPath(snapshot.data[index])
                                  .then((value) {
                                pdfPath = value;
                                email = Email(
                                  body:
                                      '\n\n\n\n\n報告までできる施工管理アプリ「パンチリスト」で作成されました。\n'
                                      'https://apps.apple.com/jp/app/id1555640163',
                                  attachmentPaths: [pdfPath],
                                );
                              });
                              await FlutterEmailSender.send(email);
                              final dir = Directory(pdfPath);
                              dir.deleteSync(recursive: true);
                            },
                          ),
                        ],
                        secondaryActions: [
                          IconSlideAction(
                            caption: '編集',
                            color: Colors.yellow,
                            icon: Icons.edit,
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditPunchlistPageState(
                                            snapshot.data[index]),
                                  ));
                            },
                          ),
                          IconSlideAction(
                            caption: '削除',
                            color: Colors.red,
                            icon: Icons.remove,
                            onTap: () {
                              _showDialog(snapshot.data[index].punchlistId);
                            },
                          ),
                        ],
                        child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.only(bottom: 5.0),
                          child: ListTile(
                              leading: Icon(Icons.folder_rounded),
                              title: Text(snapshot.data[index].punchlistName),
                              subtitle: snapshot.data[index]
                                          .explanationPunchlist.length >=
                                      34
                                  ? RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: Colors.black),
                                        children: [
                                          TextSpan(
                                              text: snapshot
                                                  .data[index].createDate),
                                          TextSpan(text: '\n'),
                                          TextSpan(
                                              text: snapshot.data[index]
                                                      .explanationPunchlist
                                                      .replaceAll('\n', '')
                                                      .substring(0, 34) +
                                                  '..'),
                                        ],
                                      ),
                                    )
                                  : RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: Colors.black),
                                        children: [
                                          TextSpan(
                                              text: snapshot
                                                  .data[index].createDate),
                                          TextSpan(text: '\n'),
                                          TextSpan(
                                              text: snapshot.data[index]
                                                  .explanationPunchlist
                                                  .replaceAll('\n', '')),
                                        ],
                                      ),
                                    ),
                              trailing: Icon(Icons.arrow_forward_ios_rounded),
                              onTap: () {
                                Navigator.of(context).pushNamed('/itemMain',
                                    arguments: snapshot.data[index]);
                              }),
                        ),
                      );
                    },
                  );
                }),
          )),
      floatingActionButton: Column(
        verticalDirection: VerticalDirection.up,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FloatingActionButton(
            backgroundColor: Colors.blue,
            child: Icon(Icons.library_add_outlined),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPunchlistPageState(),
                  ));
            },
          ),
        ],
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

  static Future<String> getPdfPath(
      PunchlistElement selectedPunchlistElement) async {
    File savedFile;
    List<Item> itemlist = await DBProvider.db
        .getAllItemByPunchlistId(selectedPunchlistElement.punchlistId);
    final punchlistName = selectedPunchlistElement.punchlistName;
    final path = await DBProvider.documentsDirectory.path;
    final pdfPath = '$path/$punchlistName.pdf';
    final pdfFile = File(pdfPath);
    final pdf = pw.Document();
    var data = await rootBundle.load('assets/font/ipagp.ttf');
    final ttf = pw.Font.ttf(data);
    if (itemlist.length != 0) {
      for (var itemNum = 0; itemNum < itemlist.length; itemNum += 5) {
        List<pw.Widget> itemPdfList = List<pw.Widget>();
        pdf.addPage(pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                children: <pw.Widget>[
                  layoutPunchlistElement(selectedPunchlistElement, ttf),
                  layoutItem(itemlist, ttf, itemNum, itemPdfList)
                ],
              );
            }));
      }
    } else {
      pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              child: layoutPunchlistElement(selectedPunchlistElement, ttf),
            );
          }));
    }
    savedFile = await pdfFile.writeAsBytes(await pdf.save());
    return await savedFile.path;
  }

  void _showTutorial(BuildContext context) async {
    final pref = await SharedPreferences.getInstance();
    if (pref.getBool('isAlreadyFirstLaunch') != true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TutorialPage(),
          fullscreenDialog: true,
        ),
      );
      await pref.setBool('isAlreadyFirstLaunch', true);
    }
  }

  static pw.Widget layoutPunchlistElement(
      PunchlistElement selectedPunchlistElement, pw.Font ttf) {
    String punchlistName = selectedPunchlistElement.punchlistName;
    String createDate = selectedPunchlistElement.createDate;
    String explanationPunchlist = selectedPunchlistElement.explanationPunchlist;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          punchlistName,
          style: pw.TextStyle(font: ttf, fontSize: 20),
        ),
        pw.Text(
          "パンチリスト作成日　：　" + createDate,
          style: pw.TextStyle(font: ttf, fontSize: 10),
        ),
        pw.Text(
          explanationPunchlist,
          style: pw.TextStyle(font: ttf, fontSize: 10),
        ),
        pw.Divider(
          height: 20,
        ),
      ],
    );
  }

  static dynamic layoutItem(List<Item> itemlist, pw.Font ttf, int itemNum,
      List<pw.Widget> itemPdfList) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: _getItemlistPdf(itemlist, ttf, itemNum, itemPdfList),
    );
  }

  static List<pw.Widget> _getItemlistPdf(List<Item> itemlist, pw.Font ttf,
      int itemNum, List<pw.Widget> itemPdfList) {
    for (int i = 0; i < 5; i++, itemNum++) {
      if (itemlist.length == itemNum) {
        break;
      }
      Item item = itemlist[itemNum];
      String imgPath = DBProvider.documentsDirectory.path + "/" + item.imgName;
      String itemName = item.itemName;
      String itemExplanation = item.itemExplanation;
      String itemStatus = item.itemStatus == '1' ? '作業完了' : '作業未完了';
      itemPdfList.add(pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          item.imgName != ''
              ? layoutImg(imgPath)
              : pw.Text(
                  '画像がありません',
                  style: pw.TextStyle(font: ttf, fontSize: 15),
                ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                itemName,
                style: pw.TextStyle(font: ttf, fontSize: 15),
              ),
              pw.Text(
                itemStatus,
                style: pw.TextStyle(
                    font: ttf,
                    fontSize: 10,
                    color: item.itemStatus == '1'
                        ? PdfColors.green
                        : PdfColors.redAccent),
              ),
              pw.Text(
                itemExplanation,
                style: pw.TextStyle(font: ttf, fontSize: 10),
              ),
            ],
          ),
        ],
      ));
      itemPdfList.add(
        pw.Divider(
          height: 20,
          color: PdfColors.grey,
        ),
      );
    }
    return itemPdfList;
  }

  static pw.Widget layoutImg(String imgPath) {
    if (imgPath != "") {
      final image = pw.MemoryImage(File(imgPath).readAsBytesSync());
      return pw.Image(
        image,
        height: 100,
        width: 100,
      );
    } else {
      return pw.Text("");
    }
  }

  _showDialog(String punchlistId) {
    showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("このパンチリストを削除しますか？"),
            actions: <Widget>[
              FlatButton(
                child: Text("いいえ"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                  child: Text("はい"),
                  onPressed: () async {
                    List<Item> itemlist = await DBProvider.db
                        .getAllItemByPunchlistId(punchlistId);
                    final path = await DBProvider.documentsDirectory.path;
                    for (var item in itemlist) {
                      String imageName = item.imgName;
                      if (imageName != "") {
                        final dir = Directory('$path/$imageName');
                        dir.deleteSync(recursive: true);
                      }
                    }
                    PunchlistModel punchlistModel = new PunchlistModel();
                    punchlistModel.delete(punchlistId);
                    setState(() {});
                    Navigator.of(context).pop();
                  }),
            ],
          );
        });
  }
}
