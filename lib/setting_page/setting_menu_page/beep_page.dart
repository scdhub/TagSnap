import 'package:flutter/material.dart';


class BeepPage extends StatefulWidget {
  const BeepPage({super.key});

  @override
  State<BeepPage> createState() => _BeepPage();
}

class _BeepPage extends State<BeepPage> {
  bool isBeepOn = true;
  String selectedVolume = '中';

  final List<String> volumeLevels = ['小', '中', '大'];

  void _showVolumePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          height: 200,
          child: Column(
            children: volumeLevels.map((level) {
              return ListTile(
                title: Center(child: Text(level)),
                onTap: () {
                  setState(() {
                    selectedVolume = level;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ビープ音',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        leading: BackButton(color: Colors.blue),
      ),
      body: Column(
        children: [
     

          // ビープ音 ON/OFF
          SwitchListTile(
            title: const Text('ビープ音'),
            value: isBeepOn,
            onChanged: (bool value) {
              setState(() {
                isBeepOn = value;
              });
            },
          ),

          // Volume
          ListTile(
            title: const Text('Volume'),
            trailing: Text(
              selectedVolume,
              style: const TextStyle(color: Colors.blue),
            ),
            onTap: _showVolumePicker,
          ),
        ],
      ),
    );
  }
}