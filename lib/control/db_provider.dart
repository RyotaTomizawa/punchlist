import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import '../domain/punchlist_element.dart';
import '../domain/item.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();
  static Database _database;
  static Directory documentsDirectory;
  static final tableNamePunchlist = "PunchlistTable";
  static final tableNameItem = "ItemTable";

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
      int samplePunchlistId = 1;
      PunchlistElement punchlistElement = new PunchlistElement(
        punchlistName: "カフェの設営",
        createDate: (DateFormat.yMMMd()).format(DateTime.now()),
        explanationPunchlist: "サンプルで作成されましたパンチリストです。"
            "\n南青山の空きテナントにカフェを設営する。"
            "\n担当する仕事は毎週水曜日にチーフへメールで共有する。"
            "\n期限が短いタスクから着手していく。",
      );
      await db.insert(tableNamePunchlist, punchlistElement.toMap());
      Item sampleItem1 = Item(
        punchlistId: samplePunchlistId,
        imgName: "",
        itemName: "椅子の設営",
        itemExplanation: "サンプルで作成されたタスクです。"
            "\n合計20脚の椅子を設営する"
            "\n内訳：白が10個、黒が10個"
            "\n白いテーブルには白い椅子"
            "\n黒いテーブルには黒い椅子"
            "\n作業員が必要な場合は事前にメールで募る",
        itemStatus: "1",
      );
      await db.insert(tableNameItem, sampleItem1.toMap());
      Item sampleItem2 = Item(
        punchlistId: samplePunchlistId,
        imgName: "",
        itemName: "テーブルの搬入",
        itemExplanation: "サンプルで作成されたタスクです。"
            "\n合計10個のテーブルを設営する"
            "\n内訳：白が5個、黒が5個"
            "\n作業員が必要な場合は事前にメールで募る",
        itemStatus: "0",
      );
      await db.insert(tableNameItem, sampleItem2.toMap());
      await pref.setBool('isAlreadySample', true);
    }
  }

  Future<Database> initDB() async {
    documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "Punchlist_info_DB.db");
    return await openDatabase(path, version: 1, onCreate: _createTable);
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute("CREATE TABLE PunchlistTable ("
        "punchlistId INTEGER PRIMARY KEY AUTOINCREMENT,"
        "punchlistName TEXT,"
        "createDate TEXT,"
        "explanationPunchlist TEXT"
        ")");
    await db.execute("CREATE TABLE ItemTable ("
        "punchlistId INTEGER,"
        "itemId INTEGER PRIMARY KEY AUTOINCREMENT,"
        "imgName TEXT,"
        "itemName TEXT,"
        "itemExplanation TEXT,"
        "itemStatus TEXT"
        ")");
  }

  // punchlist CRUDメソッド
  createPunchlistElement(PunchlistElement punchlistElement) async {
    final db = await database;
    var res = await db.insert(tableNamePunchlist, punchlistElement.toMap());
    return res;
  }

  getAllPunchlist() async {
    final db = await database;
    var res = await db.query(
      tableNamePunchlist,
      orderBy: "punchlistId DESC",
    );
    List<PunchlistElement> list = res.isNotEmpty
        ? res.map((c) => PunchlistElement.fromMap(c)).toList()
        : [];
    return list;
  }

  Future<void> updatePunchlist(PunchlistElement pundhlistElement) async {
    final db = await database;
    var res = await db.update(
      tableNamePunchlist,
      pundhlistElement.toMap(),
      where: "punchlistId = ?",
      whereArgs: [pundhlistElement.punchlistId],
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
    return res;
  }

  deletePunchlist(int punchlistId) async {
    final db = await database;
    var res = db.delete(tableNamePunchlist,
        where: "punchlistId = ?", whereArgs: [punchlistId]);
    return res;
  }

  // item CRUDメソッド
  createItem(Item item) async {
    final db = await database;
    var res = await db.insert(tableNameItem, item.toMap());
    return res;
  }

  getAllItemByPunchlistId(int punchlistId) async {
    final db = await database;
    var res = await db.query(
      tableNameItem,
      where: 'punchlistId = ?',
      whereArgs: [punchlistId],
      orderBy: "itemId DESC",
    );
    List<Item> list =
        res.isNotEmpty ? res.map((c) => Item.fromMap(c)).toList() : [];
    return list;
  }

  updateItem(Item item) async {
    final db = await database;
    var res = await db.update(tableNameItem, item.toMap(),
        where: "itemId = ?", whereArgs: [item.itemId]);
    return res;
  }

  deleteItemByItemId(int itemId) async {
    final db = await database;
    var res =
        db.delete(tableNameItem, where: "itemId = ?", whereArgs: [itemId]);
    return res;
  }

  deleteItemByPunchlistId(int punchlistId) async {
    final db = await database;
    var res = db.delete(tableNameItem,
        where: "punchlistId = ?", whereArgs: [punchlistId]);
    return res;
  }
}
