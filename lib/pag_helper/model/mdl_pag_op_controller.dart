import 'package:buff_helper/pag_helper/def_helper/dh_pag_finance_type.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';

import '../def_helper/pag_item_helper.dart';

class MdlPagOpController {
  MdlPagOpController({
    required this.appConfig,
    required this.loggedInUser,
    required this.itemKind,
    required this.itemType,
    required this.itemIdType,
    required this.opName,
    required this.listConfig,
    required this.opList,
    required this.opColsConfig,
    required this.doCheckOpList,
    required this.doOp,
    this.additonalCheck,
    this.isAdditonalKeySameTable = false,
    this.targetValList,
    this.selectedTargetVal,
    this.isImportTargetVal = true,
    this.allowScheduled = false,
    this.scheduledTime,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser? loggedInUser;
  dynamic itemType;
  PagItemKind itemKind;
  ItemIdType itemIdType;
  List<Map<String, dynamic>> listConfig;
  List<Map<String, dynamic>> opColsConfig;
  List<Map<String, dynamic>> opList;
  List<Map<String, dynamic>>? targetValList;
  List<String> requiredFields = [];
  String? identifierField;
  String? selectedTargetVal;
  bool allowScheduled;
  DateTime? scheduledTime;

  String opField = '';
  String opFieldType = 'double';
  String opFieldShortName = '';
  String resultField = '';
  String resultFieldShortName = '';
  bool isAdditonalKeySameTable;
  bool isImportTargetVal;

  Function doCheckOpList;
  Function? additonalCheck;
  Future<dynamic> Function(
      MdlPagAppConfig, Map<String, dynamic>, MdlPagSvcClaim)? doOp;
  Function? onUpdateSeleted;
  Function? onRefreshListItems;
  Function? onFlagListModified;
  dynamic opName;

  String opStatus = 'none';

  int csvErrorCount = 0;
  int dbErrorCount = 0;
  int readyForOpCount = 0;

  void reset() {
    isImportTargetVal = true;
    isAdditonalKeySameTable = false;
    targetValList = [];
    requiredFields = [];
    identifierField = null;
    opField = '';
    opFieldType = 'double';
    opFieldShortName = '';
    resultField = '';
    resultFieldShortName = '';

    listConfig = [];
    opStatus = 'none';
    selectedTargetVal = null;

    clear();
  }

  void clear() {
    opList = [];
    csvErrorCount = 0;
    dbErrorCount = 0;
    readyForOpCount = 0;
    scheduledTime = null;
  }

  List<Map<String, dynamic>> getListConfig(
    List<Map<String, dynamic>> meterListConfig,
    Map<String, dynamic> statusConfig,
  ) {
    listConfig = [];
    for (Map<String, dynamic> item in meterListConfig) {
      listConfig.add(item);
    }
    for (Map<String, dynamic> item in opColsConfig) {
      listConfig.add(item);
    }
    listConfig.add(statusConfig);

    return listConfig;
  }

  void updateOpColColor(Color color) {
    //go thru listConfig, if the fieldKey is found in opColsConfig, update the color
    for (var item in listConfig) {
      if (opColsConfig
          .any((element) => element['fieldKey'] == item['fieldKey'])) {
        item['color'] = color;
      }
    }
  }

  Future<dynamic> checkOpList(SvcClaim svcClaim,
      {Color? itemColor, Color? dbColor}) async {
    String currentValKey = 'pre_edit_$opField';
    String currentValTitle =
        'Pre Edit ${opFieldShortName.isEmpty ? opField : opFieldShortName}';

    for (var item in opList) {
      //if key contains _color, remove the key
      item.removeWhere((key, value) => key.contains('_color'));
    }

    String itemKindStr = itemKind.name;

    String itemTypeStr = '';
    if (itemType is PagFinanceType) {
      itemTypeStr = (itemType as PagFinanceType).toString();
    }
    if (itemType == null) {
      itemTypeStr = itemKindStr;
    }
    assert(itemTypeStr.isNotEmpty,
        'itemTypeStr should not be empty, itemType: $itemType');

    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'op_name': opName,
      'item_kind': itemKindStr,
      'item_type': itemTypeStr,
      'item_id_type': itemIdType.name,
      'op_list': opList,
      'op_field': isAdditonalKeySameTable ? opField : '',
    };

    List<Map<String, dynamic>> opListDb = await doCheckOpList(
      appConfig,
      loggedInUser,
      svcClaim,
      queryMap,
    );
    //check if the list item key has itemKey+'_from_db', add key itemKey+'_color'
    for (var item in opListDb) {
      List<String> keysFromDb = [];
      for (var itemKey in item.keys) {
        if (item['${itemKey}_from_db'] != null) {
          keysFromDb.add(itemKey);
        }
      }
      if (itemColor != null) {
        for (var itemKey in keysFromDb) {
          item['${itemKey}_color'] = itemColor ?? Colors.orange;
        }
      }
      if (isAdditonalKeySameTable) {
        item[currentValKey] = item['${opField}_from_db'];
      }
    }

    opList = opListDb;

    if (additonalCheck != null) {
      await additonalCheck!();
    }
    if (isAdditonalKeySameTable) {
      final currentValCol = {
        'title': currentValTitle,
        'fieldKey': currentValKey,
        'width': 135.0,
        if (dbColor != null) 'color': dbColor,
      };
      if (listConfig
          .where((element) => element['fieldKey'] == currentValKey)
          .isEmpty) {
        //insert before 'opField'
        listConfig.insert(
            listConfig.indexWhere((element) =>
                element['fieldKey'] == opColsConfig.first['fieldKey']),
            currentValCol);
      }
    }

    opList.any(
        (element) => element['checked'] == true && element['error'] == null);

    dbErrorCount =
        opList.where((element) => element['status'] == 'db check error').length;
    readyForOpCount =
        opList.where((element) => element['status'] == 'ready for op').length;
  }

  Future<dynamic> commitOp(
    // MdlPagAppConfig appConfig,
    // Map<String, dynamic> queryMap,
    MdlPagSvcClaim svcClaim,
  ) async {
    List<String> targetFields = [];
    for (var opTargets in opColsConfig) {
      targetFields.add(opTargets['fieldKey']);
    }

    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'op_name': opName,
      'item_kind': itemKind.name,
      'item_type': itemType.toString(),
      'item_id_type': itemIdType.name,
      'target_fields': targetFields.join(','),
      'op_list': opList,
    };
    final opResultList = await doOp?.call(
      appConfig,
      // itemType,
      // itemIdType,
      // 'do_op_${opName.toString().toLowerCase()}',
      // targetFields.join(','),
      // opList,
      // scheduledTime,
      queryMap,
      svcClaim,
    );

    Color successColor = Colors.green;

    for (var row in opResultList) {
      if (row['error'] != null) {
        // move error message in map
        // to error key for csv export
        var error = row['error'];
        String key = error.keys.first;
        String message = error.values.first;
        row['${key}_error'] = message;
      } else if (row['checked']) {
        // row['status'] = 'success';
        row['status_color'] = successColor;
        List<String> modifiedKeys = [];
        for (var itemKey in row.keys) {
          if (row['${itemKey}_modified'] != null) {
            modifiedKeys.add(itemKey);
          }
        }
        for (var itemKey in modifiedKeys) {
          row['${itemKey}_color'] = commitColor;
        }
      } else {
        row['status'] = 'skipped';
      }
    }

    List<Map<String, dynamic>> opResultListRet = [];
    for (var item in opResultList) {
      opResultListRet.add(item);
    }

    return opResultListRet;
  }

