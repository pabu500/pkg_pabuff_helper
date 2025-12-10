import 'package:flutter/material.dart';

import 'enum_helper.dart';

enum PagTariffPackageTypeCat {
  regular('Reg', 'regular', Colors.amberAccent),
  systemCycle('Sys Cycle', 'system_cycle', Colors.greenAccent),
  systemRate('Sys Rate', 'system_rate', Colors.teal),
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

enum PagInterestDuration {
  month('Month', 'month', Colors.amberAccent),
  annum('Annum', 'annum', Colors.greenAccent),
  ;

  const PagInterestDuration(
    this.label,
    this.tag,
    this.color,
  );

  final String label;
  final String tag;
  final Color color;

  static PagInterestDuration? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagInterestDuration? byTag(String? tag) => enumByTag(
        tag,
        values,
      );
}

String? validateInterestRate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Interest Rate is required.';
  }
  final rate = double.tryParse(value);
  if (rate == null || rate < 0) {
    return 'Please enter a valid non-negative number for Interest Rate.';
  }
  // 1 to 100 percent
  if (rate > 100) {
    return 'Interest Rate cannot exceed 100%.';
  }
  return null;
}

enum PagInterestStartDateType {
  dueDate('Due Date', 'due_date', 'due', Colors.teal),
  billDate('Bill Date', 'bill_date', 'bill', Colors.red),
  ;

  const PagInterestStartDateType(
    this.label,
    this.value,
    this.tag,
    this.color,
  );

  final String label;
  final String value;
  final String tag;
  final Color color;

  static PagInterestStartDateType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagInterestStartDateType? byTag(String? tag) => enumByTag(
        tag,
        values,
      );

  static PagInterestStartDateType? byValue(String? value) => enumByValue(
        value,
        values,
        (e) => (e).value,
      );
}
