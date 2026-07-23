import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'enum_helper.dart';

enum PagDeviceCat {
  meter('Meter', 'meter', 'm', Symbols.speed),
  meterGroup('Meter Group', 'meter_group', 'mg', Symbols.graph_6),
  sensor('Sensor', 'sensor', 'ss', Symbols.sensors),
  lock('Lock', 'lock', 'lk', Symbols.lock),
  camera('Camera', 'camera', 'cam', Symbols.videocam),
  gateway('Gateway', 'gateway', 'gw', Symbols.switch_access),
  mcu('MCU', 'mcu', 'mcu', Symbols.memory),
  motherboard('Motherboard', 'motherboard', 'mb', Symbols.developer_board),
  sim('SIM', 'sim', 'sim', Symbols.sim_card),
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
      enumByLabel(label, values, (e) => (e).label) ?? none;

  static PagDeviceCat byValue(String? value) =>
      enumByValue(value, values, (e) => (e).value) ?? none;
}

enum PagMeterType {
  electricity('Electricity', 'electricity', 'E', Symbols.bolt, 'kWh', 'MWh'),
  water('Water', 'water', 'W', Symbols.water, 'CuM', 'kCuM'),
  btu('BTU', 'btu', 'B', Symbols.hvac, 'TonHr', 'kTonHr'),
  gas('Gas', 'gas', 'G', Symbols.gas_meter, 'm³', 'm³'),
  newWater('New Water', 'new_water', 'N', Symbols.water_drop, 'CuM', 'kCuM'),
  unknown('Unknown', 'unkn', 'U', Symbols.help, null, null);

  const PagMeterType(
    this.label,
    this.value,
    this.tag,
    this.iconData,
    this.unit,
    this.unitK,
  );

  final String label;
  final String value; // the value that is stored in the database
  final String tag; // a short tag for the device category
  final String? unit;
  final String? unitK;
  final IconData iconData;

  static PagMeterType byLabel(String? label) =>
      enumByLabel(label, values, (e) => (e).label) ?? unknown;

  static PagMeterType byValue(String? value) =>
      enumByValue(value, values, (e) => (e).value) ?? unknown;

  static PagMeterType byTag(String? tag) =>
      enumByValue(tag, values, (e) => (e).tag) ?? unknown;
}

enum PagLinkOpType {
  gatewayToDevice,
  none,
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
  // String pattern = r'^[a-zA-Z0-9_ -]{5,}$';
  String pattern = r'^[a-zA-Z0-9_ \-#().&/]{5,}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    // return 'min length is 5 and letter, number, space, _, - only';
    return 'min length is 5 and letter, number, space, _, -, #, (, ), ., &, / only';
  }
  return null;
}

String? validateDescription(String val) {
  // if (val.trim().isEmpty) {
  //   return 'required';
  // }
  if (val.trim().isEmpty) {
    return null;
  }

  // validate number, letter, _, /, \, -, space, @, #, *, ', "
  // and maximum 255 characters
  String pattern = r'''^[\w&+:;=?@#|'"<>.^ *()%!-/\_]{0,255}$''';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return 'max length is 255 and letter, number, space, _, -, @, #, *, &, +, :, ;, =, ?, \', ", <, >, ., ^, (, ), /, %, !, - only';
  }
  return null;
}

String? validateSerialNumber(String val) {
  if (val.trim().isEmpty) {
    return 'required';
  }
  // validate number, letter, underscore, and dash,
  // and minimum 5 characters
  // String pattern = r'^[a-zA-Z0-9_ -]{5,}$';
  String pattern = r'^[a-zA-Z0-9_<>\-/ ]{5,}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return 'min length is 5 and letter, number, _, - only';
  }
  return null;
}

String? validateSerialNumber2(String val) {
  if (val.trim().isEmpty) {
    return null;
  }
  // validate number, letter, underscore, and dash,
  // and minimum 5 characters
  // String pattern = r'^[a-zA-Z0-9_ -]{5,}$';
  String pattern = r'^[a-zA-Z0-9_<>\-/ ]{5,}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return 'min length is 5 and letter, number, _, - only';
  }
  return null;
}

String? validateServiceType2(String val) {
  final normalizedString = val.trim().toLowerCase();

  if (normalizedString.isEmpty) {
    return 'required';
  }

  if (normalizedString != 'comm' && normalizedString != 'evs') {
    return 'service type must be either "comm" or "evs"';
  }
  return null;
}

