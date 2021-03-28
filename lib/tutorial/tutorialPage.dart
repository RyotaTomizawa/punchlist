import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overboard/flutter_overboard.dart';

class TutorialPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        brightness: Brightness.light,
        iconTheme: IconThemeData(color: Colors.black45),
        title: Text('チュートリアル', style: TextStyle(color: Colors.black87)),
      ),
      body: OverBoard(
        pages: pages,
        showBullets: true,
        skipCallback: () {
          Navigator.pop(context);
        },
        finishCallback: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  final pages = [
    PageModel(
        color: const Color(0xFF95cedd),
        imageAssetPath: 'assets/imgTutorial1.png',
        title: 'パンチリスト画面',
        body: 'タップ:タスク画面へ遷移\n'
            '左スワイプ:パンチリスト編集\n'
            '右スワイプ:テンプレートメール送信',
        doAnimateImage: true),
    PageModel(
        color: const Color(0xFF90CAF9),
        imageAssetPath: 'assets/imgTutorial2.png',
        title: 'タスク画面',
        body: 'タップ:タスク編集\n'
            '左スワイプ:タスク削除',
        doAnimateImage: true),
    PageModel.withChild(
        child: Padding(
            padding: EdgeInsets.all(25),
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: 'さあ始めましょう\n',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
                TextSpan(
                  text: 'チュートリアルは\nパンチリスト画面左上のアイコンから\nいつでも確認できます',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ]),
            )),
        color: const Color(0xFF5886d6),
        doAnimateChild: true)
  ];
}
