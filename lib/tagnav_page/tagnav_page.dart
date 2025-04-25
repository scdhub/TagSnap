import 'dart:async';
import 'package:flutter/material.dart';
import "package:url_launcher/url_launcher.dart";
import '../theme.dart';
import '../top_page_design/top_select_page/top_page.dart';

class TagnavPage extends StatefulWidget {
  const TagnavPage({super.key});

  @override
  State<TagnavPage> createState() => _TagnavPageState();
}

class _TagnavPageState extends State<TagnavPage> with WidgetsBindingObserver {
  int _dotCount = 0;
  Timer? _dotTimer;
  bool _launched = false;
  bool _returnBrowser = false; //

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _startAnimation();

    if (!_launched) {
      _launched = true;
      _launchTagNavURL();
    }
  }

  void _startAnimation() {
    _dotTimer?.cancel(); // 念のため前のタイマーをキャンセル
    _dotTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      setState(() {
        _dotCount = (_dotCount + 1) % 4;
      });
    });
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _launched && !_returnBrowser) {
      // ブラウザから戻ってきたと判定できるタイミング
      _returnBrowser = true;
      // アニメーションを止める
      _dotTimer?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TopPage(
            title: 'TagSnap',
          ), // ← 1つ前の画面に戻る
        ),
      );
      //   Future.delayed(Duration(seconds: 1), () {
      //     if (mounted) {
      //       Navigator.of(context).pushReplacement(
      //         MaterialPageRoute(
      //           builder: (_) => TopPage(
      //             title: 'TagSnap',
      //           ), // ← 1つ前の画面に戻る
      //         ),
      //       );
      //     }
      //   });
    }
  }

  Future<void> _launchTagNavURL() async {
    // const url = 'https://54.248.227.206/gps-tracker/public/';
    const url =
        'http://ec2-54-248-227-206.ap-northeast-1.compute.amazonaws.com/gps-tracker/public/';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Text(
          'TagNavを起動中$dots',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
