import 'package:buff_helper/pag_helper/def_helper/enum_helper.dart';
import 'package:flutter/material.dart';

enum PagPortalType {
  pagConsole('pag-console', 'Ops Console', 'op', Colors.teal),
  pagConsoleApp('pag-console-app', 'Ops Console App', 'opapp', Colors.blue),
  pagCmApp('pag-cm-app', 'Ops CM App', 'cmapp', Colors.indigo),
  pagEmsTp('pag-ems-tp', 'EMS Tenant Portal', 'tp', Colors.purple),
  pagEvsCp('pag-evs-cp', 'EVS Consume Portal', 'cp', Colors.orange),
  none('none', 'None', 'none', Colors.grey),
  ;

  const PagPortalType(
    this.value,
    this.label,
    this.tag,
    this.color,
  );

  final String value;
  final String label;
  final String tag;
  final Color color;

  static PagPortalType byValue(String? value) =>
      enumByValue<PagPortalType>(
        value,
        values,
        (e) => e.value,
      ) ??
      none;
}

enum PagRoleType {
  admin('admin', 'Admin', 'admin', Colors.red),
  subAdmin('sub_admin', 'Sub Admin', 'subadmin', Colors.yellow),
  ops('ops', 'Ops', 'ops', Colors.teal),
  siteOps('site_ops', 'Site Ops', 'siteops', Colors.orange),
  billingOps('billing_ops', 'Billing Ops', 'billingops', Colors.indigo),
  tenant('tenant', 'EMS Tenant', 'tenant', Colors.purple),
  consumer('consumer', 'EVS Consumer', 'consumer', Colors.green),
  unknown('unknown', 'Unknown', 'unknown', Colors.grey),
  ;

  const PagRoleType(
    this.value,
    this.label,
    this.tag,
    this.color,
  );

  final String value;
  final String label;
  final String tag;
  final Color color;

  static PagRoleType byValue(String? value) =>
      enumByValue<PagRoleType>(
        value,
        values,
        (e) => e.value,
      ) ??
      unknown;
}

String? validateRoleTag(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'required';
  }

  // Allowed:
  // 2-8 chars
  // alphanumeric, underscore, dash
  final validCharacters = RegExp(
    r"""^[a-zA-Z0-9\-_]{2,8}$""",
  );

  if (!validCharacters.hasMatch(value)) {
    return 'must be 2-8 characters and can only contain letters, numbers, hyphens, and underscores';
  }

  return null;
}
