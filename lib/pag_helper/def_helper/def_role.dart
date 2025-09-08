import 'package:buff_helper/pag_helper/def_helper/enum_helper.dart';
import 'package:flutter/material.dart';

enum PagPortalType {
  pagConsole('pag-console', 'op', Colors.teal),
  pgEmsTp('pag-ems-tp', 'tp', Colors.purple),
  pgEvsCp('pag-evs-cp', 'cp', Colors.orange),
  none('none', 'none', Colors.grey),
  ;

  const PagPortalType(
    this.value,
    this.tag,
    this.color,
  );

  final String value;
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
