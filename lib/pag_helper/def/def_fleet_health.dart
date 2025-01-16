import 'package:buff_helper/xt_ui/style/evs2_colors.dart';
import 'package:flutter/material.dart';

enum PagFleetHealthType {
  lrt('lrt_too_old', 'LRT', pag2),
  unknown('unknown', '?', Colors.grey),
  ;

  final String label;
  final String tag;
  final Color color;

  const PagFleetHealthType(this.label, this.tag, this.color);

  static PagFleetHealthType byLabel(String? label) =>
      enumByLabel(label, values, (e) => (e).label) ?? unknown;

  // static PagFleetHealthType byLabel(String? label) =>
  //     enumByLabel(label, values) ?? unknown;
}

// T? enumByLabel<T extends Enum>(String? label, List<T> values) {
//   return label == null ? null : values.asNameMap()[label];
// }

enum PagFleetHealthStatus {
  normal('normal', '  ', Colors.green),
  warning('warning', 'Warning', Colors.orange),
  lrtTooOld('lrt_too_old', '  ', Colors.redAccent),
  unknown('unknown', '--', Colors.grey),
  ;

  final String label;
  final String tag;
  final Color color;

  const PagFleetHealthStatus(this.label, this.tag, this.color);

  // static PagFleetHealthStatus byLabel(String? label) =>
  //     enumByLabel(label, values) ?? unknown;
  static PagFleetHealthStatus byLabel(String? label) =>
      enumByLabel(label, values, (e) => (e).label) ?? unknown;
}

T? enumByLabel<T extends Enum>(
    String? label, List<T> values, String Function(T) labelSelector) {
  if (label == null) return null;
  for (T value in values) {
    if (labelSelector(value) == label) {
      return value;
    }
  }
  return null;
}
