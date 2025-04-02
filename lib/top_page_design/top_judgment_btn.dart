import 'package:flutter/material.dart';

class TopJudgmentBtn extends StatefulWidget {
  const TopJudgmentBtn({super.key});

  @override
  State<TopJudgmentBtn> createState() => _TopJudgmentButton();
}

class _TopJudgmentButton extends State<TopJudgmentBtn> {
  bool isPressed = false; //ボタン押下時の変化

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width; //端末の幅に合わせる

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),  // 押した時
      onTapUp: (_) => setState(() => isPressed = false),   // 離した時
      onTapCancel: () => setState(() => isPressed = false), // キャンセル時
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: screenWidth * 0.7,
        height: 70,
        decoration: BoxDecoration(
          // color: Color(0xFFFD7B17),
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
              '真贋判定',
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