import 'package:flutter/material.dart';
import 'package:tagsnap/inventory_page/inventory_page.dart';


class LocImportBtn extends StatefulWidget {
  const LocImportBtn({super.key});

  @override
  State<LocImportBtn> createState() => _LocImportButton();
}

class _LocImportButton extends State<LocImportBtn> {
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
        width: screenWidth * 0.4,
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color:Color(0xFF44DD92), width: 2),
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
            Text(
              'インポート',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF44DD92),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}