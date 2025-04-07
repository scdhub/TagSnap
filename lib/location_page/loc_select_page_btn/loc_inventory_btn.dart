import 'package:flutter/material.dart';
import 'package:tagsnap/inventory_page/inventory_page.dart';
import 'package:tagsnap/location_page/loc_inventory/loc_inventory_page.dart';


class LocInventoryBtn extends StatefulWidget {
  const LocInventoryBtn({super.key});

  @override
  State<LocInventoryBtn> createState() => _LocInventoryButton();
}

class _LocInventoryButton extends State<LocInventoryBtn> {
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
        => LocInventoryPage()),  // 遷移先のページ
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
          border: Border.all(color:Color(0xFF42A5F5), width: 2),
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
              '棚卸',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF42A5F5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}