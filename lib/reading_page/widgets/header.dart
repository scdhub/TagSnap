// lib/reading_page/widgets/header_row.dart

import 'package:flutter/material.dart';

//　ヘッダーの箇所を描画するページ

class Header extends StatelessWidget{
  final Map<String, bool> selectedColumns;
  final double cellWidth;

  const Header({
    Key? key,
    required this.selectedColumns,
    required this.cellWidth,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        border: Border(
          bottom:
          BorderSide(color: Colors.grey),
        ),
      ),
      child: Row(
        children:
        selectedColumns.entries.where((entry) => entry.value).map((entry) {
          // どの列か判定
          final isEPCcol = entry.key == 'EPC';
          final isNoCol = entry.key == 'No' ;
          // 列ごとに幅を振り分け
          final w = isNoCol
              ? 50.0 // No 列だけ狭める
              : isEPCcol
              ? cellWidth // EPC 列は全体幅−他列幅 に合わせた動的セル幅
              : 100.0; // それ以外は従来どおり

          return Container(
            width: w,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              entry.key,
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      ),
    );
  }
}



