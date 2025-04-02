import 'package:flutter/material.dart';

class DeparturePage extends StatefulWidget {
  const DeparturePage({super.key});

  @override
  State<DeparturePage> createState() => _DeparturePage();
}

class _DeparturePage extends State<DeparturePage> {
  bool isReading = false; // タグ読取り状態の管理

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '入庫ページ',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white, // ヘッダーの背景色（ダークグレー）
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), // 余白を追加
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
          children: [
            // タグ読取り状態（センター配置）
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Text(
                  isReading ? 'タグ読取り中' : 'タグ読取り停止中',
                  style: TextStyle(
                    backgroundColor: isReading
                        ? Color(0xFF0D64FD)
                        : Color(0xFFFD0D8D), // 読取り中は赤、停止中は青
                    fontSize: 24, // フォントサイズ大きめ
                    fontWeight: FontWeight.bold, // 太字
                    color: Colors.white, // 文字色ホワイト
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // ロケーション（左寄せ）
            Text(
              'ロケーション',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),

            // ロケーションの値を表示するエリア
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Text(
                '', // 空欄（将来データが入る）
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            SizedBox(height: 20),

            // コード・品名・拡張欄1・拡張欄2の表
            Container(
              color: Colors.white, // 背景色を白にする
              child: Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(width: 0.5, color: Colors.black), // 内側の罫線
                  outside: BorderSide(width: 1, color: Colors.black), // 外枠の罫線
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(2),
                },
                children: [
                  TableRow(children: [_buildTableCell('コード'), _buildTableCell('')]),
                  TableRow(children: [_buildTableCell('品名'), _buildTableCell('')]),
                  TableRow(children: [_buildTableCell('拡張欄1'), _buildTableCell('')]),
                  TableRow(children: [_buildTableCell('拡張欄2'), _buildTableCell('')]),
                ],
              ),
            ),

            SizedBox(height: 30),

            //読み込んだタグ情報エリア（グレーのテキスト）
            Center(
              child: Container(
                padding:
                EdgeInsets.symmetric(vertical: 5, horizontal: 10), // 余白を調整
                color: Colors.white54, // 背景色を白の半透明に
                child: Text(
                  '読み込んだタグ情報が表示される',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white, // 文字色を白
                  ),
                ),
              ),
            ),
            SizedBox(height: 40),

            // ボタン（センター配置）
            Center(
              child: Column(
                children: [
                  // タグ読取り/停止ボタン
                  SizedBox(
                    width: 200, // ボタンの幅
                    height: 50, // ボタンの高さ
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isReading = !isReading; // 状態を切り替える
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReading
                            ? Color(0xFF0D64FD)
                            : Color(0xFFFD0D8D), // 読取り中は赤、停止中は青
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isReading ? '停止' : 'タグ読取り開始',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 30), // ボタンの間隔

                  // 入庫登録ボタン
                  SizedBox(
                    width: 200, // ボタンの幅
                    height: 50, // ボタンの高さ
                    child: ElevatedButton(
                      onPressed: () {
                        // ここで入庫登録の処理を入れる
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink, // ピンク色のボタン
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        '入庫登録',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // 表のセルを作成するヘルパー関数
  Widget _buildTableCell(String text) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}