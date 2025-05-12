import 'package:flutter/material.dart';
import 'package:tagsnap/common_method/api_common.dart';


// アプリ終了時に必ずSharedPreferenceへの書き出しを行う用の監視クラス
class LifecycleHandler with WidgetsBindingObserver {
  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      SharedPreferenceInfo().dispose();
    }
  }
}