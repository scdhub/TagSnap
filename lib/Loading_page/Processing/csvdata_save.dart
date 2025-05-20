/// utils/csv_saver.dart
/// CSV保存処理を切り出したユーティリティクラス
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme.dart';


// ダイアログ表示を司るインタフェース
abstract class DialogService {
  Future<void> showInfo(BuildContext context, String title, String message);
}

// 標準的な[DialogService]実装
class DefaultDialogService implements DialogService {
  @override
  Future<void> showInfo(BuildContext context, String title, String message) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.confirmDialogTheme.titleTextStyle,
          ),
          content: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.confirmDialogTheme.contentTextStyle,
            ),
          ),
          actions: [
            Align(
              alignment: Alignment.center,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.confirmDialogButtonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: AppTheme.confirmDialogBorderColor,
                      width: 2,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// CSV保存処理をまとめたサービス
class CsvSaver {
  final DialogService dialogService;

  CsvSaver({DialogService? dialogService})
      : dialogService = dialogService ?? DefaultDialogService();

  /// CSVデータを一時ディレクトリに書き込み、
  /// ファイルダイアログで保存を促し、結果に応じてダイアログ表示
  Future<void> save(
      BuildContext context,
      List<List<String>> csvData,
      String prefix,
      ) async {
    // CSV文字列に変換
    final csvString = const ListToCsvConverter().convert(csvData);
    final bytes = Uint8List.fromList(utf8.encode(csvString));

    // ファイル名: プレフィックス_YYYYMMDD_HHMMSS.csv
    final now = DateTime.now();
    final formatted = DateFormat('yyyyMMdd_HHmmss').format(now);
    final filename = '$prefix\_${formatted}.csv';

    // 一時ディレクトリに書き込み
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);

    // ファイル保存ダイアログ表示パラメータ
    final params = SaveFileDialogParams(
      sourceFilePath: file.path,
      fileName: filename,
    );

    // 保存ダイアログ表示
    final savedPath = await FlutterFileDialog.saveFile(params: params);

    if (savedPath != null) {
      await dialogService.showInfo(
        context,
        '確認',
        'リストを保存しました。',
      );
    } else {
      // キャンセル時のログだけ残す
      debugPrint('CSV保存: ユーザーがキャンセルまたは失敗しました');
    }
  }
}
