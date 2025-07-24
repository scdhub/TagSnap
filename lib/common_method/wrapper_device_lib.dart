import 'package:flutter/services.dart';
import 'package:tagsnap/common_method/taginfo_data.dart';
import 'package:tagsnap/common_method/qrinfo_data.dart';


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

  // QRコード初期化
  static Future<bool> initQR() async {
    return await _devChannel.invokeMethod<bool>('initQR') ?? false;
  }

  // QRコード読み取り
  static Future<bool> startQRScan() async {
    return await _devChannel.invokeMethod<bool>('startQRScan') ?? false;
  }

  // QRコード停止
  static Future<bool> stopQRScan() async {
    return await _devChannel.invokeMethod<bool>('stopQRScan') ?? false;
  }

  // QRコード終了
  static Future<bool> termQR() async {
    return await _devChannel.invokeMethod<bool>('TermQR') ?? false;
  }

  // Barcode初期化
  static Future<bool> initBarcode() async {
    return await _devChannel.invokeMethod<bool>('initBarcode') ?? false;
  }

  // Barcode読み取り
  static Future<bool> startBarcodeScan() async {
    return await _devChannel.invokeMethod<bool>('scanBarcode') ?? false;
  }


  // Barcode終了
  static Future<bool> termBarcode() async {
    return await _devChannel.invokeMethod<bool>('termBarcode') ?? false;
  }



  // 受信情報をMapの種別ごとに分ける
  static Stream<EventDataInfo> receiveData() async* {
    await for (final result in _devStream.receiveBroadcastStream()) {
      if (result is Map && result.containsKey('type')) {
        switch (result['type']) {
          case 'rfid':
            yield TagInfoDataEvent(tagInfoData.fromMap(Map<String, dynamic>.from(result)));
            break;
          case 'QR':
            yield QRInfoDataEvent(qrInfoData.fromMap(Map<String, dynamic>.from(result)));
            break;
          default:
            break;
        }
      }
    }
  }
}

// ストリーム受信時の結果情報切り替え用
sealed class EventDataInfo {}

class TagInfoDataEvent extends EventDataInfo {
  final tagInfoData data;
  TagInfoDataEvent(this.data);
}
class QRInfoDataEvent extends EventDataInfo {
  final qrInfoData data;
  QRInfoDataEvent(this.data);
}