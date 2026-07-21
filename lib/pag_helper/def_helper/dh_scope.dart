import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../model/list/mdl_list_col_controller.dart';
import '../model/scope/mdl_pag_building_profile.dart';
import '../model/scope/mdl_pag_location_group_profile.dart';
import '../model/scope/mdl_pag_site_group_profile.dart';
import '../model/scope/mdl_pag_site_profile.dart';
import 'enum_helper.dart';
import 'pag_item_helper.dart';

enum PagScopeType {
  project('Project', 'project', Symbols.flag),
  siteGroup('Site Group', 'site_group', Symbols.workspaces),
  site('Site', 'site', Symbols.home_pin),
  building('Building', 'building', Symbols.domain),
  locationGroup('Location Group', 'location_group', Symbols.group_work),
  location('Location', 'location', Symbols.location_on),
  none('None', 'none', Symbols.help);

  const PagScopeType(
    this.label,
    this.value,
    this.iconData,
  );

  final String label;
  final String value;
  final IconData iconData;

  static PagScopeType byLabel(String? label) =>
      enumByLabel(label, values, (e) => e.label) ?? none;

  static PagScopeType byValue(String? value) =>
      enumByValue(value, values, (e) => e.value) ?? none;
}

// T? enumByLabel<T extends Enum>(
//   String? label,
//   List<T> values,
// ) {
//   if (label == null) return null;
//   for (var value in values) {
//     if (value is PagScopeType && value.label == label) {
//       return value as T;
//     }
//   }
//   return null;
// }

// T? enumByValue<T extends Enum>(String? value, List<T> values, String Function(T) getValue) {
//   if (value == null) return null;
//   for (var enumValue in values) {
//     if (getValue(enumValue) == value) {
//       return enumValue;
//     }
//   }
//   return null;
// }

PagScopeType getChildScopeType(PagScopeType parentScopeType) {
  switch (parentScopeType) {
    case PagScopeType.project:
      return PagScopeType.siteGroup;
    case PagScopeType.siteGroup:
      return PagScopeType.site;
    case PagScopeType.site:
      return PagScopeType.building;
    case PagScopeType.building:
      return PagScopeType.locationGroup;
    case PagScopeType.locationGroup:
      return PagScopeType.location;
    case PagScopeType.location:
      return PagScopeType.none;
    case PagScopeType.none:
      return PagScopeType.none;
  }
}

bool isSmallerScope(PagScopeType scopeType1, PagScopeType scopeType2) {
  return scopeType1.index > scopeType2.index;
}

Widget getScopeIcon(BuildContext ctx, PagScopeType scopeType,
    {double size = 24}) {
  return Icon(
    scopeType.iconData,
    size: size,
    color: Theme.of(ctx).hintColor,
  );
}

String getPagScopeTypeStr(dynamic itemType) {
  switch (itemType) {
    case PagScopeType.project:
      return 'project';
    case PagScopeType.siteGroup:
      return 'siteGroup';
    case PagScopeType.site:
      return 'site';
    case PagScopeType.building:
      return 'building';
    case PagScopeType.locationGroup:
      return 'locationGroup';
    case PagScopeType.location:
      return 'location';
    default:
      return '';
  }
}

String? validateLabelScope(String val, {PagScopeType? selectedScopeType}) {
  if (val.trim().isEmpty) {
    return 'required';
  }

  // validate alphanumeric, _, -, #, ,, &, slash, back slash and dash, space,
  // and minimum 5 characters
  String pattern = r"^[a-zA-Z0-9/_ \-,#&().']{3,255}$";
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return 'alphanumeric, space, /, -, ,, ., (), # only and length 3-255';
  }
  //must contain -, _, or space
  if (false) {
    if (!val.contains('-') && !val.contains('_') && !val.contains(' ')) {}
    return 'must contain at least one of these characters: space, -, _';
  }
  return null;
}

