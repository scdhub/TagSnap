import 'package:flutter/material.dart';


class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<StatefulWidget> createState() => _LoadingPage();
  }

  //ボタンやタブを押した際の動き
class _LoadingPage extends State<LoadingPage>with SingleTickerProviderStateMixin {
  bool isReading = false; // 読み込み状態（true: 読み込み中, false: 停止中）
  late TabController _tabController; //選択したタブの色を変える

  // 表示項目選択を押した際に表示する列のチェックボックス（デフォルトは全て表示）
  Map<String, bool> selectedColumns = {
    "No": true,
    "EPC": true,
    "種別": true,
    "管理番号": true,
  };

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this); // タブは3つ（EPC, ビット割付, 紐付け）
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  //開始、停止ボタン
  void toggleReading() {
    setState(() {
      isReading = !isReading; // ボタンを押すたびに状態を切り替え
    });
  }
  
  void selectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor: Color(0xFFF7F5EE),
                title: Text('表示項目選択',textAlign: TextAlign.center,style: TextStyle(color:Colors.grey),),
                content: Column(
                    mainAxisSize: MainAxisSize.min, //最小ダイアログ
                    children: [
                      ...selectedColumns.keys.map((key) {
                        return CheckboxListTile(
                          title: Text(key),
                          value: selectedColumns[key],
                          onChanged: (bool? value) {
                            setState(() {
                              selectedColumns[key] = value ?? false;
                            });
                            setStateDialog(() {}); // ポップアップの更新
                          },
                        );
                      }).toList(),
                    ]),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(
                        side: BorderSide(width: 1,color: Colors.blueAccent),
                        backgroundColor: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {}); // 更新
                    },
                    child: Text("OK",style: TextStyle(color: Colors.blueAccent),),
                  ),
                ],
              );
            }
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              }),
          title: Text('読込み', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white60,
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(color: Color(0xFFC9C9D1)),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                tabs: [
                  Tab(text: 'EPC'),
                  Tab(text: 'ビット割付'),
                  Tab(text: '紐付け'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Center(child: Text('EPCのタブ')),
                  Center(child: Text('ビット割付のタブ')),
                  Column(
                    children: [
                      Container(
                        margin: EdgeInsets.all(5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF5FD970),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                      side: BorderSide(color: Colors.white))),
                              onPressed: () {},
                              child: Text('クリア', style: TextStyle(color: Colors.white)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: false,
                                  onChanged: (bool? value) {},
                                  visualDensity: VisualDensity(horizontal: -4.0),
                                ),
                                Text('二度読み禁止', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                      side: BorderSide(color: Colors.white))),
                              onPressed: selectionDialog,
                              child: Text('表示項目選択', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white70),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (selectedColumns["No"]!)
                              SizedBox(width: 50, child: Text('No.', textAlign: TextAlign.center)),
                            if (selectedColumns["EPC"]!)
                              Expanded(child: Text('EPC', textAlign: TextAlign.center)),
                            if (selectedColumns["種別"]!)
                              SizedBox(width: 80, child: Text('種別', textAlign: TextAlign.center)),
                            if (selectedColumns["管理番号"]!)
                              SizedBox(width: 80, child: Text('管理番号', textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            return Container(
                              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (selectedColumns["No"]!)
                                    SizedBox(width: 50, child: Text('${index + 1}', textAlign: TextAlign.center)),
                                  if (selectedColumns["EPC"]!)
                                    Expanded(child: Text('EPC ${index + 1000}', textAlign: TextAlign.center)),
                                  if (selectedColumns["種別"]!)
                                    SizedBox(width: 80, child: Text('種別 ${index + 1}', textAlign: TextAlign.center)),
                                  if (selectedColumns["管理番号"]!)
                                    SizedBox(width: 80, child: Text('管理番号 ${index + 10}', textAlign: TextAlign.center)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('タグ数:'),
                  SizedBox(
                    width: 180,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: toggleReading,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReading ? Color(0xFF0D64FD) : Color(0xFFFD0D8D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(color: Colors.white),
                        ),
                      ),
                      child: Text(isReading ? '停止' : '読み込み開始', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  SizedBox(
                    width: 85,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text('保存', style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}