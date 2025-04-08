import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final TextEditingController epcController = TextEditingController(text: 'FFFF');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('設定'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // ID表示
          Center(
            child: Text(
              'RFD850022362523020778',
              // 並木の競合用適当な編集
              // 競合が発生していると怒られたら、光嶋さんの作業環境の変更を
              // 優先するかたちで解決させればOK
              style: TextStyle(fontSize: 30,
                  fontWeight: FontWeight.normal),
            ),
          ),

          SizedBox(height: 12),

          // 接続ボタン
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  isConnected = !isConnected;
                });
              },
              child: Text(isConnected ? '切断' : '接続'),
            ),
          ),

          SizedBox(height: 20),

          // ▼ リーダー設定項目（リストタイルで遷移）
          _buildSectionTitle('リーダー設定'),
          _buildNavTile(context, 'RF出力'),
          _buildNavTile(context, 'ビープ音'),
          _buildNavTile(context, '読取モード'),
          _buildNavTile(context, '周波数チャネル'),
          _buildNavTile(context, '二度読禁止'),
          _buildNavTile(context, '設定保存'),

          SizedBox(height: 20),

          // ▼ アプリ設定
          _buildSectionTitle('アプリ設定'),
          _buildNavTile(context, '紐付け・在庫リスト選択'),
          _buildNavTile(context, '辞書定義ファイル選択'),

          _buildSwitchTile('英語モード', isEnglishMode, (val) {
            setState(() => isEnglishMode = val);
          }),
          _buildSwitchTile('ポーリング', isPolling, (val) {
            setState(() => isPolling = val);
          }),
          _buildSwitchTile('在庫リスト外表示', isInventoryDisplay, (val) {
            setState(() => isInventoryDisplay = val);
          }),

          _buildNavTile(context, 'EPCフィルター'),

          SizedBox(height: 10),
          // EPC入力欄
          TextField(
            controller: epcController,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: '床タグEPCヘッダー値（4桁）',
              border: OutlineInputBorder(),
            ),
          ),

          SizedBox(height: 20),

          _buildNavTile(context, 'FTP設定'),

          SizedBox(height: 20),

          // QR/バーコード設定
          _buildSectionTitle('QR/バーコード設定'),
          _buildNavTile(context, '対応種類'),
        ],
      ),
    );
  }

  // ▼ 共通UI部品（ナビゲーションタイル）
  Widget _buildNavTile(BuildContext context, String title) {
    return ListTile(
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // TODO: 遷移先に移動させる
        print('$title tapped');
      },
    );
  }

  // ▼ スイッチUI部品
  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
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
