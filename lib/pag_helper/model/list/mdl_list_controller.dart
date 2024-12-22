import 'package:buff_helper/pag_helper/def/pag_item_def.dart';
import 'package:flutter/foundation.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';

class MdlPagListController /*extends ChangeNotifier*/ {
  // PagItemKind pagItemKind;
  dynamic itemType;
  List<MdlListColController> listColControllerList = [];
  String? rootTableName;
  List<String> filterKeyEqualList;
  List<String> filterKeyLikeList;
  List<Map<String, dynamic>> joinKeyList = [];

  MdlPagListController({
    // required this.pagItemKind,
    required this.itemType,
    required this.listColControllerList,
    this.rootTableName,
    this.filterKeyEqualList = const [],
    this.filterKeyLikeList = const [],
    this.joinKeyList = const [],
  });

  // bool _disposed = false;

  // @override
  // void dispose() {
  //   // may get called on hot reload,
  //   // test this only close and reopen
  //   _disposed = true;
  //   if (kDebugMode) {
  //     print('MdlPagListController with $itemType disposed');
  //   }
  //   super.dispose();
  // }

  // @override
  // void notifyListeners() {
  //   if (!_disposed) {
  //     super.notifyListeners();
  //   }
  // }

  factory MdlPagListController.fromJson(Map<String, dynamic> json) {
    List<MdlListColController> listConfigItemList = [];
    if (json['list_config'] != null) {
      for (var listConfigItem in json['list_config']) {
        listConfigItem = MdlListColController.fromJson(listConfigItem);
        listConfigItemList.add(listConfigItem);
      }
    }

    String? itemKindStr = json['item_kind'];
    PagItemKind? itemKind;
    if (itemKindStr != null) {
      itemKind = PagItemKind.values.byName(itemKindStr);
    }

    List<String> filterKeyEqualList = [];
    if (json['filter_key_equal_list'] != null) {
      for (var filterKeyEqual in json['filter_key_equal_list']) {
        filterKeyEqualList.add(filterKeyEqual);
      }
    }

    List<String> filterKeyLikeList = [];
    if (json['filter_key_like_list'] != null) {
      for (var filterKeyLike in json['filter_key_like_list']) {
        filterKeyLikeList.add(filterKeyLike);
      }
    }

    List<Map<String, dynamic>> joinKeyList = [];
    if (json['join_key_list'] != null) {
      for (var joinKey in json['join_key_list']) {
        joinKeyList.add(joinKey);
      }
    }

    return MdlPagListController(
      itemType: json['item_type'],
      listColControllerList: listConfigItemList,
      rootTableName: json['root_table_name'],
      filterKeyEqualList: filterKeyEqualList,
      filterKeyLikeList: filterKeyLikeList,
      joinKeyList: joinKeyList,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    List<Map<String, dynamic>> listConfig = [];
    for (var listConfigItem in listColControllerList) {
      listConfig.add(listConfigItem.toJson());
    }

    data['item_type'] = itemType;
    data['list_config'] = listConfig;
    data['root_table_name'] = rootTableName;
    data['filter_key_equal_list'] = filterKeyEqualList;
    data['filter_key_like_list'] = filterKeyLikeList;
    data['join_key_list'] = joinKeyList;
    return data;
  }

  List<Map<String, dynamic>> getListConfig() {
    List<Map<String, dynamic>> listConfig = [];
    for (var listConfigItem in listColControllerList) {
      listConfig.add(listConfigItem.toJson());
    }
    return listConfig;
  }

  bool get isEmpty {
    return listColControllerList.isEmpty;
  }

  bool get isNotEmpty {
    return listColControllerList.isNotEmpty;
  }

  String getDisplayNameKey() {
    for (var colController in listColControllerList) {
      if (colController.isDisplayNameKey) {
        return colController.colKey;
      }
    }
    return '';
  }

  Map<String, dynamic> getFilterMap(
      {/*filterValueKey = 'label'*/
      String Function(MdlListColController)? getFilterValueKey}) {
    Map<String, dynamic> filterMap = {};
    for (var colController in listColControllerList) {
      if (colController.filterValue != null) {
        if (colController.joinKey != null) {
          filterMap[colController.joinKey!] = colController
              .filterValue?[getFilterValueKey?.call(colController)];
        } else {
          filterMap[colController.colKey] = colController
              .filterValue?[getFilterValueKey?.call(colController)];
        }
      }
    }
    return filterMap;
  }

  void clearFilter() {
    for (var colController in listColControllerList) {
      colController.resetFilter();
    }
  }

  bool isIdentifierSet() {
    for (var colController in listColControllerList) {
      if (colController.filterGroupType == PagFilterGroupType.IDENTITY) {
        if (colController.filterValue != null) {
          return true;
        }
      }
    }
    return false;
  }

  // void updatePinned(bool isPinned, String colKey) {
  //   for (var colController in listColControllerList) {
  //     if (colController.colKey == colKey) {
  //       colController.pinned = isPinned;
  //       notifyListeners();
  //       break;
  //     }
  //   }
  // }
}
