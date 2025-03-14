import 'package:flutter/material.dart';
import 'package:tagsnap/Loading_page/loading_page.dart';


class TopLoadingBtn extends StatefulWidget {
  const TopLoadingBtn({super.key});
  @override
  State<TopLoadingBtn> createState() => _TopLoadingButton();
}

  class _TopLoadingButton extends State<TopLoadingBtn> {
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
            => LoadingPage()),  // 遷移先のページ
            );
          },

        //ボタンの動作変化について
        onTapDown: (_) => setState(() => isPressed = true),  // 押した時
        onTapUp: (_) => setState(() => isPressed = false),   // 離した時
        onTapCancel: () => setState(() => isPressed = false), // キャンセル時

        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          width: screenWidth * 0.7,
          height: 65,
          decoration: BoxDecoration(
            color:  Color(0xFF776CE6),
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
                : [
            ],
          ),


          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(
              Icons.refresh,  // アイコンの追加
              color: Colors.white,  // アイコンの色
              size: 30,  // アイコンのサイズ
            ),
            SizedBox(width:  15),  // アイコンとテキストの間隔を空ける
          Text(
              '読込み',
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




//     return SizedBox(
    //       width: screenWidth * 0.8,
    //       height: 70,
    //       child: ElevatedButton(
    //         style: ElevatedButton.styleFrom(
    //           backgroundColor: Colors.blueAccent,
    //         ),
    //         onPressed: () {
    //           Navigator.push(context,
    //               MaterialPageRoute(builder: (context) => const LoadingPage()),
    //           );
    //         }, //遷移先→loading_page
    //
    //         child: Text('読込み',
    //           style: TextStyle(
    //               color: Colors.white,
    //               fontSize: 25,
    //               fontWeight: FontWeight.bold),
    //           textAlign: TextAlign.center,
    //         ),
    //       ),
    //     );
    //   }
    // }


