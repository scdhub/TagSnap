import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';

// NFC判定　OFFの場合は設定画面に飛んでOnにさせる動作を追加
class JudgmentPage extends StatefulWidget {
  @override
  _JudgmentPageState createState() => _JudgmentPageState();
}

class _JudgmentPageState extends State<JudgmentPage>
    with WidgetsBindingObserver {
  // 初期値としてNFCは無効（OFF）
  bool _nfcEnabled = false;

  @override
  void initState() {
    super.initState();
    _nfcOnOffCheck();
    WidgetsBinding.instance.addObserver(this);
  }

  // 非同期処理関数
  Future<void> _nfcOnOffCheck() async {
    bool isAvailable = await NfcManager.instance.isAvailable();

    setState(() {
      _nfcEnabled = isAvailable;
    });

    //   //　有無を言わさずOFFであれば設定画面へ
    // if (!isAvailable) {
    //   nfcSetting();
    // }
  }

  //　NFC設定画面に遷移する処理
  Future<void> nfcSetting() async {
    const platform = MethodChannel('com.example.tagsnap/settings');

    try {
      await platform.invokeMethod('openNfcSettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open settings: ${e.message}");
    }
  }

  // //　真贋判定画面外に移動して戻ってきた後にOn/Offチェックをする
  // //　以下処理がループの原因になっている。
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed) {
  //     // アプリに戻ってきたとき再チェック
  //     _nfcOnOffCheck();
  //   }
  // }

// 画面UI
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
            // NFCステータス表示
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
            // OFF時だけ出す注意メッセージ
            if (!_nfcEnabled) ...[
              SizedBox(height: 5),
              Text(
                '※ NFC設定からONにしてください',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.redAccent,
                ),
              ),
            ],

            SizedBox(height: 50),
            Text(
              "NFCモードの設定",
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 5),
            ElevatedButton(
              style:
              ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                nfcSetting();
              },
              child: Text(
                "NFC設定画面",
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
