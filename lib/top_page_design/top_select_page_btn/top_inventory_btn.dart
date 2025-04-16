import 'package:flutter/material.dart';
import 'package:tagsnap/inventory_page/inventory_page.dart';


class TopInventoryBtn extends StatefulWidget {
  const TopInventoryBtn({super.key});

  @override
  State<TopInventoryBtn> createState() => _TopInventoryButton();
}

class _TopInventoryButton extends State<TopInventoryBtn> {
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
        => InventoryPage()),  // 遷移先のページ
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
          // color: Color(0xFFE81A7E),
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
            Icons.check_box,  // アイコンの追加
            color: Colors.white,  // アイコンの色
            size: 35,  // アイコンのサイズ
          ),
              SizedBox(height:  10),  // アイコンとテキストの間隔を空ける
        Text(
            '棚卸',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          ],
        ),
      ),
      );
  }
}