import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/enum_helper.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum PagMeterGroupOpType {
  onboarding1o1('Onboarding (1 on 1)', 'onboarding1o1', Symbols.upload_file),
  update('Update', 'update', Symbols.update),
  none('None', 'none', Symbols.block),
  ;

  const PagMeterGroupOpType(
    this.label,
    this.tag,
    this.iconData,
  );

  final String label;
  final String tag;
  final IconData iconData;

  static PagMeterGroupOpType byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).tag,
      ) ??
      none;

  static PagMeterGroupOpType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagMeterGroupOpType? byTag(String? tag) => enumByTag(
        tag,
        values,
        (e) => (e).tag,
      );
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

final List<Map<String, dynamic>> listConfigOnb1o1 = [
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
];

List<Map<String, dynamic>> getListConfigBaseByOpType(
    PagMeterGroupOpType opType) {
  final List<Map<String, dynamic>> list = [];
  switch (opType) {
    case PagMeterGroupOpType.onboarding1o1:
      list.addAll(listConfigBaseMeterGroup + listConfigOnb1o1);
      break;
    case PagMeterGroupOpType.update:
      list.addAll(listConfigBaseMeterGroup + []);
      break;
    default:
      list.addAll(listConfigBaseMeterGroup);
  }
  //remove empty maps
  list.removeWhere((map) => map.isEmpty);
  return list;
}
