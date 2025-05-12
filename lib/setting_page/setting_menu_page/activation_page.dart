import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tagsnap/common_method/api_activation.dart';

import '../../dummy_data/daialog_succes_or_false.dart';
import '../../dummy_data/dummy_api_data.dart';
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
  }

  Future<void> _loadActivationStatus() async {
    setState(() {
      // _deviceInfo()で初期化済みの情報を参照する
      isActivated = apiAct.isActivate;
    });
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
    final result = await apiAct.activation(activationCodeController.text,
        deviceNameController.text);

    return result;
  }

  Future<Map<String, dynamic>?> startDeactivate() async {
    // アクティベーション「は」デプロイなのでここはまだ未実装っぽい
    return null;
    // アクティベーション解除処理実行
    var result = await apiAct.deactivate();

    return result;
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                  '解除',
                  Color(0xFFFF3C3C),
                  isActivated ? _deactivateDialog : null, // 無効化
                ),
                _buildActionButton(
                  'アクティベーション',
                  Colors.blueAccent,
                  isActivated ? null : _showMockSubmit, // 無効化
                ),
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
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
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
      setState(() => isActivated = true);
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
              child: const Text("CANCEL"),
            ),
        const SizedBox(width: 10,),
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
                final result = await startActivation();

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
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}

////アクティベーションダイアログ
// void _showMockSubmit() {
//   showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         title: Text(
//           "アクティベーション送信（仮）",
//           textAlign: TextAlign.center, // タイトルを中央揃え
//           style: AppTheme.confirmDialogTheme.titleTextStyle,
//         ),
//         content: Padding(
//           padding: const EdgeInsets.only(bottom: 10.0), // コンテンツとボタンの間に余白を追加
//           child: Text(
//             "コード: ${activationCodeController.text}\nデバイス名: ${deviceNameController.text}",
//             style: AppTheme.confirmDialogTheme.contentTextStyle,
//             textAlign: TextAlign.center,
//           ),
//         ),
//         actions: [
//           Align(
//             alignment: Alignment.center, // OKボタンを真ん中に配置
//             child: TextButton(
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: AppTheme.confirmDialogButtonColor,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8), // 角を少し丸くする
//                   side: BorderSide(
//                       color: AppTheme.confirmDialogBorderColor, width: 2),
//                 ),
//                 padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               ),
//               //遷移処理
//               onPressed: () async {
//                 // ダイアログを閉じる
//                 Navigator.pop(context);
//                 // アクティベート済みフラグを保存
//                 final prefs = await SharedPreferences.getInstance();
//                 await prefs.setBool('activated', true);
//                 // ログイン画面へ
//                 Navigator.of(context).pushReplacement(
//                   MaterialPageRoute(builder: (_) => const LoginPage()),
//                 );
//               },
//               child: Text(
//                 "OK",
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//         ],
//       );
//     },
//   );
// }

//   //解除ボタン押下後のダイアログ
//   void _deactivateDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text(
//             "確認",
//             textAlign: TextAlign.center, // タイトルを中央揃え
//             style: AppTheme.confirmDialogTheme.titleTextStyle,
//           ),
//           content: Padding(
//             padding: const EdgeInsets.only(bottom: 10.0), // コンテンツとボタンの間に余白を追加
//             child: Text(
//               "アクティベーションを解除しますか？",
//               style: AppTheme.confirmDialogTheme.contentTextStyle,
//               textAlign: TextAlign.center,
//             ),
//           ),
//           actionsAlignment: MainAxisAlignment.center,
//           actions: [
//             // キャンセル
//             TextButton(
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: Colors.lightBlue,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   side: BorderSide(color: Colors.blueAccent, width: 2),
//                 ),
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               ),
//               onPressed: () => Navigator.pop(context),
//               child: const Text(
//                 "CANCEL",
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             const SizedBox(
//               width: 10,
//             ),
//             // OK（解除実行）
//             TextButton(
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.white,
//                 backgroundColor: AppTheme.confirmDialogButtonColor,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   side: BorderSide(
//                       color: AppTheme.confirmDialogBorderColor, width: 2),
//                 ),
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//               ),
//               onPressed: () async {
//                 // SharedPreferences から activated フラグを削除
//                 final prefs = await SharedPreferences.getInstance();
//                 await prefs.remove('activated');
//
//                 // ローカル state を更新
//                 setState(() {
//                   isActivated = false;
//                 });
//
//                 // ダイアログを閉じる
//                 Navigator.pop(context);
//               },
//               child: const Text(
//                 "OK",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
