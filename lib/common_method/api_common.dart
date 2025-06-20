import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';


// 提供APIに関連する全体的な情報を管理するためのファイル

// 共通Define値
class ApiCommonDefine {
  const ApiCommonDefine();

  // アプリケーション自体のバージョン付与（更新やマイナー・メジャー番号管理どうしようね）
  final String appVer = '0.0.1';
  // ログイン・アクティベーション/解除時に必要なx-api-key
  final String xApiKey = '57d52af6513e76729b916d5f436ddf15f321d46fbf13e12b6b672b2b07fd7d50';
  // APIの共通URL
  final String baseURL = 'https://f7qxb31v00.execute-api.ap-northeast-1.amazonaws.com/v1/';
  // アクティベーション
  final String activationPath = 'tagsnap/device/activation';
  // アクティベーション解除
  final String deactivatePath = 'tagsnap/device/deactivation';
  // ログイン
  final String loginPath = 'smartlogix/login/device';
  // RFIDタグからアイテム詳細を取得
  final String tagProductsPath = 'tagsnap/products/rfid/';
  // QRコードからアイテム詳細を取得
  final String qrProductsPath = 'tagsnap/products/qrcode/';
}

// UUID作業用のクラス
class TimerStatus {
  DateTime? prevDate;
  int counter;

  TimerStatus({this.prevDate, this.counter = 0});
}

// api関連で使用するメソッド
class ApiCommonMethod {
  // デバイスUUIDを作成する
  // UUIDは以下の形式
  // ch72gsb320000udocl363eofy
  // c: 固定値 h72gsb32: timestamp 0000: Counter udoc : fingerprint l363eofy: ランダム（8桁）
  Future<String> makeDeviceUUID(TimerStatus timeStatus) async {
    // 現時点での前回作成時刻を取得
    final checkDate = timeStatus.prevDate;
    // 現在のローカル時刻を取得
    final now = DateTime.now();
    // 前回実行時日付情報を更新
    timeStatus.prevDate = now;

    // 時刻部分を作成（現在時刻をBase36にエンコードして8桁にする）
    final timePart = encodeLocalDateTimeToBase36(now);

    // 前回UUID作成時と今回とを比較して同時刻だったらインクリメント、異なっていたら初期化(0)
    if (isSameDateTimeToPrev(checkDate, now)) {
      timeStatus.counter++;
    } else {
      timeStatus.counter = 0;
    }
    // カウンター部分作成(4桁)
    final counterStr = timeStatus.counter.toString().padLeft(4, '0');

    // Fingerprint部分作成（4桁）
    AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
    final fpStr = androidInfo.fingerprint.length >= 4
        ? androidInfo.fingerprint.substring(0, 4)
        : androidInfo.fingerprint.padRight(4, 'x'); // 短い場合は'x'で埋める

    // ランダム文字列作成（8桁）
    final rdmStr = generateRandomString();

    // 作成した部品を繋げてUUID作成
    return 'c$timePart$counterStr$fpStr$rdmStr';
  }

  // UUIDの時刻部生成
  static String encodeLocalDateTimeToBase36(DateTime now) {

    // 年月日時分秒をゼロ埋めして連結
    final y = now.year.toString().padLeft(4, '0');
    final mo = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final mi = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');

    final timestampStr = '$y$mo$d$h$mi$s';
    final timestampNum = int.parse(timestampStr);

    // Base36に変換し、8桁になるように左詰め
    String base36 = timestampNum.toRadixString(36);

    // 桁数を調整（8桁以内にする、超えていたら先頭8桁を残して切る）
    if (base36.length > 8) {
      base36 = base36.substring(0, 8); // 上位8桁（下位を切り捨て）
    } else {
      base36 = base36.padLeft(8, '0'); // 8桁未満は0埋め
    }

    return base36;
  }

  // 同一時刻か（年月日時分秒まで）をチェック
  static bool isSameDateTimeToPrev(DateTime? a, DateTime? b) {
    // どちらかがnullだったら不一致判定
    if (null == a || null == b) return false;

    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute &&
        a.second == b.second;
  }

  // ランダム文字列生成
  static String generateRandomString() {
    // 8桁のランダムな文字列を作る
    final stringNum = 8;
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure(); // より安全な乱数生成

    return List.generate(stringNum, (index) => chars[rand.nextInt(chars.length)]).join();
  }
}


