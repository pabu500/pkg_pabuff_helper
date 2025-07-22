import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'enum_helper.dart';

enum PagFinanceOps {
  postPayment('Post Payment', 'soa', Symbols.contract),
  matchPayment('Match Payment', 'pyt', Symbols.attach_money),
  unSupported('Unsupported', 'unsupported', Symbols.help);

  const PagFinanceOps(
    this.label,
    this.tag,
    this.iconData,
  );

  final String label;
  final String tag;
  final IconData iconData;

  static PagFinanceOps byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).tag,
      ) ??
      unSupported;

  static PagFinanceOps? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagFinanceOps? byTag(String? tag) => enumByTag(
        tag,
        values,
      );
}

T? enumByTag<T extends Enum>(String? tag, List<T> values) {
  if (tag == null) return null;
  for (var value in values) {
    if (value is PagFinanceOps && value.tag.replaceAll('.', '') == tag) {
      return value as T;
    }
  }
  return null;
}
