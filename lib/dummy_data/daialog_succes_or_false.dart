import 'package:flutter/material.dart';
import '../theme.dart';

void showResultDialog(BuildContext ctx, Map<String, dynamic> result) {
  final bool ok = result['success'] == true;
  final String msg = result['message']
      ?? (ok ? "処理が完了しました。" : "処理に失敗しました。");

  showDialog(
    context: ctx,
    builder: (dialogCtx) => AlertDialog(
      title: Text(
        ok ? "成功" : "失敗",
        textAlign: TextAlign.center,
        style: AppTheme.confirmDialogTheme.titleTextStyle,
      ),
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: AppTheme.confirmDialogTheme.contentTextStyle,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
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
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
          ),
          onPressed: () {
            // ダイアログを閉じる場合は、このローカルコンテキストを使う
            Navigator.pop(dialogCtx);
          },
          child: const Text("OK"),
        ),
      ],
    ),
  );
}
