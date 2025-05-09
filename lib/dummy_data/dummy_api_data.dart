// activation 送信をして成功と失敗ダイアログを出す。
Future<Map<String, dynamic>> mockActivate(String code, String name) async {
  await Future.delayed(const Duration(seconds: 1));
  //↓ダミー成功／失敗パターンを切り替えたいときはここを書き換え
  return {
    "success": true,
    "message": "アクティベーションに成功しました。",
  };
}

//activation 解除をモックする
Future<Map<String, dynamic>> mockDeactivate() async {
  await Future.delayed(const Duration(seconds: 1));
  return {
    "success": true,
    "message": "アクティベーションを解除しました。",
  };
}

//login をモックする
Future<Map<String, dynamic>> mockLogin(String account, String pass) async {
  await Future.delayed(const Duration(seconds: 1));
  // 例：アカウント未指定パターン
  if (account.isEmpty) {
    return {
      "success": false,
      "message": "account is not specified in the parameters."
    };
  }
  // 成功パターン
  return {
    "success": true,
    "message": null,
    "token": "dummy.token.value",
  };
}
