import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import '../../domain/punchlist_element.dart';
import '../../domain/item.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();
  static Database _database;
  static Directory documentsDirectory;
  static final _tableNamePunchlist = "PunchlistElement";
  static final _tableNameItem = "Item";

  Future<Database> get database async {
    if (_database != null) {
      return _database;
    }
    _database = await initDB();
    await createSampleData(_database);
    return _database;
  }

  void createSampleData(Database db) async {
    final pref = await SharedPreferences.getInstance();
    if (pref.getBool('isAlreadySample') != true) {
      String samplePunchlistId = Uuid().v4();
      PunchlistElement punchlistElement = new PunchlistElement(
        punchlistId: samplePunchlistId,
        punchlistName: "カフェの設営",
        createDate: (DateFormat.yMMMd()).format(DateTime.now()),
        createUser: "サンプルユーザー",
        explanationPunchlist: "サンプルで作成されましたパンチリストです。"
            "\n南青山の空きテナントにカフェを設営する。"
            "\n担当する仕事は毎週水曜日にチーフへメールで共有する。"
            "\n期限が短いタスクから着手していく。",
      );
      await db.insert(_tableNamePunchlist, punchlistElement.toMap());
      Item sampleItem1 = Item(
        punchlistId: samplePunchlistId,
        itemId: Uuid().v4(),
        imgName: "",
        itemName: "椅子の設営",
        itemExplanation: "※サンプルで作成されたタスクです。"
            "\n合計20脚の椅子を設営する"
            "\n内訳：白が10個、黒が10個"
            "\n白いテーブルには白い椅子"
            "\n黒いテーブルには黒いテーブル"
            "\n作業員が必要な場合は事前にメールで募る",
        itemStatus: "1",
      );
      await db.insert(_tableNameItem, sampleItem1.toMap());
      Item sampleItem2 = Item(
        punchlistId: samplePunchlistId,
        itemId: Uuid().v4(),
        imgName: "",
        itemName: "テーブルの搬入",
        itemExplanation: "※サンプルで作成されたタスクです。"
            "\n合計10個のテーブルを設営する"
            "\n内訳：白が5個、黒が5個"
            "\n作業員が必要な場合は事前にメールで募る",
        itemStatus: "0",
      );
      await db.insert(_tableNameItem, sampleItem2.toMap());
      await pref.setBool('isAlreadySample', true);
    }
  }

  Future<Database> initDB() async {
    documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "Punchlist_DB.db");
    return await openDatabase(path, version: 1, onCreate: _createTable);
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute("CREATE TABLE PunchlistElement ("
        "punchlistId TEXT PRIMARY KEY,"
        "punchlistName TEXT,"
        "createDate TEXT,"
        "createUser TEXT,"
        "explanationPunchlist TEXT"
        ")");
    await db.execute("CREATE TABLE Item ("
        "punchlistId TEXT,"
        "itemId TEXT PRIMARY KEY,"
        "imgName TEXT,"
        "itemName TEXT,"
        "itemExplanation TEXT,"
        "itemStatus TEXT"
        ")");
  }

  // punchlist CRUDメソッド
  createPunchlistElement(PunchlistElement punchlistElement) async {
    final db = await database;
    var res = await db.insert(_tableNamePunchlist, punchlistElement.toMap());
    return res;
  }

  getAllPunchlist() async {
    final db = await database;
    var res = await db.query(_tableNamePunchlist);
    List<PunchlistElement> list = res.isNotEmpty
        ? res.map((c) => PunchlistElement.fromMap(c)).toList()
        : [];
    return list;
  }

  Future<void> updatePunchlist(PunchlistElement pundhlistElement) async {
    final db = await database;
    var res = await db.update(
      _tableNamePunchlist,
      pundhlistElement.toMap(),
      where: "punchlistId = ?",
      whereArgs: [pundhlistElement.punchlistId],
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
    return res;
  }

  deletePunchlist(String punchlistId) async {
    final db = await database;
    var res = db.delete(_tableNamePunchlist,
        where: "punchlistId = ?", whereArgs: [punchlistId]);
    return res;
  }

  // item CRUDメソッド
  createItem(Item item) async {
    final db = await database;
    var res = await db.insert(_tableNameItem, item.toMap());
    return res;
  }

  getAllItemByPunchlistId(String punchlistId) async {
    final db = await database;
    var res = await db.query(_tableNameItem,
        where: 'punchlistId = ?', whereArgs: [punchlistId]);
    List<Item> list =
        res.isNotEmpty ? res.map((c) => Item.fromMap(c)).toList() : [];
    return list;
  }

  updateItem(Item item) async {
    final db = await database;
    var res = await db.update(_tableNameItem, item.toMap(),
        where: "itemId = ?", whereArgs: [item.itemId]);
    return res;
  }

  deleteItemByItemId(String itemId) async {
    final db = await database;
    var res =
        db.delete(_tableNameItem, where: "itemId = ?", whereArgs: [itemId]);
    return res;
  }

  deleteItemByPunchlistId(String punchlistId) async {
    final db = await database;
    var res = db.delete(_tableNameItem,
        where: "punchlistId = ?", whereArgs: [punchlistId]);
    return res;
  }
}
