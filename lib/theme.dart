import 'package:flutter/material.dart';

class AppTheme {
  // 全体的なメインカラー
  static const Color primaryColor = Color(0xFF84848F); // 基準色/背景色
  static const Color textColor = Colors.white; // 全体のテキストカラー
  static const Color appBarTextColor = Colors.white; // AppBar全体の文字色
  static const Color iconColor = Colors.white; // アイコン全体の色
  static const Color buttonColor = Color(0xFF29B6F6); // ボタン全体の色（青系）

  //確認ダイアログのボタン
  static const Color confirmDialogButtonColor = Color(0xFFF06292);
  static const Color confirmDialogBorderColor = Color(0xFFEF85A9);
  static const Color cancelDialogButtonColor = Colors.white;
  static const Color cancelDialogBorderColor = Color(0xFFEF85A9);

  //フィルターボタンON/OFFの色
  static const Color filterOnColor = Color(0xFFBBDEFB); // 明るい青（ON用）
  static const Color filterOffColor = Color(0xFFE0E0E0); // グレー（OFF用）
  static const Color filterOnTextColor = Colors.black; // ON時は濃い文字
  static const Color filterOffTextColor = Colors.grey; // OFF時は薄い文字


  // ダイアログテーマ（確認ダイアログ）
  static final confirmDialogTheme = DialogTheme(
    backgroundColor: Colors.white,
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 25,
    ),
    contentTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 18,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

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
      onSurface: Colors.black87, // サーフェス上の文字色
    ),

    textSelectionTheme: TextSelectionThemeData(
      selectionHandleColor: Colors.black87, // ← これで丸い部分の色が変わる
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
