import 'dart:io';
import 'package:flutter/material.dart';

class AdMobService {
  String getBannerAdUnitId() {
    // iOSとAndroidで広告ユニットIDを分岐させる
    if (Platform.isAndroid) {
      // Androidの広告ユニットID
      return null;
    } else if (Platform.isIOS) {
      // iOSの広告ユニットID
      return 'ca-app-pub-6708681869328892/8846770761';
      //'ca-app-pub-3940256099942544/6300978111';
    }
    return null;
  }

  // 表示するバナー広告の高さを計算
  double getHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final percent = (height * 0.1).toDouble();

    return percent;
  }
}
