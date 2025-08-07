import 'dart:async';
// import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_file_dialog/flutter_file_dialog.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common_method/taginfo_data.dart';
import '../common_method/wrapper_device_lib.dart';
// import 'package:tagsnap/common_method/taginfo_data.dart';
import '../led_page/led_page.dart';
import '../theme.dart';
// import 'package:path/path.dart' as p;

class SearchPage extends StatefulWidget {
  //遷移画面の処理
  final String? initialSelectedEpc;
  final int? initialSelectedIndex;

  const SearchPage({
    Key? key,
    this.initialSelectedEpc,
    this.initialSelectedIndex,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  bool isReading = false;
  bool isNoDoubleRead = false;
  int? selectedIndex; // リストから選択された項目のインデックス
  int reDrawSignalVal = 0; // ゲージ描画/再描画時に参照する値（超速で値更新される時には間引いた値が入る）
  String copiedEPC = ""; // コピーしたEPCを保持
  int signalStrength = 50; // 仮の初期値（0〜100の範囲で適宜変更）
  StreamSubscription<EventDataInfo>? subscription;
  int get filledBars => (reDrawSignalVal ~/ 10).clamp(0, 10);

  List<String> tagList = [];

  //手動で検索したときの内容だが使わないのでコメント化
  // bool _epcMatch = false;// 手動入力が管理CSVのいずれかとマッチしたかどうか
  // int? _manualMatchIndex;// マッチしたときのリスト上のインデックス（選択行をハイライトするときにも使える）

  late List<FocusNode> _epcFocusNodes;
  late List<TextEditingController> _epcControllers; //EPCを入力欄に表示する
  double matchRate = 0.0; // 0.0 ～ 1.0
  // ヘッダーとリストのスクロール位置同期用の ScrollController
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();



  // タブごとの縦スクロール用コントローラ
  final ScrollController _epcScrollController = ScrollController();
  final ScrollController _himodukeScrollController = ScrollController();


  // 選択可能なカラム（初期状態は空）
  Map<String, bool> selectedColumns = {};
  List<Map<String, dynamic>> epcList = []; // 読み込み後に上書きされる
  List<Map<String, dynamic>> himodukeList = []; // 読み込み後に上書きされる

  // 設定画面で選んだ CSV ファイルのパスから読み込むマップ
  Map<String, Map<String, String>> managementMap = {};



  //EPCを入力欄に表示させる処理
  Future<void> _onManualEpcChanged() async {
    // 全て４文字埋まっているか
    if (_epcControllers.every((c) => c.text.length == 4)) {
      final entered = _epcControllers.map((c) => c.text).join();
      final match = epcList.indexWhere((e) => e['EPC'] == entered);

      if (match != -1) {
        // マッチしたとき
        setState(() {
          // _epcMatch = true;
          // _manualMatchIndex = match;
          selectedIndex = match;
          reDrawSignalVal = 0;
        });

        // ① タブをEPC(=0)に切り替え
        if (_tabController.index != 0) {
          _tabController.animateTo(0);
        }

        // ② フレーム後にスクロール
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSelected(0);
        });
      } else {
        // 不一致時
        setState(() {
          // _epcMatch = false;
          // _manualMatchIndex = null;
          selectedIndex = null;
        });
      }
    } else {
      // 途中入力時はクリア
      setState(() {
        // _epcMatch = false;
        // _manualMatchIndex = null;
        selectedIndex = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _headerScrollController.addListener(() {
      if (_listScrollController.hasClients
          && _listScrollController.offset != _headerScrollController.offset) {
        _listScrollController.jumpTo(_headerScrollController.offset);
      }
    });
    _listScrollController.addListener(() {
      if (_headerScrollController.hasClients
          && _headerScrollController.offset != _listScrollController.offset) {
        _headerScrollController.jumpTo(_listScrollController.offset);
      }
    });
    // コントローラ／フォーカスノードの生成
    _epcControllers    = List.generate(6, (_) => TextEditingController());
    _epcFocusNodes     = List.generate(6, (_) => FocusNode());

    // タブコントローラ生成（タブ数は２）
    _tabController     = TabController(length: 2, vsync: this);

    // タブ切り替え時にスクロールを走らせるリスナー
    _tabController.addListener(() {
      // タブのアニメーション中ではなく、切り替わったタイミングでだけ
      if (!_tabController.indexIsChanging && selectedIndex != null) {
        _scrollToSelected(_tabController.index);
      }
    });

    // CSVロード・初期選択も addPostFrameCallback にまとめる
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCsvMapping();
      //*********************************************
      const testEpc = '202001010000000000000230';
      managementMap[testEpc] = {
        '種別': 'テスト種別',
        '管理番号': '0001',
      };

      // epcList, himodukeList に１件だけセット
      epcList = [
        {
          "No": "1",
          "EPC": testEpc,
          "名称": managementMap[testEpc]?["種別"]     ?? "",
          "管理番号": managementMap[testEpc]?["管理番号"] ?? "",
          "回数": "1",
        },
      ];
      himodukeList = List.from(epcList);
      // 画面を再描画
      setState(() {});


      //*********************************************

      _initListsFromCsv(); // epcList, himodukeList をセット
      await initializeRFID();




      // 読み取り画面から渡された EPC があれば…
      if (widget.initialSelectedEpc != null) {
        final epc = widget.initialSelectedEpc!;
        // ① テキストフィールドに4文字ずつ分割セット
        for (var i = 0; i < _epcControllers.length; i++) {
          final start = i * 4;
          final end   = (start + 4).clamp(0, epc.length);
          _epcControllers[i].text =
          (start < epc.length) ? epc.substring(start, end) : '';
        }
        // 選択行を文字列マッチで探して selectedIndex に
        selectedIndex = epcList.indexWhere((e) => e['EPC'] == epc);
      }

      // 初回表示されるタブ（デフォルトは0)にスクロール
      if (selectedIndex != null && selectedIndex! >= 0) {
        _scrollToSelected(_tabController.index);
      }

      setState(() {});
    });
  }

  // void _setupScrollSync() {
  //   _headerScrollController.addListener(() {
  //     if (_listScrollController.hasClients &&
  //         _listScrollController.offset != _headerScrollController.offset) {
  //       _listScrollController.jumpTo(_headerScrollController.offset);
  //     }
  //   });
  //   _listScrollController.addListener(() {
  //     if (_headerScrollController.hasClients &&
  //         _headerScrollController.offset != _listScrollController.offset) {
  //       _headerScrollController.jumpTo(_listScrollController.offset);
  //     }
  //   });
  // }

  void _scrollToSelected(int tabIndex) {
    // どちらのコントローラを使うか切り替え
    final controller = (tabIndex == 0)
        ? _epcScrollController
        : _himodukeScrollController;

    const rowHeight = 34.5;                // １行あたりの高さ（実寸に合わせて調整）
    final offset    = selectedIndex! * rowHeight;
    controller.jumpTo(offset);             // 一気に飛ばす
    // controller.animateTo(offset, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  // 管理用 CSV 読み込み
  Future<void> _loadCsvMapping() async {
    final prefs = await SharedPreferences.getInstance();
    final csvPath = prefs.getString('managementCsvPath_タグ');
    // final csvPath = prefs.getString('managementCsvPath');
    if (csvPath == null) return;
    final file = File(csvPath);
    if (!await file.exists()) return;

    final content = await file.readAsString();
    final rows =
        const CsvToListConverter(eol: "\r\n", shouldParseNumbers: false)
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
    var isInit = await WrapperDeviceLib.initRFID();

    if (isInit) {
      subscription = WrapperDeviceLib.receiveData().listen((event) {
        // RFID時
        if (event is TagInfoDataEvent) {
          var getTagInfo = event.data;
          final info = managementMap[getTagInfo.epc]; // 管理CSVのデータから情報を取得

          // 重複していない時はリスト情報更新
          if (!tagList.contains(getTagInfo.epc)) {
            tagList.add(getTagInfo.epc);
            epcList.add({
              "No": (epcList.length + 1).toString(),
              "EPC": getTagInfo.epc,
              "種別": info?["種別"] ?? "",
              "管理番号": info?["管理番号"] ?? "",
              // 電波強度としてUI表示する用に値を変換
              "電波強度": ConvertRssiToPercent(getTagInfo.rssi),
              // "回数": "1",
            });
            himodukeList.add({
              "No": (epcList.length).toString(),
              "EPC": getTagInfo.epc,
              "種別": info?["種別"] ?? "",
              "管理番号": info?["管理番号"] ?? "",
              // "回数": "1",
            });
            updateData(epcList, "EPC");
            updateData(himodukeList, "Himoduke");
          } // 重複時
          else {
            if (selectedIndex != null) {
              // 選択中EPC情報と合致するデータか
              if (getTagInfo.epc == epcList[selectedIndex!]["EPC"]) {
                print('取得してきたRSSI値：${getTagInfo.rssi}');
                var convPrm = ConvertRssiToPercent(getTagInfo.rssi);
                // ゲージ描画用の値を更新
                setState(() {
                  reDrawSignalVal = convPrm;
                });
              }
            }
          }
        }// QR時
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

  @override //disposeはプラットフォームリソースの解放する
  void dispose() {
    _epcScrollController.dispose();
    _himodukeScrollController.dispose();
    _tabController.dispose();
    _headerScrollController.dispose();
    _listScrollController.dispose();
    // TextEditingController の破棄
    for (var c in _epcControllers) {
      c.dispose();
    }
    // FocusNode の破棄
    for (var node in _epcFocusNodes) {
      node.dispose();
    }

    subscription?.cancel(); // メモリリーク防止
    WrapperDeviceLib.termRFID(); // RFID ライブラリの後片づけ
    WidgetsBinding.instance.removeObserver(this); // ライフサイクル監視解除

    super.dispose();
  }

  //CSV だけで一覧を初期化（スキャン前に全レコードを表示）
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

  // RFIDの読み取り開始/停止（連続読み込みのみ）
  Future<void> changeRFIDStartStop() async {
    bool ret;
    // ステータスが未読み込み時（これから開始）
    if (!isReading) {
      ret = await WrapperDeviceLib.startRFIDScan();
    } else {
      ret = await WrapperDeviceLib.stopRFIDScan();
    }

    if (ret) {
      toggleReading();
    }
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

  //電波強度の色ロジックを変数にまとめる
  Color getMatchColor(double matchRate) {
    if (matchRate < 0.3) return Colors.red; //30未満の時は赤色
    if (matchRate < 0.7) return Colors.yellow; //30～70未満は黄色
    return Colors.green; //70~100の時は緑色
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
        PopupMenuItem(value: "copy", child: Text("コピー")),
        // 未実装機能無効化対応のためコメントアウト&一時対応に差し替え
        //PopupMenuItem(value: "led", child: Text("LED")),
        PopupMenuItem(value: "led", enabled: false, child: Text("LED"),),
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

  // RSSI値を線形変換
  int ConvertRssiToPercent(String setRssi) {
    var valRssi = double.tryParse(setRssi) ?? 0.0;

    // 変換できなかったもしくは0で受信時だったら0で返す
    if (0.0 == valRssi) {
      return 0;
    }

    // -100dBmが最小、-30dBmが最大になる
    var dBmMin = -100;
    var dBmMax = -30;
    // 小数点以下切り捨てでint値に直す
    var tmp = valRssi.clamp(dBmMin, dBmMax).toInt();

    return (tmp - dBmMin) * 100 ~/ (dBmMax - dBmMin);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("アプリ状態: $state"); //
    if (state == AppLifecycleState.paused) {
      // アプリがバックグラウンドに移行したとき
      stopReading(); // 読み取り処理を停止
    }
  }

  // ボタン操作外でのRFID停止対応
  void stopReading() async {
    if (isReading) {
      await WrapperDeviceLib.stopRFIDScan();
      toggleReading(); // ボタンの状態を更新
    }
  }

  Future<void> selectionDialog(String tabType) {
    return showDialog(
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
                                  (key, value) => true); // すべてのチェックボックスを選択
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

  Widget buildRow(
    Map<String, dynamic>? rowData, // nullならヘッダーとして扱う
    Map<String, bool> selectedColumns, {
    bool isHeader = false, // trueならヘッダー行
    bool isSelected = false, // 選択状態（背景色を変える用）
    double cellWidth = 100.0,
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
        )
      ),
      child: Row(
        children: selectedColumns.entries.where((e) => e.value).map((e) {
          // 列キー e.key に応じて幅を切り替え
          final width = (e.key == 'No')
              ? 40.0 // No列だけ狭める
              : cellWidth; // それ以外は従来どおり
          return Container(
            // width: 100,
            width: width,
            alignment: Alignment.center,
            //左寄せにしたいなら
            // alignment: Alignment.left,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              isHeader ? e.key : (rowData?[e.key]?.toString() ?? ""),
              style: isHeader ? TextStyle(fontWeight: FontWeight.bold) : null,
              textAlign: TextAlign.center,
              // textAlign: TextAlign.left,
            ),
          );
        }).toList(),
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
    // EPCタブかつ列数が１（＝EPCだけ表示）のときだけ、この幅をセル幅として使う
    final double cellWidth = (isEPCTab && columnCount == 1)
        ? finalWidth // EPC文字列を丸ごと１セルにする
        : 100.0; // それ以外は従来どおり100px

    final controller = (tabType == "EPC")
        ? _epcScrollController
        : _himodukeScrollController;

    return Column(children: [
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
                  onPressed: isEPCTab
                      ? null
                      : () async {
                          //FocusNode のフォーカスを外す
                          for (var node in _epcFocusNodes) {
                            node.unfocus();
                          }
                          //その後ダイアログを開く
                          await selectionDialog(tabType);
                        },
                  child: Text('表示項目選択', style: TextStyle(color: Colors.white)),
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
          child: buildRow(
            null,
            selectedColumns,
            isHeader: true,
            cellWidth: cellWidth,
          ),
        ),
      ),
      // リスト部分
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller:_listScrollController,
          child: Container(
            width: finalWidth,
            height: 300.0,
            child: ListView.builder(
              controller: controller,//遷移後のスクロール
              itemCount: tagCount,
              itemBuilder: (context, index) {
                bool isSelected = (index == selectedIndex);

                return GestureDetector(
                  onTap: () {
                    // リストをタップした瞬間にもフォーカス外す
                    for (var node in _epcFocusNodes) {
                      node.unfocus();
                    }

                    setState(() {
                      if (selectedIndex == index) {
                        // 選択を外す
                        selectedIndex = null;
                        for (var controller in _epcControllers) {
                          controller.text = '';
                        }
                      } else {
                        selectedIndex = index;
                        final epc = epcList[index]['EPC'] as String;
                        // 4文字ずつ切り出してコントローラに入れる
                        for (var i = 0; i < 6; i++) {
                          final start = i * 4;
                          final end = (start + 4).clamp(0, epc.length);
                          _epcControllers[i].text = (start < epc.length)
                              ? epc.substring(start, end)
                              : '';
                        }
                      }
                    });
                  },
                  onLongPressStart: (details) {
                    setState(() {
                      selectedIndex = index;
                      // ゲージ描画用の変数も初期化
                      reDrawSignalVal = 0;
                      showPopupMenu(context, details.globalPosition, index);
                    });
                  },
                  child: buildRow(
                    dataList[index],
                    selectedColumns,
                    isSelected: isSelected,
                    cellWidth: cellWidth,
                  ),
                );
              },
            ),
          ),
        ),
      ),

      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8), // 余白縮小

          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              selectedIndex != null ? "探索中のRSSI" : "探索するEPCを選択してください",
              style: TextStyle(
                fontSize: 13, // 少し小さめに
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),

          // 電波強度バー（高さ調整）
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(10, (index) {
              // ここで isActive を定義
              final bool isActive = index < filledBars;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 1.5),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isActive
                      ? getMatchColor(reDrawSignalVal / 100) // 0.0～1.0 に正規化
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),

          SizedBox(height: 4), // スペース最小限
          Text(
            "$reDrawSignalVal%",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: getMatchColor(reDrawSignalVal / 100),
            ),
          ),

          // 探索開始ボタン（サイズ縮小）
          Container(
            padding: EdgeInsets.only(top: 10),
            child: Center(
              child: SizedBox(
                width: 150,
                height: 40, // 高さを小さく
                child: ElevatedButton(
                  onPressed: changeRFIDStartStop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isReading ? Color(0xFF0D64FD) : Color(0xFFFD0D8D),
                  ),
                  child: Text(
                    isReading ? '停止' : '探索開始',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ]);
  }

  //AppBarと
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (isReading) {
            // スキャン中なら止める
            await WrapperDeviceLib.stopRFIDScan();
            setState(() {
              isReading = false;
            });
          }
          // true を返すと pop が続行される
          return true;
        },
        child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // フォーカス中のTextFieldを解除してキーボードを閉じる
              FocusScope.of(context).unfocus();
            },
            child: Scaffold(
              resizeToAvoidBottomInset: false, //キーボードが表示される時の警告を削除する
              appBar: AppBar(
                title: Text(
                  '探索',
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
              body: SingleChildScrollView(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 書込み自動インクリメント設定
                    Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "探索ID",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    // 6つのTextField
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (i) {
                          return SizedBox(
                            width: MediaQuery.of(context).size.width * 0.15,
                            height: 30,
                            child: TextField(
                              enableInteractiveSelection: true,//true=切り取り、コピー、貼り付けのメニュー、テキストキャレット(カーソル移動：▲マークで移動)が使える。
                              focusNode: _epcFocusNodes[i],
                              controller: _epcControllers[i],
                              cursorColor: Colors.white,//カーソルみたいなマークを表示
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]'))
                              ],
                              maxLength: 4,
                              maxLengthEnforcement: MaxLengthEnforcement.enforced,
                              decoration: InputDecoration(
                                filled: true,
                                // 入力欄の色がtrueの場合は黄緑色に変化する。一致するものがない場合はグレーのまま。
                                // fillColor: _epcMatch
                                //     ? Colors.lightGreen.withOpacity(0.4)
                                //     : Color(0xFF84848F),
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
                              onChanged: (_) => _onManualEpcChanged(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),


                    SizedBox(height: 20),

                    // TabBar と TabBarView（Expandedは外す）
                    TabBar(
                      controller: _tabController,
                      tabs: [Tab(text: 'EPC'), Tab(text: '紐付け')],
                    ),
                    Container(
                      height: 400, // 高さを明示（必要に応じて調整）
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
              ),
            )));
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
              textAlign: TextAlign.center,
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
