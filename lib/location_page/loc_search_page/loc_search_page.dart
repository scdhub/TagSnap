import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../led_page/led_page.dart';
import '../../search_page/search_page.dart';
import '../../theme.dart';


class LocSearchPage extends StatefulWidget {
  const LocSearchPage({super.key});

  @override
  State<StatefulWidget> createState() => _LocSearchPage();
}

class _LocSearchPage extends State<LocSearchPage>
    with SingleTickerProviderStateMixin {
  bool isReading = false;
  bool isNoDoubleRead = false;
  late TabController _tabController;
  int? selectedIndex; // 選択された項目のインデックス
  String copiedEPC = ""; // コピーしたEPCを保持
  int signalStrength = 50; // 仮の初期値（0〜100の範囲で適宜変更）


  // 各タブのデータ（実際は外部から受け取る）
  List<Map<String, dynamic>> epcList = [];
  List<Map<String, dynamic>> himodukeList = [];

  // 選択可能なカラム（初期状態は空）
  Map<String, bool> selectedColumns = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length:2, vsync: this);

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

  // buildTabContentメソッド
  Widget buildTabContent(String tabType) {
    List<Map<String, dynamic>> dataList;
    bool isEPCTab = tabType == "EPC"; // タブがEPCかどうかを判定

    if (tabType == "EPC") {
      dataList = epcList;
    } else {
      dataList = himodukeList;
    }

    int tagCount = dataList.length > 9999 ? 9999 : dataList.length;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    "書込み対象選択リスト",
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight, // 右端に固定
                child: Padding(
                  padding: EdgeInsets.only(right: 10), // 右に余白をつける
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent),
                    onPressed: isEPCTab ? null : selectionDialog,
                    child: Text('表示項目選択', style: TextStyle(color: Colors.white)),
                  ),
                ),
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

        Column(
          children: [
            // 探索中のEPCを表示
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                selectedIndex != null ? "探索中のEPC：${epcList[selectedIndex!]['EPC']}" : "探索するEPCを選択してください",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),

            // 電波強度レベルゲージ
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // 背景（灰色）
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Container(
                    width: (signalStrength / 100) * MediaQuery.of(context).size.width * 0.8, // 強度に応じて幅を変える
                    height: 20,
                    decoration: BoxDecoration(
                      color: signalStrength < 30
                          ? Colors.red
                          : signalStrength < 70
                          ? Colors.yellow
                          : Colors.green, // 色の変化
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "$signalStrength%", // 強度の数値表示
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
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
                    isReading ? '停止' : '探索開始',
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

  //AppBarと
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('探索', style: TextStyle(
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
          // 書込み自動インクリメント設定
          Padding(
            padding: EdgeInsets.only(left: 10, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左側のテキスト
                Text(
                  "探索ID",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),

          // ここに4つの入力欄を追加
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10), // 左右にちょっと余白
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.15,
                  height: 45, // 高さ50px
                  child: TextField(
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]'))
                    ],

                    maxLength: 4, // 最大8桁
                    maxLengthEnforcement: MaxLengthEnforcement.enforced, // 4文字以上入力不可
                    decoration: InputDecoration(
                      filled: true, // 背景を塗りつぶす
                      fillColor: Color(0xFF84848F), // 薄いグレーの背景
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), // 角を丸く
                        borderSide: BorderSide(color: Colors.blue, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFF454343), width: 1), // 通常時の枠
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.redAccent, width: 2), // 入力時の枠
                      ),
                      hintText: '____', // 4文字入ることが分かるように
                      hintStyle: TextStyle(color: Colors.white60), // ヒントの色を薄く
                      counterText: "", // 文字カウンターを消す
                      contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 8), // 余白調整
                    ),
                    textAlign: TextAlign.center, // テキスト中央配置
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,), // フォントサイズUP
                  ),
                );
              }),
            ),
          ),

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
