import 'dart:convert';
import 'package:flutter/material.dart';
import '../common_method/api_common.dart';
import '../common_method/api_getitemdata.dart';

class SelectedTagDetails extends StatefulWidget {
  final String initialSelectedCode;
  // true=QR, false=RFID
  final bool isQr;

  const SelectedTagDetails({
    super.key,
    // required this.initialSelectedEpc,
    // required this.initialSelectedIndex,
    required this.initialSelectedCode,
    required this.isQr,

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
    if (token == null || await TokenManager.isTokenExpired()) {
      await TokenManager.clearToken();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }
    //トークンが有効
    _loadItemDetails(widget.initialSelectedCode);
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

  void _loadItemDetails(String code) async {
    // final item = await ApiRFIDGetTagData.fetchItemDetailByRFID(epc);
    final item = widget.isQr
        ? await ApiQRGetData.fetchItemDetailByQR(code)
        : await ApiRFIDGetData.fetchItemDetailByRFID(code);

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
      body: itemName == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('選択したデータ',style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold,color: Colors.white)),
              SizedBox(height: 5),
              Text('${widget.initialSelectedCode}', style: TextStyle(fontSize: 18, color: Colors.white,),),
              SizedBox(height: 15,),

              Text('名前', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold,color: Colors.white)),
              SizedBox(height: 5),
              Text(itemName!, style: TextStyle(fontSize: 18,color: Colors.white)),
              SizedBox(height: 30),
              Text('詳細', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold,color: Colors.white)),
              SizedBox(height: 5),
              _buildDetailRow('価格', '¥${itemDetail?['price'] ?? '-'}'),
              _buildDetailRow('在庫', '${itemDetail?['stock'] ?? '-'} '),
              _buildDetailRow('カテゴリ', itemDetail?['category'] ?? '-'),
              _buildDetailRow('通貨', itemDetail?['currency'] ?? '-'),
              SizedBox(height: 30),
              Text('説明', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold,color: Colors.white)),
              SizedBox(height: 5),
              Text(itemDetail?['description'] ?? '-', style: TextStyle(fontSize: 18,color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label + '：', style: TextStyle(fontSize: 16,color: Colors.white))),
          Expanded(flex: 3, child: Text(value, style: TextStyle(fontSize: 16,color: Colors.white))),
        ],
      ),
    );
  }
}