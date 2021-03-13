import 'package:flutter/material.dart';

ThemeData punchlistTheme() {
  return ThemeData.from(
    colorScheme: ColorScheme.light(
      primary: HexColor('#2196F3'),
      onSecondary: HexColor('#FFFFFF'),
      background: HexColor('#FFFFFF'),
    ),
  );
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}
