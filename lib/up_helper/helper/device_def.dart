import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum SensorType {
  temperature,
  humidity,
  smoke,
  pressure,
  ir,
  water_leak,
  multi,
  unknown,
}

enum DeviceType {
  METER,
  SENSOR,
  LOCK,
  CAMERA,
}

enum MeterType {
  electricity1p,
  electricity3p,
  water,
  gas,
  newater,
  btu,
}

enum MeterTypeTag {
  E,
  E3P,
  W,
  B,
  N,
  G,
}

enum DeviceStatus {
  ok,
  warning,
  alarm,
  error,
  unknown,
}

enum DeivceGroupType {
  building,
  tenant,
}

String getMeterTypeTag(MeterType meterType) {
  switch (meterType) {
    case MeterType.electricity1p:
      return 'E';
    case MeterType.electricity3p:
      return 'E3P';
    case MeterType.water:
      return 'W';
    case MeterType.gas:
      return 'G';
    case MeterType.newater:
      return 'N';
    case MeterType.btu:
      return 'B';
    default:
      return '';
  }
}

MeterType? getMeterType(String meterTypeTag) {
  switch (meterTypeTag.toUpperCase()) {
    case 'E':
      return MeterType.electricity1p;
    case 'E3P':
      return MeterType.electricity3p;
    case 'W':
      return MeterType.water;
    case 'G':
      return MeterType.gas;
    case 'N':
      return MeterType.newater;
    case 'B':
      return MeterType.btu;
    default:
      return null;
  }
}

Widget getDeivceGroupType(DeivceGroupType deivceGroupType,
    {Color? iconColor, double? iconSize}) {
  double defalutIconSize = 25;
  double theIconSize = iconSize ?? defalutIconSize;

  switch (deivceGroupType) {
    case DeivceGroupType.building:
      return Icon(
        Symbols.apartment,
        size: theIconSize,
        color: iconColor ?? Colors.blueAccent,
      );
    case DeivceGroupType.tenant:
      return Icon(
        Symbols.cases,
        size: theIconSize,
        color: iconColor ?? Colors.blueAccent,
      );
    default:
      return Icon(
        Symbols.help,
        size: theIconSize,
        color: iconColor ?? Colors.blueAccent,
      );
  }
}

const Color contentColorLightMagneta = Color(0xFFFFC0CB);
const Color contentColorLightRed = Color(0xFFFF6347);

Map<DeviceStatus, Color>
// const
    sensorStatusColor = {
  DeviceStatus.ok: Colors.green.shade100,
  // AppColors.contentColorLightGreen,
  // Colors.cyanAccent,
  // AppColors.contentColorLightTeal,
  DeviceStatus.warning: Colors.limeAccent.shade200,
  DeviceStatus.error: contentColorLightMagneta,
  DeviceStatus.alarm: contentColorLightRed,
  DeviceStatus.unknown: Colors.white,
};

Widget getSensorIcon(SensorType sensorType) {
  Color iconColor = Colors.white.withOpacity(0.9);
  double iconSize = 25;
  return Icon(
    getSensorIconData(sensorType),
    size: iconSize,
    color: iconColor,
  );
}

IconData getSensorIconData(SensorType sensorType) {
  switch (sensorType) {
    case SensorType.temperature:
      return Symbols.thermostat;
    case SensorType.humidity:
      return Symbols.humidity_mid;
    case SensorType.ir:
      return Symbols.infrared;
    case SensorType.smoke:
      return Symbols.detector_smoke;
    case SensorType.water_leak:
      return Symbols.water;
    default:
      return Symbols.help;
  }
}

String getDeivceTypeUnit(dynamic deviceSubType, {String? displayContextStr}) {
  switch (deviceSubType) {
    case MeterType.electricity1p:
      return 'kWh';
    case MeterType.electricity3p:
      return 'kWh';
    case MeterType.water:
      return 'm³';
    case MeterType.gas:
      return 'm³';
    case MeterType.newater:
      return 'm³';
    case MeterType.btu:
      if ((displayContextStr ?? '') == 'meter_usage_summary') {
        return 'TonHr';
      }
      return 'kWh';
    case SensorType.temperature:
      return '°C';
    case SensorType.humidity:
      return '%';
    case SensorType.ir:
      return '°C';
    case SensorType.smoke:
      return 'ppm';
    case SensorType.water_leak:
      return 'ppm';
    default:
      return '';
  }
}

