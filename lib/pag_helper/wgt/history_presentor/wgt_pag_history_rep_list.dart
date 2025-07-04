import 'package:buff_helper/pagrid_helper/job_helper/get_job_scheduled_box.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/file/wgt_save_table.dart';
import 'package:buff_helper/xt_ui/wdgt/list/evs2_list_text.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../model/mdl_pag_app_config.dart';
import '../job/wgt_post_job.dart';

class WgtPagHistoryRepList extends StatefulWidget {
  const WgtPagHistoryRepList({
    super.key,
    required this.loggedInUser,
    required this.appConfig,
    required this.itemId,
    required this.readingTypes,
    required this.readingTypeConfig,
    required this.iniHistoryData,
    this.listKey,
    this.width = 720,
    this.height = 650,
    this.borderColor,
    this.startDate,
    this.endDate,
    this.lookBackMinutes = 1440,
    this.showIndex = true,
    this.fullCols = false,
    this.jobRequest = const {},
    this.valTitle,
    this.valDiffTitle,
  });

  final MdlPagUser loggedInUser;
  final MdlPagAppConfig appConfig;
  final String itemId;
  final List<Map<String, dynamic>> iniHistoryData;
  final Map<String, dynamic> readingTypeConfig;
  final List<String> readingTypes;
  final UniqueKey? listKey;
  final double width;
  final double height;
  final Color? borderColor;
  final DateTime? startDate;
  final DateTime? endDate;
  final int lookBackMinutes;
  final bool showIndex;
  final bool fullCols;
  final Map<String, String> jobRequest;
  final String? valTitle;
  final String? valDiffTitle;

  @override
  State<WgtPagHistoryRepList> createState() => _WgtPagHistoryRepListState();
}

class _WgtPagHistoryRepListState extends State<WgtPagHistoryRepList> {
  final double _indexWidth = 35;
  bool _isHistoryLoading = false;

  final List<Map<String, dynamic>> listConfig = [];
  final List<Map<String, dynamic>> _list = [];
  int _decimals = 2;
  String _unit = '';
  bool _jobPosted = false;

  late List<Map<String, dynamic>> _historyDataFields;

  void _getListSetting() {
    listConfig.clear();
    String timeKey = 'time';
    // get time key from first reading of first selected history data set
    // Map<String, dynamic> firstReading = widget.iniSelectedHistoryDataSets.first.values.first.first;
    // for (String key in firstReading.keys) {
    //   if (DateTime.tryParse(firstReading[key]) != null) {
    //     timeKey = key;
    //     break;
    //   }
    // }
    listConfig.add({
      'fieldKey': timeKey,
      'title': 'Time',
      'width': 150,
    });
    if (widget.fullCols) {
      listConfig.add({
        'fieldKey': 'dt_missing',
        'title': 'dt_missing',
        'width': 50,
        'show': false,
      });
    }

    for (String readingType in widget.readingTypes) {
      Map<String, dynamic> selectedReadingTypeConfig =
          widget.readingTypeConfig[readingType];
      _historyDataFields = [];
      _historyDataFields = selectedReadingTypeConfig['dataFields'];

      for (var fieldKey in _historyDataFields) {
        String keyName = fieldKey['field'];
        // if (keyName == 'a_imp') {
        //   keyName = 'a_imp_diff';
        // }
        listConfig.add({
          'fieldKey': keyName,
          'title': widget.valTitle ?? fieldKey['field'],
          'width': fieldKey['width'] ?? 150,
        });
        listConfig.add({
          'fieldKey': '${fieldKey['field']}_diff',
          'title': widget.valDiffTitle ?? '${fieldKey['field']}_diff',
          'width': fieldKey['width'] ?? 150,
        });
        if (keyName == 'a_imp') {
          listConfig.add({
            'fieldKey': 'a_imp_diff',
            'title': 'a_imp_diff',
            'width': fieldKey['width'] ?? 150,
          });
        } else if (keyName == 'kwh_total') {
          listConfig.add({
            'fieldKey': 'kwh_total_diff',
            'title': 'kwh_diff',
            'width': fieldKey['width'] ?? 150,
          });
        }
        if (widget.fullCols) {
          listConfig.add({
            'fieldKey': '${fieldKey['field']}_is_neg',
            'title': '${fieldKey['field']}_is_neg',
            'width': 50,
            'show': false,
          });
        }
      }
      _unit = selectedReadingTypeConfig['unit'] as String;
      _decimals = selectedReadingTypeConfig['decimals'] as int? ?? 0;
    }
  }

