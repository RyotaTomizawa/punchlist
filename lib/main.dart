import 'package:flutter/material.dart';
import 'package:punch_list_app/presentation/item/add_item.dart';
import 'package:punch_list_app/presentation/item/edit_item.dart';
import 'package:punch_list_app/presentation/punchlist/top_punchlist.dart';
import 'common/punchlist_colors.dart';
import 'presentation/item/top_item.dart';
import 'package:admob_flutter/admob_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Admob.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyApp createState() => _MyApp();
}

class _MyApp extends State {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => TopPunchlistPageState(),
        '/itemMain': (BuildContext context) => TopItemPageState(),
        '/addItem': (BuildContext context) => AddItemPageState(),
        '/editItem': (BuildContext context) => EditItemPageState(),
      },
      theme: punchlistTheme(),
    );
  }
}
