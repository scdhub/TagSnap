// import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
// import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tagsnap/common_method/api_activation.dart';

import '../../common_method/api_common.dart';
import '../../dummy_data/daialog_succes_or_false.dart';
// import '../../dummy_data/dummy_api_data.dart';
import '../../theme.dart';
import 'login_page.dart';

class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final TextEditingController activationCodeController =
      TextEditingController(); //アクティベーションコードの管理
  final TextEditingController deviceNameController =
      TextEditingController(); //デバイス名の管理
  bool isActivated = false; // ボタンの反応/無反応

  final ApiActivation apiAct = ApiActivation();

  // デバイス情報
  String osType = '';
  String osVersion = '';
  String appVersion = '';
  String deviceModel = '';
  String deviceUuid = '';

  // late String osType;
  // late String osVersion;
  // late String appVersion;
  // late String deviceModel;
  // late String deviceUuid;

  @override
  void initState() {
    super.initState();
    _deviceInfo();
    _loadActivationStatus(); //状態読み込み
    _loadSavedFields(); // ← 追加
  }

  //　初期表示時に SharedPreferenceInfo から読み込む
  Future<void> _loadSavedFields() async {
    // シングルトンの取得
    final prefs = SharedPreferenceInfo();

    // コントローラに値をセット
    deviceNameController.text = prefs.deviceName;
    activationCodeController.text = prefs.activationCode;

    // isActivated フラグも同時に読み込めるなら
    // isActivated = prefs.activationCode.isNotEmpty;
    setState(() {});
  }

  Future<void> _loadActivationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final activated = prefs.getBool('activated') ?? false;
    setState(() {
      // _deviceInfo()で初期化済みの情報を参照する
      isActivated = apiAct.isActivate;
    });
  }

  //アクティベーション成功時の処理部に、SharedPreferenceInfo を呼び出して保存を行う。
  Future<void> _onActivateSuccess(String code, String name) async {
    final prefs = SharedPreferenceInfo();

    // 更新（メモリ上）
    await prefs.updateInfoValue(code, SharedPreferenceKeys().actCode);
    await prefs.updateInfoValue(name, SharedPreferenceKeys().devName);

    // 永続化
    await prefs.writeSharedPreference();
  }

  Future<void> _deviceInfo() async {
    await apiAct.init();
    // final uuid = Uuid();

    osType = apiAct.osType;
    osVersion = apiAct.osVersion;
    deviceModel = apiAct.modelName;
    deviceUuid = apiAct.deviceUUID;
    appVersion = apiAct.appVer;

    // バージョン管理どうしよう
    //final packageInfo = await PackageInfo.fromPlatform();
    //appVersion = packageInfo.version;

    setState(() {}); // UI更新
  }

  Future<Map<String, dynamic>?> startActivation() async {
    // アクティベーション処理実行
    final result = await apiAct.activation(
        activationCodeController.text, deviceNameController.text);

    return result;
  }

  Future<Map<String, dynamic>?> startDeactivate() async {
    // アクティベーション解除処理実行
    var result = await apiAct.deactivate();

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: isActivated, //アクティブ中のみ戻るボタンを自動で表示
        title: const Text(
          'アクティベーション',
          style: TextStyle(
            color: Color(0xFF84848F),
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildLabeledTextField('アクティベーションコード', activationCodeController),
            const SizedBox(height: 16),
            _buildLabeledTextField('デバイス名', deviceNameController),
            const SizedBox(height: 24),
            _buildInfoRow('UUID:', deviceUuid),
            _buildInfoRow('OS.type:', osType),
            _buildInfoRow('OS.ver:', osVersion),
            _buildInfoRow('App.Ver:', appVersion),
            _buildInfoRow('Device.Model:', deviceModel),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isActivated
                    ? _buildActionButton(
                        '解除', Color(0xFFFF3C3C), _deactivateDialog)
                    : _buildActionButton(
                        'アクティベーション', Colors.blueAccent, _showMockSubmit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledTextField(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          cursorColor: Colors.white, //カーソルみたいなマークを表示
          controller: controller,
          // アクティベーション済のときは編集不可
          enabled: !isActivated,
          decoration: InputDecoration(
            border: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isActivated ? Colors.grey.shade600 : Colors.grey,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            //　アクティブ済みで、編集不可時は背景を薄くする
            fillColor: isActivated ? Colors.grey.shade100 : null,
            filled: isActivated,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 150,
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18))),
          Expanded(
              child: Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, Color activeColor, VoidCallback? onPressed) {
    final bool isEnabled = onPressed != null;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? activeColor : Colors.grey,
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Future<void> _showMockSubmit() async {
    // モック API （ダミーAPI）を呼び出し(dummy_api_data.dart)
    final result = await startActivation();

    // 成功時は SharedPreferences に保存 & 遷移
    if (null != result && result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('activated', true);

      //成功時の成功分岐を作成する。
      await _onActivateSuccess(
        activationCodeController.text,
        deviceNameController.text,
      );
      setState(() => isActivated = true);
      // setState(() => isActivated = true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }

    // ダイアログで結果表示（daialog_succes_or_false.dart）
    showResultDialog(context, result);
  }

  void _deactivateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("確認",
              textAlign: TextAlign.center,
              style: AppTheme.confirmDialogTheme.titleTextStyle),
          content: Text("アクティベーションを解除しますか？",
              textAlign: TextAlign.center,
              style: AppTheme.confirmDialogTheme.contentTextStyle),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.blueAccent, width: 2),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("いいえ"),
            ),
            const SizedBox(
              width: 10,
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppTheme.confirmDialogButtonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: AppTheme.confirmDialogBorderColor, width: 2),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                //モック API
                final result = await startDeactivate();

                //成功時のみフラグ削除 & state 更新
                if (null != result && true == result['success']) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('activated');
                  setState(() => isActivated = false);
                }

                //ダイアログ類を閉じて結果表示
                Navigator.pop(context);
                showResultDialog(context, result);
              },
              child: const Text("はい"),
            ),
          ],
        );
      },
    );
  }
}
