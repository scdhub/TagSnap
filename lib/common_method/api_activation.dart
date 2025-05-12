import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tagsnap/common_method/api_common.dart';


// 提供APIのアクティベーション処理関連をまとめたクラス
class ApiActivation {

  // 端末情報取得用
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  // 端末情報（初期化時に取得）
  static String _osType = '';
  static String _osVersion = '';
  static String _modelName = '';

  static String _workDeviceUUID = '';
  static bool _isActivate = false;

  // UUIDのカウンター調整用
  static TimerStatus _TimeStatus = TimerStatus();

  // 外部への変数公開用
  String get osType => _osType;
  String get osVersion => _osVersion;
  String get modelName => _modelName;
  String get deviceUUID => _workDeviceUUID;
  bool get isActivate => _isActivate;
  // 他クラスのアクティベーション関連情報もまとめてここから見えるようにしておく
  String get appVer => ApiCommonDefine().appVer;

  // クラス初期化時に必要情報をまとめて取得
  Future<void> init() async {

    // デバイスUUIDが空文字（未アクティベーション）の場合はUUIDを作成する
    if('' == SharedPreferenceInfo().deviceUUID) {
      _workDeviceUUID = await ApiCommonMethod().makeDeviceUUID(_TimeStatus);
      // UUID未記録なので未アクティベートと判断する
      _isActivate = false;
    } else {
      // 入っていればその情報を使用
      _workDeviceUUID = SharedPreferenceInfo().deviceUUID;
      // UUID記録済みなのでアクティベート済みと判断する
      _isActivate = true;
    }

    if (Platform.isAndroid) {
      // OSがAndroid
      _osType = 'Android';

      // デバイス情報の取得
      AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
      _osVersion = androidInfo.version.release;
      _modelName = androidInfo.model;

    } else if (Platform.isIOS) {
      // OSがAndroid
      _osType = 'iOS';
      // 将来的にここにiOS用処理を追加
    }
  }

  // アクティベーション処理
  Future<Map<String, dynamic>?> activation(String setActivationCode,
      String setDeviceName) async {
    final url = Uri.parse(ApiCommonDefine().baseURL+ApiCommonDefine().activationPath);

    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': ApiCommonDefine().xApiKey
    };
    final body = jsonEncode({
      'activation_code': setActivationCode,
      'device_name': setDeviceName,
      'device_uuid': _workDeviceUUID,
      'os_type': _osType,
      'os_version': _osVersion,
      'app_version': ApiCommonDefine().appVer,
      'device_model': _modelName
    });

    // アクティベーション処理実行
    try {
      final response = await http.post(url, headers: headers, body: body);

      // 結果分岐(結果内容の詳しい参照は画面側で行う)
      if (response.statusCode == 201) {
        // 成功時は成功情報で書き換え
        SharedPreferenceInfo().updateInfoValue(setDeviceName,
            SharedPreferenceKeys().devName);
        SharedPreferenceInfo().updateInfoValue(setActivationCode,
            SharedPreferenceKeys().actCode);
        SharedPreferenceInfo().updateInfoValue(_workDeviceUUID,
            SharedPreferenceKeys().devUUID);
        SharedPreferenceInfo().writeSharedPreference();

        final data = jsonDecode(response.body);
        return data;
      } else if(response.statusCode == 400){
        print('400エラー　エラー内容: ${response.body}');
        final data = jsonDecode(response.body);
        return data;
      } else if(response.statusCode == 409){
        print('409エラー　エラー内容: ${response.body}');
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

  // アクティベーション解除処理
  Future<Map<String, dynamic>?> deactivate() async {
    final url = Uri.parse(ApiCommonDefine().baseURL+ApiCommonDefine().deactivatePath);

    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': ApiCommonDefine().xApiKey
    };
    final body = jsonEncode({
      'device_uuid': _workDeviceUUID
    });

    // アクティベーション解除実行
    try {
      final response = await http.post(url, headers: headers, body: body);

      // SharedPreferenceの情報を空情報で上書き
      SharedPreferenceInfo().updateInfoValue('',
          SharedPreferenceKeys().actCode);
      SharedPreferenceInfo().updateInfoValue('',
          SharedPreferenceKeys().devUUID);
      SharedPreferenceInfo().writeSharedPreference();

      // 結果分岐(結果内容の詳しい参照は画面側で行う)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else if(response.statusCode == 400){
        print('400エラー　エラー内容: ${response.body}');
        final data = jsonDecode(response.body);
        return data;
      } else if(response.statusCode == 404){
        print('404エラー　エラー内容: ${response.body}');
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
