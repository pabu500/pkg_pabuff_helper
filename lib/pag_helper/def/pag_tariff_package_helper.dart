import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'enum_helper.dart';

enum PagTariffPackageTypeCat {
  regular('Reg', 'regular', Colors.amberAccent),
  system('Sys', 'system', Colors.teal),
  ;

  const PagTariffPackageTypeCat(
    this.label,
    this.tag,
    this.color,
  );

  final String label;
  final String tag;
  final Color color;

  static PagTariffPackageTypeCat? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagTariffPackageTypeCat? byTag(String? tag) => enumByTag(
        tag,
        values,
      );
}

T? enumByTag<T extends Enum>(String? tag, List<T> values) {
  if (tag == null) return null;
  for (var value in values) {
    if (value is PagTariffPackageTypeCat &&
        value.tag.replaceAll('.', '') == tag) {
      return value as T;
    }
  }
  return null;
}