  void _getHistory() {
    // print('get history');
    _list.clear();
    for (Map<String, dynamic> data in widget.iniHistoryData) {
      String time = data['dt'];
      dynamic readings = data['readings'];
      if (readings.isEmpty) continue;

      Map<String, dynamic> newRow = {};
      newRow['time'] = time;
      if (widget.fullCols) {
        bool isEstRow = data['is_est'] == 0 ? false : true;
        newRow['is_estimated'] = isEstRow;
      }
      if (widget.fullCols) {
        int dtMissing = data['dt_missing'] ?? 0;
        newRow['dt_missing'] = dtMissing == 0 ? false : true;
      }
      bool hasInsertZero = false;
      for (String key in readings.keys) {
        //get total
        newRow[key] = readings[key]['rt'];
        if (widget.fullCols) {
          int isTotalEst = readings[key]['rt_is_est'] ?? 0;
          bool readingPartTotalIsEst = (isTotalEst == 0) ? false : true;
          newRow['${key}_is_est'] = readingPartTotalIsEst;
        }
        if (widget.fullCols) {
          int isTotalNeg = readings[key]['rt_neg'] ?? 0;
          bool readingPartTotalIsNeg = (isTotalNeg == 0) ? false : true;
          newRow['${key}_is_neg'] = readingPartTotalIsNeg;
        }
        //get diff
        newRow['${key}_diff'] = readings[key]['rd'];
        if (widget.fullCols) {
          int isDiffEst = readings[key]['rd_is_est'] ?? 0;
          bool readingPartDiffIsEst = (isDiffEst == 0) ? false : true;
          int isDiffInsertZero = readings[key]['rd_is_insert_zero'] ?? 0;
          hasInsertZero = isDiffInsertZero == 1 ? true : false;
          newRow['${key}_diff_is_est'] = readingPartDiffIsEst;

          int isNeg = readings[key]['rd_neg'] ?? 0;
          bool readingPartDiffIsNeg = (isNeg == 0) ? false : true;
          newRow['${key}_diff_is_neg'] = readingPartDiffIsNeg;
        }
      }
      if (!hasInsertZero) {
        _list.add(newRow);
      }
    }
    // setState(() {});
  }

