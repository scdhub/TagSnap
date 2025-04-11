import 'package:flutter/material.dart';


class ReadingModePage extends StatefulWidget {
  const ReadingModePage({super.key});

  @override
  State<ReadingModePage> createState() => _ReadingModePage();
}

class _ReadingModePage extends State<ReadingModePage> {
  String selectedSession = 'S0';
  String selectedTagPopulation = '30';
  String selectedInventoryState = 'STATE A';
  String selectedSLFlag = 'ALL';


  final List<String> SessionLevels = ['S0', 'S1', 'S2', 'S3'];
  final List<String> TagPopulationLevels = ['1', '10', '20', '30','40', '50', '60', '70','80', '90', '100',];
  final List<String> InventoryStateLevels = ['STATE A',];
  final List<String> selectedSLFlagLevels  = ['ALL',];

  void _showSessionPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          height: 200,
          child: Column(
            children: SessionLevels.map((level) {
              return ListTile(
                title: Center(child: Text(level)),
                onTap: () {
                  setState(() {
                    selectedSession = level;
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

  //tagPopulationのテキスト
  void _tagPopulation() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          height: 200,
          child: Column(
            children: TagPopulationLevels.map((level) {
              return ListTile(
                title: Center(child: Text(level)),
                onTap: () {
                  setState(() {
                    selectedTagPopulation = level;
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

  //InventoryState
  void _tagInventoryState() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          height: 200,
          child: Column(
            children: TagPopulationLevels.map((level) {
              return ListTile(
                title: Center(child: Text(level)),
                onTap: () {
                  setState(() {
                    selectedTagPopulation = level;
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

  //InventoryState
  void _selectedSLFlag() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          height: 200,
          child: Column(
            children: TagPopulationLevels.map((level) {
              return ListTile(
                title: Center(child: Text(level)),
                onTap: () {
                  setState(() {
                    selectedTagPopulation = level;
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
          '読取りモード',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        leading: BackButton(color: Colors.blue),
      ),
      body: Column(
        children: [


          // Volume
          ListTile(
            title: const Text('Settion'),
            trailing: Text(
              selectedSession,
              style: const TextStyle(color: Colors.blue),
            ),
            onTap: _showSessionPicker,
          ),

          ListTile(
            title: const Text('Tag Population'),
            trailing: Text(
              selectedTagPopulation,
              style: const TextStyle(color: Colors.blue),
            ),
            onTap: _tagPopulation,
          ),

          ListTile(
            title: const Text('InventoryState'),
            trailing: Text(
              selectedInventoryState,
              style: const TextStyle(color: Colors.blue),
            ),
            onTap: _tagInventoryState,
          ),

          ListTile(
            title: const Text('SLFlag'),
            trailing: Text(
              selectedSLFlag,
              style: const TextStyle(color: Colors.blue),
            ),
            onTap: _selectedSLFlag,
          ),


        ],
      ),
    );
  }
}