Widget getScopeLabel(BuildContext context, MdlPagScope scope) {
  BoxDecoration boxDecoration = BoxDecoration(
    border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
    borderRadius: BorderRadius.circular(5),
  );
  BoxDecoration boxDecorationLeaf = BoxDecoration(
    border: Border.all(color: Theme.of(context).hintColor, width: 1.2),
    borderRadius: BorderRadius.circular(5),
  );
  List<Map<String, dynamic>> scopeChain = scope.getScopeChain();
  List<Widget> scopeWidgets = [];

  PagScopeType scopeType = scope.getScopeType();
  PagScopeType leafScopeType = scopeChain.last['type'];

  for (var item in scopeChain) {
    PagScopeType chainScopeType = item['type'];
    bool isLeaf = chainScopeType == leafScopeType;

    // only show the leaf scope for site group, site, and building
    if (scopeType == PagScopeType.siteGroup ||
        scopeType == PagScopeType.site ||
        scopeType == PagScopeType.building) {
      if (!isLeaf) {
        continue;
      }
    }

    // show up to the building level for location group and location
    if (scopeType == PagScopeType.locationGroup ||
        scopeType == PagScopeType.location) {
      if (chainScopeType == PagScopeType.siteGroup ||
          chainScopeType == PagScopeType.site) {
        continue;
      }
    }

    String itemGroupScopeLabel = item['label'];
    Widget scopeIcon = getScopeIcon(context, chainScopeType, size: 21);

    scopeWidgets.add(
      Container(
        decoration: isLeaf ? boxDecorationLeaf : boxDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            scopeIcon,
            horizontalSpaceTiny,
            Text(itemGroupScopeLabel,
                style: isLeaf
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : null),
          ],
        ),
      ),
    );
    if (!isLeaf) {
      scopeWidgets.add(Icon(Symbols.chevron_right,
          size: 18, color: Theme.of(context).hintColor));
    }
  }

  return Row(children: scopeWidgets);
}

enum PagScopeOpType {
  onboardingLocation('Onboard Location', 'onboard_location', 'onb'),
  onboardingLocationGroup(
      'Onboard Location Group', 'onboard_location_group', 'onb'),
  update('Update', 'update', 'upd'),
  none('None', 'none', 'none');

  final String label;
  final String value;
  final String tag;

  const PagScopeOpType(
    this.label,
    this.value,
    this.tag,
  );

  static PagScopeOpType byLabel(String? label) =>
      enumByLabel(label, values, (e) => e.label) ?? none;
  static PagScopeOpType byValue(String? value) =>
      enumByValue(value, values, (e) => e.value) ?? none;
  static PagScopeOpType byTag(String? tag) =>
      enumByValue(tag, values, (e) => e.tag) ?? none;
}

final List<Map<String, dynamic>> listConfigScopeOpsBase = [
  {
    // 'col_key': 'scope_sn',
    // 'title': 'S/N',
    // 'col_type': 'string',
    // 'width': 200,
    // 'is_mapping_required': true,
    // 'validator': validateSerialNumber,
  },
];

final List<Map<String, dynamic>> listConfigScopeOpOnbLocation = [
  {
    'col_key': 'location_label',
    'title': 'Location Label',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': true,
    'validator': validateLabelScope,
  },
  {
    'col_key': 'location_group_label',
    'title': 'Location Group Label',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateLabelScope,
  },
  {
    'col_key': 'building_label',
    'title': 'Building Label',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateLabelScope,
  },
];
final List<Map<String, dynamic>> listConfigScopeOpOnbLocationGroup = [
  {
    'col_key': 'location_group_label',
    'title': 'Location Group Label',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': true,
    'validator': validateLabelScope,
  },
  {
    'col_key': 'building_label',
    'title': 'Building Label',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateLabelScope,
  },
  {
    'col_key': 'site_label',
    'title': 'Site Label',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateLabelScope,
  },
];

