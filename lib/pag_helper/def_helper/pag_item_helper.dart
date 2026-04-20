import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_finance.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_org.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'enum_helper.dart';

enum PagItemKind {
  scope('Scope', Symbols.file_map_stack),
  device('Device', Symbols.home_iot_device),
  user('User', Symbols.person),
  role('Role', Symbols.badge),
  tenant('Tenant', Symbols.location_away),
  org('Organization', Symbols.corporate_fare),
  jobType('Job Type', Symbols.energy_program_time_used),
  jobTypeSub('Job Type Sub', Symbols.group),
  tariffPackage('Tariff Package', Symbols.price_change),
  tariffPackageType('Tariff Package Type', Symbols.price_check),
  bill('Bill', Symbols.request_quote),
  meterGroup('Meter Group', Symbols.atr),
  finance('Finance', Symbols.account_balance),
  ;

  const PagItemKind(
    this.label,
    this.iconData,
  );

  final String label;
  final IconData iconData;

  static PagItemKind? byLabel(String? label) =>
      enumByLabel(label, values, (e) => (e).label);
}

String? getItemTypeStr(dynamic itemType) {
  if (itemType == null) {
    return null;
  }
  if (itemType is PagDeviceCat) {
    // return getPagDeviceTypeStr(itemType);
    return itemType.name;
  } else if (itemType is PagScopeType) {
    return getPagScopeTypeStr(itemType);
  } else if (itemType is PagFinanceType) {
    return getPagFinanceTypeStr(itemType);
  } else if (itemType is PagOrgType) {
    return itemType.value;
  } else {
    throw Exception('Unsupported item type: ${itemType.runtimeType}');
  }
}

String? validateItemId(String? value) {
  if (value == null || value.isEmpty) {
    return 'required';
  }

  // must be a integer greater than 0
  int? intValue = int.tryParse(value);
  if (intValue == null || intValue <= 0) {
    return 'must be a integer greater than 0';
  }
  return null;
}

String? validateItemIdNotRequired(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  // must be a integer greater than 0
  int? intValue = int.tryParse(value);
  if (intValue == null || intValue <= 0) {
    return 'must be a integer greater than 0';
  }
  return null;
}
