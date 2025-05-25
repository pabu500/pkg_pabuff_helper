import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'enum_helper.dart';

enum PagItemKind {
  scope('Scope', Symbols.file_map_stack),
  device('Device', Symbols.home_iot_device),
  user('User', Symbols.person),
  role('Role', Symbols.badge),
  tenant('Tenant', Symbols.location_away),
  jobType('Job Type', Symbols.energy_program_time_used),
  jobTypeSub('Job Type Sub', Symbols.group),
  tariffPackage('Tariff Package', Symbols.price_change),
  bill('Bill', Symbols.request_quote),
  ;

  const PagItemKind(
    this.label,
    this.iconData,
  );

  final String label;
  final IconData iconData;

  static PagItemKind? byLabel(String? label) =>
      enumByLabel(label, values, (e) => (e).label);
}

enum PagDeviceLsStatus {
  cip('Commission in Progress', 'cip', Colors.lime),
  normal('Noraml', 'norm.', Colors.lightGreen),
  maintenance('Maintenance', 'maint.', Colors.orangeAccent),
  dc('Decommissioned', 'dc', Colors.brown),
  mfd('Marked for Delete', 'mfd', Colors.redAccent),
  ;

  const PagDeviceLsStatus(
    this.label,
    this.tag,
    this.color,
  );

  final String label;
  final String tag;
  final Color color;

  static PagDeviceLsStatus byLabel(String? label) =>
      enumByLabel(
        label,
        values,
        (e) => (e).label,
      ) ??
      normal;

  static PagDeviceLsStatus byTag(String? tag) =>
      enumByTag(
        tag,
        values,
      ) ??
      normal;
}

// T? enumByLabel<T extends Enum>(
//   String? label,
//   List<T> values,
// ) {
//   if (label == null) return null;
//   for (var value in values) {
//     if (value is PagDeviceLsStatus && value.label == label) {
//       return value as T;
//     }
//   }
//   return null;
// }

T? enumByTag<T extends Enum>(
  String? tag,
  List<T> values,
) {
  if (tag == null) return null;
  for (var value in values) {
    if (value is PagDeviceLsStatus && value.tag.replaceAll('.', '') == tag) {
      return value as T;
    }
  }
  return null;
}
