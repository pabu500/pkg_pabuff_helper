import 'package:buff_helper/up_helper/helper/device_def.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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

String? validateLabel(String val) {
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
