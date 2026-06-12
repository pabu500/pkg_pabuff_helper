import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_finance.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_org.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_user.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../xt_ui/xt_globals.dart';
import 'dh_pag_tariff.dart';
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
  // tariffPackage('Tariff Package', Symbols.price_change),
  // tariffPackageType('Tariff Package Type', Symbols.price_check),
  bill('Bill', Symbols.request_quote),
  meterGroup('Meter Group', Symbols.atr),
  finance('Finance', Symbols.account_balance),
  tariff('Tariff', Symbols.price_change);

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
    // return getPagFinanceTypeStr(itemType);
    return itemType.value;
  } else if (itemType is PagOrgType) {
    return itemType.value;
  } else if (itemType is PagTariff) {
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

String? validateItemLabel(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'required';
  }

  if (value.length > maxFullNameLength) {
    return 'must be at most $maxFullNameLength characters';
  }

  // Allowed:
  // alphanumeric, space, hyphen, underscore,
  // parentheses, period, comma, slash, ampersand, plus,
  // hash, colon, semicolon, double quote, single quote
  final validCharacters = RegExp(
    r"""^[a-zA-Z0-9\s\-_().,/&+#:;"']+$""",
  );

  if (!validCharacters.hasMatch(value)) {
    return 'contains invalid characters';
  }

  return null;
}

String? Function(String?)? getValidator(PagItemKind itemKind, String key) {
  switch (itemKind) {
    case PagItemKind.user:
      return getUserValidator(key);
    default:
      dev.log('No validator found for item kind: $itemKind, key: $key');
      return null;
  }
}
