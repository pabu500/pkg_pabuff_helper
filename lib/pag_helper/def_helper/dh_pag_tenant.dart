import 'package:flutter/material.dart';

import 'enum_helper.dart';

enum PagTenantLcStatus {
  onbarding('Onboarding', 'onb', 'onb', Colors.lightGreenAccent),
  normal('Normal', 'normal', 'norm', Colors.teal),
  offboarding('Offboarding', 'offb', 'offb', Colors.orange),
  terminated('Terminated', 'terminated', 'term', Colors.red),
  ;

  const PagTenantLcStatus(
    this.label,
    this.value, // the value that is stored in the database
    this.tag,
    this.color,
  );

  final String label;
  final String value;
  final String tag;

  final Color color;

  static PagTenantLcStatus? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagTenantLcStatus byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      normal;

  static PagTenantLcStatus byTag(String? tag) =>
      enumByTag(
        tag,
        values,
      ) ??
      normal;
}

T? enumByTag<T extends Enum>(String? tag, List<T> values) {
  if (tag == null) return null;
  for (var value in values) {
    if (value is PagTenantLcStatus && value.tag.replaceAll('.', '') == tag) {
      return value as T;
    }
  }
  return null;
}
