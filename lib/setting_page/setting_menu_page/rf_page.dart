import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class RfPage extends StatefulWidget {
  const RfPage({super.key});

  @override
  State<RfPage> createState() => _RfPage();
}

class _RfPage extends State<RfPage> {
  double normalPower = 20.0;
  double qrPower = 3.0;

  final List<double> powerOptions = [
    3.0, 3.5, 4.0, 4.5, 5.0, 6.0, 10.0, 20.0
  ];

  void _showPowerPicker({
    required double currentValue,
    required ValueChanged<double> onSelected,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: Colors.white,
        child: CupertinoPicker(
          backgroundColor: Colors.white,
          itemExtent: 40,
          scrollController: FixedExtentScrollController(
            initialItem: powerOptions.indexOf(currentValue),
          ),
          onSelectedItemChanged: (int index) {
            onSelected(powerOptions[index]);
          },
          children: powerOptions
              .map((value) => Center(child: Text(value.toString())))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPowerRow(String title, double value, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        '${value.toStringAsFixed(1)} dBm',
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RF出力',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: BackButton(color: Colors.blue),
      ),
      body: Column(
        children: [
          _buildPowerRow('通常時', normalPower, () {
            _showPowerPicker(
              currentValue: normalPower,
              onSelected: (val) {
                setState(() => normalPower = val);
              },
            );
          }),
          _buildPowerRow('QRコード連携 / 入庫 / 移動 / 出庫', qrPower, () {
            _showPowerPicker(
              currentValue: qrPower,
              onSelected: (val) {
                setState(() => qrPower = val);
              },
            );
          }),
        ],
      ),
    );
  }
}