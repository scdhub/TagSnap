import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../location_page/loc_search_page/loc_search_page.dart';
import '../theme.dart';

class QrcodePage extends StatefulWidget {
  const QrcodePage({Key? key}) : super(key: key);

  @override
  State<QrcodePage> createState() => _QrcodePage();
}

class _QrcodePage extends State<QrcodePage> {
  List<Map<String, String>> dataList = [
    {"rfid": "", "product": "LR-S01", "lot": "ZA18531A-50011N"}
  ];

  Map<String, bool> selectedColumns = {
    "RFID": true,
    "品番": true,
    "ロット": true,
  };

  bool isReading = false;
  int get tagCount => dataList.length;

  Future<void> saveToJsonFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/qr_rfid_data.json');

    String jsonData = jsonEncode(dataList);
    await file.writeAsString(jsonData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("データを保存しました")),
    );
  }

  void toggleReading() {
    setState(() {
      isReading = !isReading;
    });
  }

  void showPopupMenu(BuildContext context, Offset position, int index) async {
    final RenderBox overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 100, 100),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(value: "search", child: Text("探索")),
        PopupMenuItem(value: "delete", child: Text("削除")),
      ],
    );

    if (result == "delete") {
      setState(() {
        dataList.removeAt(index);
      });
    } else if (result == "search") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LocSearchPage()),
      );
    }
  }

  void selectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Column(
                children: [
                  const Text(
                    '表示項目選択',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // クリアボタン
                      SizedBox(
                        width: 65,
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedColumns.updateAll((key, value) => false);
                            });
                            setStateDialog(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white24,
                          ),
                          child: const Text('クリア', style: TextStyle(fontSize: 10)),
                        ),
                      ),
                      // すべて選択ボタン
                      SizedBox(
                        width: 85,
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedColumns.updateAll((key, value) => true);
                            });
                            setStateDialog(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white24,
                          ),
                          child: const Text('すべて選択', style: TextStyle(fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: selectedColumns.keys.map((key) {
                  return CheckboxListTile(
                    title: Text(key),
                    value: selectedColumns[key],
                    onChanged: (bool? value) {
                      setState(() {
                        selectedColumns[key] = value ?? false;
                      });
                      setStateDialog(() {});
                    },
                  );
                }).toList(),
              ),
              actions: [
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppTheme.confirmDialogButtonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                            color: AppTheme.confirmDialogBorderColor, width: 2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "OK",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ); // ← 正しくはここで閉じて、セミコロン
}
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR/RFID紐付け', style: TextStyle(
          color: Color(0xFF84848F),
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
      ),
      body: Column(
        children: [
          // 上部ボタン
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => dataList.clear()),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('クリア'),
                ),
                const SizedBox(width: 10),
                const Text('紐付けリスト',
                    style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
                const Spacer(),
                ElevatedButton(
                  onPressed: selectionDialog,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('表示項目選択'),
                ),
              ],
            ),
          ),

          // ヘッダー行
          Container(
            color: Colors.grey[300],
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                if (selectedColumns["RFID"]!)
                  const SizedBox(width: 50, child: Text('RFID', style: TextStyle(color: Colors.red))),
                if (selectedColumns["品番"]!)
                  const SizedBox(width: 100, child: Text('品番')),
                if (selectedColumns["ロット"]!)
                  const Expanded(child: Text('ロット')),
              ],
            ),
          ),

          // リスト表示
          Expanded(
            child: ListView.builder(
              itemCount: dataList.length,
              itemBuilder: (context, index) {
                final item = dataList[index];
                return GestureDetector(
                  onTapDown: (details) {
                    showPopupMenu(context, details.globalPosition, index);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey)),
                    ),
                    child: Row(
                      children: [
                        if (selectedColumns["RFID"]!)
                          SizedBox(width: 50, child: Text(item["rfid"] ?? "")),
                        if (selectedColumns["品番"]!)
                          SizedBox(width: 100, child: Text(item["product"] ?? "")),
                        if (selectedColumns["ロット"]!)
                          Expanded(child: Text(item["lot"] ?? "")),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 下部ボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('タグ数：$tagCount', style: const TextStyle(fontSize: 16)),
                SizedBox(
                  width: 170,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: toggleReading,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReading ? Colors.blue : Colors.pink,
                    ),
                    child: Text(
                      isReading ? '停止' : 'QRコード連携開始',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: saveToJsonFile,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    child: const Text('保存',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

