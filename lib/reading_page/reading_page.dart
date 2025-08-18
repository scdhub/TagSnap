//　Led画面に遷移する処理をコメント化しているので使う際は外す

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tagsnap/reading_page/Processing/csvdata_save.dart';
import 'package:tagsnap/reading_page/widgets/header.dart';
import 'package:tagsnap/selected_tag_datails/selected_tag_details.dart';
import 'dart:async';
import '../../common_screen_processing/scroll.dart';
import '../../led_page/led_page.dart';
import '../../main.dart'; // インポートして自動停止ボタンを切り替える
import '../../search_page/search_page.dart';
import '../../theme.dart';
import 'package:tagsnap/common_method/wrapper_device_lib.dart';
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

  // QR重複チェック用
  final Set<String> qrTagSet = {};

  //読取りフラグ
  bool isReading = false;
  bool isQrReading = false;

  bool isNoDoubleRead = false;
  late TabController _tabController;
  int? selectedIndex; // 選択された項目のインデックス

  // コピーしたEPCを保持
  String copiedEPC = "";

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

    //　停止処理
    _outerController = TabController(length: 2, vsync: this)
      ..addListener(() async {
        if (!_outerController.indexIsChanging) {
          // タブ移動が完了した時に必ず停止
          stopReading();
        }
      });

    //タグ/
    _tabController = TabController(length: 2, vsync: this)
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

    // Outer: 「タグ, QRコード/バーコードに変更」
    _outerController = TabController(length: 2, vsync: this)
      ..addListener(() async {
        if (_outerController.indexIsChanging) return;
        final body = _outerController.index == 0
            ? 'タグ': 'QRコード/バーコード';
        // : _outerController.index == 1
            //     ? 'QRコード'
            //     : 'バーコード';

        // _loadCsvMapping(body) だった箇所を呼び出しに置き換え
        managementMap = await _csvMappingLoader.loadMapping(body);
        refreshHimoduke();
        // 既存の epcList などをリフレッシュ
        if (_outerController.index == 1) {
          if (isReading) {
            try {
              await WrapperDeviceLib.stopRFIDScan();
            } catch (e) {
              print('stopRFIDScan error: $e');
            }
            setState(() {
              isReading = false;
            });
          }
        } else {
          // 逆に「タグタブに切り替えたときは QR を止めたい」ならここで止める
          if (isQrReading) {
            try {
              await WrapperDeviceLib.stopQRScan();
            } catch (e) {
              print('stopQRScan error: $e');
            }
            setState(() {
              isQrReading = false;
            });
          }
        }
        setState(() {});
      });

    // Inner: 中身の方なので「EPC, ビット割付, 紐付け」 ここは3で
    _innerController = TabController(length: 3, vsync: this)
      ..addListener(() {
        setState(() {});
      });

    // ここで ScrollController の同期リスナー
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

    // ScrollSyncer でヘッダーとリストのオフセット同期
    _scrollSyncer = ScrollSyncer(
      primary: _headerScrollController,
      secondary: _listScrollController,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      managementMap = await _csvMappingLoader.loadMapping('タグ');

      // //★★★★★C66以外でのテスト用★★★★★★★★★★★★★★★
      // const testEpc = '202001010000000000000230';
      // // const testEpc = '202001010000000000000235';
      // epcList = [
      //   {
      //     "No": "1",
      //     "EPC": testEpc,
      //     "名称": managementMap[testEpc]?["種別"]     ?? "",
      //     "管理番号": managementMap[testEpc]?["管理番号"] ?? "",
      //     "回数": "1",
      //   },
      // ];
      // himodukeList = List.from(epcList); // 同じ内容で紐付けタブにも表示
      // //★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★



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

  //　リソースの処理を担う
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

  //別タブに宣したときに判定
  void stopReading() async {
    if (isReading) {
      await WrapperDeviceLib.stopRFIDScan();
      setState(() {
        isReading = false;
      });
      // toggleReading(); // ボタンの状態を更新
    }
    if (isQrReading) {
      await WrapperDeviceLib.stopQRScan();
      setState(() {
        isQrReading = false;
      });
    }
  }

  // 受信周りの初期化
  Future<void> initializeDevice() async {
    // RFID呼び出し用の初期化
    var isInit = await WrapperDeviceLib.initRFID();

    if (isInit) {
      subscription = WrapperDeviceLib.receiveData().listen((event) async {
        if (event is TagInfoDataEvent) {
          if (!isReading) return;
          var getTagInfo = event.data;
          if (!tagList.contains(getTagInfo.epc)) {
            tagList.add(getTagInfo.epc);
            epcList.add({
              "No": (epcList.length + 1).toString(),
              "EPC": getTagInfo.epc,
              "名称": managementMap[getTagInfo.epc]?["種別"] ?? "",
              "管理番号": managementMap[getTagInfo.epc]?["管理番号"] ?? "",
              "回数": "1",
            });
            himodukeList.add({
              "No": (himodukeList.length + 1).toString(),
              "EPC": getTagInfo.epc,
              "名称": managementMap[getTagInfo.epc]?["種別"] ?? "",
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
          updateData(himodukeQrList, "Himoduke");
          // updateData(himodukeList, "Himoduke");
          // updateData(qrList.map((e) => {'EPC': e['EPC'], '回数': e['回数']}).toList(), "EPC");
        } else if (event is QRInfoDataEvent) {
          if (!isQrReading) return;
          final getQrInfo = event.data;
          final barcode = getQrInfo.barcodeData.trim(); // ←1つのEPCとして処理
          print("受信したQRコード/バーコード: $barcode");

          if (barcode.isEmpty) return;

          // 重複チェック＆リスト更新
          if (!qrTagSet.contains(barcode)) {
            qrTagSet.add(barcode);
            qrList.add({
              "No": (qrList.length + 1).toString(),
              "EPC": barcode,
              "回数": "1",
            });
          } else if (!isNoDoubleRead) {
            for (var item in qrList) {
              if (item["EPC"] == barcode) {
                final cnt = int.tryParse(item["回数"]) ?? 1;
                item["回数"] = (cnt + 1).toString();
                break;
              }
            }
          }


          // 紐付けリスト
          himodukeQrList = qrList.map((e) {
            final epc = e["EPC"]!;
            final info = managementMap[epc] ?? {};
            return {
              "No": e["No"],
              "EPC": epc,
              "名称": info["種別"] ?? "",
              "管理番号": info["管理番号"] ?? "",
              "回数": e["回数"],
            };
          }).toList();
          updateData(epcList, "EPC");
          updateData(himodukeList, "Himoduke");
          setState(() {});

          //QRInfoDataEvent を受信したあと、必ずスキャンを止める処理が入っているのでコメントに
          if (isQrReading) {
          //Aパターン
            bool aaaa=false;
            if(true){
              await WrapperDeviceLib.stopQRScan();
              await WrapperDeviceLib.startQRScan();
            //Bパターン　下記通さずに、そのままstartに飛ぶ
            //   setState(() {
            //     isQrReading = false;
            //   });
            }else{
              await WrapperDeviceLib.startQRScan();
            }

          }
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
        setState(() {
          isQrReading = !isQrReading;
          isReading = false;});
      }
    }
  }

  //開始、停止ボタン
  void toggleReading() {
    setState(() {
      isReading = !isReading;
      isQrReading = !isQrReading;
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
        // 紐付けタブでは No, Data, 名称, 管理番号 を表示
        selectedColumnsMap["Himoduke"] = {
          "No": true,
          "EPC": true,
          "名称": true,
          // "種別": true,
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
        // "種別": info?["種別"] ?? "",
        "名称": info?["種別"] ?? "",
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
  void showPopupMenu(BuildContext context, Offset position, int index,String bodyType,) async {
    final RenderBox overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;
    // final selectedEPC = epcList[index]["EPC"] ?? "";

    // 2. bodyType に応じて正しいリストを参照
    String selectedEPC;
    if (bodyType == 'タグ') {
      selectedEPC = epcList[index]["EPC"];
    } else if (bodyType == 'QRコード/バーコード') {
      selectedEPC = qrList[index]["EPC"];
    } else {
      selectedEPC = barcodeList[index]["EPC"];
    }

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 100, 100),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(value: "search", child: Text("探索")),
        PopupMenuItem(value: "copy", child: Text("コピー")),
        PopupMenuItem(value: "selectedtagdetails", child: Text("詳細")),
        // 未実装機能無効化対応のためコメントアウト&一時対応に差し替え
        //PopupMenuItem(value: "led", child: Text("LED")),
        PopupMenuItem(
          value: "led",
          enabled: false,
          child: Text("LED"),
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
    } else if (result == 'selectedtagdetails') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SelectedTagDetails(
                initialSelectedCode: selectedEPC,
                isQr: bodyType == 'QRコード',
              )));
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
          final isNoCol = entry.key == 'No';
          // final isNoCol = entry.key == 'No'&& _currentTab == "Himoduke";
          // 列ごとに幅を振り分け
          final w = isNoCol
              ? 40.0 // No 列だけ狭める
              : isEPCcol
              ? cellWidth // EPC 列は全体幅−他列幅 に合わせた動的セル幅
              : 100.0; // それ以外は従来どおり

          //テーブル
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
    // まずヘッダは No, EPC, 名称, 管理番号
    final List<List<String>> csvData = [
      ['No', 'EPC', '名称', '管理番号'],
    ];

    // 出力対象リストを選択
    List<Map<String, dynamic>> target;
    if (tabBody == 'タグ') {
      target = himodukeList;
    } else {
      target = himodukeQrList;
    }

    // ループで行を追加
    for (var i = 0; i < target.length; i++) {
      final e = target[i];
      csvData.add([
        (i + 1).toString(),
        e['EPC']?.toString() ?? '',
        e['名称']?.toString() ?? '',
        e['管理番号']?.toString() ?? '',
      ]);
    }

    return csvData;
  }

  // buildTabContentメソッド
  Widget buildTabContent(String tabType, String bodyType) {
    final isTagTab = _outerController.index == 0;
    // final outer = _outerController.index;
    // final isTagTab = outer == 0;
    // final isQrTab = outer == 1;
    // final isBcTab = outer == 2;

    final isEpcTab = tabType == 'EPC';
    final isBitTab = tabType == 'Bit';
    final isHimodukeTab = tabType == 'Himoduke';

    List<Map<String, dynamic>> rawList;

    if (isTagTab) {
      rawList = isEpcTab
          ? epcList.map((e) => {'EPC': e['EPC'], '回数': e['回数']}).toList()
          : isBitTab
          ? bitList
          : himodukeList;
    } else {
      rawList = isEpcTab
          ? qrList.map((e) => {'EPC': e['EPC'], '回数': e['回数']}).toList()
          : isBitTab
          ? qrBitList
          : himodukeQrList;
    }

    final dataList = rawList.map((e) {
      final key = e['EPC']; // すべて EPC に統一
      final info = managementMap[key] ?? {};
      return {
        ...e,
        '名称': info['種別'] ?? '',
        '管理番号': info['管理番号'] ?? '',
      };
    }).toList();

    // タブの大きさ
    final selectedColumns = selectedColumnsMap[tabType]!;
    final int rowCount = dataList.length;
    final double screenWidth = MediaQuery.of(context).size.width;
    final int columnCount = selectedColumns.values.where((v) => v).length;
    final double totalWidth = columnCount * 100.0;
    final double finalWidth =
    totalWidth < screenWidth ? screenWidth : totalWidth;
    final double cellWidth = (tabType == "EPC") ? (finalWidth - 100.0) : 100.0;

    //UI 上部
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
                  if (_outerController.index == 0) {
                    // タグ(RFID)タブのクリア
                    if (isReading) {
                      await WrapperDeviceLib.stopRFIDScan();
                      setState(() => isReading = false);
                    }
                    // クリア処理
                    epcList.clear();
                    himodukeList.clear();
                    tagList.clear();
                    updateData(epcList, "EPC");
                    updateData(himodukeList, "Himoduke");
                  } else if (_outerController.index == 1) {
                    //QRタブのクリア
                    if (isQrReading) {
                      await WrapperDeviceLib.stopQRScan();
                      setState(() => isQrReading = false);
                    }
                    qrTagSet.clear();
                    qrList.clear();
                    himodukeQrList.clear();
                    // QRタブは updateData() ではなく直接 setState()
                    setState(() {});
                  }
                  // （バーコードタブ用クリアが要るならここに else if ）
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
            // buildRow でヘッダーを描く
            child: buildRow(
              null, // rowData=null でヘッダー扱い
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
                        showPopupMenu(context, details.globalPosition, index,bodyType);
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
              Text('件数：$rowCount',
                  style: TextStyle(fontSize: 16, color: Colors.white)),

              // 読み込みボタン
              SizedBox(
                width: 170,
                height: 50,
                child: ElevatedButton(
                  //ボタン有効化
                  onPressed: readDeviceScanStartStop,
                  //ボタンを無効化にする
                  // バーコードタブのときだけ無効化
                  // onPressed: (_outerController.index == 2) ? null : readDeviceScanStartStop,
                  style: ElevatedButton.styleFrom(
                    // disable 時は自動的にグレイアウトされます
                    backgroundColor: (_outerController.index == 0)
                        ? (isReading ? Color(0xFF0D64FD) : Color(0xFFFD0D8D))
                        : (_outerController.index == 1)
                        ? (isQrReading
                        ? Color(0xFF0D64FD)
                        : Color(0xFFFD0D8D))
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
                          ? 'QRコード'
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
                  Tab(text: 'QRコード/バーコード'),
                  // Tab(text: 'バーコード'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _outerController,
          //指でのスワイプで移動するのを無効化
          physics: NeverScrollableScrollPhysics(),
          children: [
            // タグ読み取り
            _buildInnerTabs(bodyType: 'タグ'),
            // QRコード（デザインのみ）
            _buildInnerTabs(bodyType: 'QRコード/バーコード'),
            // バーコード（デザインのみ）
            // _buildInnerTabs(bodyType: 'バーコード'),
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
              return buildTabContent(tabType,bodyType);
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
