import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_common.dart';

class ApiService {
  // RFIDタグからアイテム詳細を取得
  static Future<Map<String, dynamic>?> fetchItemDetailByRFID(
      String tagCode) async {
    // トークンを共通メソッドから取得
    final token = await TokenManager.load();

    if (token == null) {
      print('トークンが取得できませんでした');
      return null;
    }

    //　共通メソッドで定義したURLを使用
    final url = Uri.parse(ApiCommonDefine().baseURL + ApiCommonDefine().tagprodauctsPath);

    final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };


    try {
      final response = await http.get(url, headers: headers,);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 403) {
        print('403エラー エラー内容：　${response.body}');
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 404) {
        print('404エラー エラー内容：　${response.body}');
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 500) {
        print('500エラー エラー内容：　${response.body}');
        final data = json.decode(response.body);
        return data;
      } else {
        print('ログイン失敗: ${response.statusCode}');
        print('エラー内容: ${response.body}');
        final data = jsonDecode(response.body);
        return data;
      }
    } catch (e) {
      print('通信エラー: $e');
      return null;
    }
  }
}

