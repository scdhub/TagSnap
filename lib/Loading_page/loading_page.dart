import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../led_page/led_page.dart';
import '../search_page/search_page.dart';
import '../theme.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<StatefulWidget> createState() => _LoadingPage();
}

class _LoadingPage extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  bool isReading = false;
  bool isNoDoubleRead = false;
  late TabController _tabController;
  int? selectedIndex; // 選択された項目のインデックス
  String copiedEPC = ""; // コピーしたEPCを保持

  // 各タブのデータ（実際は外部から受け取る）
  List<Map<String, dynamic>> epcList = [];
  List<Map<String, dynamic>> bitList = [];
  List<Map<String, dynamic>> himodukeList = [];

  // 選択可能なカラム（初期状態は空）
  Map<String, bool> selectedColumns = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 仮データ（外部データが来るまでのダミーを）
    updateData([
      {"No": "1", "EPC": "EPC 1001", "種別": "Type A", "回数": "1"},
      {"No": "2", "EPC": "EPC 1002", "種別": "Type B", "回数": "2"},
    ], "EPC");

    updateData([
      {"No": "1", "種別": "Type X"},
      {"No": "2", "種別": "Type Y"},
    ], "Bit");

    updateData([
      {"No": "1", "EPC": "EPC 2001", "種別": "Type C", "回数": "1"},
    ], "Himoduke");
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  //開始、停止ボタン
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
      } else if (type == "Bit") {
        bitList = newData;
      } else if (type == "Himoduke") {
        himodukeList = newData;
      }
      // カラム選択初期化
      if (newData.isNotEmpty) {
        selectedColumns = {
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
        PopupMenuItem(value: "led", child: Text("LED")),
      ],
    );

    if (result == "copy") {
      Clipboard.setData(ClipboardData(text: selectedEPC)); // EPCをコピー
      showCopyDialog();
    } else if (result == "search") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => SearchPage()));
    } else if (result == "led") {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LedPage()));
    }
  }

  void selectionDialog() {
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
                          child: Text('クリア',style: TextStyle(fontSize: 10),),
                        ),
                      ),
                      // SizedBox(width: 10),
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
                          'すべて選択',style: TextStyle(fontSize: 10),
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

  // buildTabContentメソッド
  Widget buildTabContent(String tabType) {
    List<Map<String, dynamic>> dataList;
    bool isEPCTab = tabType == "EPC"; // タブがEPCかどうかを判定

    if (tabType == "EPC") {
      dataList = epcList;
    } else if (tabType == "Bit") {
      dataList = bitList;
    } else {
      dataList = himodukeList;
    }

    int tagCount = dataList.length > 9999 ? 9999 : dataList.length;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(5),
          child: Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5FD970)),
                onPressed: () {
                  setState(() {
                    dataList.clear();
                  });
                },
                child: Text('クリア', style: TextStyle(color: Colors.white)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: isNoDoubleRead,
                    onChanged: (bool? value) {
                      setState(() {
                        isNoDoubleRead = value ?? false; // 値を更新
                      });
                    },
                    visualDensity: VisualDensity(horizontal: -4.0),
                  ),
                  Text('二度読み禁止', style: TextStyle(fontSize: 10,color: Colors.white)),
                ],
              ),
              Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent),
                onPressed: isEPCTab ? null : selectionDialog,
                child: Text('表示項目選択', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),

        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: Colors.white70),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: selectedColumns.entries
                .where((entry) => entry.value)
                .map((entry) => Expanded(
                    child: Text(entry.key, textAlign: TextAlign.center)))
                .toList(),
          ),
        ),

        //タップ時や長押しした際のポップアップ処理
        Expanded(
          child: ListView.builder(
            itemCount: tagCount,
            itemBuilder: (context, index) {
              bool isSelected = index == selectedIndex; // 選択状態を判定する

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedIndex = index; // タップ時に選択行を変更する
                  });
                },
                onLongPressStart: (details) {
                  setState(() {
                    selectedIndex = index; // 選択された行を記録する
                  });
                  showPopupMenu(context, details.globalPosition, index);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  decoration: BoxDecoration(
                    color: !isSelected
                        ? Colors.white
                        : Colors.lightBlueAccent
                            .withOpacity(0.3), // 選択時に色を変更：淡い青色
                    border:
                        Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: selectedColumns.entries
                        .where((entry) => entry.value)
                        .map((entry) => Expanded(
                              child: Text(
                                dataList[index][entry.key]?.toString() ?? "",
                                textAlign: TextAlign.center,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //タグ数（左）
              Text('タグ数：$tagCount', style: TextStyle(fontSize: 16,color: Colors.white)),

              // 読み込みボタン
              SizedBox(
                width: 170,
                height: 50,
                child: ElevatedButton(
                  onPressed: toggleReading,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isReading ? Color(0xFF0D64FD) : Color(0xFFFD0D8D),
                  ),
                  child: Text(
                    isReading ? '停止' : '読み込み開始',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),

              // 保存ボタン
              SizedBox(
                width: 60,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    saveDialog();
                  },
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: Text('保存',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('読込み'), centerTitle: true),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [Tab(text: 'EPC'), Tab(text: 'ビット割付'), Tab(text: '紐付け')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildTabContent("EPC"),
                buildTabContent("Bit"),
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
