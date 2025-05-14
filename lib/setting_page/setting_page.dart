import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tagsnap/setting_page/setting_menu_page/activation_page.dart';
import 'package:tagsnap/setting_page/setting_menu_page/beep_page.dart';
import 'package:tagsnap/setting_page/setting_menu_page/frequency_page.dart';
import 'package:tagsnap/setting_page/setting_menu_page/listselect_page.dart';
import 'package:tagsnap/setting_page/setting_menu_page/login_page.dart';
import 'package:tagsnap/setting_page/setting_menu_page/no_double_reading_page.dart';
import 'package:tagsnap/setting_page/setting_menu_page/reading_mode_page.dart';
import 'package:tagsnap/setting_page/setting_menu_page/rf_page.dart';
import 'package:tagsnap/setting_page/setting_menu_page/save_page.dart';

import '../theme.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool isConnected = false;
  bool isEnglishMode = false;
  bool isPolling = false;
  bool isInventoryDisplay = false;
  final TextEditingController epcController =
  TextEditingController(text: 'FFFF');

  @override
  Widget build(BuildContext context,{bool isButtonEnabled = false}) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '設定',
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
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // // ID表示
          // Center(
          //   child: Text(
          //     'RFD850022362523020778',
          //     style: TextStyle(
          //       color: AppTheme.textColor,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),

          SizedBox(height: 12),

          // 接続ボタン
          Center(
            child: ElevatedButton(
              onPressed: isButtonEnabled
                  ? () {
                setState(() {
                  isConnected = !isConnected;
                });
              }

              // onPressed: () {
              //   setState(() {
              //     isConnected = !isConnected;
              //   });
              // },
        : null, // ← null にするとボタンが無効になる
              child: Text(isConnected ? '切断' : '接続'),
            ),
          ),

          SizedBox(height: 20),

          // リーダー設定項目（リストタイルで遷移）
          _buildSectionTitle('リーダー設定'),
          _buildNavTile(context, 'RF出力'),
          _buildNavTile(context, 'ビープ音'),
          _buildNavTile(context, '読取モード'),
          _buildNavTile(context, '周波数チャネル'),
          _buildNavTile(context, '二度読禁止'),
          _buildNavTile(context, '設定保存'),

          SizedBox(height: 20),

          //アプリ設定
          _buildSectionTitle('アプリ設定'),
          _buildNavTile(context, '紐付け・在庫リスト選択',enabled: true),
          _buildNavTile(context, '辞書定義ファイル選択'),

          _buildSwitchTile('英語モード', isEnglishMode, (val) {
            setState(() => isEnglishMode = val);
          },enabled: false),
          _buildSwitchTile('ポーリング', isPolling, (val) {
            setState(() => isPolling = val);
          },enabled: false),
          _buildSwitchTile('在庫リスト外表示', isInventoryDisplay, (val) {
            setState(() => isInventoryDisplay = val);
          },enabled: false),

          _buildNavTile(context, 'EPCフィルター'),

          SizedBox(height: 10),
          // EPC入力欄
          TextField(
            controller: epcController,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: false,//無効化する
            decoration: InputDecoration(
              labelText: '床タグEPCヘッダー値（4桁）',
              border: OutlineInputBorder(), //通常時の枠線
              enabledBorder: OutlineInputBorder(
                // 非フォーカス時の枠線
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                // フォーカス時の枠線
                borderSide: BorderSide(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primary, width: 2.0),
              ),
            ),
          ),

          SizedBox(height: 20),

          _buildNavTile(context, 'FTP設定'),

          SizedBox(height: 20),

          // QR/バーコード設定
          _buildSectionTitle('QR/バーコード設定'),
          _buildNavTile(context, '対応種類'),

          SizedBox(height: 20),

          _buildSectionTitle('アクティベーション'),
          _buildNavTile(context, 'アクティベーション',enabled: true),
          // _buildNavTile(context, 'ログイン'),
        ],
      ),
    );
  }

  // UI部品
  Widget _buildNavTile(BuildContext context, String title,
      {bool enabled = false}) {
    return ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: enabled ? AppTheme.textColor : Colors.grey, // 無効時はグレー
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: enabled ? Colors.black : Colors.grey, // 無効時はグレー
        ),
        onTap: enabled ? () {
          Widget? destination;

          switch (title) {
            case 'RF出力':
              destination = RfPage();
              break;
            case 'ビープ音':
              destination = BeepPage();
              break;
            case '読取モード':
              destination = ReadingModePage();
              break;
            case '周波数チャネル':
              destination = FrequencyPage();
              break;
            case '二度読禁止':
              destination = NoDoubleReadingPage();
              break;
            case '設定保存':
              destination = SavePage();
              break;
            case '紐付け・在庫リスト選択':
              destination = ListselectPage();
              break;
            case 'アクティベーション':
              destination = ActivationPage();
              break;

          // case 'ログイン':
          //   destination = LoginPage();
          //   break;
          }

          if (destination != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => destination!),
            );
          }
        }
            : null, // 無効化
    );
  }

  // ▼ スイッチUI部品
  Widget _buildSwitchTile(
      String title, bool value, ValueChanged<bool> onChanged, {bool enabled = true}) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
        color: enabled ? AppTheme.textColor : Colors.grey,//無効時はグレー
        // style: TextStyle(color: AppTheme.textColor),
      ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null, // 無効時はnull
      // onChanged: onChanged,
    );
  }

  // ▼ セクションタイトル
  Widget _buildSectionTitle(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey.shade300,
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}
