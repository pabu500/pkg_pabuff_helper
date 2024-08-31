import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/wgt_bill_lc_status_update.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/list/wgt_list_column_customize.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import '../../../pagrid_helper/app_helper/pagrid_app_config.dart';
import '../wgt_popup_button.dart';
import 'evs2_list_text.dart';
import 'get_pagenation_bar.dart';
import '../file/wgt_save_table.dart';
import 'wgt_list_pane_switch_icon.dart';
import 'wgt_list_toggle_switch.dart';

import 'wgt_list_sort_icon.dart';

// ignore: must_be_immutable
class WgtEditCommitList extends StatefulWidget {
  WgtEditCommitList({
    super.key,
    this.width,
    this.height,
    this.sectionName = '',
    required this.appConfig,
    required this.loggedInUser,
    required this.scopeProfile,
    required this.listConfig,
    required this.listItems,
    this.selectShowColumn = false,
    this.showCommit = true,
    this.doCommit,
    required this.listPrefix,
    this.compareValue,
    this.altCompareValue,
    this.disabled,
    this.showHeader = true,
    this.showIndex = true,
    this.maxRowsPerPage,
    this.totalCount,
    this.currentPage,
    this.onPreviousPage,
    this.onNextPage,
    this.onClickPage,
    this.onSort,
    this.queryMap = const {},
    this.narrowPaginationBar = false,
    this.currentItemId = '',
    this.displayMode = 'list',
    this.onToggleListPaneMode,
    this.multiSelection = false,
    this.itemExt = 36,
    this.aclScopeStr,
    this.onRequestRefresh,
  });

  final PaGridAppConfig appConfig;
  final Evs2User loggedInUser;
  final ScopeProfile scopeProfile;
  final String listPrefix;
  final double? width;
  final double? height;
  final String sectionName;
  //list of field titles and field width
  final List<Map<String, dynamic>> listConfig;
  //list of items to be displayed
  final List<Map<String, dynamic>> listItems;
  final bool selectShowColumn;
  final Function? doCommit;
  final bool showCommit;
  final double? compareValue;
  final double? altCompareValue;
  bool? disabled;
  final bool showHeader;
  final bool showIndex;
  final int? maxRowsPerPage;
  final int? totalCount;
  final int? currentPage;
  final Function? onPreviousPage;
  final Function? onNextPage;
  final Function? onClickPage;
  final Function? onSort;
  final Map<String, dynamic> queryMap;
  final bool narrowPaginationBar;
  final String currentItemId;
  final String displayMode;
  final Function(String, String)? onToggleListPaneMode;
  final bool multiSelection;
  final double itemExt;
  // final String? requestByUsername;
  final String? aclScopeStr;
  final Function? onRequestRefresh;

  //for list of functions to be called when to set the modified flag for list fields
  List<Function(bool)>? fieldUpdateModified = [];

  void regFieldUpdateModified(Function(bool) updateFieldModified) {
    if (fieldUpdateModified != null) {
      fieldUpdateModified!.add(updateFieldModified);
    }
  }

  @override
  State<WgtEditCommitList> createState() => _WgtEditCommitListState();
}

class _WgtEditCommitListState extends State<WgtEditCommitList> {
  final double _indexWidth = 34;

  bool _modified = false;
  // late double _lastColWidth;
  late List<Map<String, dynamic>> _listConfig;
  late List<Map<String, dynamic>> _rows;
  late List<Map<String, dynamic>> _postCommitRows = [];
  final List<Map<String, dynamic>> _modifiedRows = [];
  late double _width;
  late double _listHeight;
  UniqueKey? _listKey;
  late TextStyle _listItemStyle;

  UniqueKey? _headerRefreshKey;

  int _widgetIndex = -1;
  final _modifiedColor = Colors.amber.shade900;

  late String _currentMode;

  List<List<dynamic>> _getCsvList() {
    List<List<dynamic>> table = [];
    table.add(widget.listConfig.map((e) => e['title']).toList());
    for (var i = 0; i < _postCommitRows.length; i++) {
      Map<String, dynamic> rowToSave = {};
      for (var j = 0; j < widget.listConfig.length; j++) {
        rowToSave[widget.listConfig[j]['fieldKey']] =
            _postCommitRows[i][widget.listConfig[j]['fieldKey']] ?? '';
      }
      table.add(rowToSave.values.toList());
    }
    return table;
  }