// SharedPreference内のkey整理用クラス
class SharedPreferenceKeys {
  const SharedPreferenceKeys();

  // SharedPreferenceで管理する情報が増えた場合はここにkey追記し
  // get/set時にはこのクラスを使ってkey名を参照すること
  final String devUUID = 'deviceUUID';
  final String devName = 'deviceName';
  final String actCode = 'activationCode';
}

// SharedPreferenceで管理する情報用クラス
class SharedPreferenceInfo {

  // シングルトンで使用する
  static final SharedPreferenceInfo _instance = SharedPreferenceInfo
      ._internal();

  factory SharedPreferenceInfo() => _instance;

  SharedPreferenceInfo._internal();

  SharedPreferences? _prefs;

  // デバイスのUUID（初期化時にSharedPreferencesから取得）
  static String _deviceUUID = '';

  // アクティベーション時にユーザ入力後はSharedPreferencesから取得or書き込みする情報
  static String _deviceName = '';
  static String _activationCode = '';

  // 初期化処理
  Future<void> init() async {
    // SharedPreferenceから情報取得
    _prefs = await SharedPreferences.getInstance();

    _deviceUUID = _prefs?.getString(SharedPreferenceKeys().devUUID) ?? '';
    _deviceName = _prefs?.getString(SharedPreferenceKeys().devName) ?? '';
    _activationCode = _prefs?.getString(SharedPreferenceKeys().actCode) ?? '';

    print(_deviceUUID);
    print(_deviceName);
    print(_activationCode);
  }

  // Getter
  String get deviceUUID => _deviceUUID;

  String get deviceName => _deviceName;

  String get activationCode => _activationCode;

  // Setter
  Future<void> updateInfoValue(String setStr, String key) async {
    // 変更する変数はkeyによって変える
    if (key == SharedPreferenceKeys().devUUID) {
      _deviceUUID = setStr;
    } else if (key == SharedPreferenceKeys().devName) {
      _deviceName = setStr;
    } else if (key == SharedPreferenceKeys().actCode) {
      _activationCode = setStr;
    }
  }

  // SharedPreferenceへの書き込み
  Future<void> writeSharedPreference() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();

    // SharedPreferencesに書き込み
    await prefs.setString(SharedPreferenceKeys().devUUID, _deviceUUID);
    await prefs.setString(SharedPreferenceKeys().devName, _deviceName);
    await prefs.setString(SharedPreferenceKeys().actCode, _activationCode);
  }

  // 終了処理
  Future<void> dispose() async {
    await writeSharedPreference();
  }
}

class TokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _tokenExpireKey = 'auth_token_expire';

  // トークンを保存
  static Future<void> saveToken(String token, {DateTime? expireAt}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

  }

  // トークンを取得
  static Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('▶ TokenManager.loadToken() => $token');
    return token;
  }

  // JWT のペイロード部分をデコードして JSON 文字列で返す！　確認用に設置：消した方が良いかな→相談
  static String decodeJwtPayload(String token) {
    final parts = token.split('.');
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return decoded;
  }


  // トークン内の tenant_uuid をコンソールに出力！　確認用に設置：消した方が良いかな→相談
  static void printTenantUuid(String token) {
    final payloadJson = decodeJwtPayload(token);
    final payloadMap = json.decode(payloadJson);
    print('▶ tenant_uuid: ${payloadMap['authUserInfo']['tenant_uuid']}');
  }


  // トークンの有効期限が切れているか確認したい　確認用に設置：消した方が良いかな→相談
  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expireStr = prefs.getString(_tokenExpireKey);
    if (expireStr == null) return false;

    final expireAt = DateTime.tryParse(expireStr);
    if (expireAt == null) return false;

    return DateTime.now().isAfter(expireAt);
  }

  // トークンが存在しているか確認したい　確認用に設置：消した方が良いかな→相談
  static Future<bool> hasToken() async {
    final token = await loadToken();
    return token != null && token.isNotEmpty;
  }

  // トークン削除（ログアウト時など）
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpireKey);
    print('🗑 TokenManager.clearToken(): token removed');
  }

}

