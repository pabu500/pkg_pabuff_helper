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
