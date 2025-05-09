import 'package:flutter/material.dart';
import 'package:tagsnap/top_page_design/top_select_page_btn/top_inventory_btn.dart';
import 'package:tagsnap/top_page_design/top_select_page_btn/top_judgment_btn.dart';
import 'package:tagsnap/top_page_design/top_select_page_btn/top_led_btn.dart';
import 'package:tagsnap/top_page_design/top_select_page_btn/top_loading_btn.dart';
import 'package:tagsnap/top_page_design/top_select_page_btn/top_location_btn.dart';
import 'package:tagsnap/top_page_design/top_select_page_btn/top_qr_btn.dart';
import 'package:tagsnap/top_page_design/top_select_page_btn/top_search_btn.dart';
import 'package:tagsnap/top_page_design/top_select_page_btn/top_setting_btn.dart';
import 'package:tagsnap/top_page_design/top_select_page_btn/top_tagnav_bt.dart';
import 'package:tagsnap/top_page_design/top_select_page_btn/top_writing_btn.dart';


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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'TagSnap',
              style: TextStyle(
                color: Color(0xFF84848F),
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8), // テキストとアイコンの間隔
            Image.asset(
              'assets/assets_tagsnap_image/TagSnap_01.png',
              height: 45,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
      ),


      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 35),
              GridView.count(
                crossAxisCount: 3, // 3列
                crossAxisSpacing: 10,
                mainAxisSpacing: 28,
                shrinkWrap: true, // サイズを中身に合わせる
                physics: NeverScrollableScrollPhysics(), // GridView自体のスクロールはしない
                children: const [
                  TopSettingBtn(),
                  TopWritingBtn(),
                  TopLoadingBtn(),
                  TopInventoryBtn(),
                  TopSearchBtn(),
                  TopLedBtn(),
                  TopLocationBtn(),
                  TopQrBtn(),
                  TopJudgmentBtn(),
                  TopTagnavBt(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}