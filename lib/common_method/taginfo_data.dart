import 'dart:typed_data';

class tagInfoData {
  final String type;
  final String epc;
  final String ant;
  final int count;
  final Uint8List epcBytes;
  final double freqPoint;
  final int index;
  final String pc;
  final int phase;
  final int remain;
  final String reserved;
  final String rssi;
  final String tid;
  final Uint8List tidBytes;
  final int timeStamp;
  final String user;
  final Uint8List userBytes;

  tagInfoData({
    required this.type,
    required this.epc,
    required this.ant,
    required this.count,
    required this.epcBytes,
    required this.freqPoint,
    required this.index,
    required this.pc,
    required this.phase,
    required this.remain,
    required this.reserved,
    required this.rssi,
    required this.tid,
    required this.tidBytes,
    required this.timeStamp,
    required this.user,
    required this.userBytes
  });

  factory tagInfoData.fromMap(Map<String, dynamic> map) {
    // null値が入っていた場合は代替値を入れる
    // Listがnull時はKotlin側で考慮し何も値が入っていないListになっている
    return tagInfoData(
      type: map['type'] as String? ?? '',
      epc: map['epc'] as String? ?? '',
      ant: map['ant'] as String? ?? '',
      count: map['count'] as int? ?? 0,
      epcBytes: Uint8List.fromList(List<int>.from(map['epcBytes'])),
      freqPoint: map['freqPoint'] as double? ?? 0.0,
      index: map['index'] as int? ?? 0,
      pc: map['pc'] as String? ?? '',
      phase: map['phase'] as int? ?? 0,
      remain: map['remain'] as int? ?? 0,
      reserved: map['reserved'] as String? ?? '',
      rssi: map['rssi'] as String? ?? '',
      tid: map['tid'] as String? ?? '',
      tidBytes: Uint8List.fromList(List<int>.from(map['tidBytes'])),
      timeStamp: map['timeStamp'] as int? ?? 0,
      user: map['user'] as String? ?? '',
      userBytes: Uint8List.fromList(List<int>.from(map['userBytes'])),
    );
  }
}