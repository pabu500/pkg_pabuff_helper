import 'dart:developer' as dev;
import 'package:buff_helper/pag_helper/def_helper/list_helper.dart';
import 'package:flutter/material.dart';

import '../../def_helper/dh_scope.dart';

enum PagFilterWidgetType {
  INPUT,
  SELECT,
  DATE,
  DATETIME,
  INPUT_SELECT,
}

enum PagColWidgetType {
  TEXT,
  CHECKBOX,
  TAG,
  CUSTOM,
  TAG_LIST,
}

enum PagFilterGroupType {
  identity,
  types,
  location,
  datetime,
  status,
  spec,
  other,
  join,
}

enum PagFilterDataType {
  string,
  number,
  boolean,
  date,
  datetime,
}

class MdlListColController {
  late final String colKey;
  String? joinKey;
  String? asIsKey;
  bool includeColKeyAsFilter;
  bool includeColKeyAsGroupBy;
  String stringAgg;
  bool isMutable;
  bool isDisplayNameKey;
  String colTitle;
  String filterLabel;
  double colWidth;
  bool showColumn;
  bool showEditPanel;
  bool showOnCard;
  bool showTimestampAsDate;
  int rowOnCard;
  int rowOrder = 1;
  bool showSort;
  String sortOrder;
  bool hidden;
  PagFilterWidgetType filterWidgetType;
  PagFilterGroupType filterGroupType;
  PagFilterDataType filterDataType;
  UniqueKey? filterResetKey;
  Map<String, dynamic>? filterValue;
  String? getListEpt;
  PagColWidgetType colWidgetType;
  // PagEditorWidgetType editorWidgetType;
  bool isDetailKey;
  bool isUnique;
  bool isClickCopy;
  bool isPaneKey;
  String colType;
  Color? colColor;
  Color? successColor;
  Color? errorColor;
  List<Map<String, dynamic>>? valueList;
  Function(Map<String, dynamic> row, String colKey)? getTag;
  bool pinned = false;
  Widget? Function(
          Map<String, dynamic> row, List<Map<String, dynamic>> fullList)?
      getCustomWidget;
  TextEditingController? filterWidgetController;
  PagScopeType? scopeType;
  String? align;
  bool useComma;
  int? decimal;
  String? Function(String)? validator;
  List<String>? contextExcludeList;
  List<String>? contextIncludeList;
  List<String>? contextRequiredOnLsList;
  bool requiredOnOnb;
  bool showFilter;
  List<Map<String, dynamic>>? opInfoList;

  MdlListColController({
    required this.colKey,
    this.joinKey,
    this.asIsKey,
    this.includeColKeyAsFilter = true,
    this.includeColKeyAsGroupBy = true,
    this.stringAgg = '',
    this.isMutable = true,
    this.isDisplayNameKey = false,
    this.colTitle = '',
    this.filterLabel = '',
    this.colWidth = 0.0,
    this.showColumn = true,
    this.showEditPanel = true,
    this.showOnCard = false,
    this.rowOnCard = 1,
    this.rowOrder = 1,
    this.showSort = false,
    this.sortOrder = 'desc',
    this.hidden = false,
    this.filterWidgetType = PagFilterWidgetType.INPUT,
    this.showTimestampAsDate = false,
    this.filterGroupType = PagFilterGroupType.other,
    this.filterDataType = PagFilterDataType.string,
    this.getListEpt,
    this.filterResetKey,
    this.colWidgetType = PagColWidgetType.TEXT,
    // this.editorWidgetType = PagEditorWidgetType.INPUT,
    this.isUnique = false,
    this.isDetailKey = false,
    this.isClickCopy = false,
    this.isPaneKey = false,
    this.colType = 'string',
    this.colColor,
    this.successColor,
    this.errorColor,
    this.valueList,
    this.getTag,
    bool? pinned,
    this.getCustomWidget,
    this.scopeType,
    this.align,
    this.decimal,
    this.useComma = false,
    this.validator,
    this.contextExcludeList,
    this.contextIncludeList,
    this.contextRequiredOnLsList,
    this.requiredOnOnb = false,
    this.showFilter = false,
    this.opInfoList,
  }) {
    pinned = pinned ?? false;
  }

