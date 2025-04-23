import 'dart:typed_data';

class tagInfoData {
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
    return tagInfoData(
      epc: map['epc'] as String,
      ant: map['ant'] as String,
      count: map['count'] as int,
      epcBytes: Uint8List.fromList(List<int>.from(map['epcBytes'])),
      freqPoint: map['freqPoint'] as double,
      index: map['index'] as int,
      pc: map['pc'] as String,
      phase: map['phase'] as int,
      remain: map['remain'] as int,
      reserved: map['reserved'] as String,
      rssi: map['rssi'] as String,
      tid: map['tid'] as String,
      tidBytes: Uint8List.fromList(List<int>.from(map['tidBytes'])),
      timeStamp: map['timeStamp'] as int,
      user: map['user'] as String,
      userBytes: Uint8List.fromList(List<int>.from(map['userBytes'])),
    );
  }
}