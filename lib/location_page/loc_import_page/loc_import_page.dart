import 'package:flutter/material.dart';

class LocImportPage extends StatefulWidget {
  const LocImportPage({super.key});

  @override
  State<LocImportPage> createState() => _LocImportPage();
}

class _LocImportPage extends State<LocImportPage> {
  int? selectedIndex;
  bool isImported = false;

  final List<String> dummyFiles = [
    "LocationData_20240328_160512.csv",
    "LocationData_20240328_160545.csv",
  ];

  void _showConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "注意！",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text("ロケーションデータは全て上書きされます"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSuccessDialog();
              },
              child: const Text("読み込み"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("キャンセル"),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        content: Center(
          heightFactor: 1.5,
          child: Text("操作が成功しました"),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      setState(() {
        selectedIndex = null;
        isImported = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("インポート", style: TextStyle(
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
      body: isImported
          ? const Center(child: Text("操作が成功しました"))
          : ListView.builder(
        itemCount: dummyFiles.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
              _showConfirmationDialog(index);
            },
            child: Container(
              color: selectedIndex == index ? Colors.grey[300] : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Text(
                dummyFiles[index],
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}
