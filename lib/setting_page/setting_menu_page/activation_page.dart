import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart';


import '../../theme.dart';

class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final TextEditingController activationCodeController = TextEditingController();
  final TextEditingController deviceNameController = TextEditingController();

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
  }

  Future<void> _deviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    // final uuid = Uuid();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        osType = 'Android';
        osVersion = androidInfo.version.release ?? '';
        deviceModel = androidInfo.model ?? '';
        deviceUuid = androidInfo.id ??'仮のUUID、ビルドバージョン';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        osType = 'iOS';
        osVersion = iosInfo.systemVersion ?? '';
        deviceModel = iosInfo.utsname.machine ?? '';
        deviceUuid = '仮のUUID'; // 実装待ち
      }

      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;

      setState(() {}); // UI更新
    } catch (e) {
      print('デバイス情報取得エラー: $e');
    }
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
                _buildActionButton('解除', Color(0xFFFF3C3C), () {
                  _deactivateDialog();


                }),
                _buildActionButton('アクティベーション', Colors.blueAccent, () {
                  _showMockSubmit();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledTextField(String label, TextEditingController controller) {
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
          cursorColor: Colors.white,//カーソルみたいなマークを表示
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


  // Widget _buildTextField(String label, TextEditingController controller) {
  //   return TextField(
  //     controller: controller,
  //     decoration: InputDecoration(
  //       labelText: label,
  //       enabledBorder: const OutlineInputBorder(
  //         borderSide: BorderSide(color: Colors.grey),
  //       ),
  //       focusedBorder: const OutlineInputBorder(
  //         borderSide: BorderSide(color: Colors.grey), // 同じ色で固定
  //       ),
  //     ),
  //   );
  // }

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

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
        ),
        onPressed: onPressed,
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
    );
  }

  void _showMockSubmit() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "アクティベーション送信（仮）",
            textAlign: TextAlign.center, // タイトルを中央揃え
            style: AppTheme.confirmDialogTheme.titleTextStyle,
          ),
          content: Padding(
            padding: const EdgeInsets.only(bottom: 10.0), // コンテンツとボタンの間に余白を追加
            child: Text(
              "コード: ${activationCodeController.text}\nデバイス名: ${deviceNameController.text}",
              style: AppTheme.confirmDialogTheme.contentTextStyle,
            ),
          ),
          actions: [
            Align(
              alignment: Alignment.center, // OKボタンを真ん中に配置
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.confirmDialogButtonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // 角を少し丸くする
                    side: BorderSide(
                        color: AppTheme.confirmDialogBorderColor,
                        width: 2),
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
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


  //解除ボタン押下後のダイアログ
  void _deactivateDialog() {
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
              "解除機能は未実装になっています。",
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
}
