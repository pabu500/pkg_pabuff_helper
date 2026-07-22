import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_finance.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_org.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_tariff_package.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_user.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../xt_ui/xt_globals.dart';
import 'dh_pag_acl.dart';
import 'dh_pag_bill.dart';
import 'dh_pag_tariff.dart';
import 'dh_pag_tenant.dart';
import 'enum_helper.dart';

enum PagItemKind {
  scope('Scope', 'scope', Symbols.file_map_stack),
  device('Device', 'device', Symbols.home_iot_device),
  user('User', 'user', Symbols.person),
  role('Role', 'role', Symbols.badge),
  tenant('Tenant', 'tenant', Symbols.location_away),
  org('Organization', 'org', Symbols.corporate_fare),
  jobType('Job Type', 'job_type', Symbols.energy_program_time_used),
  jobTypeSub('Job Type Sub', 'job_type_sub', Symbols.group),
  // tariffPackage('Tariff Package', 'tariff_package', Symbols.price_change),
  // tariffPackageType('Tariff Package Type', 'tariff_package_type', Symbols.price_check),
  bill('Bill', 'bill', Symbols.request_quote),
  meterGroup('Meter Group', 'meter_group', Symbols.atr),
  finance('Finance', 'finance', Symbols.account_balance),
  tariff('Tariff', 'tariff', Symbols.price_change);

  const PagItemKind(
    this.label,
    this.value,
    this.iconData,
  );

  final String label;
  final String value;
  final IconData iconData;

  static PagItemKind? byLabel(String? label) =>
      enumByLabel(label, values, (e) => (e).label);

  static PagItemKind? byValue(String? value) =>
      enumByLabel(value, values, (e) => (e).value);
}

// String? getItemTypeStr(dynamic itemType) {
//   if (itemType == null) {
//     return null;
//   }
//   if (itemType is PagDeviceCat) {
//     // return getPagDeviceTypeStr(itemType);
//     return itemType.name;
//   } else if (itemType is PagScopeType) {
//     return getPagScopeTypeStr(itemType);
//   } else if (itemType is PagFinanceType) {
//     // return getPagFinanceTypeStr(itemType);
//     return itemType.value;
//   } else if (itemType is PagOrgType) {
//     return itemType.value;
//   } else if (itemType is PagTariff) {
//     return itemType.value;
//   } else if (itemType is PagItemKind) {
//     return itemType.value;
//   } else {
//     throw Exception('Unsupported item type: ${itemType.runtimeType}');
//   }
// }

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

String? Function(String) getItemKindValidator(PagItemKind itemKind, String key,
    {bool isValueRequired = true, dynamic itemType}) {
  switch (itemKind) {
    case PagItemKind.user:
      return getUserValidator(key, isValueRequired: isValueRequired);
    case PagItemKind.tenant:
      return getTenantValidator(key, isValueRequired: isValueRequired);
    case PagItemKind.finance:
      return getFinanceValidator(key, itemType,
          isValueRequired: isValueRequired);
    case PagItemKind.scope:
      return getScopeValidator(key, isValueRequired: isValueRequired);
    default:
      dev.log('No validator found for item kind: $itemKind, key: $key');
      return (String value) {
        return null;
      };
  }
}

String? Function(String) getValidator(
    String? Function(String) validator, bool isValueRequired) {
  if (!isValueRequired) {
    return (String value) {
      if (value.isEmpty) {
        return null;
      }
      return validator(value);
    };
  } else {
    return validator;
  }
}

String getItemTypeValue(dynamic itemType) {
  if (itemType == null) {
    return '';
  }

  if (itemType is PagDeviceCat ||
      itemType is PagMeterCommType ||
      itemType is PagMeterPhaseType ||
      itemType is PagScopeType ||
      itemType is PagBillGenType ||
      itemType is PagBillingLcStatus ||
      itemType is PagBillPaymentStatus ||
      itemType is PagBillDueStatus ||
      itemType is PagItemKind ||
      itemType is PagTenantLcStatus ||
      itemType is PagTenantUnitType ||
      itemType is PagPaymentMethod ||
      itemType is PagTariff ||
      itemType is PagOrgType ||
      itemType is PagFinanceType ||
      itemType is PagPaymentLcStatus ||
      itemType is PaymentSoaType ||
      itemType is PagSoaEntryType ||
      itemType is PagPortalType ||
      itemType is PagRoleType ||
      itemType is PagInterestStartDateType ||
      itemType is PagPaymentOpType ||
      itemType is PagUserOpType ||
      itemType is PagScopeOpType) {
    return itemType.value ?? '';
  }

  throw Exception('Unsupported item type: ${itemType.runtimeType}');
}
