import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum PagDeviceType {
  meter('Meter', Symbols.speed),
  sensor('Sensor', Symbols.sensors),
  lock('Lock', Symbols.lock),
  camera('Camera', Symbols.videocam),
  gateway('Gateway', Symbols.switch_access),
  none('None', Symbols.help);

  const PagDeviceType(
    this.label,
    this.iconData,
  );

  final String label;
  final IconData iconData;

  static PagDeviceType byLabel(String? label) =>
      enumByLabel(label, values) ?? none;
}

T? enumByLabel<T extends Enum>(String? label, List<T> values) {
  return label == null ? null : values.asNameMap()[label];
}
