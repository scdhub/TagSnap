// import 'package:flutter/material.dart';
// import 'package:tagsnap/selected_tag_datails/selected_tag_details.dart';
//
// // スキャン結果が取れない間だけテスト用 EPC を使う Details ボタン
// class DetailsButton extends StatelessWidget {
//   // 実機からの読み取り結果
//   final String? scannedEpc;
//   // QR かどうか確認する
//   final bool isQr;
//
//   const DetailsButton({
//     Key? key,
//     this.scannedEpc,
//     this.isQr = false,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     // テスト用の固定EPC
//     const testEpc = '202001010000000000000230';
//     // const testEpc = '202001010000000000000232';
//
//     // 有効な読み取り値があればそれを、なければ testEpc を使う
//     final codeToPass = (scannedEpc != null && scannedEpc!.isNotEmpty)
//         ? scannedEpc!
//         : testEpc;
//
//     final screenWidth = MediaQuery.of(context).size.width;
//
//     return InkWell(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => SelectedTagDetails(
//               initialSelectedCode: codeToPass,
//               isQr: isQr,
//             ),
//           ),
//         );
//       },
//       onTapDown: (_) => {},   // 必要なら setState で押下感を実装
//       onTapUp:   (_) => {},   // StatelessWidget なので省略可
//       onTapCancel: () => {},  // 同上
//
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: screenWidth * 0.26,
//         height: 100,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(30),
//           border: Border.all(color: Colors.white, width: 2),
//           boxShadow: const [],  // 押下エフェクト不要なら空リスト
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: const [
//             Icon(
//               Icons.file_download_done,
//               color: Colors.white,
//               size: 35,
//             ),
//             SizedBox(height: 10),
//             Text(
//               '詳細',
//               style: TextStyle(
//                 fontSize: 20,
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
