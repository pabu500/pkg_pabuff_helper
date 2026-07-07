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

  static PagTariffPackageTypeCat? byTag(String? tag) =>
      enumByTag(tag, values, (e) => (e).tag);
}

// T? enumByTag<T extends Enum>(String? tag, List<T> values) {
//   if (tag == null) return null;
//   for (var value in values) {
//     if (value is PagTariffPackageTypeCat &&
//         value.tag.replaceAll('.', '') == tag) {
//       return value as T;
//     }
//   }
//   return null;
// }

enum PagInterestDurationType {
  month('Month', 'month', Colors.amberAccent),
  annum('Annum', 'annum', Colors.green),
  ;

  const PagInterestDurationType(
    this.label,
    this.tag,
    this.color,
  );

  final String label;
  final String tag;
  final Color color;

  static PagInterestDurationType? byValue(String? value) => enumByValue(
        value,
        values,
        (e) => (e).tag,
      );

  static PagInterestDurationType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagInterestDurationType? byTag(String? tag) => enumByTag(
        tag,
        values,
        (e) => (e).tag,
      );
}

Widget getInterestDurationTypeTag(PagInterestDurationType type) {
  return Tooltip(
    message: 'Interest Duration Type: ${type.label}',
    waitDuration: const Duration(milliseconds: 500),
    child: Container(
      decoration: BoxDecoration(
        color: type.color,
        borderRadius: BorderRadius.circular(5.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Text(type.tag),
    ),
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
  dueDate('Due Date', 'due_date', 'duedate', Colors.teal),
  billDate('Bill Date', 'bill_date', 'billdate', Colors.purpleAccent),
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

  static PagInterestStartDateType? byTag(String? tag) =>
      enumByTag(tag, values, (e) => (e).tag);

  static PagInterestStartDateType? byValue(String? value) => enumByValue(
        value,
        values,
        (e) => (e).value,
      );
}

Widget getInterestStartDateTypeTag(PagInterestStartDateType type) {
  return Tooltip(
    message: 'Interest Start Date Type: ${type.label}',
    waitDuration: const Duration(milliseconds: 500),
    child: Container(
      decoration: BoxDecoration(
        color: type.color,
        borderRadius: BorderRadius.circular(5.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Text(type.tag),
    ),
  );
}
