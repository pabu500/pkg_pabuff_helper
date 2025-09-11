import 'package:buff_helper/pag_helper/def_helper/def_role.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_finance_type.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/pag_bill_def.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/list/evs2_list_text.dart';
import 'package:buff_helper/xt_ui/wdgt/list/get_pagenation_bar.dart';
import 'package:buff_helper/xt_ui/wdgt/list/wgt_list_pane_switch_icon.dart';
import 'package:buff_helper/xt_ui/wdgt/list/wgt_list_sort_icon.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_popup_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';

import '../../def_helper/dh_device.dart';
import '../../def_helper/dh_pag_tenant.dart';
import '../wgt_list_column_customize.dart';

class WgtPagEditCommitList extends StatefulWidget {
  const WgtPagEditCommitList({
    super.key,
    this.width,
    this.height,
    this.sectionName = '',
    this.appConfig,
    this.loggedInUser,
    required this.listController,
    required this.listItems,
    required this.listPrefix,
    this.selectShowColumn = false,
    this.showCommit = true,
    this.doCommit,
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
    this.fieldUpdateModified = const [],
    this.colKeyShowList = const [],
    this.onColCustomizeSet,
    this.isFetching = false,
    this.itemType,
  });

  final MdlPagAppConfig? appConfig;
  final MdlPagUser? loggedInUser;
  final String listPrefix;
  final double? width;
  final double? height;
  final String sectionName;
  // final List<Map<String, dynamic>> listConfig;
  final MdlPagListController listController;
  final List<Map<String, dynamic>> listItems;
  final bool selectShowColumn;
  final Function? doCommit;
  final bool showCommit;
  final double? compareValue;
  final double? altCompareValue;
  final bool? disabled;
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
  final String? aclScopeStr;
  final Function? onRequestRefresh;
  //for list of functions to be called when to set the modified flag for list fields
  final List<Function(bool)>? fieldUpdateModified;
  final List<String> colKeyShowList;
  final Function? onColCustomizeSet;
  final bool isFetching;
  final dynamic itemType;

  @override
  State<WgtPagEditCommitList> createState() => _WgtPagEditCommitListState();
}

class _WgtPagEditCommitListState extends State<WgtPagEditCommitList> {
  final double _indexWidth = 34;

  bool _modified = false;
  // late double _lastColWidth;
  // late List<Map<String, dynamic>> _listConfig;
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

  void regFieldUpdateModified(Function(bool) updateFieldModified) {
    widget.fieldUpdateModified?.add(updateFieldModified);
  }