String getDeivceTypeUnitK(dynamic deviceSubType) {
  switch (deviceSubType) {
    case MeterType.electricity1p:
      return 'MWh';
    case MeterType.electricity3p:
      return 'MWh';
    case MeterType.water:
      return 'km³';
    case MeterType.gas:
      return 'km³';
    case MeterType.newater:
      return 'km³';
    case MeterType.btu:
      return 'MWh';
    case SensorType.temperature:
      return '-';
    case SensorType.humidity:
      return '-';
    case SensorType.ir:
      return '-';
    case SensorType.smoke:
      return '-';
    case SensorType.water_leak:
      return '-';
    default:
      return '-';
  }
}

String getDeivceTypeLabel(dynamic deviceSubType) {
  switch (deviceSubType) {
    case MeterType.electricity1p:
      return 'Electricity';
    case MeterType.electricity3p:
      return 'Electricity 3P';
    case MeterType.water:
      return 'Water';
    case MeterType.gas:
      return 'Gas';
    case MeterType.newater:
      return 'NeWater';
    case MeterType.btu:
      return 'BTU';
    case SensorType.temperature:
      return 'Temperature';
    case SensorType.humidity:
      return 'Humidity';
    case SensorType.ir:
      return 'IR';
    case SensorType.smoke:
      return 'Smoke';
    case SensorType.water_leak:
      return 'Water Leak';
    default:
      return '';
  }
}

Color getDeivceTypeColor(dynamic deviceSubType) {
  switch (deviceSubType) {
    case MeterType.electricity1p:
      return Colors.orangeAccent.shade200;
    case MeterType.electricity3p:
      return Colors.orangeAccent;
    case MeterType.water:
      return Colors.cyanAccent.shade400;
    case MeterType.gas:
      return Colors.redAccent;
    case MeterType.newater:
      return Colors.cyanAccent.shade200;
    case MeterType.btu:
      return Colors.yellow.shade600;
    case SensorType.temperature:
      return Colors.blueAccent;
    case SensorType.humidity:
      return Colors.blueAccent;
    case SensorType.ir:
      return Colors.blueAccent;
    case SensorType.smoke:
      return Colors.blueAccent;
    case SensorType.water_leak:
      return Colors.blueAccent;
    default:
      return Colors.blueAccent;
  }
}

Widget getDeviceTypeIcon(dynamic deviceSubType,
    {Color? iconColor, double? iconSize}) {
  double defalutIconSize = 25;
  double theIconSize = iconSize ?? defalutIconSize;
  if (kDebugMode) {
    print('theIconSize: $theIconSize');
  }
  switch (deviceSubType) {
    case MeterType.electricity1p:
      return Icon(
        Icons.bolt, // Icons.electric_meter,
        size: theIconSize,
        color: iconColor ?? Colors.orangeAccent.shade200,
      );
    case MeterType.electricity3p:
      return Icon(
        Symbols.atr,
        size: theIconSize,
        color: iconColor ?? Colors.orangeAccent,
      );
    case MeterType.water:
      return Icon(
        Symbols.water,
        size: theIconSize,
        color: iconColor ?? Colors.cyanAccent.shade400,
      );
    case MeterType.gas:
      return Icon(
        Symbols.gas_meter,
        size: theIconSize,
        color: iconColor ?? Colors.redAccent,
      );
    case MeterType.newater:
      return Icon(
        Icons.water_drop,
        size: theIconSize - 2,
        color: iconColor ?? Colors.cyanAccent.shade200,
      );
    case MeterType.btu:
      return Icon(
        // Symbols.heat,
        Icons.hvac,
        size: theIconSize,
        color: iconColor ?? Colors.yellow.shade600,
      );
    case SensorType.temperature:
      return Icon(
        Symbols.thermostat,
        size: theIconSize,
        color: iconColor,
      );
    case SensorType.humidity:
      return Icon(
        Symbols.humidity_mid,
        size: theIconSize,
        color: iconColor,
      );
    case SensorType.ir:
      return Icon(
        Symbols.infrared,
        size: theIconSize,
        color: iconColor,
      );
    case SensorType.smoke:
      return Icon(
        Symbols.detector_smoke,
        size: theIconSize,
        color: iconColor,
      );
    case SensorType.water_leak:
      return Icon(
        Symbols.water,
        size: theIconSize,
        color: iconColor,
      );
    default:
      return Icon(
        Symbols.help,
        size: theIconSize,
        color: iconColor,
      );
  }
}
