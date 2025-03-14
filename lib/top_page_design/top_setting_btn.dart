import 'package:flutter/material.dart';

import '../theme.dart';

class TopSettingBtn extends StatefulWidget {
  const TopSettingBtn({super.key});

  @override
  State<TopSettingBtn> createState() => _TopSettingButtonState();
}

class _TopSettingButtonState extends State<TopSettingBtn> {
  bool isPressed = false; //ボタン押下時の変化

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),  // 押した時
      onTapUp: (_) => setState(() => isPressed = false),   // 離した時
      onTapCancel: () => setState(() => isPressed = false), // キャンセル時
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        width: screenWidth * 0.7,
        height: 65,
        decoration: BoxDecoration(
          color:  Color(0xFF6C88E6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color:Colors.white,width: 1),
          boxShadow: isPressed
              ? [ // 押したときは影を弱く
            BoxShadow(
              color: Colors.grey.shade500,
              offset: Offset(2, 2),
              blurRadius: 5,
            ),
            BoxShadow(
              color: Colors.white,
              offset: Offset(-2, -2),
              blurRadius: 5,
            ),
          ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(
            Icons.settings,  // アイコンの追加
            color: Colors.white,  // アイコンの色
            size: 30,  // アイコンのサイズ
          ),
          SizedBox(width:  15),  // アイコンとテキストの間隔を空ける
        Text(
            '設定',
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          ],
        ),
      ),
      ),
    );
  }
}