String? validateModel(String val) {
  val = val.trim();

  if (val.isEmpty) {
    // return 'required';
    return null;
  }

  // Pattern: int.int.int[.alphanumeric] or int.int.int[.int]
  // final pattern = r'^\d{1,3}\.\d{1,3}\.\d{1,3}(\.[A-Za-z0-9]+)?$';
  const pattern1 =
      r'^(\d{1,3}\.\d{1,3}\.\d{1,3}(\.[A-Za-z0-9]+)?|[A-Za-z0-9]{3})$';

  const pattern2 = r'gen[A-Za-z0-9]+';

  // final regExp = RegExp(pattern);
  final regExp = RegExp(
    r'^(' + pattern1 + r'|' + pattern2 + r')$',
    caseSensitive: false,
  );

  if (!regExp.hasMatch(val)) {
    return 'invalid model format';
  }

  return null;
}

String? validateDeviceModel(String val) {
  val = val.trim();

  if (val.isEmpty) {
    return 'required';
  }

  // Alphanumeric, space, dot, underscore, hyphen
  const pattern = r'^[A-Za-z0-9._ -]+$';

  final regExp = RegExp(pattern);

  if (val.length > 55 || !regExp.hasMatch(val)) {
    return 'invalid model format, length must be less than 55 and only alphanumeric, space, dot, underscore, hyphen allowed';
  }

  return null;
}

String? validatePhaseType(String val) {
  val = val.trim();

  if (val.isEmpty) {
    return null;
  }

  // validate number, letter, underscore, dash, space,
  // and minimum 1 characters
  String pattern = r'^[a-zA-Z0-9_ -]{3,}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return 'min length is 1 and letter, number, space, _, - only';
  }
  return null;
}

String? validateDeviceIccid(String val) {
  val = val.trim();

  if (val.isEmpty) {
    // return 'required';
    return null;
  }

  // At least 7 digits
  String pattern = r'^\d{7,}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return 'must have at least 7 digits';
  }

  return null;
}

String? validateIp(String val) {
  val = val.trim();

  if (val.isEmpty) {
    // return 'required';
    return null;
  }

  // IPv4 pattern: 0-255.0-255.0-255.0-255
  String pattern = r'^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.){3}'
      r'(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$';

  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return 'invalid IP address';
  }

  return null;
}

String? validateDeviceType(String val) {
  // if (val.trim().isEmpty) {
  //   return 'required';
  // }

  // validate number, letter only, 1 to 21 characters
  String pattern = r'^[a-zA-Z0-9]{1,21}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return '1-21 characters, letter and number only';
  }
  return null;
}

String? validateAdapterType(String? val) {
  if (val == null || val.trim().isEmpty) {
    return 'required';
  }

  String value = val.toLowerCase();

  if (!value.contains('jbs2') && !value.contains('evs2sim')) {
    return 'Value must contain "jbs2" or "evs2sim"';
  }

  return null;
}

String? validatePollingLaw(String? val) {
  if (val == null || val.trim().isEmpty) {
    return 'required';
  }

  String value = val.toLowerCase();

  if (value != '0' && value != '1' && value != '2') {
    return 'Value must be "0", "1", or "2"';
  }

  return null;
}

String? validateTag(String val) {
  val = val.trim();

  if (val.isEmpty) {
    return 'required';
  }

  // tag pattern: letter, number, underscore, dash, space, 0 to 55 characters
  String pattern = r'^[a-zA-Z0-9_ -]{0,55}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return 'max length is 55 and letter, number, space, _, - only';
  }
  return null;
}

String? validateServiceType(String val) {
  // Service Type pattern: letter, number, underscore, dash, space, 1 to 21 characters

  String pattern = r'^[a-zA-Z0-9_ -]{1,21}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return '1-21 characters, letter, number, space, _, - only';
  }

  return null;
}

String? validateMeterReadingValue(String val) {
  val = val.trim();

  if (val.isEmpty) {
    return 'required';
  }

  // validate double value, can have decimal point
  String pattern = r'^\d+(\.\d+)?$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return 'invalid reading value';
  }

  // max value 1 billion
  double? readingValue = double.tryParse(val);
  if (readingValue == null || readingValue > 1000000000) {
    return 'reading value must be less than 1 billion';
  }

  return null;
}

