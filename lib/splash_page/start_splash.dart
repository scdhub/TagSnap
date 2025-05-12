import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../setting_page/setting_menu_page/activation_page.dart';
import '../setting_page/setting_menu_page/login_page.dart';
import '../top_page_design/top_select_page/top_page.dart'; // 遷移に使う
import 'package:package_info_plus/package_info_plus.dart'; //ver情報を取るために使う
import 'package:tagsnap/common_method/api_common.dart';


class StartSplash extends StatefulWidget {
  const StartSplash({Key? key, required String title}) : super(key: key);


  @override
  State<StartSplash> createState() => _StartSplashState();
}

class _StartSplashState extends State<StartSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  String _appVersion = ''; //バージョン情報を取得するクラス


  @override
  void initState() {
    super.initState();
    _loadAppVersion();//バージョン情報を取得するための処理
    // アニメーションコントローラ
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
    // )..repeat(reverse: true);

    // テキストを拡大縮小
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // フェードインアウト　
    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 一定時間後にTopへ遷移させる
    Future.delayed(const Duration(seconds: 5), _checkAndNavigate);
  }

  //app情報を取得する
  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  Future<void> _checkAndNavigate() async {
    //final activated = true;
    final activated = (SharedPreferenceInfo().deviceUUID.length > 0) ? true : false; //アクティベーションtrue:済　false:未
    final loggedIn  = false;
    //prefs.getBool('loggedIn')  ?? true; //ログインtrue:済　false:未

    if (!activated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ActivationPage()),
      );
    } else if (!loggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TopPage(title: 'TagSnap')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: const Text(
                'Smart Logi X',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Color(0xFF5E7EB6)
                ),
              ),
            ),
          ),

          //バージョン情報
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('TagSnap', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text('ver$_appVersion', style: const TextStyle(fontSize: 20, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

