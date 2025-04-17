import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class WritingPage extends StatefulWidget {
  const WritingPage({super.key});

  @override
  State<StatefulWidget> createState() => _WritingPage();
}

class _WritingPage extends State<WritingPage>
    with SingleTickerProviderStateMixin {
  bool isReading = false;
  bool isNoDoubleRead = false;
  late TabController _tabController;
  int? selectedIndex; // 選択された項目のインデックス
  String copiedEPC = ""; // コピーしたEPCを保持
  int _selectedIncrementMode = 0; // 初期値「なし」

  // 各タブのデータ（実際は外部から受け取る）
  List<Map<String, dynamic>> epcList = [];
  List<Map<String, dynamic>> himodukeList = [];

  // タブごとの表示項目（初期状態）
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

    // ダミーデータの設定
    updateData([
      {"済": "OK", "No": "1", "EPC": "EPC 1001", "種別": "Type A", "管理番号": "1234"},
      {"済": "OK", "No": "2", "EPC": "EPC 1002", "種別": "Type B", "管理番号": "2468"},
      {
        "済": "OK",
        "No": "3",
        "EPC": "EPC 1003",
        "種別": "Type C",
        "管理番号": "9999999999"
      },
    ], "EPC");

    updateData([
      {"済": "OK", "No": "1", "EPC": "EPC 2001", "種別": "Type C", "管理番号": "1"},
      {"済": "OK", "No": "2", "EPC": "EPC 1002", "種別": "Type B", "管理番号": "2468"},
      {
        "済": "OK",
        "No": "3",
        "EPC": "EPC 1003",
        "種別": "Type C",
        "管理番号": "9999999999"
      },
    ], "Himoduke");

    // ヘッダーとリストのスクロール位置を同期するリスナーを登録
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
          "済": true,
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

  void selectionDialog(String tabType) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          var selectedColumns = selectedColumnsMap[tabType]!;
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('表示項目選択',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
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
                        child: Text('クリア', style: TextStyle(fontSize: 10)),
                      ),
                    ),
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
                        child: Text('すべて選択', style: TextStyle(fontSize: 10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  selectedColumns.keys.where((key) => key != "済").map((key) {
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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("OK",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        });
      },
    );
  }
  // 1行分（ヘッダー or データ）を描画する共通メソッド
  Widget buildRow(
      Map<String, dynamic>? rowData,            // nullならヘッダーとして扱う
      Map<String, bool> selectedColumns, {
        bool isHeader = false,                    // trueならヘッダー行
        bool isSelected = false,                  // 選択状態（背景色を変える用）
      }) {
    // 背景色
    final bgColor = isHeader
        ? Colors.grey.shade300
        : isSelected
        ? Colors.lightBlueAccent.withOpacity(0.3)
        : Colors.white;

    return Container(
      // ヘッダーだけ下線を濃くするとかも自由に設定できる
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: isHeader ? Colors.grey : Colors.grey.shade300),
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
            // ヘッダーならカラム名、そうでなければ rowData の値
            isHeader
                ? entry.key
                : (rowData?[entry.key]?.toString() ?? ""),
            style: isHeader
                ? TextStyle(fontWeight: FontWeight.bold)
                : null,
            textAlign: TextAlign.center,
          ),
        ))
            .toList(),
      ),
    );
  }

  Widget buildTabContent(String tabType) {
    // 1) タブがEPCか紐付けかでデータリストを切り替え
    bool isEPCTab = (tabType == "EPC");
    List<Map<String, dynamic>> dataList = isEPCTab ? epcList : himodukeList;

    // 2) 表示対象のカラム情報
    var selectedColumns = selectedColumnsMap[tabType] ?? {};
    int tagCount = dataList.length > 9999 ? 9999 : dataList.length;

    // 3) 画面幅 & 必要な幅の計算
    final double screenWidth = MediaQuery.of(context).size.width;
    final int columnCount =
        selectedColumns.entries.where((entry) => entry.value).length;
    final double calculatedWidth = columnCount * 100.0;
    final double finalWidth =
    calculatedWidth < screenWidth ? screenWidth : calculatedWidth;

    return Column(
      children: [
        // 上部の「書込み対象選択リスト」など
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

        // 4) ヘッダー部分
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _headerScrollController, // 同期用コントローラー
          child: Container(
            width: finalWidth, // カラム数が少なくても画面幅を確保
            child: buildRow(null, selectedColumns, isHeader: true),
          ),
        ),

        // 5) リスト部分
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _listScrollController, // 同期用コントローラー
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
                      });
                    },
                    // データ行を共通の buildRow で描画
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
        // 6) ボタンなど
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
                  isReading ? '停止' : '書込み開始',
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
          '書込み',
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
          // 書込み自動インクリメント設定
          Padding(
            padding: EdgeInsets.only(left: 10, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "書込みID自動インクリ",
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
                SizedBox(width: 10),
                ToggleButtons(
                  constraints: BoxConstraints(minWidth: 50, minHeight: 28),
                  borderRadius: BorderRadius.circular(6),
                  textStyle: TextStyle(fontSize: 12),
                  isSelected: [
                    _selectedIncrementMode == 0,
                    _selectedIncrementMode == 1,
                    _selectedIncrementMode == 2,
                    _selectedIncrementMode == 3,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedIncrementMode = index;
                    });
                  },
                  borderWidth: 1,
                  borderColor: Color(0xFF454343),
                  selectedBorderColor: Colors.redAccent,
                  fillColor: Colors.blue.withOpacity(0.2),
                  selectedColor: Colors.redAccent,
                  children: [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("なし")),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("10進")),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("16進")),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("改行")),
                  ],
                ),
              ],
            ),
          ),
          // 4つの入力欄
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.15,
                  height: 45,
                  child: TextField(
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]'))
                    ],
                    maxLength: 4,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF84848F),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Color(0xFF454343), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: Colors.redAccent, width: 2),
                      ),
                      hintText: '____',
                      hintStyle: TextStyle(color: Colors.white60),
                      counterText: "",
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              physics: NeverScrollableScrollPhysics(),
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
}
