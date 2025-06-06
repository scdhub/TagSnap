
//stful

import 'package:flutter/cupertino.dart';

class  SelectedTagDetails extends StatefulWidget {
 final String initialSelectedEpc;
 final int initialSelectedIndex;

  const SelectedTagDetails({
    super.key,
    required this.initialSelectedEpc,
    required this.initialSelectedIndex,
  });

  @override
  State<StatefulWidget> createState() => _SelectedTagDetailsState();
}

class _SelectedTagDetailsState extends State<SelectedTagDetails> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