enum PagDeviceOpType {
  onboarding('Onboarding', 'onb', 'onb'),
  // mbOnb1on1('Meter Group Onboarding 1-on-1', 'mg_onb_1on1', 'mg_onb_1on1'),
  update('Update', 'upd', 'upd'),
  none('None', 'none', 'none');

  const PagDeviceOpType(
    this.label,
    this.value,
    this.tag,
  );

  final String label;
  final String value; // the value that is stored in the database
  final String tag; // a short tag for the device category

  static PagDeviceOpType byLabel(String? label) =>
      enumByLabel(label, values, (e) => (e).label) ?? none;

  static PagDeviceOpType byValue(String? value) =>
      enumByValue(value, values, (e) => (e).value) ?? none;

  static PagDeviceOpType byTag(String? tag) =>
      enumByValue(tag, values, (e) => (e).tag) ?? none;
}

final List<Map<String, dynamic>> listConfigBaseDevice = [
  {
    'col_key': 'sn',
    'title': 'S/N',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': true,
    'validator': validateSerialNumber,
  },
  {
    'col_key': 'label',
    'title': 'Label',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateDeviceLabel,
  },
  {
    'col_key': 'displayname',
    'title': 'Displayname',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateDeviceLabel,
  },
  {
    'col_key': 'tag',
    'title': 'tag',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateTag,
  },
  {
    'col_key': 'type',
    'title': 'Type',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': false,
    'validator': validateDeviceType,
  },
  {
    'col_key': 'model',
    'title': 'model',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateModel,
  },
  {
    'col_key': 'description',
    'title': 'Description',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateDescription,
  },
];

final List<Map<String, dynamic>> listConfigBaseMeter = [
  {
    'col_key': 'phase_type',
    'title': 'Phase',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validatePhaseType,
  },
  {
    'col_key': 'site_label',
    'title': 'Site Label',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateLabelScope,
  },
  {
    'col_key': 'building_label',
    'title': 'Building Label',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateLabelScope,
  },
  {
    'col_key': 'location_label',
    'title': 'Location Label',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateLabelScope,
  },
];

final List<Map<String, dynamic>> listConfigBaseGateway = [
  {
    'col_key': 'ip',
    'title': 'ip',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateIp,
  },
  {
    'col_key': 'iccid',
    'title': 'iccid',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateDeviceIccid,
  },
];

final List<Map<String, dynamic>> listConfigBaseMcu = [
  // {
  //   'col_key': 'ip',
  //   'title': 'ip',
  //   'col_type': 'string',
  //   'width': 150,
  //   'is_mapping_required': false,
  //   'validator': validateIp,
  // },
  // {
  //   'col_key': 'iccid',
  //   'title': 'iccid',
  //   'col_type': 'string',
  //   'width': 150,
  //   'is_mapping_required': false,
  //   'validator': validateDeviceIccid,
  // },
  {
    'col_key': 'motherboard_sn',
    'title': 'Motherboard S/N',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateSerialNumber,
  },
];

final List<Map<String, dynamic>> listConfigBaseMotherboard = [];

final List<Map<String, dynamic>> listConfigBaseMeterGroup = [
  {
    'col_key': 'service_type',
    'title': 'Service Type',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateServiceType,
  },
  {
    'col_key': 'site_label',
    'title': 'Site Label',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateLabelScope,
  },
  {
    'col_key': 'building_label',
    'title': 'Building Label',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateLabelScope,
  },
  {
    'col_key': 'location_label',
    'title': 'Location Label',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateLabelScope,
  },
];

final List<Map<String, dynamic>> listConfigBaseSim = [
  {
    'col_key': 'ip',
    'title': 'ip',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateIp,
  },
  {
    'col_key': 'iccid',
    'title': 'ICCID',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateDeviceIccid,
  },
  {
    'col_key': 'package',
    'title': 'Package',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': true,
    'validator': validateDeviceType,
  },
  {
    'col_key': 'adapter_type',
    'title': 'Adapter Type',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': true,
    'validator': validateAdapterType,
  },
];

List<Map<String, dynamic>> getDeviceConfigListByCat(PagDeviceCat cat) {
  switch (cat) {
    case PagDeviceCat.meter:
      return listConfigBaseDevice + listConfigBaseMeter;
    case PagDeviceCat.gateway:
      return listConfigBaseDevice + listConfigBaseGateway;
    case PagDeviceCat.mcu:
      return listConfigBaseDevice + listConfigBaseMcu;
    case PagDeviceCat.motherboard:
      return listConfigBaseDevice + listConfigBaseMotherboard;
    case PagDeviceCat.meterGroup:
      return listConfigBaseDevice + listConfigBaseMeterGroup;
    case PagDeviceCat.sim:
      return listConfigBaseDevice + listConfigBaseSim;
    default:
      return listConfigBaseDevice;
  }
}

