import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'dh_pag_item.dart';
import 'enum_helper.dart';

enum PagOrgType {
  bank('Bank', 'bank', 'bank', Symbols.account_balance),
  amgr('Asset Manager', 'amgr', 'amgr', Symbols.apartment),
  landlord('Landlord', 'landlord', 'landlord', Symbols.home_work),
  none('None', 'none', 'none', Symbols.block);

  const PagOrgType(
    this.label,
    this.value,
    this.tag,
    this.iconData,
  );

  final String label;
  final String value;
  final String tag;
  final IconData iconData;

  static PagOrgType byValue(String? value) =>
      enumByValue(
        value,
        values,
        (e) => (e).value,
      ) ??
      none;

  static PagOrgType byLabel(String? label) =>
      enumByLabel(
        label,
        values,
        (e) => (e).label,
      ) ??
      none;

  static PagOrgType byTag(String? tag) =>
      enumByTag(
        tag,
        values,
        (e) => (e).tag,
      ) ??
      none;
}

String getPagOrgTypeStr(dynamic itemType) {
  switch (itemType) {
    case PagOrgType.amgr:
      return PagOrgType.amgr.value;
    case PagOrgType.landlord:
      return PagOrgType.landlord.value;
    default:
      return '';
  }
}

String? validateBankCode(String? value) {
  if (value == null || value.isEmpty) {
    return 'Bank code is required';
  }
  if (value.length > 20) {
    return 'Bank code must be at most 20 characters';
  }
  return null;
}

String? validateBranchCode(String? value) {
  if (value == null || value.isEmpty) {
    return 'Branch code is required';
  }
  if (value.length > 20) {
    return 'Branch code must be at most 20 characters';
  }
  return null;
}

String? validateSwiftCode(String? value) {
  if (value == null || value.isEmpty) {
    return 'SWIFT code is required';
  }
  if (value.length > 20) {
    return 'SWIFT code must be at most 20 characters';
  }
  return null;
}

String? validateBankTag(String? value) {
  if (value != null && value.length > 8) {
    return 'Bank tag must be at most 8 characters';
  }
  return null;
}

String? Function(String) getOrgValidator(String key, dynamic itemType,
    {bool isValueRequired = true}) {
  switch (itemType) {
    case PagOrgType.amgr:
      return getAmgrValidator(key, isValueRequired: isValueRequired);
    case PagOrgType.landlord:
      return getLandlordValidator(key, isValueRequired: isValueRequired);
    case PagOrgType.bank:
      return getBankValidator(key, isValueRequired: isValueRequired);
    default:
      dev.log('No validator found for key: $key');
      return (String? value) {
        return null;
      };
  }
}

String? Function(String) getAmgrValidator(String key,
    {bool isValueRequired = true}) {
  switch (key) {
    case 'label':
      return getValidator(validateItemLabel, isValueRequired);
    case 'company_reg_number':
      return getValidator(validateBankAccountNumber, isValueRequired);
    case 'gst_reg_number':
      return getValidator(validateBankAccountNumber, isValueRequired);
    case 'uen':
      return getValidator(validateBankAccountNumber, isValueRequired);
    case 'company_trading_name':
      return getValidator(validateCompanyTradingName, isValueRequired);
    case 'address_line_1':
      return getValidator(validateBillingAddressLine1, isValueRequired);
    case 'address_line_2':
      return getValidator(validateBillingAddressLine2, isValueRequired);
    case 'address_line_3':
      return getValidator(validateBillingAddressLine3, isValueRequired);
    default:
      dev.log('No validator found for resource key: $key');
      return (String value) {
        return null;
      };
  }
}

String? Function(String) getLandlordValidator(String key,
    {bool isValueRequired = true}) {
  switch (key) {
    case 'label':
      return getValidator(validateItemLabel, isValueRequired);
    case 'bank_account_util':
      return getValidator(validateBankAccountNumber, isValueRequired);
    case 'audit_fee':
    case 'audit_fee_ftf':
    case 'metering_billing_fee':
    case 'metering_billing_fee_coc_mss_only':
    case 'metering_billing_fee_vacant':
    case 'metering_billing_fee_non_coc':
    case 'consultancy_fee':
    case 'management_fee':
      return getValidator(validateFee, isValueRequired);
    default:
      dev.log('No validator found for resource key: $key');
      return (String value) {
        return null;
      };
  }
}

String? validateFee(String? value) {
  if (value == null || value.isEmpty) {
    return 'Fee is required';
  }
  final fee = double.tryParse(value);
  if (fee == null) {
    return 'Fee must be a valid number';
  }
  if (fee < 0) {
    return 'Fee must be non-negative';
  }
  return null;
}

String? Function(String) getBankValidator(String key,
    {bool isValueRequired = true}) {
  switch (key) {
    case 'label':
      return getValidator(validateItemLabel, isValueRequired);
    case 'bank_code':
      return getValidator(validateBankCode, isValueRequired);
    case 'swift_code':
      return getValidator(validateSwiftCode, isValueRequired);
    case 'bank_tag':
      return getValidator(validateBankTag, isValueRequired);
    default:
      dev.log('No validator found for resource key: $key');
      return (String value) {
        return null;
      };
  }
}
