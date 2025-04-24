import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme.dart';

class ListselectPage extends StatefulWidget {
  const ListselectPage({Key? key}) : super(key: key);

  @override
  State<ListselectPage> createState() => _ListselectPageState();
}

class _ListselectPageState extends State<ListselectPage> {
  String? _folderPath;

  @override
  void initState() {
    super.initState();
    _loadSavedFolder();
  }

  // フルパスからファイル名だけを取得
  String? _fileName() {
    if (_folderPath == null) return null;
    return _folderPath!.split('/').last;
  }


  // SharedPreferences から保存済みのフォルダパスを読み込む
  Future<void> _loadSavedFolder() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // _folderPath = prefs.getString('managementFolderPath');
      _folderPath = prefs.getString('managementCsvPath');
    });
  }

  // フォルダ選択ダイアログを開いてパスを保存
  Future<void> _pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('managementCsvPath', filePath); //フルパスをと
      setState(() => _folderPath = filePath);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('CSVファイルを設定しました。\n$filePath')),
      fileSettingOkDialog(); //file
    }
  }

  // 保存済み設定をクリア
  Future<void> _clearFolder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('managementCsvPath');
    setState(() => _folderPath = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('紐付け・在庫リスト選択',style: TextStyle(
            color:Color(0xFF84848F),fontSize: 23,
          fontWeight: FontWeight.bold,
        ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 25),
            ElevatedButton.icon(
              icon: Icon(Icons.insert_drive_file),
              label: Text('CSVファイルを選択'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                minimumSize: Size(260, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _pickCsvFile,
            ),
            SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_folderPath != null) ...[
                  SizedBox(height: 10), // ボタンとの間の余
                  Center(
                    child: Text(
                      '▼選択中のファイル',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],



                Center(
                  child: Text(
                    _fileName() ?? '未設定のためファイルを選択してください。',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_folderPath != null) ...[
                  SizedBox(height: 40),
                  Center(
                    child: TextButton(
                      onPressed: _clearFolder,
                      style: TextButton.styleFrom(
                        backgroundColor: Color(0xFF5FD970),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12), // パディング
                        minimumSize: Size(80, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // 角丸
                          // side: BorderSide(color: Colors.redAccent), // 必要ならつける
                        ),
                      ),
                      child: Text(
                        'クリア',
                        style: TextStyle(fontSize: 16), // 任意：フォントサイズ調整
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
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
