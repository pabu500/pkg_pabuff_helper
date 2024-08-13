import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WgtProgressStat extends StatefulWidget {
  const WgtProgressStat({
    super.key,
    this.onClose,
    this.completed,
    required this.stopPolling,
    required this.updateStatDef,
  });

  // final List<Map<String, dynamic>> Function() getlist;
  final Function() stopPolling;
  final List<Map<String, dynamic>> updateStatDef;
  final Function()? onClose;
  final bool? completed;

  @override
  State<WgtProgressStat> createState() => _WgtProgressStatState();
}

class _WgtProgressStatState extends State<WgtProgressStat> {
  final Map<String, dynamic> _stat = {};
  bool _inProgress = false;

  Future<void>? _polling() async {
    bool stopPolling = false;
    // int extendCount = 2;
    while (mounted && !stopPolling) {
      stopPolling = widget.stopPolling();

      await Future.delayed(const Duration(milliseconds: 500));
      // List<Map<String, dynamic>> list = widget.getlist();
      // if (list.isEmpty) {
      //   return;
      // }
      if (kDebugMode) {
        print('polling');
      }

      for (var statDef in widget.updateStatDef) {
        if (statDef['showIf'] != null) {
          if (!statDef['showIf']()) {
            continue;
          }
        }
        // if (statDef['countIf'] == null) {
        //   continue;
        // }

        // statDef['value'] = 0;
        // for (var item in list) {
        //   if (statDef['countIf'](item[statDef['key']])) {
        //     setState(() {
        //       statDef['value'] = statDef['value'] + 1;
        //     });
        //   }
        // }
        if (statDef['updateValue'] != null) {
          statDef['value'] = statDef['updateValue']();

          // if ((statDef['value'] ?? 0) > (_stat[statDef['label']] ?? 0)) {
          if (kDebugMode) {
            print('${statDef['label']}:${statDef['value']}');
          }
          if ((statDef['value'] ?? 0) > 0) {
            setState(() {
              _stat[statDef['label']] = statDef['value'];
            });
          }
        } else {
          _stat[statDef['label']] = statDef['value'];
        }
        // if (kDebugMode) {
        //   print('${statDef['label']}:${_stat[statDef['label']]}');
        // }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _polling();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> list = [];
    if (widget.onClose != null && (widget.completed ?? false)) {
      list.add(
        IconButton(
          onPressed: () {
            widget.onClose!();
          },
          icon: const Icon(Icons.cancel),
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }
    //add getStat to the list
    List<Widget> stat = getStat();
    for (var item in stat) {
      list.add(item);
    }
    if (!(widget.completed ?? false)) {
      list.add(horizontalSpaceSmall);
      list.add(xtWait(
        color: Theme.of(context).colorScheme.primary,
      ));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: list,
    );
  }

  List<Widget> getStat() {
    List<Widget> list = [];
    for (var statDef in widget.updateStatDef) {
      if (statDef['showIf'] != null) {
        if (!statDef['showIf']()) {
          continue;
        }
      }
      list.add(
        Container(
          margin: const EdgeInsets.only(right: 10),
          child: Row(
            children: [
              Text(
                (_stat[statDef['label']] ?? 0).toString(),
                style: TextStyle(
                  color: statDef['color'],
                  // fontSize: 13,
                  // fontWeight: FontWeight.bold,
                ),
              ),
              horizontalSpaceTiny,
              Text(
                statDef['label'],
                style: TextStyle(
                  color: statDef['color'],
                  // fontSize: 13,
                  // fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return list;
  }
}
