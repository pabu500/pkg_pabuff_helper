import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/def_helper/list_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';

import '../../def_helper/dh_device.dart';
import '../../def_helper/dh_pag_finance.dart';
import '../../def_helper/dh_pag_org.dart';
import '../../def_helper/dh_pag_tariff.dart';

class MdlPagListController /*extends ChangeNotifier*/ {
  // PagItemKind pagItemKind;
  dynamic itemTypeEnum;
  List<MdlListColController> listColControllerList = [];
  String? rootTableName;
  List<String> filterKeyEqualList;
  List<String> filterKeyLikeList;
  List<Map<String, dynamic>> joinKeyList;
  bool enableGroupBy;

  MdlPagListController({
    // required this.pagItemKind,
    required this.itemTypeEnum,
    required this.listColControllerList,
    this.rootTableName,
    this.filterKeyEqualList = const [],
    this.filterKeyLikeList = const [],
    this.joinKeyList = const [],
    this.enableGroupBy = false,
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

  factory MdlPagListController.fromJson(Map<String, dynamic> json,
      {PagListContextType? listContextType}) {
    List<MdlListColController> listConfigItemList = [];
    if (json['list_config'] != null) {
      for (var listConfigItem in json['list_config']) {
        listConfigItem = MdlListColController.fromJson(listConfigItem,
            listContextType: listContextType);
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

    bool enableGroupBy = json['enable_group_by'] == 'true';

    String? itemTypeStr = json['item_type'];
    dynamic itemTypeEnum;
    if (itemTypeStr != null) {
      switch (itemTypeStr) {
        case 'meter':
          itemTypeEnum = PagDeviceCat.meter;
          break;
        case 'meterGroup':
          itemTypeEnum = PagDeviceCat.meterGroup;
          break;
        case 'sensor':
          itemTypeEnum = PagDeviceCat.sensor;
          break;
        case 'lock':
          itemTypeEnum = PagDeviceCat.lock;
          break;
        case 'camera':
          itemTypeEnum = PagDeviceCat.camera;
          break;
        case 'gateway':
          itemTypeEnum = PagDeviceCat.gateway;
          break;
        case 'mcu':
          itemTypeEnum = PagDeviceCat.mcu;
          break;
        case 'motherboard':
          itemTypeEnum = PagDeviceCat.motherboard;
          break;
        case 'sim':
          itemTypeEnum = PagDeviceCat.sim;
          break;
        case 'project':
          itemTypeEnum = PagScopeType.project;
          break;
        case 'site_group' || 'siteGroup':
          itemTypeEnum = PagScopeType.siteGroup;
          break;
        case 'site':
          itemTypeEnum = PagScopeType.site;
          break;
        case 'building':
          itemTypeEnum = PagScopeType.building;
          break;
        case 'location_group' || 'locationGroup':
          itemTypeEnum = PagScopeType.locationGroup;
          break;
        case 'location':
          itemTypeEnum = PagScopeType.location;
          break;
        case 'bill':
          itemTypeEnum = PagItemKind.bill;
          break;
        case 'tenant_soa':
          itemTypeEnum = PagFinanceType.tenantSoa;
          break;
        case 'payment':
          itemTypeEnum = PagFinanceType.payment;
          break;
        case 'payment_apply':
          itemTypeEnum = PagFinanceType.paymentApply;
          break;
        case 'amgr':
          itemTypeEnum = PagOrgType.amgr;
          break;
        case 'landlord':
          itemTypeEnum = PagOrgType.landlord;
          break;
        case 'bank':
          itemTypeEnum = PagOrgType.bank;
          break;
        case 'tariff_package':
          itemTypeEnum = PagTariff.tariffPackage;
          break;
        case 'tariff_package_type':
          itemTypeEnum = PagTariff.tariffPackageType;
          break;
        case 'tariff_rate':
          itemTypeEnum = PagTariff.tariffRate;
          break;
        case 'billing_cost_item':
          itemTypeEnum = PagTariff.billingCostItem;
          break;
        default:
          itemTypeEnum = null;

          dev.log('Unknown item type: $itemTypeStr');
      }
    }

    return MdlPagListController(
      itemTypeEnum: itemTypeEnum,
      listColControllerList: listConfigItemList,
      rootTableName: json['root_table_name'],
      filterKeyEqualList: filterKeyEqualList,
      filterKeyLikeList: filterKeyLikeList,
      joinKeyList: joinKeyList,
      enableGroupBy: enableGroupBy,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    List<Map<String, dynamic>> listConfig = [];
    for (var listConfigItem in listColControllerList) {
      listConfig.add(listConfigItem.toJson());
    }

    String itemTypeStr = 'unknown_item_type';
    if (itemTypeEnum is PagDeviceCat) {
      // itemTypeStr = getPagDeviceTypeStr(itemType);
      itemTypeStr = (itemTypeEnum as PagDeviceCat).name; // use the enum's name
      // switch (itemType) {
      //   case PagDeviceCat.meter:
      //     itemTypeStr = 'meter';
      //     break;
      //   case PagDeviceCat.meterGroup:
      //     itemTypeStr = 'meterGroup';
      //     break;
      //   case PagDeviceCat.sensor:
      //     itemTypeStr = 'sensor';
      //     break;
      //   case PagDeviceCat.lock:
      //     itemTypeStr = 'lock';
      //     break;
      //   case PagDeviceCat.camera:
      //     itemTypeStr = 'camera';
      //     break;
      //   case PagDeviceCat.gateway:
      //     itemTypeStr = 'gateway';
      //     break;
      //   default:
      //     itemTypeStr = '';
      // }
    }

    data['item_type'] = itemTypeStr;
    data['list_config'] = listConfig;
    data['root_table_name'] = rootTableName;
    data['filter_key_equal_list'] = filterKeyEqualList;
    data['filter_key_like_list'] = filterKeyLikeList;
    data['join_key_list'] = joinKeyList;
    data['enable_group_by'] = enableGroupBy.toString();
    // data['item_kind'] = PagItemKind.values.byValue(itemType).name;
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

  // String? getLabelKey() {
  //   for (var colController in listColControllerList) {
  //     if (colController.colKey.toLowerCase().contains('label')) {
  //       return colController.colKey;
  //     }
  //   }
  //   // return '';
  //   return null;
  // }

  Map<String, dynamic> getFilterMap(
      {/*filterValueKey = 'label'*/
      String Function(MdlListColController)? getFilterValueKey}) {
    Map<String, dynamic> filterMap = {};
/* NOTE: not collapse location filter to leaf scope
// reason: if leaf is location label, the label is not unique
    // colapse location filter to leaf scope
    List<MdlListColController> listColControllerListLocation = [];
    List<MdlListColController> listColControllerListNonLocation = [];
    MdlListColController? colControllerLocationLeaf;

    for (var colController in listColControllerList) {
      if (colController.filterValue == null) {
        continue;
      }
      if (colController.filterGroupType == PagFilterGroupType.LOCATION) {
        listColControllerListLocation.add(colController);
      } else {
        listColControllerListNonLocation.add(colController);
      }
    }
    for (var colController in listColControllerListLocation) {
      colControllerLocationLeaf ??= colController;

      PagScopeType? leafScopeType = colControllerLocationLeaf.scopeType;
      PagScopeType? currentScopeType = colController.scopeType;
      if (isSmallerScope(currentScopeType!, leafScopeType!)) {
        colControllerLocationLeaf = colController;
      }
    }

    List<MdlListColController> listColControllerListFlitered = [];
    listColControllerListFlitered.addAll(listColControllerListNonLocation);
    if (colControllerLocationLeaf != null) {
      listColControllerListFlitered.add(colControllerLocationLeaf);
    }
*/

    List<MdlListColController> listColControllerListFlitered =
        listColControllerList;
    for (var colController in listColControllerListFlitered) {
      if (colController.filterValue != null) {
        // if (false) {
        // use join key (in e.g. s.label, b.name etc., format for filter map)
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
      if (colController.filterGroupType == PagFilterGroupType.identity) {
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
