import 'package:flutter/material.dart';
import '../theme.dart';

Future<void> showResultDialog(BuildContext ctx, Map<String, dynamic>? result) {
  final bool ok = result != null && result['success'] == true;
  // resultがnullだったら処理失敗
  // result['message']がnullならokの結果を見て完了or失敗
  // result['message']にメッセージがあればその内容をそのまま入れる
  final String msg = result == null
      ? "処理に失敗しました。"
      : (result['message'] == null
      ? (ok ? "処理が完了しました。" : "処理に失敗しました。")
      : result['message'] as String);

  return showDialog<void>(
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
