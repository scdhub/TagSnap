import 'package:flutter/material.dart';
import 'package:tagsnap/reading_page/reading_page.dart';


class TopReadingBtn extends StatefulWidget {
  const TopReadingBtn({super.key});
  @override
  State<TopReadingBtn> createState() => _TopReadingButton();
}

class _TopReadingButton extends State<TopReadingBtn> {
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
        => ReadingPage()),  // 遷移先のページ
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
          // color:  Color(0xFFC45827),
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
              : [
          ],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh,  // アイコンの追加
              color: Colors.white,  // アイコンの色
              size: 35,  // アイコンのサイズ
            ),
            SizedBox(height:  10),  // アイコンとテキストの間隔を空ける
            Text(
              '読込み',
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




