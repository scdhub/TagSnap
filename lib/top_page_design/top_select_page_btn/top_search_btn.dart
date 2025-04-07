import 'package:flutter/material.dart';

import '../../search_page/search_page.dart';

class TopSearchBtn extends StatefulWidget {
  const TopSearchBtn({super.key});

  @override
  State<TopSearchBtn> createState() => _TopSearchButtonState();
  }

  class _TopSearchButtonState extends State<TopSearchBtn> {
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
            => SearchPage()),  // 遷移先のページ
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
            // color:  Color(0xFF3AB98E),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color:Colors.white,width: 2),
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
                : [ ], //通常時のボタンは変化なし
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(
              Icons.search,  // アイコンの追加
              color: Colors.white,  // アイコンの色
              size: 35,  // アイコンのサイズ
            ),
                SizedBox(height:  10),  // アイコンとテキストの間隔を空ける
          Text(
              '探索',
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
