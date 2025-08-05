import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'enum_helper.dart';

enum PagFinanceType {
  soa('Statement of Account', 'soa', Symbols.contract),
  payment('Payment', 'pyt', Symbols.attach_money),
  ;

  const PagFinanceType(
    this.label,
    this.tag,
    this.iconData,
  );

  final String label;
  final String tag;
  final IconData iconData;

  static PagFinanceType byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).tag,
      ) ??
      soa;

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

String getPagFinanceTypeStr(dynamic itemType) {
  switch (itemType) {
    case PagFinanceType.soa:
      return PagFinanceType.soa.name;
    case PagFinanceType.payment:
      return PagFinanceType.payment.name;
    default:
      return '';
  }
}

enum PagPaymentLcStatus {
  posted('posted', 'Posted', 'pt', Colors.lightBlue),
  pending('matched', 'Matched', 'mt', Colors.teal),
  failed('released', 'Released', 'rl', Colors.orangeAccent),
  unknown('unknown', 'Unknown', 'un', Colors.grey),
  ;

  const PagPaymentLcStatus(this.value, this.label, this.tag, this.color);

  final String label;
  final String value;
  final String tag;
  final Color color;

  static PagPaymentLcStatus byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      unknown;
}
