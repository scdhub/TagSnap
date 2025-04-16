import 'package:flutter/material.dart';

import '../../location_page/location_select_page/location_select_page.dart';

class TopLocationBtn extends StatefulWidget {
  const TopLocationBtn({super.key});

  @override
  State<TopLocationBtn> createState() => _TopLocationButton();
}

class _TopLocationButton extends State<TopLocationBtn> {
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
          => LocationSelectPage(title: "操作メニュー")),  // 遷移先のページ
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
            Icons.location_on,  // アイコンの追加
            color: Colors.white,  // アイコンの色
            size: 35,  // アイコンのサイズ
          ),
              SizedBox(height:  5),  // アイコンとテキストの間隔を空ける
        Text(
            'ロケーション管理',
            style: TextStyle(
              fontSize: 16,
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
