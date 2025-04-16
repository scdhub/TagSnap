import 'package:flutter/material.dart';


class NoDoubleReadingPage extends StatefulWidget {
  const NoDoubleReadingPage({super.key});

  @override
  State<NoDoubleReadingPage> createState() => _NoDoubleReadingPage();
}

class _NoDoubleReadingPage extends State<NoDoubleReadingPage> {
  bool isBeepOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '二度読み禁止',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        leading: BackButton(color: Colors.blue),
      ),
      body: Column(
        children: [


          // ビープ音 ON/OFF
          SwitchListTile(
            title: const Text('一回リードのみ'),
            value: isBeepOn,
            onChanged: (bool value) {
              setState(() {
                isBeepOn = value;
              });
            },
          ),
        ],
      ),
    );
  }
}