import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

import 'evs2_list_text.dart';
import '../file/wgt_save_table.dart';
import 'wgt_usage_bar.dart';

class WgtDashboardList extends StatefulWidget {
  const WgtDashboardList({
    super.key,
    required this.itemList,
    this.title = '',
    this.reportNamePrefix,
    this.width = 200,
    this.height = 250,
    required this.listConfig,
    this.showSelected = false,
    this.padding = EdgeInsets.zero,
    this.contentPadding,
  });

  final double width;
  final double height;
  final String? title;
  final String? reportNamePrefix;
  final List<Map<String, dynamic>> itemList;
  final List<Map<String, dynamic>> listConfig;
  final bool showSelected;
  final EdgeInsets? padding;
  final EdgeInsets? contentPadding;

  @override
  State<WgtDashboardList> createState() => _WgtDashboardListState();
}

class _WgtDashboardListState extends State<WgtDashboardList> {
  late List<Map<String, dynamic>> _rows;

  late final List<Map<String, dynamic>> _listConfig;

  List<List<dynamic>> _getCsvList() {
    List<List<dynamic>> table = [];
    table.add(_listConfig.map((e) => e['title']).toList());
    for (var i = 0; i < _rows.length; i++) {
      Map<String, dynamic> rowToSave = {};
      for (var j = 0; j < _listConfig.length; j++) {
        rowToSave[_listConfig[j]['fieldKey']] =
            _rows[i][_listConfig[j]['fieldKey']];
      }
      table.add(rowToSave.values.toList());
    }
    return table;
  }

  @override
  void initState() {
    super.initState();
    _rows = widget.itemList;
    _listConfig = widget.listConfig;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        SizedBox(
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? '',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).hintColor,
                ),
              ),
              horizontalSpaceTiny,
              WgtSaveTable(
                iconSize: 21,
                // list: _tariffHistory!,
                getList: _getCsvList,
                fileName: makeReportName(
                    widget.reportNamePrefix ?? 'report', null, null, null),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
              shrinkWrap: true,
              // cacheExtent: 100,
              // padding: EdgeInsets.all(0),
              itemExtent: 25,
              itemCount: _rows.length, //+ 1,
              itemBuilder: (context, index) {
                // if (index == 0) {
                //   return _buildListHeader();
                // } else {
                //   Map<String, dynamic> row = _rows[index - 1];
                //   return _buildListItem(row);
                // }
                Map<String, dynamic> row = _rows[index];
                return _buildListItem(_rows, row);
              }),
        ),
      ]),
    );
  }

  Widget _buildListHeader() {
    TextStyle listHeaderStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Theme.of(context).hintColor,
    );

    //build list header from widget.listConfig
    List<Evs2ListText> listHeader = [];
    for (Map<String, dynamic> item in _listConfig) {
      if (item != _listConfig.last) {
        listHeader.add(
          Evs2ListText(
            originalFullText: item['title'],
            width: item['width'],
            style: listHeaderStyle,
          ),
        );
      } else {
        listHeader.add(
          Evs2ListText(
            originalFullText: item['title'],
            width: item['width'],
            style: listHeaderStyle,
            suffix: [
              WgtSaveTable(
                // list: _tariffHistory!,
                getList: _getCsvList,
                fileName: makeReportName(
                    widget.reportNamePrefix ?? 'report', null, null, null),
              ),
            ],
          ),
        );
      }
    }

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -4),
      title: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).hintColor,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ...listHeader,
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(
      List<Map<String, dynamic>> rows, Map<String, dynamic> row) {
    List<Widget> listItem = [];
    for (Map<String, dynamic> configItem in _listConfig) {
      if (!(configItem['show'] ?? true)) {
        continue;
      }
      double width = configItem['width'];
      Color? color = row['${configItem['fieldKey']}_color'];
      String displayText = row[configItem['fieldKey']] ?? '';
      if (configItem['decimals'] != null) {
        double? val = double.tryParse(displayText);
        if (val != null) {
          displayText = val.toStringAsFixed(configItem['decimals']);
        }
      }
      listItem.add(
        configItem['useWidget'] == null
            ? SizedBox(
                width: width,
                // height: 10,
                child: SelectableText(row[configItem['fieldKey']] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: color ?? Theme.of(context).hintColor,
                    ),
                    maxLines: 1),
              )
            : configItem['useWidget'] == 'box'
                ? Container(
                    width: width,
                    decoration: BoxDecoration(
                      color: Theme.of(context).hintColor.withAlpha(80),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    padding: const EdgeInsets.only(left: 3),
                    child: Padding(
                      padding: configItem['padding'] ?? EdgeInsets.zero,
                      child: Text(
                        displayText, //row[configItem['fieldKey']],
                        style: TextStyle(fontSize: 13, color: color),
                      ),
                    ),
                  )
                : configItem['useWidget'] == 'WgtUsageBar'
                    ? row[configItem['fieldKey']] == null
                        ? Container()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 0),
                            child: WgtUsageBar(
                              balance:
                                  double.parse(row[configItem['fieldKey']]),
                              total: double.parse(row['data_bal_ini']),
                              totalWidth: 70,
                              totalHeight: 25,
                              usageTextStyle: const TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.white, //Theme.of(context).hintColor,
                              ),
                            ),
                          )
                    : configItem['useWidget'] == 'deviceStatus'
                        ? getDeviceStatus(row[configItem['fieldKey']])
                        : configItem['useWidget'] == 'custom'
                            ? configItem['customWidget'](rows, row,
                                configItem['fieldKey'], configItem['width'])
                            : Container(),
      );
    }

    return ListTile(
      // minVerticalPadding: -8,
      dense: true,
      contentPadding: widget.contentPadding,
      visualDensity: const VisualDensity(vertical: -4),
      title: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          border: widget.showSelected && (row['selected'] ?? false)
              ? Border.all(
                  color: pag3,
                  width: 1,
                )
              : Border(
                  bottom: BorderSide(
                    color: Theme.of(context).hintColor.withOpacity(0.34),
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          // mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: listItem,
        ),
      ),
    );
  }

  Widget getDeviceStatus(String? status) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 2),
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          color: status == null
              ? Theme.of(context).hintColor
              : status.toLowerCase() == 'active' ||
                      status.toLowerCase() == 'online' ||
                      status.toLowerCase() == 'normal'
                  ? Colors.green.shade300
                  : status.toLowerCase() == 'inactive' ||
                          status.toLowerCase() == 'offline' ||
                          status.toLowerCase() == 'error'
                      ? Colors.redAccent.shade100
                      : Theme.of(context).hintColor.withOpacity(0.34),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
