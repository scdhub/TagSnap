import 'dart:typed_data';

class qrInfoData {
  final String type;
  final String aimID;
  final Uint8List barcodeBytes;
  final String barcodeData;
  final String barcodeName;
  final int barcodeSymbology;
  final int decodeTime;
  final int errCode;
  final Uint8List prefix;

  qrInfoData({
    required this.type,
    required this.aimID,
    required this.barcodeBytes,
    required this.barcodeData,
    required this.barcodeName,
    required this.barcodeSymbology,
    required this.decodeTime,
    required this.errCode,
    required this.prefix
  });

  factory qrInfoData.fromMap(Map<String, dynamic> map) {
    // null値が入っていた場合は代替値を入れる
    // Listがnull時はKotlin側で考慮し何も値が入っていないListになっている
    return qrInfoData(
        type: map['type'] as String? ?? '',
        aimID: map['aimID'] as String? ?? '',
        barcodeBytes: Uint8List.fromList(List<int>.from(map['barcodeBytes'])),
        barcodeData: map['barcodeData'] as String? ?? '',
        barcodeName: map['barcodeName'] as String? ?? '',
        barcodeSymbology: map['barcodeSymbology'] as int? ?? 0,
        decodeTime: map['decodeTime'] as int? ?? 0,
        errCode: map['errCode'] as int? ?? 0,
        prefix: Uint8List.fromList(List<int>.from(map['prefix'])),
    );
  }
}