  List<List<dynamic>> _getCsvList() {
    List<List<dynamic>> table = [];
    //add header
    List<dynamic> header = [];
    for (var item in widget.listController.listColControllerList) {
      // if (item.show) {
      header.add(item.colTitle);
      // }
    }
    table.add(header);

    for (var i = 0; i < _postCommitRows.length; i++) {
      Map<String, dynamic> rowToSave = {};
      for (var item in widget.listController.listColControllerList) {
        rowToSave[item.colKey] = _postCommitRows[i][item.colKey] ?? '';
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

    // _listConfig = widget.listController.getListConfig();
  }

  double getListWidth() {
    if (widget.width != null) {
      return widget.width!;
    }
    double width = 120;
    // for (Map<String, dynamic> item in _listConfig) {
    //   if (item['show'] ?? true) {
    //     width += item['width'];
    //   }
    // }
    for (var item in widget.listController.listColControllerList) {
      if (item.showColumn) {
        width += item.colWidth;
      }
    }
    return width;
  }

  @override
  Widget build(BuildContext context) {
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
      decoration: panelBoxDecor(Theme.of(context).hintColor),
      child: widget.isFetching
          ? const Center(
              child: WgtPagWait(),
            )
          : ListView.builder(
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
                              padding: const EdgeInsets.only(top: 8),
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
                      child: _buildListItem(
                          index, row, modifiedRow, _postCommitRows));

                  return _buildListItem(
                      index, row, modifiedRow, _postCommitRows);
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

    for (var item in widget.listController.listColControllerList) {
      if (widget.colKeyShowList.isNotEmpty &&
          !widget.colKeyShowList.contains(item.colKey)) {
        continue;
      }
      // the space for checkbox column title is taken by save table icon
      if (widget.multiSelection &&
          item.colWidgetType == PagColWidgetType.CHECKBOX) {
        continue;
      }
      if (!item.showColumn) {
        continue;
      }
      List<Widget> suffix = [];
      if (item.showSort) {
        suffix.add(
          WgtListSortIcon(
            sortOrder: item.sortOrder,
            onSort: (sortOrder) {
              for (MdlListColController colCtrl
                  in widget.listController.listColControllerList) {
                colCtrl.sortOrder = '';
              }
              item.sortOrder = sortOrder;
              if (sortOrder.isEmpty) {
                return;
              }
              _sortList(item.colKey, sortOrder == 'asc' ? true : false);
            },
          ),
        );
      }

      if (item.isDetailKey) {
        if (_currentMode == 'pane') {
          suffix.add(Expanded(child: Container()));
        }
        suffix.add(WgtListPaneIcon(
            mode: _currentMode,
            onToggleMode: (mode) {
              if (widget.onToggleListPaneMode != null) {
                widget.onToggleListPaneMode!(mode, item.colKey);
              }
            }));
      }
      listHeader.add(Evs2ListText(
        originalFullText: item.colTitle,
        width: item.colWidth,
        style: listHeaderStyle,
        suffix: suffix,
        mainAixsAlignment: item.align == 'right'
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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
    // for (Map<String, dynamic> configItem in _listConfig) {
    for (var ctrlItem in widget.listController.listColControllerList) {
      if (!(ctrlItem.showColumn)) {
        continue;
      }
      if (widget.colKeyShowList.isNotEmpty &&
          !widget.colKeyShowList.contains(ctrlItem.colKey)) {
        continue;
      }

      _listItemStyle = TextStyle(
        fontSize: 13.5,
        color: Theme.of(context).hintColor,
      );

      bool unique = ctrlItem.isUnique;
      List<String> listValues = [];
      if (unique) {
        for (Map<String, dynamic> row in fullList!) {
          listValues.add(row[ctrlItem.colKey] ?? '');
        }
      }

      // bool showAltIcon = false;
      // if (ctrlItem['altIconIf'] != null) {
      //   showAltIcon = ctrlItem['altIconIf'](row, widget.altCompareValue);
      // }
      // bool showIcon = true;
      // if (ctrlItem['showIconIf'] != null) {
      //   showIcon = ctrlItem['showIconIf'](row, widget.compareValue);
      // }
      // String? iconTooltip;
      // if (ctrlItem['getIconTooltip'] != null) {
      //   iconTooltip = ctrlItem['getIconTooltip'](row, widget.compareValue);
      // }

      // //check if item is disabled
      bool disabled = false;
      // if (ctrlItem['disableIf'] != null) {
      //   disabled = ctrlItem['disableIf'](row, widget.compareValue);
      // }
      // int dataIndex = index;
      // if (widget.showHeader) {
      //   dataIndex = index - 1;
      // }

      //check width
      double width = ctrlItem.colWidth;
      //check item editable
      // NOTE: col editable not set here
      // bool itemEditable = false;
      // if (row[ctrlItem.colKey] != null) {
      //   if (row['${ctrlItem.colKey}_editable'] != null) {
      //     itemEditable = row['${ctrlItem.colKey}_editable'];
      //   }
      // }

      //check col editable
      // bool colEditable = false;
      // if (ctrlItem['editable'] != null) {
      //   colEditable = ctrlItem['editable'];
      // } else if (ctrlItem['editableIf'] != null) {
      //   colEditable = ctrlItem['editableIf'](row[ctrlItem.colKey]);
      // }

      if (row[ctrlItem.colKey] != null) {
        //col colors
        if (ctrlItem.colColor != null) {
          _listItemStyle = _listItemStyle.copyWith(
            color: ctrlItem.colColor,
            fontWeight: FontWeight.w500,
          );
        }

        // if (ctrlItem['style'] != null) {
        //   _listItemStyle = ctrlItem['style'];
        // }

        // if (ctrlItem['getStyle'] != null) {
        //   _listItemStyle =
        //       ctrlItem['getStyle'](row[ctrlItem.colKey]) ?? _listItemStyle;
        // }

        // item colors
        // is determined in the following order:
        // 1. error color
        // 2. item color
        // 3. modified color
        // 4. success color
        // 5. col editable color
        if (ctrlItem.errorColor != null &&
            (row[ctrlItem.colKey] as String).contains(
                'error') /*&& row['error'].keys.first == item['fieldKey']*/) {
          _listItemStyle = _listItemStyle.copyWith(
              color: ctrlItem.errorColor, fontWeight: FontWeight.w500);
        } else if (row['${ctrlItem.colKey}_color'] != null) {
          _listItemStyle = _listItemStyle.copyWith(
              color: row['${ctrlItem.colKey}_color'],
              fontWeight: FontWeight.w500);
        } else if (row['${ctrlItem.colKey}_modified'] != null) {
          _listItemStyle = _listItemStyle.copyWith(
              color: _modifiedColor, fontWeight: FontWeight.w500);
        } else if (ctrlItem.successColor != null &&
            (row[ctrlItem.colKey] as String).contains('success')) {
          _listItemStyle = _listItemStyle.copyWith(
              color: ctrlItem.successColor, fontWeight: FontWeight.w500);
        }
        // else if (colEditable) {
        //   _listItemStyle = _listItemStyle.copyWith(
        //       color: Theme.of(context).colorScheme.onSurface,
        //       fontWeight: FontWeight.w500);
        // }
      }

      String originalFullText = '';
      if (row[ctrlItem.colKey] != null) {
        originalFullText = row[ctrlItem.colKey].toString();
        // if (ctrlItem['prefix'] != null) {
        //   originalFullText = ctrlItem['prefix'] + originalFullText;
        // }
      }
      // if (ctrlItem['getDisplayString'] != null) {
      //   originalFullText =
      //       ctrlItem['getDisplayString'](row[ctrlItem.colKey]) ?? '';
      // }
      if (ctrlItem.useComma) {
        originalFullText =
            getCommaNumberStr(double.tryParse(originalFullText), decimal: 2);
      }

      bool showTag = false;
      String tagText = '';
      String? tagTooltip;
      Color? tagColor;

      if (ctrlItem.getTag != null) {
        Map<String, dynamic> tagInfo = ctrlItem.getTag!(row, ctrlItem.colKey);
        if (tagInfo.isNotEmpty) {
          showTag = true;
          tagText = tagInfo['tag'];
          tagColor = tagInfo['color'];
          tagTooltip = tagInfo['tooltip'];
        }
      }

      listItem.add(
        ctrlItem.colWidgetType == PagColWidgetType.TEXT
            ? Tooltip(
                message: originalFullText,
                waitDuration: const Duration(milliseconds: 500),
                child: getCellText(
                  originalFullText: originalFullText,
                  width: width,
                  style: _listItemStyle,
                  alignment: ctrlItem.align == 'right'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  // fieldKey: ctrlItem.colKey,
                  // modifiedRow: modifiedRow,
                  // flagModified: flagModified,
                  // unique: unique,
                  // listValues: listValues,
                  // nonSelectable: ctrlItem.isClickCopy,
                  // clickCopy: ctrlItem.isClickCopy,
                ),
                // Evs2ListText(
                //   parentListWgt: null,
                //   originalFullText: originalFullText,
                //   width: width,
                //   clickEditable: false,
                //   style: _listItemStyle,
                //   fieldKey: ctrlItem.colKey,
                //   modifiedRow: modifiedRow,
                //   flagModified: flagModified,
                //   // validator: ctrlItem['validator'],
                //   // colValidator: ctrlItem['uniqueValidator'],
                //   unique: unique,
                //   listValues: listValues,
                //   nonSelectable: ctrlItem.isClickCopy,
                //   clickCopy: ctrlItem.isClickCopy,
                // ),
              )
            : ctrlItem.colWidgetType == PagColWidgetType.TAG && showTag
                ? getTag(
                    row: row,
                    configItem: ctrlItem.toJson(),
                    width: width,
                    tagColor: tagColor,
                    tagText: tagText,
                    tagTooltip: tagTooltip,
                  )
                : ctrlItem.colWidgetType == PagColWidgetType.TAG_LIST
                    ? getTagList(
                        row: row,
                        configItem: ctrlItem.toJson(),
                        width: width,
                        tagColor: tagColor,
                        tagText: row[ctrlItem.colKey] ?? '',
                        tagTooltip: tagTooltip,
                      )
                    // :
                    // ctrlItem.colWidgetType == PagColWidgetType.CHECKBOX
                    //     ? Tooltip(
                    //         message: '',
                    //         // disabled ? ctrlItem['disabledTooltip'] ?? '' : '',
                    //         waitDuration: const Duration(milliseconds: 500),
                    //         child: SizedBox(
                    //           width: width,
                    //           child: Checkbox(
                    //             // checkColor: Theme.of(context).hintColor,
                    //             // activeColor: Theme.of(context).colorScheme.secondary,
                    //             value: ctrlItem['getVal']?.call(row) ??
                    //                 row[ctrlItem.colKey] ??
                    //                 false,
                    //             onChanged: disabled
                    //                 ? null
                    //                 : (value) {
                    //                     ctrlItem['onChanged'](value, row);
                    //                   },
                    //           ),
                    //         ),
                    //       )
                    // :
                    // ctrlItem['useWidget'] == 'iconButton'
                    //     ? Padding(
                    //         padding: const EdgeInsets.only(bottom: 8.0),
                    //         child: SizedBox(
                    //           width: width,
                    //           height: 18,
                    //           child: Align(
                    //             alignment: Alignment.centerLeft,
                    //             child: showAltIcon
                    //                 ? Tooltip(
                    //                     message: ctrlItem['altIconTooltip'],
                    //                     child: Icon(
                    //                       ctrlItem['altIcon'],
                    //                       color: Theme.of(context).hintColor,
                    //                     ),
                    //                   )
                    //                 : InkWell(
                    //                     onTap: ctrlItem['onTap'] == null
                    //                         ? ctrlItem['onTap']
                    //                         : () => ctrlItem['onTap'](
                    //                             context,
                    //                             row,
                    //                             fullList!,
                    //                             widget.queryMap),
                    //                     onHover: (val) {
                    //                       setState(() {
                    //                         if (val) {
                    //                           _widgetIndex = index;
                    //                         } else {
                    //                           _widgetIndex = -1;
                    //                         }
                    //                       });
                    //                     },
                    //                     child: showIcon
                    //                         ? Tooltip(
                    //                             waitDuration: const Duration(
                    //                                 milliseconds: 500),
                    //                             message:
                    //                                 ctrlItem['iconTooltip'] ??
                    //                                     iconTooltip ??
                    //                                     '',
                    //                             child: Icon(
                    //                               ctrlItem['iconData'] ??
                    //                                   Icons.edit,
                    //                               color:
                    //                                   ctrlItem['iconColor'] ??
                    //                                       Theme.of(context)
                    //                                           .colorScheme
                    //                                           .primary
                    //                                           .withOpacity(0.5),
                    //                               size: ctrlItem['iconSize'],
                    //                             ),
                    //                           )
                    //                         : Container(),
                    //                   ),
                    //           ),
                    //         ),
                    //       )
                    // :
                    // ctrlItem['useWidget'] == 'dropdown'
                    //     ? DropdownButton(
                    //         isExpanded: true,
                    //         value: row[ctrlItem.colKey],
                    //         items: ctrlItem['dropdownItems']
                    //             .map<DropdownMenuItem<dynamic>>((item) {
                    //           return DropdownMenuItem(
                    //             value: item['value'],
                    //             child: Text(item['label']),
                    //           );
                    //         }).toList(),
                    //         onChanged: disabled
                    //             ? null
                    //             : (value) {
                    //                 ctrlItem['onChanged'](value, row);
                    //               },
                    //       )
                    // :
                    // ctrlItem['useWidget'] == 'singleKey'
                    //     ? ctrlItem['onTap'] == null
                    //         ? Container()
                    //         : InkWell(
                    //             onTap: () {
                    //               ctrlItem['onTap'](row);
                    //             },
                    //             child: Tooltip(
                    //               message:
                    //                   ctrlItem['detailTooltip'] ?? '',
                    //               waitDuration:
                    //                   const Duration(milliseconds: 500),
                    //               child: Evs2ListText(
                    //                 nonSelectable: true,
                    //                 // parentListWgt: widget,
                    //                 originalFullText: originalFullText,
                    //                 width: width,
                    //                 style: row[ctrlItem.colKey] ==
                    //                         widget.currentItemId
                    //                     ? TextStyle(
                    //                         backgroundColor:
                    //                             Theme.of(context)
                    //                                 .colorScheme
                    //                                 .primary,
                    //                         fontSize: 15,
                    //                         color: Colors.white,
                    //                         fontWeight: FontWeight.w500,
                    //                       )
                    //                     : _listItemStyle.copyWith(
                    //                         color: Theme.of(context)
                    //                             .colorScheme
                    //                             .primary,
                    //                         fontWeight: FontWeight.w500,
                    //                       ),
                    //               ),
                    //             ),
                    //           )
                    : Container(
                        width: width + 10,
                        alignment: Alignment.centerLeft,
                        child: ctrlItem.colWidgetType == PagColWidgetType.CUSTOM
                            ? Container(
                                decoration: (row['is_selected'] ?? false)
                                    ? BoxDecoration(
                                        border: Border.all(
                                          color:
                                              Theme.of(context).highlightColor,
                                          // Theme.of(context).colorScheme.primary,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      )
                                    : null,
                                child:
                                    ctrlItem.getCustomWidget?.call(row, _rows))
                            : Container(),
                      ),
      );
    }

    return ListTile(
      // contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 0),
      // minVerticalPadding: 2,
      // hoverColor: _widgetIndex == index ? Colors.red : null,
      tileColor: _widgetIndex == index
          ? Theme.of(context).hintColor.withAlpha(25)
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

  Widget getCellText({
    required String originalFullText,
    required double width,
    required TextStyle style,
    Alignment alignment = Alignment.centerLeft,
    // required String fieldKey,
    // required Map<String, dynamic> modifiedRow,
    // required Function(bool) flagModified,
    // required bool unique,
    // required List<String> listValues,
    // required bool nonSelectable,
    // required bool clickCopy,
  }) {
    String displayText = convertToDisplayString(originalFullText, width, style);

    return SizedBox(
      width: width,
      child: Align(
        alignment: alignment,
        child: SelectableText.rich(
          TextSpan(
            text: displayText,
            style: style,
          ),
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
            popupChild: WgtPagListColumnCustomize(
              sectionName: widget.sectionName,
              listController: widget.listController,
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
                  widget.onColCustomizeSet?.call();
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
    // for (Map<String, dynamic> configItem in _listConfig) {
    for (MdlListColController configItem
        in widget.listController.listColControllerList) {
      // if (configItem['show'] == false) {
      //   continue;
      // }
      columnSelection.add(
        Row(
          children: [
            Transform.scale(
              scale: 0.8,
              child: Checkbox(
                value: configItem.showColumn,
                onChanged: (value) {
                  setState(() {
                    configItem.showColumn = value!;
                  });
                },
              ),
            ),
            Text(
              configItem.colTitle,
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

  Widget getTagList({
    required Map<String, dynamic> row,
    required Map<String, dynamic> configItem,
    required String tagText,
    Color? tagColor,
    String? tagTooltip,
    required double width,
  }) {
    List<String> tagList = tagText.split(',');
    List<Widget> tagWidgets = [];
    for (String tag in tagList) {
      tagWidgets.add(
        getTag2(
          row: row,
          configItem: configItem,
          tagText: tag,
          tagColor: tagColor,
          tagTooltip: tagTooltip,
          width: width,
        ),
      );
    }
    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tagWidgets,
      ),
    );
  }

  Widget getTag2({
    required Map<String, dynamic> row,
    required Map<String, dynamic> configItem,
    required String tagText,
    Color? tagColor,
    String? tagTooltip,
    required double width,
  }) {
    String tagLabel = '';
    Color tagColor = Colors.grey;
    if (configItem['col_key'] == 'portal_type_str') {
      PagPortalType portalType = PagPortalType.byValue(tagText);
      tagLabel = portalType.tag;
      tagColor = portalType.color;
    } else if (configItem['col_key'] == 'lc_status') {
      if (widget.itemType is PagDeviceCat) {
        PagDeviceLsStatus deviceLsStatus = PagDeviceLsStatus.byTag(tagText);
        tagLabel = deviceLsStatus.tag;
        tagColor = deviceLsStatus.color.withAlpha(130);
      } else if (widget.itemType is PagFinanceType) {
        PagPaymentLcStatus financeLcStatus =
            PagPaymentLcStatus.byValue(tagText);
        tagLabel = financeLcStatus.tag;
        tagColor = financeLcStatus.color.withAlpha(130);
      } else if (widget.itemType is PagItemKind) {
        if (widget.itemType == PagItemKind.bill) {
          PagBillingLcStatus billingLcStatus =
              PagBillingLcStatus.byValue(tagText);
          tagLabel = billingLcStatus.tag ?? '';
          tagColor = billingLcStatus.color?.withAlpha(130) ??
              Colors.grey.withAlpha(130);
        }
        if (widget.itemType == PagItemKind.tenant) {
          PagTenantLcStatus tenantLcStatus = PagTenantLcStatus.byValue(tagText);
          tagLabel = tenantLcStatus.tag;
          tagColor = tenantLcStatus.color.withAlpha(130);
        }
      }
    } else {
      tagLabel = tagText;
    }
    return Tooltip(
      message: tagTooltip ??
          configItem['getTooltip']?.call(row[configItem['fieldKey']]) ??
          '',
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        height: 23,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        margin: const EdgeInsets.only(right: 1),
        decoration: BoxDecoration(
          color: tagColor,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(tagLabel,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13.5)),
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
}
