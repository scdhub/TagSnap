import 'package:flutter/material.dart';

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
          color:  Color(0xFF102466),
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
              : [],
        ),

        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Icon(
            Icons.qr_code,  // アイコンの追加
            color: Colors.white,  // アイコンの色
            size: 30,  // アイコンのサイズ
          ),
          SizedBox(width:  15),  // アイコンとテキストの間隔を空ける
        Text(
            'QRコード連携',
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