  //getter isJoinKey
  bool get isJoinKey => joinKey != null;

  void prePopulateFilterValue() {
    if (valueList?.length == 1) {
      filterValue = valueList?.first;
    }
  }

  void resetFilter({Map<String, dynamic>? defaultFilterValue}) {
    filterValue = defaultFilterValue;
    filterWidgetController?.clear();
    filterResetKey = UniqueKey();
    prePopulateFilterValue();
  }

  void clearFilter() {
    valueList = [];
    filterValue = null;
    filterWidgetController?.clear();
    filterResetKey = UniqueKey();
  }

  factory MdlListColController.fromJson(Map<String, dynamic> json,
      {PagListContextType? listContextType}) {
    String? colKey = json['colKey'] ?? json['col_key'] ?? json['fieldKey'];
    if (colKey == null) {
      throw Exception('col_key is missing');
    }

    dynamic isIncludeColKeyAsFilter =
        json['include_col_key_as_filter'] ?? 'true';
    if (isIncludeColKeyAsFilter is String) {
      isIncludeColKeyAsFilter = isIncludeColKeyAsFilter.toLowerCase() == 'true';
    }

    dynamic isIncludeColKeyAsGroupBy =
        json['include_col_key_as_group_by'] ?? 'true';
    if (isIncludeColKeyAsGroupBy is String) {
      isIncludeColKeyAsGroupBy =
          isIncludeColKeyAsGroupBy.toLowerCase() != 'false';
    }

    String stringAgg = json['string_agg'] ?? '';

    String isMutableStr = json['is_mutable'] ?? 'true';
    bool isMutable = isMutableStr.toLowerCase() == 'true';

    String isDisplayNameKeyStr = json['is_display_name_key'] ?? 'false';
    bool isDisplayNameKey = isDisplayNameKeyStr.toLowerCase() == 'true';

    String colTitle =
        json['colTitle'] ?? json['col_title'] ?? json['title'] ?? colKey;

    String filterLabel = json['filterLabel'] ??
        json['filter_label_flexi'] ??
        json['filter_label'] ??
        json['label'] ??
        colTitle;

    double width = 0.0;
    if (json['colWidth'] != null ||
        json['width'] != null ||
        json['col_width'] != 0.0) {
      dynamic widthValueStr =
          json['col_width'] ?? json['colWidth'] ?? json['width'];
      if (widthValueStr is double) {
        width = widthValueStr;
      } else if (widthValueStr is String) {
        width = double.parse(widthValueStr);
      }
    }

    String? colType;
    if (json['colType'] != null || json['col_type'] != null) {
      colType = json['col_type'] ?? json['colType'];
    }

    bool showColumn = true;
    bool showEditPanel = true;
    if (json['show'] != null) {
      dynamic showValue = json['show'];
      if (showValue is bool) {
        showColumn = showValue;
      } else if (showValue is String) {
        showColumn = showValue.toLowerCase() == 'true';
      }
    }

    showEditPanel = showColumn;

    if (json['show_edit_panel'] != null) {
      dynamic showEditPanelValue = json['show_edit_panel'];
      if (showEditPanelValue is bool) {
        showEditPanel = showEditPanelValue;
      } else if (showEditPanelValue is String) {
        showEditPanel = showEditPanelValue.toLowerCase() == 'true';
      }
    }

    bool permHidden = false;
    if (json['hidden'] != null) {
      dynamic custHiddenValue = json['hidden'];
      if (custHiddenValue is bool) {
        permHidden = custHiddenValue;
      } else if (custHiddenValue is String) {
        permHidden = custHiddenValue.toLowerCase() == 'true';
      }
    }

    if (permHidden) {
      showEditPanel = false;
    }

    bool showSort = false;
    if (json['show_sort'] != null) {
      dynamic showSortValue = json['show_sort'];
      if (showSortValue is bool) {
        showSort = showSortValue;
      } else if (showSortValue is String) {
        showSort = showSortValue.toLowerCase() == 'true';
      }
    }

    String sortOrder = json['sort_order'] ?? 'desc';

    PagFilterWidgetType filterWidgetType = PagFilterWidgetType.INPUT;
    try {
      String? filterWidgetTypeStr = json['filter_widget_type'];
      if (filterWidgetTypeStr != null) {
        filterWidgetType = PagFilterWidgetType.values
            .byName(filterWidgetTypeStr.toUpperCase());
      }
    } catch (e) {
      dev.log('Error in parsing filter_widget_type: $e');

      rethrow;
    }

    PagFilterGroupType filterGroupType = PagFilterGroupType.other;
    try {
      if (json['filter_group_type'] != null) {
        String filterGroupTypeStr = json['filter_group_type'];
        filterGroupType = PagFilterGroupType.values.byName(filterGroupTypeStr);
      }
    } catch (e) {
      dev.log('Error in parsing filter_group_type: $e');

      rethrow;
    }

    String? getListEpt = json['getListEpt'] ?? json['get_list_ept'];

    PagColWidgetType colWidgetType = PagColWidgetType.TEXT;
    if (json['col_widget_type'] != null) {
      String colTypeStr = json['col_widget_type'];
      colWidgetType = PagColWidgetType.values.byName(colTypeStr.toUpperCase());
    }

    // PagEditorWidgetType editorWidgetType = PagEditorWidgetType.INPUT;
    // if (json['editorWidgetType'] != null) {
    //   String editorWidgetTypeStr = json['editorWidgetType'];
    //   editorWidgetType =
    //       PagEditorWidgetType.values.byName(editorWidgetTypeStr.toUpperCase());
    // }

    PagFilterDataType filterDataType = PagFilterDataType.string;
    if (json['filter_data_type'] != null) {
      String filterDataTypeStr = json['filter_data_type'];
      filterDataType =
          PagFilterDataType.values.byName(filterDataTypeStr.toLowerCase());
    }

    bool isUnique = false;
    if (json['is_unique'] != null) {
      dynamic isUniqueValue = json['is_unique'];
      if (isUniqueValue is bool) {
        isUnique = isUniqueValue;
      } else if (isUniqueValue is String) {
        isUnique = isUniqueValue.toLowerCase() == 'true';
      }
    }

    bool isDetailKey = false;
    if (json['is_detail_key'] != null) {
      dynamic isDetailKeyValue = json['is_detail_key'];
      if (isDetailKeyValue is bool) {
        isDetailKey = isDetailKeyValue;
      } else if (isDetailKeyValue is String) {
        isDetailKey = isDetailKeyValue.toLowerCase() == 'true';
      }
    }

    bool isClickCopy = false;
    if (json['is_click_copy'] != null) {
      dynamic isClickCopyValue = json['is_click_copy'];
      if (isClickCopyValue is bool) {
        isClickCopy = isClickCopyValue;
      } else if (isClickCopyValue is String) {
        isClickCopy = isClickCopyValue.toLowerCase() == 'true';
      }
    }

    List<Map<String, dynamic>> valueList = [];
    if (json['value_list'] != null) {
      dynamic valueListValue = json['value_list'];
      if (valueListValue is List) {
        valueList = List<Map<String, dynamic>>.from(valueListValue);
      }
    }

    List<String> contextExcludeList = [];
    if (json['context_exclude'] != null) {
      dynamic contextExcludeListValue = json['context_exclude'];
      if (contextExcludeListValue is List) {
        contextExcludeList =
            List<String>.from(contextExcludeListValue.map((e) => e.toString()));
      }
    }

    List<String> contextIncludeList = [];
    if (json['context_include'] != null) {
      dynamic contextIncludeListValue = json['context_include'];
      if (contextIncludeListValue is List) {
        contextIncludeList =
            List<String>.from(contextIncludeListValue.map((e) => e.toString()));
      }
    }

    if (listContextType != null) {
      if (contextExcludeList.contains(listContextType.name)) {
        showColumn = false;
      }
      if (contextIncludeList.isNotEmpty &&
          !contextIncludeList.contains(listContextType.name)) {
        showColumn = false;
      }
    }

    List<String> contextRequiredOnLsList = [];
    if (json['context_required_on_ls'] != null) {
      dynamic contextRequiredOnLsListValue = json['context_required_on_ls'];
      if (contextRequiredOnLsListValue is List) {
        contextRequiredOnLsList = List<String>.from(
            contextRequiredOnLsListValue.map((e) => e.toString()));
      }
    }

    bool requiredOnOnb = false;
    if (json['required_on_onb'] != null) {
      dynamic requiredOnOnbValue = json['required_on_onb'];
      if (requiredOnOnbValue is bool) {
        requiredOnOnb = requiredOnOnbValue;
      } else if (requiredOnOnbValue is String) {
        requiredOnOnb = requiredOnOnbValue.toLowerCase() == 'true';
      }
    }

    Widget Function(
            Map<String, dynamic> row, List<Map<String, dynamic>> fullList)?
        getCustomWidget;
    if (json['get_custom_widget'] != null) {
      dynamic customWidgetValue = json['get_custom_widget'];
      if (customWidgetValue is Function) {
        getCustomWidget = customWidgetValue as Widget Function(
            Map<String, dynamic> row, List<Map<String, dynamic>> fullList);
      }
    }

    bool isPaneKey = false;
    if (json['is_pane_key'] != null) {
      dynamic isPaneKeyValue = json['is_pane_key'];
      if (isPaneKeyValue is bool) {
        isPaneKey = isPaneKeyValue;
      } else if (isPaneKeyValue is String) {
        isPaneKey = isPaneKeyValue.toLowerCase() == 'true';
      }
    }

    PagScopeType? scopeType;
    if (filterGroupType == PagFilterGroupType.location) {
      String scopeKey = colKey.replaceFirst('_label', '');
      scopeType = PagScopeType.byValue(scopeKey);
    }

    String? align;
    if (json['align'] != null) {
      dynamic alignValue = json['align'];
      if (alignValue is String) {
        align = alignValue;
      }
    }

    int? decimal;
    if (json['decimal'] != null) {
      dynamic decimalValue = json['decimal'];
      if (decimalValue is int) {
        decimal = decimalValue;
      } else if (decimalValue is String) {
        decimal = int.tryParse(decimalValue);
      }
    }

    bool showFilter = showColumn;
    if (json['show_filter'] != null) {
      dynamic showFilterValue = json['show_filter'];
      if (showFilterValue is bool) {
        showFilter = showFilterValue;
      } else if (showFilterValue is String) {
        showFilter = showFilterValue.toLowerCase() == 'true';
      }
    }

    bool showOnCard = false;
    if (json['show_on_card'] != null) {
      dynamic showOnCardValue = json['show_on_card'];
      if (showOnCardValue is bool) {
        showOnCard = showOnCardValue;
      } else if (showOnCardValue is String) {
        showOnCard = showOnCardValue.toLowerCase() == 'true';
      }
    }

    int rowOnCard = 1;
    if (json['row_on_card'] != null) {
      dynamic rowOnCardValue = json['row_on_card'];
      if (rowOnCardValue is int) {
        rowOnCard = rowOnCardValue;
      } else if (rowOnCardValue is String) {
        rowOnCard = int.tryParse(rowOnCardValue) ?? 1;
      }
    }

    bool showTimestampAsDate = false;
    if (json['show_timestamp_as_date'] != null) {
      dynamic showTimestampAsDateValue = json['show_timestamp_as_date'];
      if (showTimestampAsDateValue is bool) {
        showTimestampAsDate = showTimestampAsDateValue;
      } else if (showTimestampAsDateValue is String) {
        showTimestampAsDate = showTimestampAsDateValue.toLowerCase() == 'true';
      }
    }

    int rowOrder = 0;
    if (json['row_order'] != null) {
      dynamic rowOrderValue = json['row_order'];
      if (rowOrderValue is int) {
        rowOrder = rowOrderValue;
      } else if (rowOrderValue is String) {
        rowOrder = int.tryParse(rowOrderValue) ?? 0;
      }
    }

    List<Map<String, dynamic>>? opInfoList;
    if (json['op_info_list'] != null) {
      dynamic opsInfoListValue = json['op_info_list'];
      if (opsInfoListValue is List) {
        opInfoList = List<Map<String, dynamic>>.from(opsInfoListValue);
      }
    }

    return MdlListColController(
      colKey: colKey,
      joinKey: json['join_key'],
      asIsKey: json['as_is_key'],
      colTitle: colTitle,
      colType: colType ?? 'string',
      includeColKeyAsFilter: isIncludeColKeyAsFilter,
      includeColKeyAsGroupBy: isIncludeColKeyAsGroupBy,
      stringAgg: stringAgg,
      isMutable: isMutable,
      isDisplayNameKey: isDisplayNameKey,
      filterLabel: filterLabel,
      colWidth: width,
      showColumn: showColumn,
      showEditPanel: showEditPanel,
      showOnCard: showOnCard,
      rowOnCard: rowOnCard,
      showSort: showSort,
      sortOrder: sortOrder,
      hidden: permHidden,
      filterWidgetType: filterWidgetType,
      filterGroupType: filterGroupType,
      filterDataType: filterDataType,
      getListEpt: getListEpt,
      colWidgetType: colWidgetType,
      // editorWidgetType: editorWidgetType,
      isUnique: isUnique,
      isDetailKey: isDetailKey,
      isClickCopy: isClickCopy,
      valueList: valueList,
      getCustomWidget: getCustomWidget,
      isPaneKey: isPaneKey,
      scopeType: scopeType,
      align: align,
      decimal: decimal,
      contextExcludeList: contextExcludeList,
      contextIncludeList: contextIncludeList,
      contextRequiredOnLsList: contextRequiredOnLsList,
      requiredOnOnb: requiredOnOnb,
      showFilter: showFilter,
      showTimestampAsDate: showTimestampAsDate,
      rowOrder: rowOrder,
      opInfoList: opInfoList,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['col_key'] = colKey;
    data['join_key'] = joinKey;
    data['as_is_key'] = asIsKey;
    // need be to handle both bool and string
    data['include_col_key_as_filter'] = includeColKeyAsFilter.toString();
    data['include_col_key_as_group_by'] = includeColKeyAsGroupBy.toString();
    data['string_agg'] = stringAgg;
    data['is_mutable'] = isMutable.toString();
    data['is_display_name_key'] = isDisplayNameKey.toString();
    data['col_title'] = colTitle;
    data['col_type'] = colType;
    data['filter_label'] = filterLabel;
    data['col_width'] = colWidth;
    data['show_column'] = showColumn.toString();
    data['show_edit_panel'] = showEditPanel.toString();
    data['show_on_card'] = showOnCard.toString();
    data['row_on_card'] = rowOnCard;
    data['show_sort'] = showSort.toString();
    // data['custHidden'] = hidden.toString();
    data['hidden'] = hidden.toString();
    data['col_widget_type'] = colWidgetType.name;
    data['filter_widget_type'] = filterWidgetType.name;
    // data['editorWidgetType'] = editorWidgetType.name;
    data['filter_group_type'] = filterGroupType.name;
    data['align'] = align;
    data['decimal'] = decimal;
    data['context_exclude'] = contextExcludeList;
    data['context_include'] = contextIncludeList;
    data['context_required_on_ls'] = contextRequiredOnLsList;
    data['filter_data_type'] = filterDataType.name;
    data['required_on_onb'] = requiredOnOnb.toString();
    data['show_filter'] = showFilter.toString();
    data['show_timestamp_as_date'] = showTimestampAsDate.toString();
    data['row_order'] = rowOrder;
    data['op_info_list'] = opInfoList;

    return data;
  }
}
