import 'package:flutter/material.dart';
import '../../theme.dart';

class LocExportBtn extends StatefulWidget {
  const LocExportBtn({super.key});

  @override
  State<LocExportBtn> createState() => _LocExportButton();
}

class _LocExportButton extends State<LocExportBtn> {
  bool isPressed = false;

  // エクスポートの確認ダイアログ
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '確認',
            textAlign: TextAlign.center, // タイトルを中央揃え
            style: AppTheme.confirmDialogTheme.titleTextStyle,
          ),
          content: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              'ファイルをエクスポートしますか？',
              style: AppTheme.confirmDialogTheme.contentTextStyle,
            ),
          ),
          actions: <Widget>[
        Row(
        mainAxisAlignment: MainAxisAlignment.center, // ボタンを中央寄せ
          children: [
        TextButton(
        style: TextButton.styleFrom(
        foregroundColor: Colors.white,
            backgroundColor: AppTheme.cancelDialogButtonColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppTheme.cancelDialogBorderColor,width: 2))),
            onPressed: () {
              Navigator.of(context).pop(); // ダイアログを閉じる
            },
            child: Text('Cancel',style: TextStyle(color: Color(0xFFF06292)),),
        ),
            SizedBox(width: 30), // ボタンの間に適度なスペースを追加
            // OK ボタン
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.confirmDialogButtonColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: AppTheme.confirmDialogBorderColor,
                      width: 2
                  ),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text(
                "OK",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
        ),
        ],
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: () {
        _showExportDialog(context); // エクスポートの確認ダイアログを表示
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: screenWidth * 0.4,
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color:Colors.white,width: 2),
          boxShadow: isPressed
              ? [
            BoxShadow(
              color: Colors.grey.shade400,
              offset: Offset(1, 1),
              blurRadius: 3,
            ),
            BoxShadow(
              color: Colors.grey.shade200,
              offset: Offset(-1, -1),
              blurRadius: 3,
            ),
          ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'エクスポート',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
