import 'package:buff_helper/pag_helper/def_helper/enum_helper.dart';
import 'package:flutter/material.dart';

enum PagPortalType {
  pagConsole('pag-console', 'op', Colors.teal),
  emsTp('ems-tp', 'tp', Colors.purple),
  evsCp('evs-cp', 'cp', Colors.orange),
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

// T? enumByLabel<T extends Enum>(
//   String? label,
//   List<T> values,
// ) {
//   return label == null ? null : values.asNameMap()[label];
// }

// T? enumByLabel<T extends Enum>(
//   String? value,
//   List<T> values,
// ) {
//   if (value == null) return null;
//   for (var val in values) {
//     if (val is PagPortalType && val.value == value) {
//       return value as T;
//     }
//   }
//   return null;
// }
