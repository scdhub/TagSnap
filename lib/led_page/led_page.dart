import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../search_page/search_page.dart';
import '../theme.dart';

class LedPage extends StatefulWidget {
  const LedPage({super.key});

  @override
  State<StatefulWidget> createState() => _LedPage();
}

class _LedPage extends State<LedPage> with SingleTickerProviderStateMixin {
  bool isReading = false;
  bool isNoDoubleRead = false;
  late TabController _tabController;
  int? selectedIndex; // 選択された項目のインデックス
  String copiedEPC = ""; // コピーしたEPCを保持

  // 各タブのデータ（実際は外部から受け取る）
  List<Map<String, dynamic>> epcList = [];
  List<Map<String, dynamic>> himodukeList = [];

  // タブごとの表示項目
  Map<String, Map<String, bool>> selectedColumnsMap = {
    "EPC": {},
    "Himoduke": {},
  };

  // ヘッダーとリストのスクロール位置同期用の ScrollController
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 仮データ（外部データが来るまでのダミー）
    updateData([
      {"EPC": "EPC 1001"},
      {"EPC": "EPC 1002"},
    ], "EPC");

    updateData([
      {"No": "1", "EPC": "EPC 2001", "種別": "Type C", "回数": "1"},
    ], "Himoduke");

    // ヘッダーとリストのスクロール位置を同期するリスナーを initState 内で登録
    _headerScrollController.addListener(() {
      if (_listScrollController.hasClients &&
          _listScrollController.offset != _headerScrollController.offset) {
        _listScrollController.jumpTo(_headerScrollController.offset);
      }
    });
    _listScrollController.addListener(() {
      if (_headerScrollController.hasClients &&
          _headerScrollController.offset != _listScrollController.offset) {
        _headerScrollController.jumpTo(_listScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerScrollController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  void toggleReading() {
    setState(() {
      isReading = !isReading;
    });
  }

  // 外部データを受け取る関数
  void updateData(List<Map<String, dynamic>> newData, String type) {
    setState(() {
      if (type == "EPC") {
        epcList = newData;
        selectedColumnsMap[type] = {
          "EPC": true,
          "No": false,
          "種別": false,
          "回数": false,
        };
      } else if (type == "Himoduke") {
        himodukeList = newData;
        selectedColumnsMap[type] = {
          for (var key in newData.first.keys) key: true,
        };
      }
    });
  }

  // メニューを表示する関数
  void showPopupMenu(BuildContext context, Offset position, int index) async {
    final RenderBox overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;
    final selectedEPC = epcList[index]["EPC"] ?? "";

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 100, 100),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(value: "search", child: Text("探索")),
        PopupMenuItem(value: "copy", child: Text("コピー")),
      ],
    );

    if (result == "copy") {
      Clipboard.setData(ClipboardData(text: selectedEPC)); // EPCをコピー
      showCopyDialog();
    } else if (result == "search") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => SearchPage()));
    }
  }

  void selectionDialog(String tabType) {
    Map<String, bool> selectedColumns = selectedColumnsMap[tabType]!;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('表示項目選択',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black)),
                  SizedBox(height: 20), // タイトルとボタンの間の余白

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 65,
                        height: 30,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedColumns.updateAll(
                                      (key, value) => false); // すべてのチェックボックスを解除
                            });
                            setStateDialog(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white24,
                          ),
                          child: Text(
                            'クリア',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 85, // 幅
                        height: 30, // 高さ
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedColumns.updateAll(
                                      (key, value) => true); // すべてのチェックボックスを選択
                            });
                            setStateDialog(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white24,
                          ),
                          child: Text(
                            'すべて選択',
                            style: TextStyle(fontSize: 10),
                          ),
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
                  alignment: Alignment.center, // OKボタンを真ん中に配置
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white, // 文字を白
                      backgroundColor:
                      AppTheme.confirmDialogButtonColor, // 背景色を青系
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // 角を少し丸くする
                        side: BorderSide(
                            color: AppTheme.confirmDialogBorderColor,
                            width: 2), // 明るい枠線
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10), // 余白を適切に
                    ),
                    onPressed: () {
                      Navigator.pop(context); // ダイアログを閉じる
                    },
                    child: Text(
                      "OK",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
 Widget buildRow(
    Map<String, dynamic>? rowData, // nullならヘッダーとして扱う
    Map<String, bool> selectedColumns, {
      bool isHeader = false, // trueならヘッダー行
      bool isSelected = false, // 選択状態（背景色を変える用）
    }) {
  final bgColor = isHeader
      ? Colors.grey.shade300
      : isSelected
      ? Colors.lightBlueAccent.withOpacity(0.3)
      : Colors.white;
  return Container(
    decoration: BoxDecoration(
      color: bgColor,
      border: Border(
        bottom: BorderSide(
            color: isHeader ? Colors.grey : Colors.grey.shade300),
      ),
    ),
    child: Row(
      children: selectedColumns.entries
          .where((entry) => entry.value)
          .map((entry) => Container(
        width: 100,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          isHeader
              ? entry.key
              : (rowData?[entry.key]?.toString() ?? ""),
          style:
          isHeader ? TextStyle(fontWeight: FontWeight.bold) : null,
          textAlign: TextAlign.center,
        ),
      ))
          .toList(),
    ),
  );
}

