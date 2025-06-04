import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tagsnap/reading_page/Processing/csvdata_save.dart';
import 'dart:async';
import '../../common_screen_processing/scroll.dart';
import '../../led_page/led_page.dart';
import '../../main.dart'; // インポートして自動停止ボタンを切り替える
import '../../search_page/search_page.dart';
import '../../theme.dart';
import 'package:tagsnap/common_method/wrapper_device_lib.dart';
import 'package:tagsnap/common_method/taginfo_data.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import '../Loading_page/Processing/csvdata_save.dart';
import '../Processing/csvdata_save.dart';
import 'Processing/csv_mapping_loader.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key});

  @override
  State<StatefulWidget> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  //タブ２段構成
  late TabController _outerController;
  late TabController _innerController;

  //読取りフラグ
  bool isReading = false;
  bool isQrReading = false;

  bool isNoDoubleRead = false;
  late TabController _tabController;
  int? selectedIndex; // 選択された項目のインデックス

  String copiedEPC = ""; // コピーしたEPCを保持
  String _currentTab = "EPC";

  // 各タブのデータ（実際は外部から受け取る）
  List<Map<String, dynamic>> epcList = [];
  List<Map<String, dynamic>> bitList = [];
  List<Map<String, dynamic>> himodukeList = [];

  // QR とバーコード用の空リストを追加
  List<Map<String, dynamic>> qrList = [];
  List<Map<String, dynamic>> qrBitList = [];
  List<Map<String, dynamic>> himodukeQrList = [];
  List<Map<String, dynamic>> barcodeList = [];
  List<Map<String, dynamic>> bcBitList = [];
  List<Map<String, dynamic>> himodukeBcList = [];

  // _LoadingPageState のフィールド
  final _csvSaver = CsvSaver();

  // ヘッダーとリストのスクロール位置同期用の ScrollController
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();

  //scroll.dart
  late final ScrollSyncer _scrollSyncer;

  // 選択可能なカラム（初期状態は空）
  Map<String, bool> selectedColumns = {};

  // RFIDの重複していないタグ情報を格納するためのリストとStreamからの受信用変数
  final Set<String> tagList = {};
  late StreamSubscription<EventDataInfo>? subscription;

  // 設定画面で選んだ CSV ファイルのパスから読み込むマップ
  Map<String, Map<String, String>> managementMap = {};

  //CSVマッピングを読み込む
  final CsvMappingLoader _csvMappingLoader = CsvMappingLoader();

  //初期
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        // タブ切り替えを検知して State に保存
        switch (_tabController.index) {
          case 0:
            _currentTab = "EPC";
            break;
          case 1:
            _currentTab = "Bit";
            break;
          case 2:
            _currentTab = "Himoduke";
            break;
        }
        setState(() {}); // buildRow も再描画
      });

    // Outer: タグ, QRコード, バーコード
    _outerController = TabController(length: 3, vsync: this)
      ..addListener(() async {
        final body = _outerController.index == 0
            ? 'タグ'
            : _outerController.index == 1
            ? 'QRコード'
            : 'バーコード';

        // _loadCsvMapping(body) だった箇所を呼び出しに置き換え
        managementMap = await _csvMappingLoader.loadMapping(body);
        refreshHimoduke();
        // 既存の epcList などをリフレッシュ
        setState(() {});
      });

    // Inner: EPC, ビット割付, 紐付け
    _innerController = TabController(length: 3, vsync: this)
      ..addListener(() {
        setState(() {});
      });

    // ScrollSyncer でヘッダーとリストのオフセット同期
    _scrollSyncer = ScrollSyncer(
      primary: _headerScrollController,
      secondary: _listScrollController,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      managementMap = await _csvMappingLoader.loadMapping('タグ');
      // epcList はまだ空でも、ここで selectedColumnsMap を初期化
      updateData(epcList, "EPC");
      updateData(himodukeList, "Himoduke");
      setState(() {});
    });
    initializeDevice();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ライフサイクル監視解除
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    _outerController.dispose();
    _innerController.dispose();

    // ScrollSyncer のリスナー解除
    _scrollSyncer.dispose();
    _headerScrollController.dispose();
    _listScrollController.dispose();

    WrapperDeviceLib.termRFID();
    WrapperDeviceLib.termQR();

    subscription?.cancel();

    super.dispose();
  }

  @override
  void didPushNext() {
    // 新しい画面が押下されたら自動停止
    stopReading();
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

  void stopReading() async {
    if (isReading) {
      await WrapperDeviceLib.stopRFIDScan();
      toggleReading(); // ボタンの状態を更新
    }
  }

  // 受信周りの初期化
  Future<void> initializeDevice() async {
    // RFID呼び出し用の初期化
    var isInit = await WrapperDeviceLib.initRFID();
    // QR呼び出し用の初期化(こちらは特に結果を待たない)
    await WrapperDeviceLib.initQR();

    if (isInit) {
      subscription = WrapperDeviceLib.receiveData().listen((event) async {
        if (event is TagInfoDataEvent) {
          var getTagInfo = event.data;
          if (!tagList.contains(getTagInfo.epc)) {
            tagList.add(getTagInfo.epc);
            epcList.add({
              "No": (epcList.length + 1).toString(),
              "EPC": getTagInfo.epc,
              "種別": managementMap[getTagInfo.epc]?["種別"] ?? "",
              "管理番号": managementMap[getTagInfo.epc]?["管理番号"] ?? "",
              "回数": "1",
            });
            himodukeList.add({
              "No": (himodukeList.length + 1).toString(),
              "EPC": getTagInfo.epc,
              "種別": managementMap[getTagInfo.epc]?["種別"] ?? "",
              "管理番号": managementMap[getTagInfo.epc]?["管理番号"] ?? "",
              "回数": "1",
            });
          } else {
            // 重複タグを検出 → チェックOFF時のみ回数をインクリメント
            if (!isNoDoubleRead) {
              for (var item in epcList) {
                if (item["EPC"] == getTagInfo.epc) {
                  int cnt = int.tryParse(item["回数"]) ?? 1;
                  item["回数"] = (cnt + 1).toString();
                  break;
                }
              }
              // 紐付けタブにも反映
              refreshHimoduke();
            }
          }
          // 最後にUI更新
          updateData(epcList, "EPC");
          updateData(himodukeList, "Himoduke");
        } else if (event is QRInfoDataEvent) {
          // QRに関する情報の取得(仮)
          var getQRInfo = event.data;
          var getData = getQRInfo.barcodeData;
          await WrapperDeviceLib.startQRScan();
        }
      }, onError: (error) {
        print("epcStreamエラー: $error");
      });
    }
  }

  Future<void> readDeviceScanStartStop() async {
    bool ret = false;

    // タグ（RFID）タブ（index == 0）の場合
    if (_outerController.index == 0) {
      if (!isReading) {
        // RFID スキャン開始
        ret = await WrapperDeviceLib.startRFIDScan();
      } else {
        // RFID スキャン停止
        ret = await WrapperDeviceLib.stopRFIDScan();
      }

      if (ret) {
        // 成功したら isReading をトグル!　フラグは必ず OFF になる
        isReading = !isReading;
        isQrReading = false;
        setState(() {});
      }
    }
    // QRコードタブで（index == 1）の場合
    else if (_outerController.index == 1) {
      if (!isQrReading) {
        // QR スキャン開始
        ret = await WrapperDeviceLib.startQRScan();
      } else {
        // QR スキャン停止
        ret = await WrapperDeviceLib.stopQRScan();
      }

      if (ret) {
        // 成功したら isQrReading をトグル、RFIDフラグは必ず OFF に
        isQrReading = !isQrReading;
        isReading = false;
        setState(() {});
      }
    }
    // バーコードタブ（index == 2）で（!isbarcodeReading）
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
          "回数": true,
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
          "回数": true,
        };
      }
    });
  }

  // epcList を更新したあと、必ず呼ぶ
  void refreshHimoduke() {
    himodukeList = epcList.map((e) {
      final epc = e["EPC"] as String;
      final info = managementMap[epc];
      return {
        "No": e["No"],
        "EPC": epc,
        "種別": info?["種別"] ?? "",
        "管理番号": info?["管理番号"] ?? "",
        "回数": e["回数"], //回数が読み込まれる
      };
    }).toList();
    // 表示用の selectedColumnsMap も更新
    updateData(himodukeList, "Himoduke");
  }



  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<StreamSubscription<EventDataInfo>>(
        'subscription', subscription));
    properties.add(DiagnosticsProperty<StreamSubscription<EventDataInfo>>(
        'subscription', subscription));
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
        // 未実装機能無効化対応のためコメントアウト&一時対応に差し替え
        //PopupMenuItem(value: "led", child: Text("LED")),
        PopupMenuItem(value: "led", enabled: false, child: Text("LED"),
        ),
      ],
    );

    if (result == "copy") {
      Clipboard.setData(ClipboardData(text: selectedEPC)); // EPCをコピー
      showCopyDialog();

    } else if (result == "search") {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SearchPage(
                initialSelectedEpc: selectedEPC,
                initialSelectedIndex: index, // index がそのまま使えるなら渡しておく
              ))); //（）に引数を持っていく。SearchPageでもうう。

    } else if (result == "led") {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LedPage())); //（）に引数を持っていく。LEDPageでもらう。
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
                              backgroundColor: Color(0xFF5FD970)),
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
                children:
                selectedColumns.keys.where((key) => key != "回数").map((key) {
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
        double cellWidth = 100.0, //リストの幅
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
        children:
        selectedColumns.entries.where((entry) => entry.value).map((entry) {
          // どの列か判定
          final isEPCcol = entry.key == 'EPC';
          final isNoCol = entry.key == 'No' && _currentTab == "Himoduke";
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
              isHeader ? entry.key : (rowData?[entry.key]?.toString() ?? ""),
              style: isHeader ? TextStyle(fontWeight: FontWeight.bold) : null,
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      ),
    );
  }

  //CSVデータを格納するだけのクラス
  //外側 tabBody: 'タグ', 'QRコード', 'バーコード'
  //内側 tabType: 'EPC', 'Bit', 'Himoduke'
  List<List<String>> buildCsvData({
    required String tabBody,
    required String tabType,
  }) {
    // まずヘッダは No, EPC, 種別, 管理番号
    final List<List<String>> csvData = [
      ['No', 'EPC', '種別', '管理番号'],
    ];

    // 出力対象リストを選択
    List<Map<String, dynamic>> target;
    if (tabBody == 'タグ') {
      target = himodukeList;
    } else if (tabBody == 'QRコード') {
      target = himodukeQrList;
    } else {
      // 'バーコード'
      target = himodukeBcList;
    }

    // ループで行を追加
    for (var i = 0; i < target.length; i++) {
      final e = target[i];
      csvData.add([
        (i + 1).toString(),
        e['EPC']?.toString() ?? '',
        e['種別']?.toString() ?? '',
        e['管理番号']?.toString() ?? '',
      ]);
    }

    return csvData;
  }

  // buildTabContentメソッド
  Widget buildTabContent(String tabType) {
    // 今どの外側タブか判定
    // 外側タブ(タグ/QR/バーコード)の判定
    final outer = _outerController.index;
    final isTagTab = outer == 0;
    final isQrTab = outer == 1;
    final isBcTab = outer == 2; //バーコードができたら使う

    final isEpcTab = tabType == 'EPC';
    final isBitTab = tabType == 'Bit';
    final isHimodukeTab = tabType == 'Himoduke';

    // 各リスト選択
    List<Map<String, dynamic>> rawList;
    if (isTagTab) {
      rawList = isEpcTab
          ? epcList.map((e) => {'EPC': e['EPC'], '回数': e['回数']}).toList()
          : isBitTab
          ? bitList
          : himodukeList;
    } else if (isQrTab) {
      rawList = isEpcTab
          ? qrList.map((e) => {'Data': e['data'], '回数': e['count']}).toList()
          : isBitTab
          ? qrBitList
          : himodukeQrList;
    } else {
      rawList = isEpcTab
          ? barcodeList
          .map((e) => {'Data': e['data'], '回数': e['count']})
          .toList()
          : isBitTab
          ? bcBitList
          : himodukeBcList;
    }

    // managementMap による紐付け
    final dataList = rawList.map((e) {
      final key = isEpcTab ? (isTagTab ? e['EPC'] : e['Data']) : e['EPC'];
      final info = managementMap[key] ?? {};
      return {...e, '種別': info['種別'] ?? '', '管理番号': info['管理番号'] ?? ''};
    }).toList();

    // 以下は元のまま。selectedColumnsMap やスクロール幅計算などもそのまま使えます。
    final selectedColumns = selectedColumnsMap[tabType]!;
    final int rowCount = dataList.length;
    final double screenWidth = MediaQuery.of(context).size.width;
    final int columnCount = selectedColumns.values.where((v) => v).length;
    final double totalWidth = columnCount * 100.0;
    final double finalWidth =
    totalWidth < screenWidth ? screenWidth : totalWidth;
    final double cellWidth = (tabType == "EPC") ? (finalWidth - 100.0) : 100.0;





    //UI
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(5),
          child: Row(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5FD970)),
                onPressed: () async {
                  // スキャン中なら停止
                  if (isReading) {
                    await WrapperDeviceLib.stopRFIDScan();
                    toggleReading(); // ボタン表示も止め状態に合わせる
                  }
                  // クリア処理
                  epcList.clear();
                  himodukeList.clear();
                  tagList.clear();
                  updateData(epcList, "EPC");
                  updateData(himodukeList, "Himoduke");
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
                onPressed:
                tabType == "EPC" ? null : () => selectionDialog(tabType),
                // onPressed: () => selectionDialog(tabType),
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
            controller: _listScrollController,
            child: SizedBox(
              width: finalWidth,
              height: 300.0,
              child: ListView.builder(
                itemCount: rowCount,
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
                      cellWidth: cellWidth,
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
              Text('タグ数：$rowCount',
                  style: TextStyle(fontSize: 16, color: Colors.white)),

              // 読み込みボタン
              SizedBox(
                width: 170,
                height: 50,
                child: ElevatedButton(
                  //ボタン有効化
                  onPressed: readDeviceScanStartStop,
                  //ボタンを無効化にする
                  // (_outerController.index == 0) ? readRFIDStartStop : null,
                  style: ElevatedButton.styleFrom(
                    // disable 時は自動的にグレイアウトされます
                    backgroundColor:
                    (_outerController.index == 0)
                        ? (isReading ? Color(0xFF0D64FD) : Color(0xFFFD0D8D))

                        : (_outerController.index == 1)
                        ? (isReading
                        ? Color(0xFF0D64FD) : Color(0xFFFD0D8D))
                        : Color(0xFFFD0D8D), // バーコードタブの！2ができたら上コピペして使っていいかも
                  ),
                  child: Text(
                    (_outerController.index == 0)
                        ? (isReading ? '停止' : '読込み開始')
                        : (_outerController.index == 1)
                        ? (isQrReading ? '停止' : '読込み開始')
                        : '読込み開始',
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
                      final body = _outerController.index == 0
                          ? 'タグ'
                          : _outerController.index == 1
                          ? 'QR'
                          : 'バーコード';

                      final csvData = buildCsvData(
                        tabBody: body,
                        tabType: _currentTab,
                        // // CSVデータを組み立て
                        // final csvData = DataListByTabType(_currentTab);
                      );
                      await _csvSaver.save(context, csvData, body);
                      // // 新しい CsvSaver を呼び出し
                      // await _csvSaver.save(context, csvData, prefix);
                    },
                    style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    child: Text(
                      '保存',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                    ),
                  ))
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    //ユーザーが Android の戻るボタンや AppBar 左矢印でポップする直前に確実にキャッチ
    return WillPopScope(
      onWillPop: () async {
        stopReading();
        return true; // pop を続行
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '読込み',
            style: TextStyle(
              color: Color(0xFF84848F),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 40,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: Container(
              color: Colors.grey.shade800, // 背景グレー
              child: TabBar(
                controller: _outerController,
                labelColor: Colors.white,
                // 選択中タブ文字は白
                unselectedLabelColor: Colors.white70,
                // 非選択はやや薄めの白
                indicatorColor: Colors.white,
                // インジケーターも白
                // タップされたときにも必ずインデックス補正
                onTap: (index) {
                  if (index != 0) {
                    // そのまま index を受け入れる（何もしない）
                    _outerController.index = index; // TabBar が自動で切り替えてくれる
                  }
                },
                tabs: [
                  Tab(text: 'タグ'),
                  Tab(text: 'QR'),
                  Tab(text: 'バーコード'),
                ],
              ),
            ),
          ),
        ),
        // スワイプ不可＋ controller 側で補正済み
        body: TabBarView(
          controller: _outerController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            // タグ読み取り
            _buildInnerTabs(bodyType: 'タグ'),
            // QRコード（デザインのみ）
            _buildInnerTabs(bodyType: 'QRコード'),
            // バーコード（デザインのみ）
            _buildInnerTabs(bodyType: 'バーコード'),
          ],
        ),
      ),
    );
  }

  // Build the nested inner tab structure
  Widget _buildInnerTabs({required String bodyType}) {
    // タブラベルは固定
    final tabTypes = ["EPC", "Bit", "Himoduke"];

    return Column(
      children: [
        // 内側タブバー
        Material(
          color: Colors.grey,
          child: TabBar(
            controller: _innerController,
            isScrollable: true,
            tabs: [
              Tab(text: 'EPC'),
              Tab(text: 'ビット割付'),
              Tab(text: '紐付け'),
            ],
          ),
        ),

        // データ表示部（タグと同じデザイン）
        Expanded(
          child: TabBarView(
            controller: _innerController,
            children: tabTypes.map((tabType) {
              return buildTabContent(tabType);
            }).toList(),
          ),
        ),
      ],
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
