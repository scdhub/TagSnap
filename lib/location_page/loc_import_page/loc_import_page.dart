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

  void _showConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            '注意',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Text(
            'ロケーションデータは全て上書きされます',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.redAccent, width: 2),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showSuccessDialog(context); // contextを渡すように修正
                  },
                  child: Text(
                    '読み込み',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                SizedBox(width: 30),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey, width: 2),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        content: Center(
          heightFactor: 1.5,
          child: Text(
            "インポートが成功しました",
            style: TextStyle(fontSize: 16),
          ),
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
              _showConfirmationDialog(context,index);
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
