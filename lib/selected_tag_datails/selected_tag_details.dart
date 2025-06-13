import 'dart:convert';
import 'package:flutter/material.dart';
import '../common_method/api_common.dart';
import '../common_method/selected_tag_details.dart';

class SelectedTagDetails extends StatefulWidget {
  final String initialSelectedEpc;
  final int initialSelectedIndex;

  const SelectedTagDetails({
    super.key,
    required this.initialSelectedEpc,
    required this.initialSelectedIndex,
  });

  @override
  State<StatefulWidget> createState() => _SelectedTagDetailsState();
}

class _SelectedTagDetailsState extends State<SelectedTagDetails> {
  String? itemName;
  Map<String, dynamic>? itemDetail;

  @override
  void initState() {
    super.initState();
    _checkTokenAndLoadDetails();
  }

  Future<void> _checkTokenAndLoadDetails() async {
    final token = await TokenManager.loadToken();
    if (token == null || isTokenExpired(token)) {
      await TokenManager.clearToken();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }
    //トークンが有効
    _loadItemDetails(widget.initialSelectedEpc);
  }

  // 内容見たい(期限
  bool isTokenExpired(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return true;

    final payloadMap = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
    );
    final int? exp = payloadMap['exp'];
    final int nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (exp != null) {
      // exp を月日に直す
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true).toLocal();
      print('▶ Token expiry (exp): $exp  → DateTime: $expiryDate');


      //　現在時刻　＞　有効期限
      return nowSec >= exp;
    }

    return true;
  }

  void _loadItemDetails(String epc) async {
    final item = await ApiService.fetchItemDetailByRFID(epc);
    if (item == null) {
      print('取得失敗: レスポンス自体が null');
      return;
    }
    if (item['success'] != true) {
      print('取得失敗: ${item['message']}');
      return;
    }

    final dataList = item['data'];
    if (dataList is! List || dataList.isEmpty) {
      print('取得データが空です');
      return;
    }

    final first = dataList[0] as Map<String, dynamic>;
    print('アイテム名: ${first['name']}');
    print('詳細: ${first['detail']}');

    setState(() {
      itemName = first['name'];
      itemDetail = first['detail'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          '詳細',
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
        child: itemName == null
            ? CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('名前：$itemName', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text('詳細：${itemDetail.toString()}',
                  style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
