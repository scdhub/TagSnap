import 'package:flutter/material.dart';

class AppTheme {
  // 全体的なメインカラー
  static const Color primaryColor = Color(0xFFC9C9D1); // 基準色/背景色
  static const Color textColor = Colors.white; // 全体のテキストカラー
  static const Color appBarTextColor = Colors.white; // AppBar全体の文字色
static const Color iconColor = Colors.white; // アイコン全体の色
static const Color buttonColor = Color(0xFF29B6F6); // ボタン全体の色（青系）

  // AppBarのデザイン（詳細）
  static final LightTheme = ThemeData(
    useMaterial3: false,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      // primaryColorから基準の色を計算
      brightness: Brightness.light,
      //primarycolorに対して白文字が表示
      primary: primaryColor,
      // 主要な色を primaryColor に設定　ボタンとタブバーとか
      onPrimary: Colors.white,
      // //テキストやアイコンの色を指定、その上に白い文字（onPrimary: Colors.white）を表示する
      // secondary: buttonColor,
      // サブカラーとして buttonColor を設定
      onSecondary: Colors.white,
      // secondaryColor の上に表示する文字色は白
      surface: Colors.white,
      // サーフェスカラー（背景色など）
      onSurface: textColor, // サーフェス上の文字色
    ),

    scaffoldBackgroundColor: primaryColor,
    fontFamily: 'NotoSansJP',
    //テキスト全体のフォント

    // AppBarのデザイン（詳細）
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.grey),
      actionsIconTheme: IconThemeData(color: Colors.white54),
      // アクションアイコン
      titleTextStyle: TextStyle(
        color: Colors.black, // タイトル文字色
        fontSize: 17,
        fontWeight: FontWeight.bold, //太字
      ),
    ),
  );
}
