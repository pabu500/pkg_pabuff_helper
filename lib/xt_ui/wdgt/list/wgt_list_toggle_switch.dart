import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

import 'wgt_edit_commit_list.dart';

class WgtListToggleSwith extends StatefulWidget {
  WgtListToggleSwith({
    Key? key,
    this.width,
    this.parentListWgt,
    this.modifiedRow,
    this.flagModified,
    this.fieldKey,
    required this.initialLabelIndex,
    // this.onToggle,
    this.disabled,
  }) : super(key: key);

  final double? width;
  final String? fieldKey;
  final Map<String, dynamic>? modifiedRow;
  final Function(bool)? flagModified;
  final WgtEditCommitList? parentListWgt;

  int initialLabelIndex;
  // final Function(int?)? onToggle;
  bool? disabled;

  @override
  State<WgtListToggleSwith> createState() => _WgtListToggleSwithState();
}

class _WgtListToggleSwithState extends State<WgtListToggleSwith> {
  bool _modified = false;
  int _currentLabelIndex = 0;

  void _updateList() {
    if (_modified) {
      if (widget.modifiedRow == null || widget.fieldKey == null) return;

      widget.modifiedRow![widget.fieldKey!] =
          _currentLabelIndex == 1 ? true : false;
      if (widget.flagModified != null) {
        widget.flagModified!(true);
      }
      // _changed = false;
    }
  }

  void updateModified(bool modified) {
    setState(() {
      _modified = modified;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.parentListWgt != null) {
      widget.parentListWgt!.regFieldUpdateModified(updateModified);
    }
    _currentLabelIndex = widget.initialLabelIndex;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Row(
        children: [
          // Text('test'),
          ToggleSwitch(
            minWidth: 25.0,
            minHeight: _modified ? 12 : 15.0,
            cornerRadius: 8.0,
            activeBgColors: (widget.disabled != null && widget.disabled!)
                ? [
                    [Colors.grey],
                    [Colors.grey]
                  ]
                : [
                    [Colors.red[500]!],
                    [Colors.green[500]!]
                  ],
            borderColor: _modified ? [Colors.amber.shade900] : null,
            borderWidth: _modified ? 2 : null,
            activeFgColor: Colors.white,
            inactiveBgColor: Colors.grey[400]!,
            inactiveFgColor: Colors.white,
            initialLabelIndex: _currentLabelIndex,
            totalSwitches: 2,
            labels: ["Yes", "No"],
            radiusStyle: true,
            onToggle: (widget.disabled != null && widget.disabled!)
                ? null
                : (index) {
                    print('switched to: $index');

                    //when using static index,
                    //setState rebuilds and assigns same initialLabelIndex
                    // need to assign dynamic index to initialLabelIndex when
                    // using setState as shown below,
                    setState(() {
                      _modified = index != widget.initialLabelIndex;
                      _currentLabelIndex = index!;
                    });

                    _updateList();
                  },
          ),
        ],
      ),
    );
  }
}
