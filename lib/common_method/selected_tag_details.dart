import 'package:http/http.dart' as http;
import 'dart:convert';

import 'api_common.dart';



class ApiService {
  // RFIDタグからアイテム詳細を取得
  static Future<Map<String, dynamic>?> fetchItemDetailByRFID(String tagCode) async {
    // トークン取得
    final token = await TokenManager.loadToken();

    if (token == null) {
      print('トークンが取得できませんでした');
      return null;
    }

    // 呼び出し時
    final prefix = ApiCommonDefine().tagproductsPath;
    final url = Uri.parse('${ApiCommonDefine().baseURL}$prefix$tagCode');

    print("▶ 選択されたtagCode: [$tagCode]");

    //　認証はトークンのみ
    final headers = {
      'Authorization': 'Bearer $token',
      //　APIを使用しても401エラー発生
      // 'x-api-key': ApiCommonDefine().xApiKey
    };
    print('▶ URL: $url');
    print('▶ headers: $headers');


    try {
      final response = await http.get(url, headers: headers,);
      // final decoded = jsonDecode(response.body);
      print('▶ Status: ${response.statusCode}');
      // print('▶ Decoded: $decoded');
      print("▶ body: ${response.body}");

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

