import 'package:flutter/material.dart';
import '../../tagnav_page/tagnav_page.dart'; // 追加

class TopTagnavBt extends StatefulWidget {
  const TopTagnavBt({super.key});

  @override
  State<TopTagnavBt> createState() => _TopTagnavButtonState();
}

class _TopTagnavButtonState extends State<TopTagnavBt> {
  bool isPressed = false;



  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TagnavPage()),
        );
      },


      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),

      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: screenWidth * 0.26,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: isPressed
              ? [
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
              Icons.public,
              color: Colors.white,
              size: 35,
            ),
            SizedBox(height: 10),
            Text(
              'TagNav',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}