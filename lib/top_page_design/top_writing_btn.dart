import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../writing_page/writing_page.dart';

class TopWritingBtn extends StatefulWidget {
  const TopWritingBtn({super.key});//ボタンの状態変化ウィジェットを作成

  @override
  State<TopWritingBtn> createState() => _TopWritingButtonState();
}

  class _TopWritingButtonState extends State<TopWritingBtn> {
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
            => WritingPage()),  // 遷移先のページ
            );
          },

      //ボタンの動作変化について
        onTapDown: (_) => setState(() => isPressed = true),  // 押した時
        onTapUp: (_) => setState(() => isPressed = false),   // 離した時
        onTapCancel: () => setState(() => isPressed = false), // キャンセル時

        child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
              width: screenWidth * 0.7,
              height: 70,
          decoration: BoxDecoration(
            // color:  Color(0xFF86D365),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color:Colors.white, width: 2),
            boxShadow: isPressed
                ? [ // 押したときは影をうすくする
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
                : [ // 通常時の影

            ],
          ),

          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(
              Icons.edit,  // アイコンの追加
              color: Colors.white,  // アイコンの色
              size: 35,  // アイコンのサイズ
            ),
            SizedBox(height:  10),  // アイコンとテキストの間隔を空ける
            Text(
              '書込み',
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