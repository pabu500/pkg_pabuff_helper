import 'package:flutter/material.dart';

enum PagItemKind {
  // LOCATION,
  scope,
  device,
  user,
  tenant,
  jobType,
  jobTypeSub,
  // METER,
  // CONCENTRATOR,
  // GATEWAY,
  // CAMERA,
  // METER_GRROP,
  // SENSOR,
  // LOCK,
  // USER_GROUP,
  // TARIFF,
}

enum PagDeviceLsStatus {
  cip('Commission in Progress', 'cip', Colors.lime),
  normal('Noraml', 'norm.', Colors.lightGreen),
  maintenance('Maintenance', 'maint.', Colors.orangeAccent),
  dc('Decommissioned', 'dc', Colors.brown),
  mfd('Marked for Delete', 'mfd', Colors.redAccent),
  ;

  const PagDeviceLsStatus(
    this.label,
    this.tag,
    this.color,
  );

  final String label;
  final String tag;
  final Color color;

  static PagDeviceLsStatus byLabel(String? label) =>
      enumByLabel(
        label,
        values,
      ) ??
      normal;

  static PagDeviceLsStatus byTag(String? tag) =>
      enumByTag(
        tag,
        values,
      ) ??
      normal;
}

T? enumByLabel<T extends Enum>(
  String? label,
  List<T> values,
) {
  if (label == null) return null;
  for (var value in values) {
    if (value is PagDeviceLsStatus && value.label == label) {
      return value as T;
    }
  }
  return null;
}

T? enumByTag<T extends Enum>(
  String? tag,
  List<T> values,
) {
  if (tag == null) return null;
  for (var value in values) {
    if (value is PagDeviceLsStatus && value.tag.replaceAll('.', '') == tag) {
      return value as T;
    }
  }
  return null;
}
