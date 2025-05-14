import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tagsnap/common_method/api_common.dart';


// 提供APIのログイン処理内容をまとめたクラス
class ApiLogin {

  // 提供されたアクティベート済みのログイン情報
  static const String _Account = 'test@scd.jp';
  static const String _Pass = '123456';
  static const String _UUID = 'cm9kmmewb0000wguc9l6f9kh0';

  Future<Map<String, dynamic>?> loginServer(String username,
      String password, String devUUID) async {
    final url = Uri.parse(ApiCommonDefine().baseURL+ApiCommonDefine().loginPath);

    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': ApiCommonDefine().xApiKey
    };
    final body = jsonEncode({
      'account': username,
      'password': password,
      'device_uuid': devUUID,
    });

    // ログイン処理実行
    try {
      final response = await http.post(url, headers: headers, body: body);

      // 完了時には色々データ取れる
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if(response.statusCode == 400){
        print('400エラー　エラー内容: ${response.body}');
        final data = jsonDecode(response.body);
        return data;
      } else if(response.statusCode == 401){
        print('401エラー　エラー内容: ${response.body}');
        final data = jsonDecode(response.body);
        return data;
      }  else if(response.statusCode == 403){
        print('403エラー　エラー内容: ${response.body}');
        final data = jsonDecode(response.body);
        return data;
      } else if(response.statusCode == 500){
        print('500エラー　エラー内容: ${response.body}');
        final data = jsonDecode(response.body);
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