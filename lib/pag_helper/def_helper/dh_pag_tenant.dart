import 'package:flutter/material.dart';

import 'enum_helper.dart';

enum PagTenantLcStatus {
  onbarding('Onboarding', 'onb', Colors.lightGreenAccent),
  active('Active', 'act', Colors.teal),
  offboarding('Offboarding', 'offb', Colors.orange),
  terminated('Terminated', 'term', Colors.red),
  ;

  const PagTenantLcStatus(
    this.label,
    this.tag,
    this.color,
  );

  final String label;
  final String tag;
  final Color color;

  static PagTenantLcStatus? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagTenantLcStatus? byTag(String? tag) => enumByTag(
        tag,
        values,
      );
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
