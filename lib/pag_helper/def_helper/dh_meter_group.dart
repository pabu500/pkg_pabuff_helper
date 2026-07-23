import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/enum_helper.dart';

enum PagEmsMeterGroupOpType {
  onboarding1on1('EMS Onboarding 1-on-1', 'ems_onb_1on1', 'ems_onb_1on1'),
  update('Update', 'update', 'update'),
  none('None', 'none', 'none'),
  ;

  const PagEmsMeterGroupOpType(
    this.label,
    this.value,
    this.tag,
  );
  final String label;
  final String value;
  final String tag;

  static PagEmsMeterGroupOpType byValue(String? value) =>
      enumByValue(
        value,
        values,
        (e) => (e).value,
      ) ??
      none;

  static PagEmsMeterGroupOpType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagEmsMeterGroupOpType? byTag(String? tag) => enumByTag(
        tag,
        values,
        (e) => (e).tag,
      );
}

enum MeterGroupServiceType {
  comm('comm', 'comm', 'comm'),
  ems('ems', 'ems', 'ems'),
  unknown('unknown', 'unknown', 'unknown');

  const MeterGroupServiceType(
    this.label,
    this.value,
    this.tag,
  );
  final String label;
  final String value;
  final String tag;

  static MeterGroupServiceType byValue(String? value) =>
      enumByValue(
        value,
        values,
        (e) => (e).value,
      ) ??
      unknown;

  static MeterGroupServiceType byLabel(String? label) =>
      enumByLabel(
        label,
        values,
        (e) => (e).label,
      ) ??
      unknown;

  static MeterGroupServiceType byTag(String? tag) =>
      enumByTag(
        tag,
        values,
        (e) => (e).tag,
      ) ??
      unknown;
}

// must be 'auto-1-on-1'
String? validateMeterGroupOnbType(dynamic value) {
  if (value == null || value.toString().isEmpty) {
    return 'Onb Type is required';
  }
  final validTypes = ['auto-1-on-1'];
  if (!validTypes.contains(value.toString())) {
    return 'Invalid Onb Type';
  }
  return null;
}

final List<Map<String, dynamic>> listConfigBaseMeterGroup = [];

final List<Map<String, dynamic>> listConfigOnb1on1 = [
  {
    'col_key': 'meter_sn',
    'title': 'Meter Serial Number',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': true,
    'validator': validateSerialNumber,
  },
  {
    'col_key': 'onb_type',
    'title': 'Onb Type',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': true,
    'validator': validateMeterGroupOnbType,
  },
  {
    'col_key': 'polling_id_mapping_law',
    'title': 'Polling Law',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': false
  },
  {
    'col_key': 'service_type',
    'title': 'Service Type',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': false
  },
];

List<Map<String, dynamic>> getListConfigBaseByOpType(
    PagEmsMeterGroupOpType opType) {
  final List<Map<String, dynamic>> list = [];
  switch (opType) {
    case PagEmsMeterGroupOpType.onboarding1on1:
      list.addAll(listConfigBaseMeterGroup + listConfigOnb1on1);
      break;
    case PagEmsMeterGroupOpType.update:
      list.addAll(listConfigBaseMeterGroup + []);
      break;
    default:
      list.addAll(listConfigBaseMeterGroup);
  }
  //remove empty maps
  list.removeWhere((map) => map.isEmpty);
  return list;
}
