import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'enum_helper.dart';

enum PagFinanceOpType {
  postPayment('Post Payment', 'soa', Symbols.contract),
  matchPayment('Match Payment', 'pyt', Symbols.attach_money),
  unSupported('Unsupported', 'unsupported', Symbols.help);

  const PagFinanceOpType(
    this.label,
    this.tag,
    this.iconData,
  );

  final String label;
  final String tag;
  final IconData iconData;

  static PagFinanceOpType byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).tag,
      ) ??
      unSupported;

  static PagFinanceOpType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagFinanceOpType? byTag(String? tag) => enumByTag(
        tag,
        values,
      );
}

T? enumByTag<T extends Enum>(String? tag, List<T> values) {
  if (tag == null) return null;
  for (var value in values) {
    if (value is PagFinanceOpType && value.tag.replaceAll('.', '') == tag) {
      return value as T;
    }
  }
  return null;
}

enum PagLinkOpType {
  gatewayToDevice,
  none,
}
