import 'package:flutter/material.dart';

import '../../led_page/led_page.dart';

class TopLedBtn extends StatefulWidget {
  const TopLedBtn({super.key});

  @override
  State<TopLedBtn> createState() => _TopLEDButton();
}

class _TopLEDButton extends State<TopLedBtn> {
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
          => LedPage()),  // 遷移先のページ
          );
        },


      onTapDown: (_) => setState(() => isPressed = true),  // 押した時
      onTapUp: (_) => setState(() => isPressed = false),   // 離した時
      onTapCancel: () => setState(() => isPressed = false), // キャンセル時
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: screenWidth * 0.7,
        height: 70,
        decoration: BoxDecoration(
          // color: Color(0xFFFCC403),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color:Colors.white, width: 2),
          boxShadow: isPressed
              ? [ // 押したときは影を弱く
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
              : [
          ],
        ),

        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(
            Icons.lightbulb,  // アイコンの追加
            color: Colors.white,  // アイコンの色
            size: 35,  // アイコンのサイズ
          ),
              SizedBox(height:  10),  // アイコンとテキストの間隔を空ける
        Text(
            'LED点灯',
            style: TextStyle(
              fontSize: 20,
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