import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

      // return InkWell(
      //     onTap: () {
      //       Navigator.push(context,MaterialPageRoute(builder: (context)
      //       => NextPage()),  // 遷移先のページ
      //       );
      //     },
      return GestureDetector(
      //ボタンの動作変化について
        onTapDown: (_) => setState(() => isPressed = true),  // 押した時
        onTapUp: (_) => setState(() => isPressed = false),   // 離した時
        onTapCancel: () => setState(() => isPressed = false), // キャンセル時

        child: AnimatedContainer(
            duration: Duration(milliseconds: 150),
              width: screenWidth * 0.7,
              height: 65,
          decoration: BoxDecoration(
            color:  Color(0xFF6CAFE6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color:Colors.white, width: 1),
            boxShadow: isPressed
                ? [ // 押したときは影をうすくする
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
                : [ // 通常時の影

            ],
          ),

          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(
              Icons.edit,  // アイコンの追加
              color: Colors.white,  // アイコンの色
              size: 30,  // アイコンのサイズ
            ),
            SizedBox(width:  15),  // アイコンとテキストの間隔を空ける
            Text(
              '書込み',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
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