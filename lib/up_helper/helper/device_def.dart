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
  GATEWAY,
}

enum MeterType {
  electricity1p,
  electricity3p,
  water,
  gas,
  newater,
  btu,
  bidirection,
  // manualElectricity1p,
}

enum MeterTypeTag {
  E,
  E3P,
  W,
  B,
  N,
  G,
  ME,
  SE1,
  BD,
}

enum DeviceStatus {
  ok,
  warning,
  alarm,
  error,
  unknown,
  INACTIVE,
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
    case MeterType.bidirection:
      return 'SE1';
    // case MeterType.manualElectricity1p:
    //   return 'ME';
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
    case 'SE1':
      return MeterType.bidirection;
    // case 'ME':
    //   return MeterType.manualElectricity1p;
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
  DeviceStatus.warning: Colors.limeAccent.shade200,
  DeviceStatus.error: contentColorLightMagneta,
  DeviceStatus.alarm: contentColorLightRed,
  DeviceStatus.unknown: Colors.white,
  DeviceStatus.INACTIVE: Colors.grey.shade100,
};

Color getSensorStatusColor(DeviceStatus deviceStatus) {
  return sensorStatusColor[deviceStatus] ?? Colors.white;
}

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
      } else if ((displayContextStr ?? '') == 'tenant_usage_summary') {
        return 'kWh(mech)';
      } else if ((displayContextStr ?? '') == 'ems_top_stat') {
        return 'TonHr';
      }
      return 'kWh';
    case MeterType.bidirection:
      return 'kWh';
    // case MeterType.manualElectricity1p:
    //   return 'kWh';
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

String getDeivceTypeUnitK(dynamic deviceSubType, {String? displayContextStr}) {
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
      if ((displayContextStr ?? '') == 'meter_usage_summary') {
        return 'kTonHr';
      } else if ((displayContextStr ?? '') == 'tenant_usage_summary') {
        return 'MWh(mech)';
      } else if ((displayContextStr ?? '') == 'ems_top_stat') {
        return 'kTonHr';
      }
      return 'MWh';
    case MeterType.bidirection:
      return 'MWh';
    // case MeterType.manualElectricity1p:
    //   return 'MWh';
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

Map<String, dynamic> getDeivceTypeUnitSet(dynamic deviceSubType,
    {String? displayContextStr}) {
  String unit = '';
  String unitK = '';
  String unitM = '';
  String unitG = '';
  switch (deviceSubType) {
    case MeterType.electricity1p:
      unit = 'kWh';
      unitK = 'MWh';
      unitM = 'GWh';
      unitG = 'TWh';
      break;
    case MeterType.electricity3p:
      unit = 'kWh';
      unitK = 'MWh';
      unitM = 'GWh';
      unitG = 'TWh';
      break;
    case MeterType.water:
      unit = 'm³';
      unitK = 'km³';
      unitM = 'Gm³';
      unitG = 'Tm³';
      break;
    case MeterType.gas:
      unit = 'm³';
      unitK = 'km³';
      unitM = 'Gm³';
      unitG = 'Tm³';
      break;
    case MeterType.newater:
      unit = 'm³';
      unitK = 'km³';
      unitM = 'Gm³';
      unitG = 'Tm³';
      break;
    case MeterType.btu:
      if ((displayContextStr ?? '') == 'meter_usage_summary') {
        unit = 'TonHr';
        unitK = 'kTonHr';
        unitM = 'GTonHr';
        unitG = 'TTonHr';
      } else if ((displayContextStr ?? '') == 'tenant_usage_summary') {
        unit = 'kWh(mech)';
        unitK = 'MWh(mech)';
        unitM = 'GWh(mech)';
        unitG = 'TWh(mech)';
      } else if ((displayContextStr ?? '') == 'ems_top_stat') {
        unit = 'TonHr';
        unitK = 'kTonHr';
        unitM = 'GTonHr';
        unitG = 'TTonHr';
      } else {
        unit = 'kWh';
        unitK = 'MWh';
        unitM = 'GWh';
        unitG = 'TWh';
      }
    case MeterType.bidirection:
      unit = 'kWh';
      unitK = 'MWh';
      unitM = 'GWh';
      unitG = 'TWh';
      break;
    case SensorType.temperature:
      unit = '°C';
      unitK = '-';
      unitM = '-';
      unitG = '-';
      break;
    case SensorType.humidity:
      unit = '%';
      unitK = '-';
      unitM = '-';
      unitG = '-';
      break;
    case SensorType.ir:
      unit = '°C';
      unitK = '-';
      unitM = '-';
      unitG = '-';
      break;
    case SensorType.smoke:
      unit = 'ppm';
      unitK = '-';
      unitM = '-';
      unitG = '-';
      break;
    case SensorType.water_leak:
      unit = 'ppm';
      unitK = '-';
      unitM = '-';
      unitG = '-';
      break;
    default:
      unit = '';
      unitK = '';
      unitM = '';
      unitG = '';
  }
  return {
    'unit': unit,
    'unitK': unitK,
    'unitM': unitM,
    'unitG': unitG,
  };
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
    case MeterType.bidirection:
      return 'Solar';
    // case MeterType.manualElectricity1p:
    //   return 'Electricity (Manual)';
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
    case MeterType.bidirection:
      return Colors.yellowAccent.shade400;
    // case MeterType.manualElectricity1p:
    //   return Colors.orangeAccent.shade200;
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
    case DeviceType.LOCK:
      return Icon(
        Icons.lock,
        size: theIconSize,
        color: iconColor,
      );
    case DeviceType.METER:
      return Icon(
        Symbols.speed,
        size: theIconSize,
        color: iconColor,
      );
    case DeviceType.SENSOR:
      return Icon(
        Symbols.sensors,
        size: theIconSize,
        color: iconColor,
      );
    case DeviceType.CAMERA:
      return Icon(
        Symbols.videocam,
        size: theIconSize,
        color: iconColor,
      );
    case DeviceType.GATEWAY:
      return Icon(
        Symbols.switch_access,
        size: theIconSize,
        color: iconColor,
      );
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
    case MeterType.bidirection:
      return Icon(
        Icons.wb_sunny,
        size: theIconSize,
        color: iconColor ?? Colors.yellowAccent.shade400,
      );
    // case MeterType.manualElectricity1p:
    //   return Icon(
    //     Icons.bolt, // Icons.electric_meter,
    //     size: theIconSize,
    //     color: iconColor ?? Colors.orangeAccent.shade200,
    //   );
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
