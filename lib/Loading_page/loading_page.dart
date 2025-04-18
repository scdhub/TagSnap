import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../led_page/led_page.dart';
import '../search_page/search_page.dart';
import '../theme.dart';
import 'package:tagsnap/common_method/wrapper_device_lib.dart';

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

  // ヘッダーとリストのスクロール位置同期用の ScrollController
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();

  // 選択可能なカラム（初期状態は空）
  Map<String, bool> selectedColumns = {};

  // RFIDの重複していないタグ情報を格納するためのリストとStreamからの受信用変数
  final Set<String> tagList = {};
  late StreamSubscription<String>? subscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // RFID関連の初期化
    initializeRFID();

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

    WrapperDeviceLib.termRFID();
    subscription?.cancel();
    super.dispose();
  }

  // RFID周りの初期化
  Future<void> initializeRFID() async {
    // RFID呼び出し用の初期化
    var isInitRFID = await WrapperDeviceLib.initRFID();

    if (isInitRFID) {
      // ストリームの購読は読み取り開始より先にセット
      subscription = WrapperDeviceLib.epcStream.listen((epc) {
        // データ受信時、epcListを直接編集しながらデータ蓄積を行う
        // 重複していないデータ受信時は新規追加
        if (!tagList.contains(epc)) {
          setState(() {
            // ユニークのタグ文字列管理用変数を更新
            tagList.add(epc);
            // epcListも行追加
            // 種別をどうするか
            epcList.add({
              "No": (epcList.length + 1).toString(),
              "EPC": epc,
              "種別": "",
              "管理番号": "",
              "回数": "1",
            });
            // 紐付けリストにも追加
            himodukeList.add({
              "No": (epcList.length).toString(),
              "EPC": epc,
              "種別": "",
              "管理番号": "",
              "回数": "1",
            });
            updateData(epcList, "EPC");
            updateData(himodukeList, "Himoduke");
          });
        }
        // 重複している場合
        else {
          // 単一読み込み（クリアボタン押下せず読んでいる）場合は情報更新無し
          // 連続読み込みは回数のみ情報更新
          if (!isNoDoubleRead) {
            setState(() {
              // epcList内の該当行を取得し、回数情報をインクリメント
              for (var item in epcList) {
                if (item["EPC"] == epc) {
                  int cnt = int.tryParse(item["回数"]) ?? 1;
                  item["回数"] = (cnt + 1).toString();
                  break;
                }
              }
            });
          }
        }

        // カラム初期化目的で呼び出し
        updateData(epcList, "EPC"); //  "None" → "EPC" に修正
        // updateData(epcList, "None"); //マージ時の状態
      }, onError: (error) {
        print("epcStreamでエラー発生: $error");
      });
    }
  }

  // 読み取り開始/停止処理
  Future<void> readRFIDStartStop() async {
    bool ret;
    // 読み取りフラグの状態により呼び出し切り替え
    if (!isReading) {
      // 二度読み禁止フラグの有効時は単一読み取り、無効時は連続読み取り
      if (isNoDoubleRead) {
        ret = await WrapperDeviceLib.startRFIDScanOnce();
      } else {
        ret = await WrapperDeviceLib.startRFIDScan();
      }
    } else {
      ret = await WrapperDeviceLib.stopRFIDScan();
    }

    if (!isNoDoubleRead) {
      if (ret) {
        toggleReading();
        // 状態更新を反映
        setState(() {});
      }
    }
  }

  //開始、停止ボタン
  void toggleReading() {
    setState(() {
      isReading = !isReading;
    });
  }

  //タブを独立
  Map<String, Map<String, bool>> selectedColumnsMap = {
    "EPC": {},
    "Bit": {},
    "Himoduke": {},
  };

  // 外部データを受け取る関数
  void updateData(List<Map<String, dynamic>> newData, String type) {
    setState(() {
      if (type == "EPC") {
        epcList = newData;
        // EPCタブでは Data と 回数 のみ表示
        selectedColumnsMap["EPC"] = {
          "EPC": true,
          // "回数": true,
        };
      } else if (type == "Bit") {
        bitList = newData;
        // Bitタブは必要に応じて設定
        selectedColumnsMap["Bit"] = {
          for (var key in newData.first.keys) key: true,
        };
      } else if (type == "Himoduke") {
        himodukeList = newData;
        // 紐付けタブでは No, Data, 種別, 管理番号 を表示
        selectedColumnsMap["Himoduke"] = {
          "No": true,
          "EPC": true,
          "種別": true,
          "管理番号": true,
          "回数": false,
        };
      }
    });
  }

  //   setState(() {
  //     if (type == "EPC") {
  //       epcList = newData;
  //       selectedColumnsMap["EPC"] = {
  //         "Data": true,
  //         "回数": true,
  //         "No": false,
  //         "種別": false,
  //         "管理番号": false,
  //       };
  //     } else if (type == "Bit") {
  //       bitList = newData;
  //     } else if (type == "Himoduke") {
  //       himodukeList = newData;
  //     }
  //
  //     // カラム選択初期化
  //     if (newData.isNotEmpty) {
  //       selectedColumnsMap[type] = {
  //         for (var key in newData.first.keys) key: true,
  //       };
  //     }
  //   });
  // }

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

  void selectionDialog(String tabType) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            var selectedColumns = selectedColumnsMap[tabType]!;
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
          bottom:
              BorderSide(color: isHeader ? Colors.grey : Colors.grey.shade300),
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

  // buildTabContentメソッド
  Widget buildTabContent(String tabType) {
    // タブ種別判定
    final bool isEPCTab = (tabType == "EPC");
    final List<Map<String, dynamic>> dataList = isEPCTab
        ? epcList
        : (tabType == "Bit" ? bitList : himodukeList);

    //初期化する
    final List<List<String>> csvData = [];

    if (tabType == "EPC") {
      csvData.add(["EPC"]);
      csvData.addAll(epcList.map((e) => [
        e["EPC"]?.toString() ?? ""
      ]));
    } else {
      csvData.add(["No", "EPC", "種別", "管理番号"]);
      csvData.addAll(himodukeList.map((e) => [
        e["No"]?.toString()       ?? "",
        e["EPC"]?.toString() ?? "",
        e["種別"]?.toString()     ?? "",
        e["管理番号"]?.toString()     ?? "",
      ]));
    }
    // bool isEPCTab = (tabType == "EPC");
    // List<Map<String, dynamic>> dataList;
    // if (tabType == "EPC") {
    //   dataList = epcList;
    // } else if (tabType == "Bit") {
    //   dataList = bitList;
    // } else {
    //   // Himoduke
    //   dataList = himodukeList;
    // }

    // そのほか既存のロジック…
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
        Container(
          margin: EdgeInsets.all(5),
          child: Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5FD970)),
                onPressed: () {
                  setState(() {
                    dataList.clear(); // クリアボタンが押されたらデータを消去
                    // RFIDの受信管理用の変数も合わせてクリアする
                    tagList.clear();
                  });
                },
                child: Text('クリア', style: TextStyle(color: Colors.white)),
              ),

              // 二度読み禁止のチェックボックス
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
                  Text('二度読み禁止',
                      style: TextStyle(fontSize: 10, color: Colors.white)),
                ],
              ),
              Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent),
                onPressed: isEPCTab ? null : () => selectionDialog(tabType),
                child: Text('表示項目選択', style: TextStyle(color: Colors.white)),
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
            child: SizedBox(
              width: finalWidth,
              height: 300.0,
              child: ListView.builder(
                itemCount: tagCount,
                itemBuilder: (context, index) {
                  bool isSelected = (index == selectedIndex);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = (selectedIndex == index) ? null : index;
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

        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //タグ数（左）
              Text('タグ数：$tagCount',
                  style: TextStyle(fontSize: 16, color: Colors.white)),

              // 読み込みボタン
              SizedBox(
                width: 170,
                height: 50,
                child: ElevatedButton(
                  onPressed: readRFIDStartStop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isReading ? Color(0xFF0D64FD) : Color(0xFFFD0D8D),
                  ),
                  child: Text(
                    isReading ? '停止' : '読込み開始',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),

              // 保存ボタン
              SizedBox(
                width: 60,
                height: 40,
                child: ElevatedButton(
                  onPressed: () async {
                    List<List<String>> csvData = [];

                    if (isEPCTab) {
                      csvData.add(["EPC"]);

                      for (final item in epcList) {
                        csvData.add([item["管理番号"]?.toString() ?? ""]);
                      }
                    } else {
                      csvData.add(["No", "EPC", "種別", "管理番号"]);

                      for (final item in himodukeList) {
                        csvData.add([
                          item["No"]?.toString() ?? "",
                          item["EPC"]?.toString() ?? "",
                          item["種別"]?.toString() ?? "",
                          item["管理番号"]?.toString() ?? "",
                        ]);
                      }
                    }
                    // ここで既存の関数を呼び出すだけ！
                    await saveCsvWithPicker(context, csvData, "LoadingDate");
                  },
                  child: Text('保存'),
                )
              ),
            ],
          ),
        ),
      ],
    );
  }

  // List<Map<String, String>> himodukeData = [
  //   {"No": "1", "EPC": "EPC 2001", "種別": "Type C", "回数": "1"},
  //   {"No": "2", "EPC": "EPC 2002", "種別": "Type A", "回数": "2"},
  // ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '読込み',
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

  Future<void> saveCsvWithPicker(
    BuildContext context,
    List<List<String>> csvData,
    String defaultFileName,
  ) async {
    // CSV文字列化
    final csvString = const ListToCsvConverter().convert(csvData);
    // バイナリ化
    final bytes = Uint8List.fromList(utf8.encode(csvString));

    // 日付付きファイル名
    final now = DateTime.now();
    final fn =
        "${defaultFileName}_${DateFormat('yyyyMMdd_HHmm').format(now)}.txt";
    // "${defaultFileName}_${DateFormat('yyyyMMdd_HHmm').format(now)}.csv";

    // ファイルピッカーを開く
    final params = SaveFileDialogParams(
      data: bytes,
      fileName: fn,
      mimeTypesFilter: ['text/plain', 'text/csv'],
    );

    final savedPath = await FlutterFileDialog.saveFile(params: params);
    if (savedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存しました:\n$savedPath')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存をキャンセルしました')),
      );
    }
  }
}
