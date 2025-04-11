import 'package:flutter/material.dart';
import 'package:tagsnap/setting_page/setting_page.dart';

import '../../theme.dart';

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

    return InkWell(
        onTap: () {
          Navigator.push(context,MaterialPageRoute(builder: (context)
          => SettingPage()),  // 遷移先のページ
          );
        },

      onTapDown: (_) => setState(() => isPressed = true),  // 押した時
      onTapUp: (_) => setState(() => isPressed = false),   // 離した時
      onTapCancel: () => setState(() => isPressed = false), // キャンセル時
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: screenWidth * 0.26,
        height: 100,
        decoration: BoxDecoration(
          // color:  Color(0xFFD42424),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color:Colors.white,width: 2),
          boxShadow: isPressed
              ? [ // 押したときは影を弱く
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
            Icons.settings,  // アイコンの追加
            color: Colors.white,  // アイコンの色
            size: 35,  // アイコンのサイズ
          ),
              SizedBox(height:  10),  // アイコンとテキストの間隔を空ける
        Text(
            '設定',
            style: TextStyle(
              fontSize: 20,
              color: AppTheme.textColor,
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