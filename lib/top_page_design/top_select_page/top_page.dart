import 'package:flutter/material.dart';
import 'package:tagsnap/top_page_design/top_inventory_btn.dart';
import 'package:tagsnap/top_page_design/top_judgment_btn.dart';
import 'package:tagsnap/top_page_design/top_led_btn.dart';
import 'package:tagsnap/top_page_design/top_loading_btn.dart';
import 'package:tagsnap/top_page_design/top_location_btn.dart';
import 'package:tagsnap/top_page_design/top_qr_btn.dart';
import 'package:tagsnap/top_page_design/top_search_btn.dart';
import 'package:tagsnap/top_page_design/top_setting_btn.dart';
import 'package:tagsnap/top_page_design/top_writing_btn.dart';


//ホーム画面全体のデザイン
class TopPage extends StatefulWidget {
  final String title;
  const TopPage({super.key, required this.title});

  @override
  State<TopPage> createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SmartLogiX',
          style: TextStyle(color: Color(0xFF84848F),fontSize:40, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 110, // 高さを調整
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 5,
        ),

        child: Column(
          children: [
            SizedBox(height: 50,),
            // 3×3のボタンレイアウト
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 3, // 3列
                  crossAxisSpacing: 10, // 横方向の間隔
                  mainAxisSpacing: 28, // 縦方向の間隔
                  physics: NeverScrollableScrollPhysics(), // スクロールを無効にする
                  children: [
                    TopSettingBtn(), // 設定ボタン
                    TopWritingBtn(), // 書込ボタン
                    TopLoadingBtn(), // 読込ボタン
                    TopInventoryBtn(), // 棚卸ボタン
                    TopSearchBtn(), // 探索ボタン
                    TopLedBtn(), // LED点灯ボタン
                    TopLocationBtn(), // ロケーション管理ボタン
                    TopQrBtn(), // QRコードボタン
                    TopJudgmentBtn(), // 真贋判定ボタン
                  ],
                ),
              ),
            ),

            // バージョン表示
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                '(ver.3.0.1)',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}