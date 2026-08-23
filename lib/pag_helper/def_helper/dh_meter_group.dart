import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/enum_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:flutter/material.dart';

enum PagEmsMeterGroupOpType {
  onb1on1('EMS Onboarding 1-on-1', 'ems_onb_1on1', '1on1'),
  onbIndLoc1on1(
    'EMS Independent Location Onboarding 1-on-1',
    'ems_onb_ind_loc_1on1',
    'iloc1on1',
  ),
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

enum EmsMeterGroupAssignmentType {
  ems1on1('1-on-1', 'ems_onb_1on1', '1on1', Colors.purple),
  emsIndLoc1on1(
      'Ind. Loc. 1-on-1', 'ems_onb_ind_loc_1on1', 'iloc1on1', Colors.blue),
  manual('manual', 'manual', 'man', Colors.teal),
  unknown('unknown', 'unknown', 'unknown', Colors.grey);

  const EmsMeterGroupAssignmentType(
    this.label,
    this.value,
    this.tag,
    this.color,
  );
  final String label;
  final String value;
  final String tag;
  final Color color;

  static EmsMeterGroupAssignmentType byValue(String? value) {
    return enumByValue(
          value,
          values,
          (e) => (e).value,
        ) ??
        unknown;
  }

  static EmsMeterGroupAssignmentType byLabel(String? label) =>
      enumByLabel(
        label,
        values,
        (e) => (e).label,
      ) ??
      unknown;

  static EmsMeterGroupAssignmentType byTag(String? tag) =>
      enumByTag(
        tag,
        values,
        (e) => (e).tag,
      ) ??
      unknown;
}

enum MeterGroupServiceType {
  comm('comm', 'comm', 'comm', Colors.blue),
  ems('ems', 'ems', 'ems', Colors.orange),
  evs('evs', 'evs', 'evs', Colors.purple),
  unknown('unknown', 'unknown', 'unknown', Colors.grey);

  const MeterGroupServiceType(
    this.label,
    this.value,
    this.tag,
    this.color,
  );
  final String label;
  final String value;
  final String tag;
  final Color color;

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

final List<Map<String, dynamic>> listConfigOnbIndLoc1on1 = [
  {
    'col_key': 'meter_sn',
    'title': 'Meter Serial Number',
    'col_type': 'string',
    'width': 200,
    'join_key': 'meter_id',
    'is_id_col': true,
    'is_column_mapping_required': true,
    'is_value_required': true,
    'validator': validateSerialNumber,
  },
  {
    'col_key': 'building_label',
    'title': 'Building Label',
    'col_type': 'string',
    'width': 200,
    'join_key': 'scope_id',
    'is_id_col': false,
    'is_column_mapping_required': true,
    'is_value_required': true,
    'validator': (String value) =>
        value.trim().isEmpty ? 'Building Label is required' : null,
  },
];

List<Map<String, dynamic>> getListConfigBaseByOpType(
    PagEmsMeterGroupOpType opType) {
  final List<Map<String, dynamic>> list = [];
  switch (opType) {
    case PagEmsMeterGroupOpType.onb1on1:
      list.addAll(listConfigBaseMeterGroup + listConfigOnb1on1);
      break;
    case PagEmsMeterGroupOpType.onbIndLoc1on1:
      list.addAll(listConfigBaseMeterGroup + listConfigOnbIndLoc1on1);
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

String? Function(String) getMeterGroupValidator(String key,
    {bool isValueRequired = true}) {
  switch (key) {
    case 'meter_sn':
      return getValidator(validateSerialNumber, isValueRequired);
    case 'onb_type':
      return getValidator(validateMeterGroupOnbType, isValueRequired);
    case 'service_type':
      return getValidator(validateServiceType, isValueRequired);
    default:
      dev.log('No validator found for meter group key: $key');
      return (String value) {
        return null;
      };
  }
}
