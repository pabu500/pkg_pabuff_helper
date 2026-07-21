import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';

import '../model/list/mdl_list_col_controller.dart';

List<Map<String, dynamic>> getOpListConfig(
    List<dynamic>? listConfig,
    List<MdlListColController> listColControllerList,
    dynamic selectedOpType,
    PagItemKind itemKind,
    {dynamic itemType}) {
  List<Map<String, dynamic>> opListConfig = [];

  List<Map<String, dynamic>> colConfigList = [];
  if (listConfig != null) {
    for (var item in listConfig) {
      colConfigList.add(item);
    }
  }
  if (colConfigList.isEmpty) {
    throw Exception('col_config_list is empty');
  }

  for (var colConfig in colConfigList) {
    MdlListColController listColController =
        MdlListColController.fromJson(colConfig);
    listColControllerList.add(listColController);
  }

  // dev.log('list controller list: size ${listColControllerList.length}');

  if (listColControllerList.isNotEmpty) {
    for (MdlListColController colController in listColControllerList) {
      final colKey = colController.colKey;

      List<Map<String, dynamic>>? opInfoList = colController.opInfoList;
      // e.g. [{'op':'onb', 'is_column_mapping_required': 'true'}]
      if (opInfoList == null) {
        continue;
      }

      for (var opInfo in opInfoList) {
        String op = opInfo['op'] ?? '';
        if (op != selectedOpType?.value) {
          continue;
        }
        bool isMappingRequired = true;
        if (opInfo['is_column_mapping_required'] == 'false') {
          isMappingRequired = false;
        }
        bool isValueRequired = true;
        if (opInfo['is_value_required'] == 'false') {
          isValueRequired = false;
        }
        opListConfig.add({
          'col_key': colKey,
          'is_id_col':
              colController.filterGroupType == PagFilterGroupType.identity,
          'title': colController.colTitle,
          'col_type': colController.colType,
          'width': colController.colWidth,
          'is_column_mapping_required': isMappingRequired,
          'is_value_required': isValueRequired,
          'validator': getItemKindValidator(
            itemKind,
            colKey,
            isValueRequired: isValueRequired,
            itemType: itemType,
          ),
        });
      }
      // sort id col to the top
      opListConfig.sort((a, b) {
        if (a['is_id_col'] == true) {
          return -1;
        } else if (b['is_id_col'] == true) {
          return 1;
        } else {
          return 0;
        }
      });
    }
  }
  return opListConfig;
}
