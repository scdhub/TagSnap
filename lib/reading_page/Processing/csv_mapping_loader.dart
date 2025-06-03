// lib/services/csv_mapping_loader.dart

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:shared_preferences/shared_preferences.dart';

///CSV マッピングを読み込み、
//「キー（EPCなど） → {'種別': ..., '管理番号': ...}」の Map を返すサービスクラス。

// 使い方:
//final loader = CsvMappingLoader();
//final map = await loader.loadMapping('タグ');
//map は Map<String, Map<String, String>> 型 (EPC → 種別＆管理番号)


class CsvMappingLoader {
  // bodyType には 'タグ' / 'QRコード' / 'バーコード' のいずれかを指定。
  // SharedPreferences に key: 'managementCsvPath_$bodyType'
  // で保存されている CSV のパスを読み出してファイルをパースする。
  Future<Map<String, Map<String, String>>> loadMapping(String bodyType) async {
    // 1. SharedPreferences から csvPath を取得
    final prefs = await SharedPreferences.getInstance();
    final key = 'managementCsvPath_$bodyType';
    final csvPath = prefs.getString(key);

    // 2. 戻り値用の空マップを準備
    final Map<String, Map<String, String>> managementMap = {};

    // 3. csvPath が null ではなく、かつファイルが実際に存在するなら読み込む
    if (csvPath != null && await File(csvPath).exists()) {
      final content = await File(csvPath).readAsString();

      // 4. CSV 文字列を行・列のリストに変換
      final rows = const CsvToListConverter(
        eol: '\r\n',            // 改行コード
        shouldParseNumbers: false, // 数値として自動パースしない
      ).convert(content);

      // 5. 1行目はヘッダー行とみなして i=1 からループ
      for (var i = 1; i < rows.length; i++) {
        // 列ごとに文字列化して余分な空白を除去
        final cols = rows[i].map((c) => c.toString().trim()).toList();

        // ここでは「2列目(cols[1]) をキー」「3列目(cols[2]) を '種別'」
        // 「4列目(cols[3]) を '管理番号'」と仮定
        if (cols.length >= 4) {
          final keyValue = cols[1];
          managementMap[keyValue] = {
            '種別': cols[2],
            '管理番号': cols[3],
          };
        }
      }
    }

    // 6. 存在しないかパースに失敗した場合は空のまま返る
    return managementMap;
  }
}
