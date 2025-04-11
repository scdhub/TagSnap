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
          '操作メニュー', style: TextStyle(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildButton(const LocInboundBtn()),    // 入庫
            _buildButton(const LocDepartureBtn()),  // 出荷
            _buildButton(const LocInventoryBtn()),  // 棚卸
            _buildButton(const LocSearchBtn()),     // 探索
            _buildButton(const LocLedBtn()),        // LED
            _buildButton(const LocMoveBtn()),       // 移動
            _buildButton(const LocStockListBtn()),  // 在庫リスト
            _buildButton(const LocExportBtn()),     // エクスポート
            _buildButton(const LocImportBtn()),     // インポート
          ],
        ),
      ),
    );
  }

  Widget _buildButton(Widget button) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: button,
    );
  }
}
