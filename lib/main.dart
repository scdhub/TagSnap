import 'package:flutter/material.dart';
import 'package:tagsnap/splash_page/start_splash.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:tagsnap/top_page_design/top_select_page/top_page.dart';
import 'theme.dart';


void main() {
  runApp(const MyApp());
}

// ここでグローバルに１つだけ定義
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // デバッグバナーを非表示
      title: 'TagSnap',
      theme: AppTheme.LightTheme, // `theme.dart` のテーマを適用
      home: const StartSplash(title: 'animation',), // スプラッシュ画面を最初に表示
      navigatorObservers: [routeObserver],
    );
  }
}