  void insertNewValCol(Color committedColor, {double? width = 120}) {
    if (opField.isEmpty) {
      return;
    }
    String resultFieldTitle =
        resultFieldShortName.isEmpty ? resultField : resultFieldShortName;
    String resultFieldKey = resultField.isEmpty ? 'new_$opField' : resultField;
    listConfig.insert(
        listConfig.indexWhere((element) => element['fieldKey'] == opField) + 1,
        {
          'title': resultFieldTitle,
          'fieldKey': resultFieldKey,
          'width': width,
          'decimals': opFieldType == 'double' ? 2 : 0,
          'color': Colors.blue,
        });

    for (var row in opList) {
      String newValStr = row[opField] ?? '';
      if (opFieldType == 'double') {
        double? newValDbl = double.tryParse(
          newValStr.replaceAll(',', ''),
        );
        newValStr = newValDbl!.toStringAsFixed(2);
      } else if (opFieldType == 'int') {
        int? newValInt = int.tryParse(
          newValStr.replaceAll(',', ''),
        );
        newValStr = newValInt!.toString();
      }

      // double? newValDbl = double.tryParse(newVal ?? '');
      row[opField] = newValStr;
      row['${opField}_color'] = committedColor;
    }
  }

  bool populateNewVal(
      // String? newVal,
      // String targetField,
      {
    int? decimals,
  }) {
    String? newVal = selectedTargetVal;
    if (newVal == null) {
      return false;
    }
    if (decimals != null) {
      double? newValDbl = double.tryParse(newVal);
      if (newValDbl == null) {
        return false;
      }
      newVal = newValDbl.toStringAsFixed(decimals);
    }

    for (var item in opList) {
      if (item['checked'] == false) {
        continue;
      }
      item[opField] = newVal;
      item['${opField}_color'] = commitColor;
    }
    bool populated = opList.any((element) =>
        element['checked'] == true &&
        element['error'] == null &&
        (element['${opField}_color'] == commitColor || element[opField] == ''));

    return populated;
  }
}
