import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../xt_ui/util/xt_util_InputFieldValidator.dart';
import 'enum_helper.dart';

enum PagUserOpType {
  onboarding('Onboarding', 'onb', 'onb', Symbols.person_add),
  none('None', 'none', 'none', Symbols.block),
  ;

  const PagUserOpType(
    this.label,
    this.value,
    this.tag,
    this.iconData,
  );

  final String label;
  final String value;
  final String tag;
  final IconData iconData;

  static PagUserOpType byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      none;

  static PagUserOpType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagUserOpType? byTag(String? tag) => enumByTag(
        tag,
        values,
        (e) => (e).tag,
      );
}

String? Function(String?)? getUserValidator(String key) {
  switch (key) {
    case 'username':
      return validateUsername;
    case 'fullname':
      return validateFullName;
    case 'email':
      return validateEmail;
    case 'contact_number':
      return validatePhone;
    case 'designation':
      return validateDesignation;
    case 'remark':
      return validateUserRemark;
    case 'auth_provider':
      return validateAuthProvider;
    case 'portal_type_str':
      return validatePortalTypeStr;
    default:
      return null;
  }
}

String? validatePortalTypeStr(String? value) {
  if (value == null || value.isEmpty) {
    return 'required';
  }

  List<String> allowedValues = ['pag-console', 'ems-tp', 'evs-cp'];
  if (!allowedValues.contains(value)) {
    return 'must be either ${allowedValues.join(", ")}';
  }
  return null;
}

String? validateAuthProvider(String? value) {
  if (value == null || value.isEmpty) {
    return 'required';
  }

  if (value != 'local' && value != 'microsoft') {
    return 'must be either local or microsoft';
  }
  return null;
}

String? validateDesignation(String? value) {
  if (value == null) {
    return null;
  }

  if (value != null && value.length > 55) {
    return 'Designation must be at most 55 characters';
  }
  return null;
}

String? validateUserRemark(String? value) {
  if (value == null) {
    return null;
  }

  if (value != null && value.length > 55) {
    return 'Remark must be at most 55 characters';
  }
  return null;
}