  void flagModified(bool modified) {
    setState(() {
      _modified = modified;
    });
  }

  void clearModifiedFlag() {
    setState(() {
      _modified = false;
      _modifiedRows.clear();
    });
  }

  List<Map<String, dynamic>> getModifiedList() {
    //clean up the list so only the modified rows are sent to the server
    _modifiedRows.removeWhere((element) => element.length == 1);

    //update the _postCommitRows with the modified rows
    for (Map<String, dynamic> modifiedRow in _modifiedRows) {
      for (Map<String, dynamic> postCommitRow in _postCommitRows) {
        if (postCommitRow['id'] == modifiedRow['id']) {
          //replace with the modified row
          postCommitRow.addAll(modifiedRow);
        }
      }
    }
    return _modifiedRows;
  }

  void _sortList(String key, bool ascending) {
    bool inlineSort = true;
    if (widget.maxRowsPerPage != null &&
        widget.totalCount != null &&
        widget.currentPage != null &&
        widget.totalCount! > widget.maxRowsPerPage!) {
      inlineSort = false;
    }
    if (inlineSort) {
      //if list items are all empty, then do not sort
      bool allEmpty = true;
      for (Map<String, dynamic> row in _rows) {
        if (row[key] != null && row[key] != '') {
          allEmpty = false;
          break;
        }
      }
      if (allEmpty) {
        if (kDebugMode) {
          print('all empty, no sort');
        }
        return;
      }

      setState(() {
        _rows.sort((a, b) {
          if (ascending) {
            return (a[key] ?? '').compareTo(b[key] ?? '');
          } else {
            return (b[key] ?? '').compareTo(a[key] ?? '');
          }
        });
        _listKey = UniqueKey();
      });
    } else {
      if (widget.onSort != null) {
        widget.onSort!(key, ascending ? 'asc' : 'desc');
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _currentMode = widget.displayMode;
    _rows = widget.listItems;
    //copy the list to _postCommitRows
    _postCommitRows = List.from(_rows);

    _listConfig = List.from(widget.listConfig);
  }

  double getListWidth() {
    if (widget.width != null) {
      return widget.width!;
    }
    double width = 120;
    for (Map<String, dynamic> item in _listConfig) {
      if (item['show'] ?? true) {
        width += item['width'];
      }
    }
    return width;
  }

  @override
  Widget build(BuildContext context) {
    // if (widget.showCommit || _modified) {
    //   widget.listConfig.last['width'] = _lastColWidth + 30;
    // }
    double itemExt = widget.itemExt;
    _listItemStyle = TextStyle(
      fontSize: 13.5,
      color: Theme.of(context).hintColor,
    );
    _width = widget.width ?? getListWidth();
    _listHeight = widget.height ?? widget.listItems.length * itemExt + itemExt;

    if (kDebugMode) {
      print('list width: $_width list height: $_listHeight');
    }

    bool showPagination = widget.totalCount != null &&
        widget.currentPage != null &&
        widget.totalCount! > 0;

    if (showPagination) {
      _listHeight += 60;
    }
    double height = _listHeight > (widget.height ?? 830)
        ? (widget.height ?? 900)
        : _listHeight < 120
            ? 120
            : _listHeight;
    return Container(
      height: height,
      width: _width,
      decoration: panelBoxDecor(
        Theme.of(context).hintColor,
      ),
      child: ListView.builder(
          key: _listKey,
          shrinkWrap: false,
          // padding: EdgeInsets.all(0),
          itemExtent: itemExt,
          //1 for header, 1 for footer, 1 for footer padding
          itemCount: _rows.length + 3,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildListHeader();
            } else if (index == _rows.length + 1) {
              //footer
              return ListTile(
                  title: showPagination
                      ? Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: getPagenationBar(
                            context,
                            _rows.length,
                            widget.maxRowsPerPage, //_rows.length,
                            widget.totalCount,
                            widget.currentPage,
                            widget.onPreviousPage,
                            widget.onNextPage,
                            widget.onClickPage,
                            narrow: widget.narrowPaginationBar,
                            rows: _rows,
                            getCsv: _getCsvList,
                            listPrefix: widget.listPrefix,
                          ),
                        )
                      : Container());
            } else if (index == _rows.length + 2) {
              //footer padding
              return Container(height: 10);
            } else {
              // return Container();
              Map<String, dynamic> row = _rows[index - 1];
              Map<String, dynamic> modifiedRow = {'id': row['id']};
              //check if row with id exists in _modifiedRows
              //if it does, then use that row
              //otherwise, add a new row with just the id
              bool rowExists = false;
              if (_modifiedRows.isNotEmpty) {
                for (Map<String, dynamic> modRow in _modifiedRows) {
                  if (modRow['id'] == row['id']) {
                    rowExists = true;
                    modifiedRow = modRow;
                  }
                }
              }
              if (!rowExists) {
                _modifiedRows.add(modifiedRow);
              }

              return Transform.translate(
                  offset: Offset(0, itemExt - 30),
                  child:
                      _buildListItem(index, row, modifiedRow, _postCommitRows));

              return _buildListItem(index, row, modifiedRow, _postCommitRows);
            }
          }),
    );
  }

  Widget _buildListHeader() {
    if (kDebugMode) {
      print('build list header');
    }
    TextStyle listHeaderStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
      color: Theme.of(context).hintColor,
    );

    //build list header from widget.listConfig
    List<Widget> listHeader = [];
    // if (widget.showIndex != null && widget.showIndex!) {
    // if (widget.showCommit || _modified) {
    listHeader.add(
      SizedBox(
        width: _indexWidth,
        child:
            // widget.showCommit && _modified
            //     ? CommitModifiedTable(
            //         getList: getModifiedList,
            //         doCommit: (list, byUser) async =>
            //             await widget.doCommit(list, byUser),
            //         updateItemModified: widget.fieldUpdateModified,
            //         clearListModifiedFlag: clearModifiedFlag,
            //       )
            // :
            widget.selectShowColumn ? getCustomize() : Container(),
      ),
    );

    for (Map<String, dynamic> configItem in _listConfig) {
      // if (item != widget.listConfig.last) {
      // the space for checkbox column title is taken by save table icon
      if (widget.multiSelection && configItem['useWidget'] == 'checkbox') {
        continue;
      }
      if (!(configItem['show'] ?? true)) {
        continue;
      }
      List<Widget> suffix = [];
      if (configItem['showSort'] ?? false) {
        suffix.add(
          WgtListSortIcon(
            sortOrder: configItem['sortOrder'] ?? '',
            onSort: (sortOrder) {
              for (var rowConfig in _listConfig) {
                rowConfig['sortOrder'] = '';
              }
              configItem['sortOrder'] = sortOrder;
              if (sortOrder.isEmpty) {
                return;
              }
              _sortList(
                  configItem['fieldKey'], sortOrder == 'asc' ? true : false);
            },
          ),
        );
      }
      if (configItem['detailKey'] ?? false) {
        if (_currentMode == 'pane') {
          suffix.add(Expanded(child: Container()));
        }
        suffix.add(WgtListPaneIcon(
            mode: _currentMode,
            onToggleMode: (mode) {
              if (widget.onToggleListPaneMode != null) {
                widget.onToggleListPaneMode!(mode, configItem['fieldKey']);
              }
            }));
      }
      listHeader.add(Evs2ListText(
        originalFullText: configItem['title'],
        width: configItem['width'].toDouble(),
        style: listHeaderStyle,
        suffix: suffix,
      ));
    }

    if (kDebugMode) {
      print('header count ${listHeader.length}');
    }
    return ListTile(
      key: _headerRefreshKey,
      dense: true,
      // visualDensity: VisualDensity(vertical: -4),
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

  Widget _buildListItem(int index, Map<String, dynamic> row,
      Map<String, dynamic> modifiedRow, List<Map<String, dynamic>>? fullList) {
    List<Widget> listItem = [];
    String indexLabel = index.toString();
    if (widget.maxRowsPerPage != null &&
        widget.totalCount != null &&
        widget.currentPage != null &&
        widget.currentPage! > 1) {
      indexLabel = ((widget.currentPage! - 1) * widget.maxRowsPerPage! + index)
          .toString();
    }
    widget.showIndex
        ? listItem.add(
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
    for (Map<String, dynamic> configItem in _listConfig) {
      if (!(configItem['show'] ?? true)) {
        continue;
      }
      _listItemStyle = TextStyle(
        fontSize: 13.5,
        color: Theme.of(context).hintColor,
      );

      bool unique = configItem['unique'] ?? false;
      List<String> listValues = [];
      if (unique) {
        for (Map<String, dynamic> row in fullList!) {
          listValues.add(row[configItem['fieldKey']]);
        }
      }

      bool showAltIcon = false;
      if (configItem['altIconIf'] != null) {
        showAltIcon = configItem['altIconIf'](row, widget.altCompareValue);
      }
      bool showIcon = true;
      if (configItem['showIconIf'] != null) {
        showIcon = configItem['showIconIf'](row, widget.compareValue);
      }
      String? iconTooltip;
      if (configItem['getIconTooltip'] != null) {
        iconTooltip = configItem['getIconTooltip'](row, widget.compareValue);
      }

      //check if item is disabled
      bool disabled = false;
      if (configItem['disableIf'] != null) {
        disabled = configItem['disableIf'](row, widget.compareValue);
      }
      int dataIndex = index;
      if (widget.showHeader) {
        dataIndex = index - 1;
      }
      //check width
      double width = configItem['width'].toDouble();
      //check item editable
      // NOTE: col editable not set here
      bool itemEditable = false;
      if (row[configItem['fieldKey']] != null) {
        if (row['${configItem['fieldKey']}_editable'] != null) {
          itemEditable = row['${configItem['fieldKey']}_editable'];
        }
      }

      //check col editable
      bool colEditable = false;
      if (configItem['editable'] != null) {
        colEditable = configItem['editable'];
      } else if (configItem['editableIf'] != null) {
        colEditable = configItem['editableIf'](row[configItem['fieldKey']]);
      }

      if (row[configItem['fieldKey']] != null) {
        //col colors
        if (configItem['color'] != null) {
          _listItemStyle = _listItemStyle.copyWith(
            color: configItem['color'],
            fontWeight: FontWeight.w500,
          );
        }

        if (configItem['style'] != null) {
          _listItemStyle = configItem['style'];
        }

        if (configItem['getStyle'] != null) {
          _listItemStyle =
              configItem['getStyle'](row[configItem['fieldKey']]) ??
                  _listItemStyle;
        }

        // item colors
        // is determined in the following order:
        // 1. error color
        // 2. item color
        // 3. modified color
        // 4. success color
        // 5. col editable color
        if (configItem['error_color'] != null &&
            (row[configItem['fieldKey']] as String).contains(
                'error') /*&& row['error'].keys.first == item['fieldKey']*/) {
          _listItemStyle = _listItemStyle.copyWith(
              color: configItem['error_color'], fontWeight: FontWeight.w500);
        } else if (row['${configItem['fieldKey']}_color'] != null) {
          _listItemStyle = _listItemStyle.copyWith(
              color: row['${configItem['fieldKey']}_color'],
              fontWeight: FontWeight.w500);
        } else if (row['${configItem['fieldKey']}_modified'] != null) {
          _listItemStyle = _listItemStyle.copyWith(
              color: _modifiedColor, fontWeight: FontWeight.w500);
        } else if (configItem['success_color'] != null &&
            (row[configItem['fieldKey']] as String).contains('success')) {
          _listItemStyle = _listItemStyle.copyWith(
              color: configItem['success_color'], fontWeight: FontWeight.w500);
        } else if (colEditable) {
          _listItemStyle = _listItemStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500);
        }
      }

      String originalFullText = '';
      if (row[configItem['fieldKey']] != null) {
        originalFullText = row[configItem['fieldKey']].toString();
        if (configItem['prefix'] != null) {
          originalFullText = configItem['prefix'] + originalFullText;
        }
        // if (configItem['decimal'] != null) {
        //   if (isNumeric(row[configItem['fieldKey']])) {
        //     double? d = double.tryParse(row[configItem['fieldKey']]);
        //     if(d != null) {
        //       originalFullText = d.toStringAsFixed(configItem['decimal']);
        //   }
        // }
      }
      if (configItem['getDisplayString'] != null) {
        originalFullText =
            configItem['getDisplayString'](row[configItem['fieldKey']]) ?? '';
      }

      bool showTag = false;
      String tagText = '';
      String? tagTooltip;
      Color? tagColor;

      if (configItem['getTag'] != null) {
        Map<String, dynamic> tagInfo =
            configItem['getTag'](row, configItem['fieldKey']);
        if (tagInfo.isNotEmpty) {
          showTag = true;
          tagText = tagInfo['tag'];
          tagColor = tagInfo['color'];
          tagTooltip = tagInfo['tooltip'];
        }
      }

      listItem.add(
        configItem['useWidget'] == null && !showTag
            ? Tooltip(
                message: row['${configItem['fieldKey']}_tooltip'] ??
                    (disabled ? configItem['disabledTooltip'] ?? '' : ''),
                waitDuration: const Duration(milliseconds: 500),
                child: Evs2ListText(
                  parentListWgt: widget,
                  originalFullText: originalFullText,
                  width: width,
                  clickEditable: disabled ? false : colEditable || itemEditable,
                  style: _listItemStyle,
                  fieldKey: configItem['fieldKey'],
                  modifiedRow: modifiedRow,
                  flagModified: flagModified,
                  validator: configItem['validator'],
                  colValidator: configItem['uniqueValidator'],
                  unique: unique,
                  listValues: listValues,
                  nonSelectable:
                      (configItem['clickCopy'] ?? false) ? true : false,
                  clickCopy: configItem['clickCopy'] ?? false,
                ),
              )
            : configItem['useWidget'] == 'billingLcSatusUpdate'
                ? getBillingLcStatusControl(
                    row: row,
                    configItem: configItem,
                    tagText: tagText,
                    tagColor: tagColor,
                    tagTooltip: tagTooltip,
                    width: width)
                : configItem['useWidget'] == 'tag' || showTag
                    ? getTag(
                        row: row,
                        configItem: configItem,
                        width: width,
                        tagColor: tagColor,
                        tagText: tagText,
                        tagTooltip: tagTooltip,
                      )
                    : configItem['useWidget'] == 'checkbox'
                        ? Tooltip(
                            message: disabled
                                ? configItem['disabledTooltip'] ?? ''
                                : '',
                            waitDuration: const Duration(milliseconds: 500),
                            child: SizedBox(
                              width: width,
                              child: Checkbox(
                                // checkColor: Theme.of(context).hintColor,
                                // activeColor: Theme.of(context).colorScheme.secondary,
                                value: configItem['getVal']?.call(row) ??
                                    row[configItem['fieldKey']] ??
                                    false,
                                onChanged: disabled
                                    ? null
                                    : (value) {
                                        configItem['onChanged'](value, row);
                                      },
                              ),
                            ),
                          )
                        : configItem['useWidget'] == 'toggleSwitch'
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 5.0),
                                child: Tooltip(
                                  message: disabled
                                      ? 'value: ${row[configItem['fieldKey']] ? 'Yes' : 'No'} | info: ${configItem['disabledTooltip'] ?? ''}'
                                      : 'value: ${row[configItem['fieldKey']] ? 'Yes' : 'No'}',
                                  waitDuration:
                                      const Duration(milliseconds: 500),
                                  child: WgtListToggleSwith(
                                    disabled: disabled,
                                    parentListWgt: widget,
                                    initialLabelIndex:
                                        row[configItem['fieldKey']] == null
                                            ? 0
                                            : row[configItem['fieldKey']]
                                                        as bool ==
                                                    true
                                                ? 1
                                                : 0,
                                    width: width,
                                    // clickEditable: false,
                                    fieldKey: configItem['fieldKey'],
                                    modifiedRow: modifiedRow,
                                    flagModified: flagModified,
                                  ),
                                ))
                            : configItem['useWidget'] == 'iconButton'
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: SizedBox(
                                      width: width,
                                      height: 18,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: showAltIcon
                                            ? Tooltip(
                                                message: configItem[
                                                    'altIconTooltip'],
                                                child: Icon(
                                                  configItem['altIcon'],
                                                  color: Theme.of(context)
                                                      .hintColor,
                                                ),
                                              )
                                            : InkWell(
                                                onTap: configItem['onTap'] ==
                                                        null
                                                    ? configItem['onTap']
                                                    : () => configItem['onTap'](
                                                        context,
                                                        row,
                                                        fullList!,
                                                        widget.queryMap),
                                                onHover: (val) {
                                                  setState(() {
                                                    if (val) {
                                                      _widgetIndex = index;
                                                    } else {
                                                      _widgetIndex = -1;
                                                    }
                                                  });
                                                },
                                                child: showIcon
                                                    ? Tooltip(
                                                        waitDuration:
                                                            const Duration(
                                                                milliseconds:
                                                                    500),
                                                        message: configItem[
                                                                'iconTooltip'] ??
                                                            iconTooltip ??
                                                            '',
                                                        child: Icon(
                                                          configItem[
                                                                  'iconData'] ??
                                                              Icons.edit,
                                                          color: configItem[
                                                                  'iconColor'] ??
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withOpacity(
                                                                      0.5),
                                                          size: configItem[
                                                              'iconSize'],
                                                        ),
                                                      )
                                                    : Container(),
                                              ),
                                      ),
                                    ),
                                  )
                                : configItem['useWidget'] == 'dropdown'
                                    ? DropdownButton(
                                        isExpanded: true,
                                        value: row[configItem['fieldKey']],
                                        items: configItem['dropdownItems']
                                            .map<DropdownMenuItem<dynamic>>(
                                                (item) {
                                          return DropdownMenuItem(
                                            value: item['value'],
                                            child: Text(item['label']),
                                          );
                                        }).toList(),
                                        onChanged: disabled
                                            ? null
                                            : (value) {
                                                configItem['onChanged'](
                                                    value, row);
                                              },
                                      )
                                    : configItem['useWidget'] ==
                                            'wgtPasswordResetPopupButton'
                                        ? SizedBox(
                                            width: width,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child:
                                                  getWgtPasswordResetPopupButton(
                                                configItem,
                                                row['username'],
                                                row['id'],
                                                index,
                                                disabled,
                                              ),
                                            ),
                                          )
                                        : configItem['useWidget'] == 'singleKey'
                                            ? configItem['onTap'] == null
                                                ? Container()
                                                : InkWell(
                                                    onTap: () {
                                                      configItem['onTap'](row);
                                                    },
                                                    child: Tooltip(
                                                      message: configItem[
                                                              'detailTooltip'] ??
                                                          '',
                                                      waitDuration:
                                                          const Duration(
                                                              milliseconds:
                                                                  500),
                                                      child: Evs2ListText(
                                                        nonSelectable: true,
                                                        // parentListWgt: widget,
                                                        originalFullText:
                                                            originalFullText,
                                                        width: width,
                                                        style: row[configItem[
                                                                    'fieldKey']] ==
                                                                widget
                                                                    .currentItemId
                                                            ? TextStyle(
                                                                backgroundColor:
                                                                    Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary,
                                                                fontSize: 15,
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              )
                                                            : _listItemStyle
                                                                .copyWith(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                      ),
                                                    ),
                                                  )
                                            : Container(),
      );
    }

    return ListTile(
      // contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 0),
      // minVerticalPadding: 2,
      // hoverColor: _widgetIndex == index ? Colors.red : null,
      tileColor: _widgetIndex == index
          ? Theme.of(context).hintColor.withOpacity(0.1)
          : null,
      title: Container(
        // width: _width,
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
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: listItem,
        ),
      ),
    );
  }

  Widget getCustomize() {
    // return
    // WgtListColumnCustomize(
    //   listConfig: _listConfig,
    //   onChanged: () {},
    //   onReset: () {},
    // );
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: 'Customize columns',
        waitDuration: const Duration(milliseconds: 500),
        child: WgtPopupButton(
            width: 15,
            height: 15,
            popupWidth: 130,
            popupHeight: 255,
            direction: 'right',
            popupChild: WgtListColumnCustomize(
              sectionName: widget.sectionName,
              listConfig: _listConfig,
              listHeight: 220,
              onChanged: (bool selected) {
                // setState(() {
                // _headerRefreshKey = UniqueKey();
                // _listKey = UniqueKey();
                // });
              },
              onSet: () {
                setState(() {
                  _headerRefreshKey = UniqueKey();
                  _listKey = UniqueKey();
                });
              },
            ),
            // getColumnSelection(),
            child: Icon(
              Icons.settings,
              size: 13,
              color: Theme.of(context).hintColor,
            )),
      ),
    );
  }

  Widget getColumnSelection() {
    List<Widget> columnSelection = [];
    for (Map<String, dynamic> configItem in _listConfig) {
      // if (configItem['show'] == false) {
      //   continue;
      // }
      columnSelection.add(
        Row(
          children: [
            Transform.scale(
              scale: 0.8,
              child: Checkbox(
                value: configItem['show'] ?? true,
                onChanged: (value) {
                  setState(() {
                    configItem['show'] = value;
                  });
                },
              ),
            ),
            Text(
              configItem['title'],
              style:
                  TextStyle(fontSize: 13.5, color: Theme.of(context).hintColor),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: columnSelection,
      ),
    );
  }

  Widget getWgtPasswordResetPopupButton(
      Map<String, dynamic> item,
      String username,
      int userId,
      int index,
      /*, GlobalKey buttonKey*/ bool disabled) {
    return Tooltip(
      message: disabled ? item['disabledTooltip'] ?? '' : '',
      child: WgtPopupButton(
        width: 35,
        height: 35,
        xOffset: 35,
        popupWidth: 335,
        popupHeight: 250,
        direction: 'left',
        popupChild: WgtUpdatePassword(
          appConfig: widget.appConfig,
          loggedInUser: widget.loggedInUser,
          aclScopeStr: item['aclScopeStr'] ?? widget.aclScopeStr!,
          changeTargetUserId: userId,
          requireOldPassword: false,
          passwordLengthMin: 3,
          updatePassword: item['updatePassword'],
        ),
        child: Icon(
          Icons.password,
          color: disabled
              ? Theme.of(context).hintColor.withOpacity(0.34)
              : Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget getTag({
    required Map<String, dynamic> row,
    required Map<String, dynamic> configItem,
    required String tagText,
    Color? tagColor,
    String? tagTooltip,
    required double width,
  }) {
    return Tooltip(
      message: tagTooltip ??
          configItem['getTooltip']?.call(row[configItem['fieldKey']]) ??
          '',
      waitDuration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: width,
        child: Stack(
          children: [
            Container(
              // width: width,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: tagColor ??
                    configItem['getColor']?.call(row[configItem['fieldKey']]),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(tagText,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget getBillingLcStatusControl({
    required Map<String, dynamic> row,
    required Map<String, dynamic> configItem,
    required String tagText,
    Color? tagColor,
    String? tagTooltip,
    required double width,
  }) {
    return WgtPopupButton(
      width: width,
      height: 20,
      popupWidth: 170,
      popupHeight: 190,
      direction: 'left',
      popupChild: WgtBillLcStatusUpdate(
        appConfig: widget.appConfig,
        loggedInUser: widget.loggedInUser,
        scopeProfile: widget.scopeProfile,
        billingRec: row,
        initialBillingLcStatusTagStr: tagText,
        onUpdate: (tag) {
          widget.onRequestRefresh?.call();
        },
      ),
      child: getTag(
        row: row,
        configItem: configItem,
        tagText: tagText,
        tagColor: tagColor,
        tagTooltip: tagTooltip,
        width: width,
      ),
    );
  }
}
