import 'package:flutter/services.dart';
import 'package:tagsnap/common_method/taginfo_data.dart';


// デバイス通信を行うための処理を隠ぺいするためのクラス
class WrapperDeviceLib {

  // 端末操作メソッドとの連携用チャンネル作成
  static const _devChannel = MethodChannel('com.example.tagsnap/DevChannel');
  static const _devStream = EventChannel('com.example.tagsnap/DevStream');

  // RFID情報読み取り用
  // 初期化
  static Future<bool> initRFID() async {
    return await _devChannel.invokeMethod<bool>('initRFID') ?? false;
  }

  // 連続読み取り開始
  static Future<bool> startRFIDScan() async {
    return await _devChannel.invokeMethod<bool>('startRFIDScan') ?? false;
  }

  // 読み取った情報の戻り値取得
  static Stream<tagInfoData> get tagInfoStream {
    return _devStream.receiveBroadcastStream().map((result) {
      if (result is Map) {
        return tagInfoData.fromMap(Map<String, dynamic>.from(result));
      } else {
        throw Exception("Get Error : tagInfoStream");
      }
    });
  }

  // 読み取り停止
  static Future<bool> stopRFIDScan() async {
    return await _devChannel.invokeMethod<bool>('stopRFIDScan') ?? false;
  }

  // 単一読み取り
  static Future<bool> startRFIDScanOnce() async {
    return await _devChannel.invokeMethod<bool>('startRFIDScanOnce') ?? false;
  }

  // 終了
  static Future<bool> termRFID() async {
    return await _devChannel.invokeMethod<bool>('TermRFID') ?? false;
  }


  // QRコード読み取り用（未）
  bool callDevice2DLib(int setNum){
    bool ret = true;

    return ret;
  }

}