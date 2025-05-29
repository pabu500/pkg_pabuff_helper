import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'enum_helper.dart';

enum PagTariffPackageType {
  ftf('FTF', 'ftf', Colors.amberAccent),
  spLt('SP LT', 'sp_lt', Colors.teal),
  ;

  const PagTariffPackageType(
    this.label,
    this.tag,
    this.color,
  );

  final String label;
  final String tag;
  final Color color;

  static PagTariffPackageType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagTariffPackageType? byTag(String? tag) => enumByTag(
        tag,
        values,
      );
}

T? enumByTag<T extends Enum>(String? tag, List<T> values) {
  if (tag == null) return null;
  for (var value in values) {
    if (value is PagTariffPackageType && value.tag.replaceAll('.', '') == tag) {
      return value as T;
    }
  }
  return null;
}