  List<List<dynamic>> _getCsvList() {
    List<List<dynamic>> table = [];
    table.add(listConfig.map((e) => e['title']).toList());
    for (var i = 0; i < _list.length; i++) {
      Map<String, dynamic> rowToSave = {};
      for (var j = 0; j < listConfig.length; j++) {
        rowToSave[listConfig[j]['fieldKey']] =
            _list[i][listConfig[j]['fieldKey']] ?? '';
      }
      table.add(rowToSave.values.toList());
    }
    return table;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _getListSetting();
    _getHistory();

    bool showList = _list.isNotEmpty &&
        _list.length < 340 &&
        listConfig.length <= 8 &&
        widget.jobRequest.isEmpty;

    if (kDebugMode) {
      print('list length: ${_list.length}');
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: showList
          ? ListView.builder(
              key: widget.listKey,
              shrinkWrap: true,
              itemExtent: 25,
              itemCount: _list.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return _buildListHeader();
                } else {
                  Map<String, dynamic> row = _list[index - 1];
                  return _buildListItem(index, row);
                }
              },
            )
          : Row(
              children: [
                Expanded(child: Container()),
                Container(
                  width: 340,
                  height: 130,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).hintColor,
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  padding: const EdgeInsets.all(13),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Text(
                        //   'Too Many Records to Display',
                        //   style: TextStyle(
                        //     fontSize: 16,
                        //     color: Theme.of(context).hintColor,
                        //   ),
                        // ),

                        Text(
                          widget.jobRequest.isEmpty
                              ? 'Download Report'
                              : 'Get Report by Email',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        verticalSpaceTiny,
                        widget.jobRequest.isEmpty
                            ? WgtSaveTable(
                                iconSize: 55,
                                getList:
                                    _getCsvList, //widget.getCsvList, // _getCsvList,
                                fileName: makeReportName(
                                  'reading',
                                  widget.itemId,
                                  widget.startDate ?? DateTime.now(),
                                  widget.endDate ?? DateTime.now(),
                                ),
                              )
                            : _jobPosted
                                ? getJobScheduledBox(
                                    context,
                                    'job',
                                    getTargetLocalDatetimeNow(widget
                                        .loggedInUser.selectedScope
                                        .getProjectTimezone()))
                                : WgtPagPostJob(
                                    loggedInUser: widget.loggedInUser,
                                    pagAppConfig: widget.appConfig,
                                    title: 'Post Job',
                                    jobRequest: widget.jobRequest,
                                    iconSize: 55,
                                    iconColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha(180),
                                    onPosted: (result) {
                                      setState(() {
                                        _jobPosted = true;
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Job posted'),
                                        ),
                                      );
                                    },
                                  ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
    );
  }

  Widget _buildListHeader() {
    TextStyle listHeaderStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Theme.of(context).hintColor,
    );

    List<Widget> listHeader = [];

    listHeader.add(
      Transform.translate(
        offset: const Offset(-5, 0),
        child: WgtSaveTable(
          enabled: _list.isNotEmpty,
          getList: _getCsvList,
          fileName: makeReportName(
            'reading',
            widget.itemId,
            widget.startDate ?? DateTime.now(),
            widget.endDate ?? DateTime.now(),
          ),
        ),
      ),
    );

    for (Map<String, dynamic> configItem in listConfig) {
      bool show = configItem['show'] ?? true;
      if (!show) continue;

      List<Widget> suffix = [];

      listHeader.add(
        Evs2ListText(
          originalFullText: configItem['title'],
          width: configItem['width'].toDouble(),
          style: listHeaderStyle,
          suffix: suffix,
        ),
      );
    }
    return ListTile(
      dense: true,
      // visualDensity: VisualDensity(vertical: -4),
      title: Transform.translate(
        offset: const Offset(0, -6),
        child: Container(
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
      ),
    );
  }

  Widget _buildListItem(int index, Map<String, dynamic> row) {
    List<Evs2ListText> listRow = [];
    String indexLabel = index.toString();
    widget.showIndex
        ? listRow.add(
            Evs2ListText(
              // originalFullText: index.toString(),
              originalFullText: indexLabel,
              width: _indexWidth,
              style: TextStyle(
                fontSize: 13.5,
                color: Theme.of(context).hintColor,
              ),
            ),
          )
        : Container();

    for (Map<String, dynamic> configItem in listConfig) {
      TextStyle listItemStyle = TextStyle(
        fontSize: 13.5,
        color: Theme.of(context).hintColor,
      );
      bool show = configItem['show'] ?? true;
      if (!show) continue;

      double width = configItem['width'].toDouble();
      String originalFullText = '';
      if (row[configItem['fieldKey']] != null) {
        String str = row[configItem['fieldKey']].toString();
        double? value = double.tryParse(str);
        originalFullText =
            value == null ? str : value.toStringAsFixed(_decimals);
        bool dtIsMissing = row['dt_missing'] ?? false;
        if (dtIsMissing && value is! double) {
          listItemStyle = listItemStyle.copyWith(
            color: Colors.yellow.shade900,
          );
        }

        bool isEst = row['${configItem['fieldKey']}_is_est'] ?? false;
        if (isEst) {
          listItemStyle = listItemStyle.copyWith(
            color: Colors.yellow.shade900,
          );
        }
        bool isNeg = row['${configItem['fieldKey']}_is_neg'] ?? false;
        if (isNeg) {
          listItemStyle = listItemStyle.copyWith(color: Colors.yellow.shade900);
        }
      }

      listRow.add(
        Evs2ListText(
          originalFullText: originalFullText,
          width: width,
          style: listItemStyle,
          fieldKey: configItem['fieldKey'],
        ),
      );
    }
    return // getListTile(listRow);
        ListTile(
      tileColor: null,
      title: Transform.translate(
        offset: const Offset(0, -8),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).hintColor.withAlpha(180),
                width: 0.3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            // crossAxisAlignment: CrossAxisAlignment.center,
            children: listRow,
          ),
        ),
      ),
    );
  }
}
