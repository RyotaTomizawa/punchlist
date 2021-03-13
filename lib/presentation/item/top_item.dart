import 'dart:io';
import 'package:flutter/material.dart';
import 'package:punch_list_app/domain/item.dart';
import 'package:punch_list_app/domain/punchlist_element.dart';
import 'package:punch_list_app/presentation/control/db_provider.dart';
import 'package:punch_list_app/services/admob.dart';
import '../model/item_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:admob_flutter/admob_flutter.dart';

class TopItemPageState extends StatefulWidget {
  @override
  _TopItemPageState createState() => _TopItemPageState();
}

class _TopItemPageState extends State {
  @override
  Widget build(BuildContext context) {
    PunchlistElement selectedPunchlistElement =
        ModalRoute.of(context).settings.arguments;
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedPunchlistElement.punchlistName,
            style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        child: ChangeItemlist(selectedPunchlistElement),
      ),
      bottomNavigationBar: AdmobBanner(
        adUnitId: AdMobService().getBannerAdUnitId(),
        adSize: AdmobBannerSize(
          width: MediaQuery.of(context).size.width.toInt(),
          height: AdMobService().getHeight(context).toInt(),
          name: 'SMART_BANNER',
        ),
      ),
      floatingActionButton: Column(
        verticalDirection: VerticalDirection.up,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FloatingActionButton(
            backgroundColor: Colors.blue,
            child: Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/addItem',
                  arguments: selectedPunchlistElement);
            },
          ),
        ],
      ),
    );
  }
}

class ChangeItemlist extends StatefulWidget {
  @override
  PunchlistElement selectedPunchlistElement;
  ChangeItemlist(this.selectedPunchlistElement);
  State<StatefulWidget> createState() =>
      _ChangeItemlist(selectedPunchlistElement);
}

class _ChangeItemlist extends State<ChangeItemlist> {
  @override
  PunchlistElement selectedPunchlistElement;
  _ChangeItemlist(this.selectedPunchlistElement);
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: StreamBuilder(
          stream: ItemModel(selectedPunchlistElement.punchlistId).itemStream,
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
                child: Text('アイテムがありません'),
              );
            }
            //該当データあり
            return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (context, int index) {
                return Slidable(
                  actionPane: SlidableScrollActionPane(),
                  // 右側に表示するWidget
                  secondaryActions: [
                    IconSlideAction(
                      caption: '編集',
                      color: Colors.yellow,
                      icon: Icons.edit,
                      onTap: () {
                        Navigator.pushNamed(context, '/editItem', arguments: {
                          "selectedItem": snapshot.data[index],
                          "selectedPunchListElement": selectedPunchlistElement
                        });
                      },
                    ),
                    IconSlideAction(
                      caption: '削除',
                      color: Colors.red,
                      icon: Icons.remove,
                      onTap: () {
                        _showDialog(snapshot.data[index]);
                      },
                    ),
                  ],
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.only(bottom: 5.0),
                    child: ListTile(
                        title: Text(snapshot.data[index].itemName),
                        leading: snapshot.data[index].imgName != ''
                            ? Container(
                                width: 50.0,
                                height: 50.0,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border:
                                        snapshot.data[index].itemStatus == "1"
                                            ? Border.all(
                                                color: Colors.green, width: 2)
                                            : Border.all(
                                                color: Colors.red, width: 2),
                                    image: DecorationImage(
                                        fit: BoxFit.fill,
                                        image: AssetImage(
                                            DBProvider.documentsDirectory.path +
                                                "/" +
                                                snapshot.data[index].imgName))),
                              )
                            : Container(
                                width: 50.0,
                                height: 50.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: snapshot.data[index].itemStatus == "1"
                                      ? Border.all(
                                          color: Colors.green, width: 2)
                                      : Border.all(color: Colors.red, width: 2),
                                ),
                              ),
                        subtitle:
                            snapshot.data[index].itemExplanation.length >= 34
                                ? Text(snapshot.data[index].itemExplanation
                                        .replaceAll('\n', '')
                                        .substring(0, 34) +
                                    '..')
                                : Text(snapshot.data[index].itemExplanation
                                    .replaceAll('\n', '')),
                        onTap: () async {
                          Item item;
                          ItemModel itemModel =
                              new ItemModel(snapshot.data[index].punchlistId);
                          item = Item(
                            punchlistId: snapshot.data[index].punchlistId,
                            itemId: snapshot.data[index].itemId,
                            imgName: snapshot.data[index].imgName,
                            itemName: snapshot.data[index].itemName,
                            itemExplanation:
                                snapshot.data[index].itemExplanation,
                            itemStatus: snapshot.data[index].itemStatus == "1"
                                ? "0"
                                : "1",
                          );
                          await itemModel.update(item);
                          await setState(() {});
                        }),
                  ),
                );
              },
            );
          }),
    );
  }

  _showDialog(Item selectedItem) {
    showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("このアイテムを削除しますか？"),
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
                    ItemModel itemModel =
                        ItemModel(selectedPunchlistElement.punchlistId);
                    itemModel.delete(selectedItem);
                    if (selectedItem.imgName != "") {
                      final path = await DBProvider.documentsDirectory.path;
                      String imageName = selectedItem.imgName;
                      final dir = Directory('$path/$imageName');
                      dir.deleteSync(recursive: true);
                    }
                    setState(() {});
                    Navigator.of(context).pop();
                  }),
            ],
          );
        });
  }
}
