import 'dart:async';
import '../control/db_provider.dart';
import '../../domain/item.dart';

class ItemModel {
  final _itemController = StreamController<List<Item>>();
  Stream<List<Item>> get itemStream => _itemController.stream;

  ItemModel(String punchlistId) {
    getItem(punchlistId);
  }

  getItem(String punchlistId) async {
    _itemController.sink
        .add(await DBProvider.db.getAllItemByPunchlistId(punchlistId));
  }

  Future<Stream<List<Item>>> getItemStream(String punchlistId) async {
    _itemController.sink
        .add(await DBProvider.db.getAllItemByPunchlistId(punchlistId));
    return itemStream;
  }

  dispose() {
    _itemController.close();
  }

  create(Item item) {
    DBProvider.db.createItem(item);
    getItem(item.punchlistId);
  }

  update(Item item) {
    DBProvider.db.updateItem(item);
    getItem(item.punchlistId);
  }

  delete(Item item) {
    DBProvider.db.deleteItemByItemId(item.itemId);
    getItem(item.punchlistId);
  }
}
