import 'dart:async';
import '../control/db_provider.dart';
import '../domain/punchlist_element.dart';

class PunchlistModel {
  final _punchlistElementController =
      StreamController<List<PunchlistElement>>();
  Stream<List<PunchlistElement>> get punchlistStream =>
      _punchlistElementController.stream;

  getPunchlist() async {
    _punchlistElementController.sink.add(await DBProvider.db.getAllPunchlist());
  }

  PunchlistModel() {
    getPunchlist();
  }

  dispose() {
    _punchlistElementController.close();
  }

  create(PunchlistElement punchlistElement) {
    DBProvider.db.createPunchlistElement(punchlistElement);
    getPunchlist();
  }

  update(PunchlistElement punchlistElement) {
    DBProvider.db.updatePunchlist(punchlistElement);
    getPunchlist();
  }

  delete(int punchlistId) {
    DBProvider.db.deletePunchlist(punchlistId);
    DBProvider.db.deleteItemByPunchlistId(punchlistId);
    getPunchlist();
  }
}
