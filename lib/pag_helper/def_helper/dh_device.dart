import 'package:buff_helper/up_helper/helper/device_def.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum PagDeviceCat {
  meter('Meter', 'meter', 'm', Symbols.speed),
  meterGroup('Meter Group', 'meter_group', 'mg', Symbols.graph_6),
  sensor('Sensor', 'sensor', 'ss', Symbols.sensors),
  lock('Lock', 'lock', 'lk', Symbols.lock),
  camera('Camera', 'camera', 'cam', Symbols.videocam),
  gateway('Gateway', 'gateway', 'gw', Symbols.switch_access),
  mcu('MCU', 'mcu', 'mcu', Symbols.memory),
  motherboard('Motherboard', 'motherboard', 'mb', Symbols.developer_board),
  none('None', 'none', 'non', Symbols.help);

  const PagDeviceCat(
    this.label,
    this.value,
    this.tag,
    this.iconData,
  );

  final String label;
  final String value; // the value that is stored in the database
  final String tag; // a short tag for the device category
  final IconData iconData;

  static PagDeviceCat byLabel(String? label) =>
      enumByLabel(label, values) ?? none;

  static PagDeviceCat byValue(String? value) =>
      enumByValue(value, values) ?? none;
}

T? enumByLabel<T extends Enum>(String? label, List<T> values) {
  if (label == null) return null;
  for (var item in values) {
    if (item is PagDeviceCat && item.label.replaceAll('.', '') == label) {
      return item as T;
    }
  }
  return null;
}

T? enumByValue<T extends Enum>(String? value, List<T> values) {
  if (value == null) return null;
  for (var item in values) {
    if (item is PagDeviceCat && item.value.replaceAll('.', '') == value) {
      return item as T;
    }
  }
  return null;
}

T? enumByTag<T extends Enum>(String? tag, List<T> values) {
  if (tag == null) return null;
  for (var value in values) {
    if (value is PagDeviceCat && value.tag.replaceAll('.', '') == tag) {
      return value as T;
    }
  }
  return null;
}

// String getPagDeviceTypeStr(dynamic itemType) {
//   switch (itemType) {
//     case PagDeviceCat.meter:
//       return 'meter';
//     case PagDeviceCat.sensor:
//       return 'sensor';
//     case PagDeviceCat.lock:
//       return 'lock';
//     case PagDeviceCat.camera:
//       return 'camera';
//     case PagDeviceCat.gateway:
//       return 'gateway';
//     case PagDeviceCat.meterGroup:
//       return 'meterGroup';
//     default:
//       return '';
//   }
// }

Widget getSensorTypeIcon(SensorType sensorType) {
  Color iconColor = Colors.white.withAlpha(230);
  double iconSize = 25;
  switch (sensorType) {
    case SensorType.temperature:
      return Icon(
        Symbols.thermostat,
        size: iconSize,
        color: iconColor,
      );
    case SensorType.humidity:
      return Icon(
        Symbols.humidity_mid,
        size: iconSize,
        color: iconColor,
      );
    case SensorType.ir:
      return Icon(
        Symbols.infrared,
        size: iconSize,
        color: iconColor,
      );
    case SensorType.smoke:
      return Icon(
        Symbols.detector_smoke,
        size: iconSize,
        color: iconColor,
      );
    case SensorType.water_leak:
      return Icon(
        Symbols.water,
        size: iconSize,
        color: iconColor,
      );
    default:
      return Icon(
        Symbols.help,
        size: iconSize,
        color: iconColor,
      );
  }
}

String? validateDeviceLabel(String val) {
  if (val.trim().isEmpty) {
    return 'required';
  }

  // validate number, letter, underscore, and dash, space,
  // and minimum 5 characters
  String pattern = r'^[a-zA-Z0-9_ -]{5,}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return 'min length is 5 and letter, number, space, _, - only';
  }
  return null;
}

String? validateSerialNumber(String val) {
  if (val.trim().isEmpty) {
    return 'required';
  }
  // validate number, letter, underscore, and dash,
  // and minimum 5 characters
  String pattern = r'^[a-zA-Z0-9_ -]{5,}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return 'min length is 5 and letter, number, _, - only';
  }
  return null;
}
