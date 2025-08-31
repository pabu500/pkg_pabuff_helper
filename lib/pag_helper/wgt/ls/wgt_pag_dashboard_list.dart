import 'dart:math' as math;

import 'package:buff_helper/pag_helper/def_helper/tag_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/file/wgt_save_table.dart';
import 'package:buff_helper/xt_ui/wdgt/list/evs2_list_text.dart';
import 'package:buff_helper/xt_ui/wdgt/list/wgt_usage_bar.dart';
import 'package:flutter/material.dart';

class WgtPagDashboardList extends StatefulWidget {
  const WgtPagDashboardList({
    super.key,
    required this.itemList,
    this.title = '',
    this.reportNamePrefix,
    this.maxWidth = 200,
    this.maxHeight = 250,
    required this.listConfig,
    this.showSelected = false,
    this.padding = EdgeInsets.zero,
    this.contentPadding,
  });

  final double maxWidth;
  final double maxHeight;
  final String? title;
  final String? reportNamePrefix;
  final List<Map<String, dynamic>> itemList;
  final List<Map<String, dynamic>> listConfig;
  final bool showSelected;
  final EdgeInsets? padding;
  final EdgeInsets? contentPadding;

  @override
  State<WgtPagDashboardList> createState() => _WgtPagDashboardListState();
}

class _WgtPagDashboardListState extends State<WgtPagDashboardList> {
  final double titleHeight = 20;
  final double rowHeight = 25;
  final labelStyle = const TextStyle(fontSize: 13);

  late double _listWidth;
  // late final listHeight;

  late List<Map<String, dynamic>> _rows;

  late final List<Map<String, dynamic>> _listConfig;

  List<List<dynamic>> _getCsvList() {
    List<List<dynamic>> table = [];
    table.add(_listConfig.map((e) => e['title']).toList());
    for (var i = 0; i < _rows.length; i++) {
      Map<String, dynamic> rowToSave = {};
      for (var j = 0; j < _listConfig.length; j++) {
        rowToSave[_listConfig[j]['col_key']] =
            _rows[i][_listConfig[j]['col_key']];
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
    // listHeight = _rows.length * rowHeight;

    // find list width
    _listWidth = 0;
    for (Map<String, dynamic> item in _listConfig) {
      _listWidth += item['width'] + 10;
    }
  }

  @override
  Widget build(BuildContext context) {
    // find a maxHeight that is rounded to the whole number of rows
    // show the row will not be cut off
    double showRows = (widget.maxHeight - titleHeight) / (rowHeight + 1);
    double maxListDisplayHeight = showRows.floor() * (rowHeight + 1);

    return SizedBox(
      height: widget.maxHeight,
      child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        SizedBox(
          height: titleHeight,
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
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.min(widget.maxWidth, _listWidth + 30),
            maxHeight: maxListDisplayHeight,
          ),
          // SizedBox(
          //   // width: math.min(widget.maxWidth, _listWidth + 20),
          //   width: _listWidth + 30,
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
    double tileWidth = 0;
    for (Map<String, dynamic> configItem in _listConfig) {
      if (!(configItem['show'] ?? true)) {
        continue;
      }
      double width = configItem['width'];
      tileWidth += width;
      Color? color = row['${configItem['col_key']}_color'];
      String displayText = row[configItem['col_key']] ?? '';
      if (configItem['decimals'] != null) {
        double? val = double.tryParse(displayText);
        if (val != null) {
          displayText = val.toStringAsFixed(configItem['decimals']);
        }
      }
      String displayString =
          convertToDisplayString(displayText, width, labelStyle);
      listItem.add(
        configItem['use_widget'] == null
            ? SizedBox(
                width: width,
                // height: 10,
                child: Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: SelectableText(
                      /*row[configItem['col_key']]*/ displayString,
                      style: labelStyle.copyWith(color: color),
                      maxLines: 1),
                ),
              )
            : configItem['use_widget'] == 'box'
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
                        displayString, //displayText, //row[configItem['col_key']],
                        style: labelStyle.copyWith(color: color),
                      ),
                    ),
                  )
                : configItem['use_widget'] == 'WgtUsageBar'
                    ? row[configItem['col_key']] == null
                        ? Container()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 0),
                            child: WgtUsageBar(
                              balance: double.parse(row[configItem['col_key']]),
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
                    : configItem['use_widget'] == 'deviceStatus'
                        ? getDeviceStatus(row[configItem['col_key']])
                        : configItem['use_widget'] == 'custom'
                            ? configItem['customWidget'](rows, row,
                                configItem['col_key'], configItem['width'])
                            : configItem['use_widget'] == 'tagList'
                                ? getTagList(
                                    context: context,
                                    row: row,
                                    configItem: configItem,
                                    width: width,
                                    tagColor: color,
                                    tagText: displayText,
                                    tagTooltip: configItem['tooltip'] ??
                                        row[configItem['col_key']],
                                  )
                                : Container(),
      );
    }

    return ListTile(
      // minVerticalPadding: -8,
      dense: true,
      contentPadding: widget.contentPadding,
      visualDensity: const VisualDensity(vertical: -4),
      title: Container(
        // width: _listWidth + 40,
        // width: tileWidth,
        padding: widget.padding,
        decoration: BoxDecoration(
          border: widget.showSelected && (row['selected'] ?? false)
              ? Border.all(width: 1, color: pag3)
              : Border(
                  bottom: BorderSide(
                      width: 0.5,
                      color: Theme.of(context).hintColor.withAlpha(80)),
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
                      : Theme.of(context).hintColor.withAlpha(80),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