enum PagMeterOpType {
  // NONE,
  none,
  CPC,
  BYPASS,
  UNBYPASS,
  SET_CONC,
  SET_SITE,
  SET_CONC_TARIFF,
  REPLACEMENT,
  DETACH_SN,
  ATTACH_SN,
  // READING_DATA_INSERT,
  readingDataInsert,
  SET_LC_STATUS,
  MANUAL_READING,
}

final List<Map<String, dynamic>> listConfigMeterOpsBase = [
  {
    'col_key': 'meter_sn',
    'title': 'S/N',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': true,
    'validator': validateSerialNumber,
  },
];

final List<Map<String, dynamic>> listConfigMeterOpsInsertReadingSingleVal = [
  {
    'col_key': 'dt',
    'title': 'Reading Time',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': true,
    'validator': validateDatTimeStr,
  },
  {
    'col_key': 'val',
    'title': 'Reading',
    'col_type': 'double',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateLastReadingValue,
  },
];

List<Map<String, dynamic>> getMeterOpsConfigList(PagMeterOpType opType) {
  switch (opType) {
    case PagMeterOpType.readingDataInsert:
      return listConfigMeterOpsBase + listConfigMeterOpsInsertReadingSingleVal;
    default:
      return listConfigMeterOpsBase;
  }
}

String getMeterOpsFileUploadMessage(PagMeterOpType opType) {
  switch (opType) {
    case PagMeterOpType.readingDataInsert:
      return 'Upload Meter Reading Data';
    default:
      return 'Unsupported Meter Operation';
  }
}

enum PagMeterCommType {
  mms('mms', 'mms', 'mms', Colors.brown),
  evs2loop('evs2loop', 'evs2_loop', 'evs2loop', Colors.deepPurple),
  evs2mcu('evs2mcu', 'evs2_mcu', 'evs2mcu', Colors.green),
  mcu05('mcu05', 'mcu05', 'mcu05', Colors.indigo),
  unknown('unknown', 'unknown', 'unknown', Colors.grey);

  const PagMeterCommType(
    this.label,
    this.value, // the value that is stored in the database
    this.tag,
    this.color,
  );

  final String label;
  final String value;
  final String tag;

  final Color color;

  static PagMeterCommType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagMeterCommType byValue(String? value) =>
      enumByValue(
        value,
        values,
        (e) => (e).value,
      ) ??
      unknown;

  static PagMeterCommType? byTag(String? tag) => enumByTag(
        tag,
        values,
        (e) => (e).tag,
      );

  static Widget getTagWidget(PagMeterCommType status) {
    Color color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(210),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status.tag,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }
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
        (e) => (e).label,
      ) ??
      normal;

  static PagDeviceLsStatus byTag(String? tag) =>
      enumByTag(
        tag,
        values,
        (e) => (e).tag,
      ) ??
      normal;
}

enum PagMeterPhaseType {
  single('Single Phase', 'single_phase'),
  threePhaseDirect('Three Phase Direct', 'three_phase_direct'),
  threePhaseCt('Three Phase CT', 'three_phase_ct');

  const PagMeterPhaseType(this.key, this.value);

  final String key; // UI display
  final String value; // API / storage

  static PagMeterPhaseType? byKey(String? key) {
    for (final e in values) {
      if (e.key == key) return e;
    }
    return null;
  }

  static PagMeterPhaseType? byValue(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

enum PagSimPackageEnum {
  nano("Nano"),
  micro("Micro"),
  standard("Standard"),
  ;

  const PagSimPackageEnum(this.label);

  final String label;

  static PagSimPackageEnum? byLabel(String? label) =>
      enumByLabel(label, values, (e) => e.label);
}

// enum PagGwGenEnum {
//   gen1("Gen1"),
//   gen2("Gen2"),
//   gen3("Gen3"),
//   ;

//   const PagGwGenEnum(this.label);

//   final String label;

//   static PagGwGenEnum? byLabel(String? label) =>
//       enumByLabel(label, values, (e) => e.label);
// }
