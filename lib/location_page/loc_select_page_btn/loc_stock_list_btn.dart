import 'package:flutter/material.dart';
import 'package:tagsnap/location_page/loc_stock_list_page/loc_stock_list_page.dart';


class LocStockListBtn extends StatefulWidget {
  const LocStockListBtn({super.key});

  @override
  State<LocStockListBtn> createState() => _LocStockListButton();
}

class _LocStockListButton extends State<LocStockListBtn> {
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
        => LocStockListPage()),  // 遷移先のページ
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
          border: Border.all(color:Color(0xFF704118), width: 2),
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
              '在庫リスト',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF704118),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}