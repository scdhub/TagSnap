import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dummy_data/daialog_succes_or_false.dart';
// import '../../dummy_data/dummy_api_data.dart';
import '../../top_page_design/top_select_page/top_page.dart';
import 'package:tagsnap/common_method/api_login.dart';
import 'package:tagsnap/common_method/api_common.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final TextEditingController _accountController = TextEditingController(text: 'test@scd.jp');
  final TextEditingController _passwordController = TextEditingController(text: '');



  Future<Map<String, dynamic>?> startLogin() async {
    // ログイン処理実行
    var result = await ApiLogin().loginServer(_accountController.text,
        _passwordController.text, SharedPreferenceInfo().deviceUUID);



    return result;
  }

  @override
  void initState() {
    super.initState();
    SharedPreferenceInfo().init().then((_) {
      setState((){}); // deviceUUID が読み込まれたら再描画したいなら
    });
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, //オーバーフロー警告を消す
      appBar: AppBar(
        title: const Text(
          'ログイン',
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('アカウント',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),

            TextField(
              cursorColor: Colors.white, //カーソルみたいなマークを表示
              controller: _accountController,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                  // contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const Text('パスワード',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),

            TextField(
              cursorColor: Colors.white, //カーソルみたいなマークを表示
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                  // contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // // UUIDは現状表示させない。
            // Row(
            //   children: [
            //     const Text('UUID： ', style: TextStyle(fontSize: 16,color: Colors.white)),
            //     Expanded(
            //       child: Text(
            //         '************',
            //         style: TextStyle(fontSize: 16, color: Colors.white),
            //         overflow: TextOverflow.ellipsis,
            //       ),
            //     ),
            //   ],
            // ),

            //遷移処理
            Center(
              child: ElevatedButton(
                onPressed: () async {

                  //ログイン処理
                  final result = await startLogin();

                  //成否で処理を分岐
                  final bool ok = result != null && result['success'] == true;
                  if (!ok) {
                    //失敗時のみダイアログを表示
                    await showResultDialog(context, result);
                    return; // ここで終わり
                  }

                  //成功時は SharedPreferences に保存して画面遷移
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('loggedIn', true);


                  // トークン保存する処理
                  final token = result['token'];
                  if (token != null) {
                    await TokenManager.saveToken(token);
                    print('トークンを保存しました: $token');

                    // トークンのデコードと tenant_uuid の表示を追加
                    final parts = token.split('.');
                    final payload = parts[1];
                    final normalized = base64Url.normalize(payload);
                    final decoded = utf8.decode(base64Url.decode(normalized));
                    final map = json.decode(decoded);
                    print('▶ tenant_uuid: ${map['authUserInfo']['tenant_uuid']}');
                    print('★ JWT Payload 全体: $map');

                    // 比較
                    final token1 = await TokenManager.loadToken();
                    final token2 = token as String;
                    print('同じ？ ${token1 == token2}');


                  } else {
                    print('トークンが null でした');
                  }



                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => TopPage(title: 'TagSnap',)),
                        (route) => false, // すべての前画面を削除
                  );
                  return;
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: const Text(
                  'ログイン',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
