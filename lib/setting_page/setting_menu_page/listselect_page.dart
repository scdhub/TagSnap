import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme.dart';

class ListselectPage extends StatefulWidget {
  final String bodyType;

  const ListselectPage({
    Key? key,
    required this.bodyType,
  }) : super(key: key);

  @override
  State<ListselectPage> createState() => _ListselectPage();
}

class _ListselectPage extends State<ListselectPage> {
  /// タイプごとのファイルパスを管理
  final Map<String, String?> _filePaths = {
    'タグ': null,
    'QRコード': null,
    'バーコード': null,
  };

  @override
  void initState() {
    super.initState();
    _loadAllSavedFiles();
  }

  //SharedPreferences から全タイプの設定をロード
  Future<void> _loadAllSavedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final newPaths = <String, String?>{};
    _filePaths.forEach((type, _) {
      newPaths[type] = prefs.getString('managementCsvPath_$type');
    });

    setState(() {
      _filePaths.addAll(newPaths);
    });
  }


  //CSVファイルを選択して保存
  Future<void> _pickCsvFile(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('managementCsvPath_$type', path);
      setState(() => _filePaths[type] = path);
      fileSettingOkDialog();
    }
  }

  //保存済み設定をクリア
  Future<void> _clearCsvFile(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('managementCsvPath_$type');
    setState(() => _filePaths[type] = null);
  }

  //セクションウィジェットの共通ビルド
  Widget _buildSection(String type) {
    debugPrint('▶︎ $type: path = ${_filePaths[type]}');
    final fileName = _filePaths[type]?.split('/').last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$type 読取り',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        ElevatedButton.icon(
          icon: Icon(Icons.insert_drive_file),
          label: Text(
            'CSVファイルを選択',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            minimumSize: Size(240, 65),
            padding: EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _pickCsvFile(type),
        ),

        // 選択済みか未設定かで表示を切り替え
        if (_filePaths[type] != null) ...[
          SizedBox(height: 10),
          Text(
            fileName!,
            style: TextStyle(fontSize: 14, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFF5FD970),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: Size(0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () => _clearCsvFile(type),
            child: Text('クリア'),
          ),
        ] else ...[
          SizedBox(height: 10),
          Text(
            '未設定のためファイルを選択してください。',
            style: TextStyle(fontSize: 14, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],

        SizedBox(height: 40),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '紐付け・在庫リスト選択',
          style: TextStyle(
            color: Color(0xFF84848F),
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
      ),
      body: SingleChildScrollView(
    child: Center( // ← これを追加
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), // ← 上だけ4に変更
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...['タグ', 'QRコード', 'バーコード']
                    .map((type) => _buildSection(type))
                    .toList(),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }


        void fileSettingOkDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "確認",
            textAlign: TextAlign.center,
            style: AppTheme.confirmDialogTheme.titleTextStyle,
          ),
          content: Text(
            "CSVファイルを設定しました。",
            textAlign: TextAlign.center,
            style: AppTheme.confirmDialogTheme.contentTextStyle,
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
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "OK",
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
