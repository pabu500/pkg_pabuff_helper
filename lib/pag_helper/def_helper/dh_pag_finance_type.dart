import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'enum_helper.dart';

enum PagFinanceType {
  soa('Statement of Account', 'SoA', Symbols.contract),
  ;

  const PagFinanceType(
    this.label,
    this.tag,
    this.iconData,
  );

  final String label;
  final String tag;
  final IconData iconData;

  static PagFinanceType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagFinanceType? byTag(String? tag) => enumByTag(
        tag,
        values,
      );
}

T? enumByTag<T extends Enum>(String? tag, List<T> values) {
  if (tag == null) return null;
  for (var value in values) {
    if (value is PagFinanceType && value.tag.replaceAll('.', '') == tag) {
      return value as T;
    }
  }
  return null;
}
