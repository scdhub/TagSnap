import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common_method/wrapper_device_lib.dart';
import '../led_page/led_page.dart';
import '../theme.dart';
import 'package:path/path.dart' as p;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<StatefulWidget> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  bool isReading = false;
  bool isNoDoubleRead = false;
  int? selectedIndex; // 選択された項目のインデックス
  String copiedEPC = ""; // コピーしたEPCを保持
  int signalStrength = 50; // 仮の初期値（0〜100の範囲で適宜変更）
  StreamSubscription<String>? subscription;
  List<String> tagList = [];
  late List<TextEditingController> _epcControllers;//EPCを入力欄に表示する
  // ヘッダーとリストのスクロール位置同期用の ScrollController
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();

  // 選択可能なカラム（初期状態は空）
  Map<String, bool> selectedColumns = {};

  List<Map<String, dynamic>> epcList = []; // ← 読み込み後に上書きされる
  List<Map<String, dynamic>> himodukeList = []; // ← 読み込み後に上書きされる

  // 設定画面で選んだ CSV ファイルのパスから読み込むマップ
  Map<String, Map<String, String>> managementMap = {};

  //EPCを入力欄に表示させる処理
  Future<void> _onManualEpcChanged() async {
    // 全て４文字埋まっているか
    if (_epcControllers.every((c) => c.text.length == 4)) {
      final entered = _epcControllers.map((c) => c.text).join();
      final match = epcList.indexWhere((e) => e['EPC'] == entered);
      if (match != -1) {
        setState(() {
          selectedIndex = match;
        });
        // 必要ならスクロール位置を合わせるなど
      }
    }
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _epcControllers = List.generate(6, (_) => TextEditingController());
    _setupScrollSync();

    // フレーム後に設定からの CSV パスを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCsvMapping();
      _initListsFromCsv();
      setState(() {});
    });
    initializeRFID();
  }

  void _setupScrollSync() {
    _headerScrollController.addListener(() {
      if (_listScrollController.hasClients &&
          _listScrollController.offset !=
              _headerScrollController.offset) {
        _listScrollController
            .jumpTo(_headerScrollController.offset);
      }
    });
    _listScrollController.addListener(() {
      if (_headerScrollController.hasClients &&
          _headerScrollController.offset !=
              _listScrollController.offset) {
        _headerScrollController
            .jumpTo(_listScrollController.offset);
      }
    });
  }

  /// 管理用 CSV 読み込み
  Future<void> _loadCsvMapping() async {
    final prefs = await SharedPreferences.getInstance();
    final csvPath = prefs.getString('managementCsvPath');
    if (csvPath == null) return;
    final file = File(csvPath);
    if (!await file.exists()) return;

    final content = await file.readAsString();
    final rows = const CsvToListConverter(
        eol: '\n', shouldParseNumbers: false)
        .convert(content);

    if (rows.length < 2) return;
    // 1行目をヘッダ、2行目以降をデータ
    managementMap.clear();
    for (var i = 1; i < rows.length; i++) {
      final cols = rows[i].map((c) => c.toString().trim()).toList();
      // cols = [No., EPC, 種別, 管理番号, …]
      managementMap[cols[1]] = {
        '種別': cols[2],
        '管理番号': cols[3],
      };
    }
    print('管理CSV 読み込み完了: ${managementMap.length} 件');
  }

  Future<void> initializeRFID() async {
    var isInitRFID = await WrapperDeviceLib.initRFID();

    if (isInitRFID) {
      subscription = WrapperDeviceLib.epcStream.listen((epc) {
        final info = managementMap[epc]; // 管理CSVのデータから情報を取得

        if (!tagList.contains(epc)) {
          tagList.add(epc);
          epcList.add({
            "No": (epcList.length + 1).toString(),
            "EPC": epc,
            "種別": info?["種別"] ?? "",
            "管理番号": info?["管理番号"] ?? "",
            // "回数": "1",
          });
          himodukeList.add({
            "No": (epcList.length).toString(),
            "EPC": epc,
            "種別": info?["種別"] ?? "",
            "管理番号": info?["管理番号"] ?? "",
            // "回数": "1",
          });
          updateData(epcList, "EPC");
          updateData(himodukeList, "Himoduke");
        }
      });
    }
  }

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
      } else if (type == "Himoduke") {
        himodukeList = newData;
        // 紐付けタブでは No, Data, 種別, 管理番号 を表示
        selectedColumnsMap["Himoduke"] = {
          "No": true,
          "EPC": true,
          "種別": true,
          "管理番号": true,
          // "回数": true,
        };
      }
    });
  }


  @override
  void dispose() {
    _tabController.dispose();
    _headerScrollController.dispose();
    _listScrollController.dispose();
    for (var c in _epcControllers) c.dispose();

    subscription?.cancel();//メモリリーク防止
    WrapperDeviceLib.termRFID();
    WidgetsBinding.instance.removeObserver(this); // ライフサイクル監視解除
    super.dispose();
  }

  /// CSV だけで一覧を初期化（スキャン前に全レコードを表示）
  void _initListsFromCsv() {
    epcList = [];
    himodukeList = [];

    int idx = 1;
    managementMap.forEach((epc, info) {
      epcList.add({
        'No': idx.toString(),
        'EPC': epc,
        // '回数': '0',
      });
      himodukeList.add({
        'No': idx.toString(),
        'EPC': epc,
        '種別': info['種別']!,
        '管理番号': info['管理番号']!,
        // '回数': '0',
      });
      idx++;
    });

    // 初期表示カラム
    selectedColumnsMap['EPC'] = {
      'EPC': true,
      // '回数': true,
    };
    selectedColumnsMap['Himoduke'] = {
      'No': true,
      'EPC': true,
      '種別': true,
      '管理番号': true,
      // '回数': true,
    };
  }


  void toggleReading() {
    setState(() {
      isReading = !isReading;
    });
  }



  //タブを独立
  Map<String, Map<String, bool>> selectedColumnsMap = {
    "EPC": {},
    "Himoduke": {},
  };




  // メニューを表示する関数
  void showPopupMenu(BuildContext context, Offset position, int index) async {
    final RenderBox overlay =
    Overlay
        .of(context)
        .context
        .findRenderObject() as RenderBox;
    final selectedEPC = epcList[index]["EPC"] ?? "";

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 100, 100),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(value: "copy", child: Text("コピー")),
        PopupMenuItem(value: "led", child: Text("LED")),
      ],
    );

    if (result == "copy") {
      Clipboard.setData(ClipboardData(text: selectedEPC)); // EPCをコピー
      showCopyDialog();
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
                                      (key,
                                      value) => false); // すべてのチェックボックスを解除
                            });
                            setStateDialog(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Color(0xFF5FD970),
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
                                      (key,
                                      value) => true); // すべてのチェックボックスを選択
                            });
                            setStateDialog(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blueAccent,
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


  Widget buildRow(Map<String, dynamic>? rowData, // nullならヘッダーとして扱う
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
            .map((entry) =>
            Container(
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

    final double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final int columnCount =
        selectedColumns.entries
            .where((entry) => entry.value)
            .length;
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
                    "探索対象リスト",
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
                    onPressed: isEPCTab ? null : () =>
                        selectionDialog(tabType),
                    child:
                    Text('表示項目選択',
                        style: TextStyle(color: Colors.white)),
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
                      final epc = epcList[index]['EPC'] as String;
                      // 4文字ずつ切り出してコントローラに入れる
                      for (var i = 0; i < 6; i++) {
                        final start = i * 4;
                        final end = (start + 4).clamp(0, epc.length);
                        _epcControllers[i].text = (start < epc.length)
                            ? epc.substring(start, end)
                            : '';
                      }
                      setState(() {
                        selectedIndex = index;
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

        Column(
          children: [
            // 探索中のEPCを表示
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                selectedIndex != null
                    ? "探索中のEPC：${epcList[selectedIndex!]['EPC']}"
                    : "探索するEPCを選択してください",
                style: TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
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
                    width: (signalStrength / 100) * MediaQuery
                        .of(context)
                        .size
                        .width * 0.8, // 強度に応じて幅を変える
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

          // ここに6つの入力欄を追加
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10), // 左右にちょっと余白
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: MediaQuery
                      .of(context)
                      .size
                      .width * 0.15,
                  height: 30, // 高さ50px
                  child: TextField(
                    controller: _epcControllers[i],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(
                          r'[0-9a-fA-F]'))
                    ],

                    maxLength: 4,
                    // 最大8桁
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    // 4文字以上入力不可
                    decoration: InputDecoration(
                      filled: true,
                      // 背景を塗りつぶす
                      fillColor: Color(0xFF84848F),
                      // 薄いグレーの背景
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), // 角を丸く
                        borderSide: BorderSide(color: Colors.blue, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Color(0xFF454343), width: 1), // 通常時の枠
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.redAccent, width: 2), // 入力時の枠
                      ),
                      hintText: '____',
                      // 4文字入ることが分かるように
                      hintStyle: TextStyle(color: Colors.white60),
                      // ヒントの色を薄く
                      counterText: "",
                      // 文字カウンターを消す
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 5, vertical: 8), // 余白調整
                    ),
                    textAlign: TextAlign.center,
                    onChanged: (_) => _onManualEpcChanged(),
                    // テキスト中央配置
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight
                        .bold,), // フォントサイズUP
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
              physics: NeverScrollableScrollPhysics(), //左右スクロールでタブ移動しないようにする
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
                  foregroundColor: Colors.white,
                  // 文字を白
                  backgroundColor: AppTheme.confirmDialogButtonColor,
                  // 背景色を青系
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
}





