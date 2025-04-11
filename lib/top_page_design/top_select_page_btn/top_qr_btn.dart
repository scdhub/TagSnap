import 'package:flutter/material.dart';

import '../../qrcode_page/qrcode_page.dart';

class TopQrBtn extends StatefulWidget {
  const TopQrBtn({super.key});

  @override
  State<TopQrBtn> createState()  => _TopQrButton();
  }

class _TopQrButton extends State<TopQrBtn> {
  bool isPressed = false; //ボタン押下時の変化

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width; //端末の幅に合わせる

    return InkWell(
        onTap: () {
          Navigator.push(context,MaterialPageRoute(builder: (context)
          => QrcodePage()),  // 遷移先のページ
          );
        },

      //ボタンの動作変化について
      onTapDown: (_) => setState(() => isPressed = true),  // 押した時
      onTapUp: (_) => setState(() => isPressed = false),   // 離した時
      onTapCancel: () => setState(() => isPressed = false), // キャンセル時

      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: screenWidth * 0.26,
        height: 100,
        decoration: BoxDecoration(
          // color:  Color(0xFF219346),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color:Colors.white, width: 2),
          boxShadow: isPressed
              ? [ // 押したときは影をうすくする
            BoxShadow(
              color: Colors.grey.shade500,
              offset: Offset(1, 1),
              blurRadius: 3,
            ),
            BoxShadow(
              color: Colors.white,
              offset: Offset(-1, -1),
              blurRadius: 3,
            ),
          ]
              : [],
        ),

        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(
            Icons.qr_code,  // アイコンの追加
            color: Colors.white,  // アイコンの色
            size: 35,  // アイコンのサイズ
          ),
              SizedBox(height:  5),  // アイコンとテキストの間隔を空ける
        Text(
            'QRコード\n連携',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          textAlign: TextAlign.center, // テキストを中央揃え
          ),
          ],
        ),
      ),
      );
  }
}


