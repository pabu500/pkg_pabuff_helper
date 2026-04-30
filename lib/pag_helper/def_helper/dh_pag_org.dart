import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      none;

  static PagOrgType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagOrgType? byTag(String? tag) => enumByTag(
        tag,
        values,
        (e) => (e).tag,
      );
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
