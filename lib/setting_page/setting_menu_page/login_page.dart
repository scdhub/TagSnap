import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,//オーバーフロー警告を消す
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
            const Text('アカウント', style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.bold,)),
            const SizedBox(height: 8),

            TextField(
              cursorColor: Colors.white,//カーソルみたいなマークを表示
              controller: _accountController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            const Text('パスワード', style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.bold,)),
            const SizedBox(height: 8),

            TextField(
              cursorColor: Colors.white,//カーソルみたいなマークを表示
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            const SizedBox(height: 24),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  // ログイン処理をここに追加
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
