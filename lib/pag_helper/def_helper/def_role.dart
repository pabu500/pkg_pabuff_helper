import 'package:flutter/material.dart';

enum PagPortalType {
  pagConsole('pag-console', 'op', Colors.teal),
  emsTp('ems-tp', 'tp', Colors.purple),
  evsCp('evs-cp', 'cp', Colors.orange),
  none('none', 'none', Colors.grey),
  ;

  const PagPortalType(
    this.label,
    this.tag,
    this.color,
  );

  final String label;
  final String tag;
  final Color color;

  static PagPortalType byLabel(String? label) =>
      enumByLabel(
        label,
        values,
      ) ??
      none;
}

// T? enumByLabel<T extends Enum>(
//   String? label,
//   List<T> values,
// ) {
//   return label == null ? null : values.asNameMap()[label];
// }

T? enumByLabel<T extends Enum>(
  String? label,
  List<T> values,
) {
  if (label == null) return null;
  for (var value in values) {
    if (value is PagPortalType && value.label == label) {
      return value as T;
    }
  }
  return null;
}
