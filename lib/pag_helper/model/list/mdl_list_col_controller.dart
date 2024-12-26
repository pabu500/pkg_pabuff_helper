import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  IDENTITY,
  TYPE,
  LOCATION,
  DATETIME,
  STATUS,
  SPEC,
  OTHER,
}

class MdlListColController {
  late final String colKey;
  String? joinKey;
  bool includeColKeyAsFilter;
  bool includeColKeyAsGroupBy;
  String stringAgg;
  bool isMutable;
  bool isDisplayNameKey;
  String colTitle;
  String filterLabel;
  double colWidth;
  bool show;
  bool showSort;
  String sortOrder;
  bool hidden;
  PagFilterWidgetType filterWidgetType;
  PagFilterGroupType filterGroupType;
  UniqueKey? filterResetKey;
  Map<String, dynamic>? filterValue;
  String? getListEpt;
  PagColWidgetType colWidgetType;
  // PagEditorWidgetType editorWidgetType;
  bool isDetailKey;
  bool isUnique;
  bool isClickCopy;
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

  MdlListColController({
    required this.colKey,
    this.joinKey,
    this.includeColKeyAsFilter = true,
    this.includeColKeyAsGroupBy = true,
    this.stringAgg = '',
    this.isMutable = true,
    this.isDisplayNameKey = false,
    this.colTitle = '',
    this.filterLabel = '',
    this.colWidth = 0.0,
    this.show = true,
    this.showSort = false,
    this.sortOrder = 'desc',
    this.hidden = false,
    this.filterWidgetType = PagFilterWidgetType.INPUT,
    this.filterGroupType = PagFilterGroupType.OTHER,
    this.getListEpt,
    this.filterResetKey,
    this.colWidgetType = PagColWidgetType.TEXT,
    // this.editorWidgetType = PagEditorWidgetType.INPUT,
    this.isUnique = false,
    this.isDetailKey = false,
    this.isClickCopy = false,
    this.colColor,
    this.successColor,
    this.errorColor,
    this.valueList,
    this.getTag,
    bool? pinned,
    this.getCustomWidget,
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

  factory MdlListColController.fromJson(Map<String, dynamic> json) {
    String? colKey = json['colKey'] ?? json['col_key'] ?? json['fieldKey'];
    if (colKey == null) {
      throw Exception('col_key not found');
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

    bool show = true;
    if (json['show'] != null) {
      dynamic showValue = json['show'];
      if (showValue is bool) {
        show = showValue;
      } else if (showValue is String) {
        show = showValue.toLowerCase() == 'true';
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
      if (kDebugMode) {
        print('Error in parsing filter_widget_type: $e');
      }
      rethrow;
    }

    PagFilterGroupType filterGroupType = PagFilterGroupType.OTHER;
    try {
      if (json['filter_group_type'] != null) {
        String filterGroupTypeStr = json['filter_group_type'];
        filterGroupType =
            PagFilterGroupType.values.byName(filterGroupTypeStr.toUpperCase());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in parsing filter_group_type: $e');
      }
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

    return MdlListColController(
      colKey: colKey,
      joinKey: json['join_key'],
      colTitle: colTitle,
      includeColKeyAsFilter: isIncludeColKeyAsFilter,
      includeColKeyAsGroupBy: isIncludeColKeyAsGroupBy,
      stringAgg: stringAgg,
      isMutable: isMutable,
      isDisplayNameKey: isDisplayNameKey,
      filterLabel: filterLabel,
      colWidth: width,
      show: show,
      showSort: showSort,
      sortOrder: sortOrder,
      hidden: permHidden,
      filterWidgetType: filterWidgetType,
      filterGroupType: filterGroupType,
      getListEpt: getListEpt,
      colWidgetType: colWidgetType,
      // editorWidgetType: editorWidgetType,
      isUnique: isUnique,
      isDetailKey: isDetailKey,
      isClickCopy: isClickCopy,
      valueList: valueList,
      getCustomWidget: getCustomWidget,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['col_key'] = colKey;
    data['join_key'] = joinKey;
    // need be to handle both bool and string
    data['include_col_key_as_filter'] = includeColKeyAsFilter.toString();
    data['include_col_key_as_group_by'] = includeColKeyAsGroupBy.toString();
    data['string_agg'] = stringAgg;
    data['is_mutable'] = isMutable.toString();
    data['is_display_name_key'] = isDisplayNameKey.toString();
    data['col_title'] = colTitle;
    data['filter_label'] = filterLabel;
    data['col_width'] = colWidth;
    data['show'] = show.toString();
    data['show_sort'] = showSort.toString();
    // data['custHidden'] = hidden.toString();
    data['hidden'] = hidden.toString();
    data['col_widget_type'] = colWidgetType.name;
    data['filter_widget_type'] = filterWidgetType.name;
    // data['editorWidgetType'] = editorWidgetType.name;

    return data;
  }
}
