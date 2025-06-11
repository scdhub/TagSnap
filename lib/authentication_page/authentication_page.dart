import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';

// NFC判定　OFFでも自動遷移させず、テキストだけ更新する
class AuthenticationPage extends StatefulWidget {
  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage>
    with WidgetsBindingObserver {
  bool _nfcEnabled = false; //onoffフラグ
  bool _hasCheckedOnce = false; // 初回チェックフラグ

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _autoNfcCheckAndNavigate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateNfcStatus();
    }
  }

  // アプリ起動時（initState）に実行する。NFCがOFFなら設定画面へ遷移。
  Future<void> _autoNfcCheckAndNavigate() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    setState(() => _nfcEnabled = isAvailable);

    if (!isAvailable && !_hasCheckedOnce) {
      _hasCheckedOnce = true;
      _openNfcSettings();
    }
  }

  // 画面復帰時（resume）のみステータス更新。
  Future<void> _updateNfcStatus() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    setState(() => _nfcEnabled = isAvailable);
  }

  // 設定画面を開く共通メソッド
  Future<void> _openNfcSettings() async {
    const platform = MethodChannel('com.example.tagsnap/settings');
    try {
      await platform.invokeMethod('openNfcSettings');
    } on PlatformException catch (e) {
      debugPrint('Failed to open settings: \${e.message}');
    }
  }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '真贋判定',
            style: TextStyle(
              color: Color(0xFF84848F),
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 80,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _nfcEnabled ? Color(0xFFFD0D8D) : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  _nfcEnabled ? 'NFC設定：ON' : 'NFC設定：OFF',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              if (!_nfcEnabled) ...[
                SizedBox(height: 5),
                Text(
                  '※ NFC設定からONにしてください',
                  style: TextStyle(fontSize: 15, color: Colors.redAccent),
                ),
              ],
              SizedBox(height: 50),
              Text(
                'NFCモードの設定',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              SizedBox(height: 5),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () {
                  _openNfcSettings();
                },
                child: Text('NFC設定画面', style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ),
      );
    }
  }