Widget buildTabContent(String tabType) {
  bool isEPCTab = (tabType == "EPC");
  List<Map<String, dynamic>> dataList = isEPCTab ? epcList : himodukeList;
  var selectedColumns = selectedColumnsMap[tabType] ?? {};
  int tagCount = dataList.length > 9999 ? 9999 : dataList.length;

  final double screenWidth = MediaQuery.of(context).size.width;
  final int columnCount =
      selectedColumns.entries.where((entry) => entry.value).length;
  final double calculatedWidth = columnCount * 100.0;
  final double finalWidth =
  calculatedWidth < screenWidth ? screenWidth : calculatedWidth;

  return Column(
    children: [
      Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  "LED点灯対象",
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent),
                  onPressed: isEPCTab ? null : () => selectionDialog(tabType),
                  child:
                  Text('表示項目選択', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
      // ヘッダー部分
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _headerScrollController,
        child: Container(
          width: finalWidth,
          child: buildRow(null, selectedColumns, isHeader: true),
        ),
      ),
      // リスト部分
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _listScrollController,
          child: Container(
            width: finalWidth,
            height: 300.0,
            child: ListView.builder(
              itemCount: tagCount,
              itemBuilder: (context, index) {
                bool isSelected = (index == selectedIndex);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex =
                      (selectedIndex == index) ? null : index;
                    });
                  },
                  onLongPressStart: (details) {
                    setState(() {
                      selectedIndex = index;
                      showPopupMenu(context, details.globalPosition, index);
                    });
                  },
                  child: buildRow(
                    dataList[index],
                    selectedColumns,
                    isSelected: isSelected,
                  ),
                );
              },
            ),
          ),
        ),
      ),


      // 書き込み／点灯ボタンなど
      Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 170,
            height: 50,
            child: ElevatedButton(
              onPressed: toggleReading,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isReading ? Color(0xFF0D64FD) : Color(0xFFFD0D8D),
              ),
              child: Text(
                isReading ? '停止' : '点灯開始',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        'LED点灯',
        style: TextStyle(
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
        // ここに必要な入力欄や設定UI
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            "点灯タグEPC",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
        // 入力欄等は省略...
        TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'EPC'), Tab(text: '紐付け')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              buildTabContent("EPC"),
              buildTabContent("Himoduke"),
            ],
          ),
        ),
      ],
    ),
  );
}

// コピー完了ダイアログ
  void showCopyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "確認",
            textAlign: TextAlign.center, // タイトルを中央揃え
            style: AppTheme.confirmDialogTheme.titleTextStyle,
          ),
          content: Padding(
            padding: const EdgeInsets.only(bottom: 10.0), // コンテンツとボタンの間に余白を追加
            child: Text(
              "EPCをコピーしました。",
              style: AppTheme.confirmDialogTheme.contentTextStyle,
            ),
          ),
          actions: [
            Align(
              alignment: Alignment.center, // OKボタンを真ん中に配置
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white, // 文字を白
                  backgroundColor: AppTheme.confirmDialogButtonColor, // 背景色を青系
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // 角を少し丸くする
                    side: BorderSide(
                        color: AppTheme.confirmDialogBorderColor,
                        width: 2), // 明るい枠線
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10), // 余白を適切に
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "OK",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void saveDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "確認",
            textAlign: TextAlign.center, // タイトルを中央揃え
            style: AppTheme.confirmDialogTheme.titleTextStyle,
          ),
          content: Padding(
            padding: const EdgeInsets.only(bottom: 10.0), // コンテンツとボタンの間に余白を追加
            child: Text(
              "リストを保存しました。",
              textAlign: TextAlign.center, // コンテンツを中央揃え
              style: AppTheme.confirmDialogTheme.contentTextStyle,
            ),
          ),
          actions: [
            Align(
              alignment: Alignment.center, // OKボタンを真ん中に配置
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white, // 文字を白
                  backgroundColor: AppTheme.confirmDialogButtonColor, // 背景色を青系
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // 角を少し丸くする
                    side: BorderSide(
                        color: AppTheme.confirmDialogBorderColor,
                        width: 2), // 明るい枠線
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10), // 余白を適切に
                ),
                onPressed: () {
                  Navigator.pop(context); // ダイアログを閉じる
                },
                child: Text(
                  "OK",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
