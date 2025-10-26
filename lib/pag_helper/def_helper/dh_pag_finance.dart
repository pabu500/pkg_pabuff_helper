import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'enum_helper.dart';

enum PagFinanceType {
  tenantSoa('Statement of Account', 'tenant_soa', 'soa', Symbols.contract),
  payment('Payment', 'payment', 'pyt', Symbols.attach_money),
  paymentApply('Payment Apply', 'payment_apply', 'pya', Symbols.bucket_check),
  ;

  const PagFinanceType(
    this.label,
    this.value,
    this.tag,
    this.iconData,
  );

  final String label;
  final String value;
  final String tag;
  final IconData iconData;

  static PagFinanceType byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).tag,
      ) ??
      tenantSoa;

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
    case PagFinanceType.tenantSoa:
      return PagFinanceType.tenantSoa.name;
    case PagFinanceType.payment:
      return PagFinanceType.payment.name;
    default:
      return '';
  }
}

enum PagPaymentLcStatus {
  posted('posted', 'Posted', 'pt', Colors.lightBlue),
  matched('matched', 'Matched', 'mt', Colors.teal),
  released('released', 'Released', 'rl', Colors.orangeAccent),
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

Widget getPaymentLcStatusTagWidget(
  BuildContext ctx,
  PagPaymentLcStatus status, {
  TextStyle? style,
}) {
  Color bgColor = status.color;
  return Container(
    decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: Theme.of(ctx).hintColor,
        )),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    child: Text(
      status.tag,
      style: style ??
          const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
          ),
    ),
  );
}

enum PagSoaEntryType {
  initialBalance('Initial Balance', 'initial_balance', 'init', Colors.teal),
  tenantSoa('Bill', 'bill', 'bill', Colors.deepOrangeAccent),
  payment('Payment', 'payment', 'pmt', Colors.green),
  paymentApply('Payment Apply', 'payment_apply', 'pya', Colors.orangeAccent),
  adjustment('Adjustment', 'adjustment', 'adj', Colors.blueAccent),
  ;

  const PagSoaEntryType(
    this.label,
    this.value,
    this.tag,
    this.color,
  );

  final String label;
  final String value;
  final String tag;
  final Color color;

  static PagSoaEntryType byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      tenantSoa;

  static PagSoaEntryType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagSoaEntryType? byTag(String? tag) => enumByTag(
        tag,
        values,
      );
}
