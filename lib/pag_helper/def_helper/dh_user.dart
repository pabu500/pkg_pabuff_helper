import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
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

String? Function(String) getUserValidator(String key,
    {bool isValueRequired = true}) {
  switch (key) {
    case 'username':
      return validateUsername;
    case 'initial_password':
      return validateInitialPassword;
    case 'fullname':
      return validateFullName;
    case 'email':
      return validateEmail;
    case 'contact_number':
      return isValueRequired ? validatePhone : validatePhoneNotRequired;
    case 'designation':
      return validateDesignation;
    case 'remark':
      return validateUserRemark;
    case 'auth_provider':
      return validateAuthProvider;
    case 'portal_type_str':
      return validatePortalTypeStr;
    case 'role_label_str':
      return validateRoleLabelStr;
    case 'tenant_label':
      return isValueRequired
          ? validateTenantLabel
          : validateTenantLabelNotRequired;
    case 'tenaant_account_number':
      return isValueRequired
          ? validateTenantAccountNumber
          : validateTenantAccountNumberNotRequired;
    case 'receive_billing_notification':
      return validateReceiveBillingNotification;
    case 'enabled':
      return validateEnabled;
    default:
      dev.log('No validator found for user key: $key');
      return (String? value) {
        return null;
      };
  }
}

// enabled must be either yes or no
String? validateEnabled(String? value) {
  if (value == null || value.isEmpty) {
    return 'required';
  }
  if (value != 'true' && value != 'false') {
    return 'must be either true or false';
  }
  return null;
}

// initial password must be at least 3 characters and at most 55 characters,
// must be alphanumeric
String? validateInitialPassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'required';
  }

  if (value.length < 3 || value.length > 55) {
    return 'must be between 3 and 55 characters';
  }

  final regex = RegExp(r'^[a-zA-Z0-9]+$');
  if (!regex.hasMatch(value)) {
    return 'only alphanumeric characters allowed';
  }

  return null;
}

String? validateReceiveBillingNotification(String? value) {
  if (value == null || value.isEmpty) {
    return 'required';
  }

  if (value != 'yes' && value != 'no') {
    return 'must be either yes or no';
  }
  return null;
}

// comma separated role labels, each label must be 3-20 characters, only alphanumeric, comma, space, dash and underscore allowed
String? validateRoleLabelStr(String? value) {
  if (value == null || value.isEmpty) {
    return 'required';
  }

  if (value.length < 3 || value.length > 20) {
    return 'must be between 3 and 20 characters';
  }

  //alphanumeric, comma, space, dash and underscore only
  final regex = RegExp(r'^[a-zA-Z0-9 ,_-]+$');
  if (!regex.hasMatch(value)) {
    return 'only alphanumeric, comma, space, dash and underscore allowed';
  }

  return null;
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
