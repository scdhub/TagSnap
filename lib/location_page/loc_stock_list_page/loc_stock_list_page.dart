import 'package:flutter/material.dart';

import '../../theme.dart';

class LocStockListPage extends StatefulWidget {
  const LocStockListPage({super.key});

  @override
  State<StatefulWidget> createState() => _LocStockListPage();
}

class _LocStockListPage extends State<LocStockListPage> {
  @override
  Widget build(BuildContext context) {
    return InventoryScreen();
  }
}

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController extra1Controller = TextEditingController();
  final TextEditingController extra2Controller = TextEditingController();

  bool isLocationFilterOn = false;
  bool isCodeFilterOn = false;
  bool isNameFilterOn = false;
  bool isExtra1FilterOn = false;
  bool isExtra2FilterOn = false;

  List<Map<String, String>> inventory = [
    {
      'コード': '2-X01-1001',
      '物品EPC': 'FFFF01234567890123450002',
      '品名': '木製机M42',
      '拡張欄1': '',
      '拡張欄2': '',
      'ロケーション': 'F1-X93*Y02',
      'ロケ確定日時': '2024/4/1 21:17'
    },
    {
      'コード': '2-X01-1002',
      '物品EPC': 'FFFF01234567890123450003',
      '品名': '木製机M43',
      '拡張欄1': '',
      '拡張欄2': '',
      'ロケーション': 'F1-X93*Y03',
      'ロケ確定日時': '2024/4/2 21:17'
    },
    {
      'コード': '2-X01-1003',
      '物品EPC': 'FFFF01234567890123450004',
      '品名': '木製机M44',
      '拡張欄1': '',
      '拡張欄2': '',
      'ロケーション': 'F1-X93*Y04',
      'ロケ確定日時': '2024/4/3 21:17'
    },
    {
      'コード': '2-X01-1004',
      '物品EPC': 'FFFF01234567890123450005',
      '品名': '木製机M45',
      '拡張欄1': '',
      '拡張欄2': '',
      'ロケーション': 'F1-X93*Y05',
      'ロケ確定日時': '2024/4/4 21:17'
    },
  ];

  List<Map<String, String>> filteredInventory = [];

  @override
  void initState() {
    super.initState();
    filteredInventory = List.from(inventory);
  }

  void filterList() {
    setState(() {
      filteredInventory = inventory.where((item) {
        return (!isLocationFilterOn ||
                item['ロケーション']!.contains(locationController.text)) &&
            (!isCodeFilterOn || item['コード']!.contains(codeController.text)) &&
            (!isNameFilterOn || item['品名']!.contains(nameController.text)) &&
            (!isExtra1FilterOn ||
                item['拡張欄1']!.contains(extra1Controller.text)) &&
            (!isExtra2FilterOn ||
                item['拡張欄2']!.contains(extra2Controller.text));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('在庫リスト',style: TextStyle(
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
    body: Column(
        children: [
          Column(
            children: [
              _buildFilterField('ロケ', locationController, (value) {
                setState(() => isLocationFilterOn = value);
                filterList();
              }, isLocationFilterOn),
              _buildFilterField('コード', codeController, (value) {
                setState(() => isCodeFilterOn = value);
                filterList();
              }, isCodeFilterOn),
              _buildFilterField('品名', nameController, (value) {
                setState(() => isNameFilterOn = value);
                filterList();
              }, isNameFilterOn),
              _buildFilterField('拡張欄1', extra1Controller, (value) {
                setState(() => isExtra1FilterOn = value);
                filterList();
              }, isExtra1FilterOn),
              _buildFilterField('拡張欄2', extra2Controller, (value) {
                setState(() => isExtra2FilterOn = value);
                filterList();
              }, isExtra2FilterOn),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('コード',style: TextStyle(color:AppTheme.textColor))),
                  DataColumn(label: Text('物品EPC',style: TextStyle(color:AppTheme.textColor))),
                  DataColumn(label: Text('品名',style: TextStyle(color:AppTheme.textColor))),
                  DataColumn(label: Text('拡張欄1',style: TextStyle(color:AppTheme.textColor))),
                  DataColumn(label: Text('拡張欄2',style: TextStyle(color:AppTheme.textColor))),
                  DataColumn(label: Text('ロケーション',style: TextStyle(color:AppTheme.textColor))),
                  DataColumn(label: Text('ロケ確定日時',style: TextStyle(color:AppTheme.textColor))),
                ],
                rows: filteredInventory.map((item) {
                  return DataRow(cells: [
                    DataCell(Text(item['コード']!,style: TextStyle(color:AppTheme.textColor))),
                    DataCell(Text(item['物品EPC']!,style: TextStyle(color:AppTheme.textColor))),
                    DataCell(Text(item['品名']!,style: TextStyle(color:AppTheme.textColor))),
                    DataCell(Text(item['拡張欄1']!,style: TextStyle(color:AppTheme.textColor))),
                    DataCell(Text(item['拡張欄2']!,style: TextStyle(color:AppTheme.textColor))),
                    DataCell(Text(item['ロケーション']!,style: TextStyle(color:AppTheme.textColor))),
                    DataCell(Text(item['ロケ確定日時']!,style: TextStyle(color:AppTheme.textColor))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterField(String label, TextEditingController controller,
      ValueChanged<bool> onToggle, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // 縦の余白を減らす
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 垂直方向の位置揃え
        children: [
          Switch(
            value: isActive,
            onChanged: onToggle,
          ),
          SizedBox(width: 4), // スイッチとテキストの間隔を少しだけに
          SizedBox(
            width: 80, // ラベルの幅を固定化して揃える
            child: Text(
              label,
              style: TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(width: 8), // テキストとTextFieldの間隔
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: controller,
                onChanged: (value) => filterList(),
                enabled: isActive,
                style: TextStyle(color: Colors.white), // 入力文字の色
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                  hintText: '絞り込むテキスト',
                  hintStyle: TextStyle(color: Colors.white60),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white60),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}