List<Map<String, dynamic>> getScopeOpsConfigList(PagScopeOpType opType) {
  final List<Map<String, dynamic>> list = [];
  switch (opType) {
    case PagScopeOpType.onboardingLocation:
      list.addAll(listConfigScopeOpsBase + listConfigScopeOpOnbLocation);
      break;
    case PagScopeOpType.onboardingLocationGroup:
      list.addAll(listConfigScopeOpsBase + listConfigScopeOpOnbLocationGroup);
      break;
    default:
      list.addAll(listConfigScopeOpsBase);
  }
  //remove empty maps
  list.removeWhere((map) => map.isEmpty);
  return list;
}

({
  MdlPagSiteGroupProfile? siteGroupProfile,
  MdlPagSiteProfile? siteProfile,
  MdlPagBuildingProfile? buildingProfile,
  MdlPagLocationGroupProfile? locationGroupProfile,
  MdlListColController? siteGroupColController,
  MdlListColController? siteColController,
  MdlListColController? buildingColController,
  MdlListColController? locationGroupColController,
}) iniScopesPreload(
  MdlPagScopeProfile scopeProfile,
  List<MdlListColController> listColControllerList,
  TextEditingController siteGroupController,
  TextEditingController siteController,
  TextEditingController buildingController,
  TextEditingController locationGroupController,
) {
  final siteGroupProfile = scopeProfile.siteGroupProfile;
  final siteProfile = scopeProfile.siteProfile;
  final buildingProfile = scopeProfile.buildingProfile;
  final locationGroupProfile = scopeProfile.locationGroupProfile;

  MdlListColController? siteGroupColController;
  MdlListColController? siteColController;
  MdlListColController? buildingColController;
  MdlListColController? locationGroupColController;

  for (final colController in listColControllerList) {
    switch (colController.colKey) {
      case 'site_group_label':
        siteGroupColController = colController;
        colController.filterWidgetController = siteGroupController;
        break;

      case 'site_label':
        siteColController = colController;
        colController.filterWidgetController = siteController;
        break;

      case 'building_label':
        buildingColController = colController;
        colController.filterWidgetController = buildingController;
        break;

      case 'location_group_label':
        locationGroupColController = colController;
        colController.filterWidgetController = locationGroupController;
        break;
    }
  }

  scopeProfile.projectProfile?.bindFilterColController(
    siteGroupColController,
    defaultSiteGroupProfile: siteGroupProfile,
    limitToDefault: true,
  );

  siteGroupProfile?.bindFilterColController(
    siteColController,
    defaultSiteProfile: siteProfile,
    limitToDefault: true,
  );

  siteProfile?.bindFilterColController(
    buildingColController,
    defaultBuildingProfile: buildingProfile,
    limitToDefault: true,
  );

  buildingProfile?.bindFilterColController(
    locationGroupColController,
    defaultLocationGroupProfile: locationGroupProfile,
    limitToDefault: true,
  );

  return (
    siteGroupProfile: siteGroupProfile,
    siteProfile: siteProfile,
    buildingProfile: buildingProfile,
    locationGroupProfile: locationGroupProfile,
    siteGroupColController: siteGroupColController,
    siteColController: siteColController,
    buildingColController: buildingColController,
    locationGroupColController: locationGroupColController,
  );
}

String? Function(String) getScopeValidator(String key,
    {bool isValueRequired = true}) {
  switch (key) {
    case 'label':
      return getValidator(validateLabelScope, isValueRequired);
    case 'location_group_label':
      return getValidator(validateLabelScope, isValueRequired);
    case 'building_label':
      return getValidator(validateLabelScope, isValueRequired);
    case 'site_label':
      return getValidator(validateLabelScope, isValueRequired);
    case 'site_group_label':
      return getValidator(validateLabelScope, isValueRequired);
    default:
      dev.log('No validator found for key: $key');
      return (String? value) {
        return null;
      };
  }
}
