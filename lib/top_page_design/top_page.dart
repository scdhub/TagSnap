import 'package:flutter/material.dart';
import 'package:tagsnap/top_page_design/top_inventory_btn.dart';
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
    // TODO: implement build
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
            top: MediaQuery
                .of(context)
                .padding
                .top + 5
        ), // ステータスバーの高さを考慮した上部の余白を追加
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  '#TagSnap', //'iTemsPro ver.(3.0.1)',
                  style: TextStyle(fontSize: 55,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                )
            ),
            //ボタンリスト
            Center(child: TopSettingBtn()), //設定ボタン
            SizedBox(height: 10),
            Center(child: TopWritingBtn()), //書込ボタン
            SizedBox(height: 10),
            Center(child: TopLoadingBtn()), //読込ボタン
            SizedBox(height: 10),
            Center(child: TopInventoryBtn()), //棚卸ボタン
            SizedBox(height: 10),
            Center(child: TopSearchBtn()), //探索ボタン
            SizedBox(height: 10),
            Center(child: TopLedBtn()), //LED点灯ボタン
            SizedBox(height: 10),
            Center(child: TopLocationBtn()), //ロケーション管理ボタン
            SizedBox(height: 10),
            Center(child: TopQrBtn()), //QRコードボタン

            Spacer(),

            // アプリバージョン表示（下部に移動）
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                '(ver.3.0.1)', // バージョン情報
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