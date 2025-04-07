import 'package:flutter/material.dart';
import 'package:tagsnap/location_page/loc_select_page_btn/loc_import_btn.dart';
import 'package:tagsnap/location_page/loc_select_page_btn/loc_inbound_btn.dart';
import 'package:tagsnap/location_page/loc_select_page_btn/loc_departure_btn.dart';
import 'package:tagsnap/location_page/loc_select_page_btn/loc_inventory_btn.dart';
import 'package:tagsnap/location_page/loc_select_page_btn/loc_search_btn.dart';
import 'package:tagsnap/location_page/loc_select_page_btn/loc_led_btn.dart';
import 'package:tagsnap/location_page/loc_select_page_btn/loc_move_btn.dart';
import 'package:tagsnap/location_page/loc_select_page_btn/loc_stock_list_btn.dart';
import 'package:tagsnap/location_page/loc_select_page_btn/loc_export_btn.dart';

class LocationSelectPage extends StatefulWidget {
  final String title;
  const LocationSelectPage({super.key, required this.title});

  @override
  State<LocationSelectPage> createState() => _LocationSelectPageState();
}

class _LocationSelectPageState extends State<LocationSelectPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '操作メニュー',
          style: TextStyle(
            color: Color(0xFF84848F),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 縦方向に中央揃え
          children: [
            _buildButtonRow(LocInboundBtn(), LocDepartureBtn()), // 入庫 出荷
            const SizedBox(height: 20), // 余白を追加
            _buildButtonRow(LocInventoryBtn(), LocSearchBtn()), // 棚卸 探索
            const SizedBox(height: 20), // 余白を追加
            _buildButtonRow(LocLedBtn(), LocMoveBtn()), // LED 移動
            const SizedBox(height: 20), // 余白を追加
            _buildButtonRow(LocStockListBtn(), LocExportBtn()), // 在庫リスト エクスポート), // 在庫リスト エクスポート
            const SizedBox(height: 20), // 余白を追加
            const Center(child: LocImportBtn()), // 6行目の中央にインポートボタン
          ],
        ),
      ),
    );
  }

  //2つのボタンを並べる行を作成
  Widget _buildButtonRow(Widget leftButton, Widget rightButton) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10), // 上下の余白
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // 水平方向に中央揃え
        children: [
          leftButton,
          const SizedBox(width: 20), // ボタン間の間隔
          rightButton,
        ],
      ),
    );
  }
}
