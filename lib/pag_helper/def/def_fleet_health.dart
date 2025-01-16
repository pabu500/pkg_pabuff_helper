import 'package:flutter/material.dart';

enum PagFleetHealthType {
  lrt('lrt_too_old', 'LRT', Colors.redAccent),
  unknown('unknown', '?', Colors.grey),
  ;

  final String label;
  final String tag;
  final Color color;

  const PagFleetHealthType(this.label, this.tag, this.color);

  static PagFleetHealthType byLabel(String? label) =>
      enumByLabel(label, values) ?? unknown;
}

T? enumByLabel<T extends Enum>(String? label, List<T> values) {
  return label == null ? null : values.asNameMap()[label];
}
