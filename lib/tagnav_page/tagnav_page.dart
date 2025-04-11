import 'package:flutter/material.dart';
import "package:url_launcher/url_launcher.dart";

import '../../theme.dart';

class TagnavPage extends StatefulWidget {
  const TagnavPage({super.key});

  @override
  State<TagnavPage> createState() => _TagnavPageState();
}

class _TagnavPageState extends State<TagnavPage> {

  @override
  void initState() {
    super.initState();
    _launchTagNavURL(); // ページ表示時にブラウザを開く
  }

  Future<void> _launchTagNavURL() async {
    // const url = 'https://54.248.227.206/gps-tracker/public/';
    const url = 'http://ec2-54-248-227-206.ap-northeast-1.compute.amazonaws.com/gps-tracker/public/';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('TagNavを起動中...',style: TextStyle(color: Colors.white),),
      ),
    );
  }
}
