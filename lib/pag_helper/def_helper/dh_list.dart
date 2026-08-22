import 'package:buff_helper/pkg_buff_helper.dart';

import 'enum_helper.dart';

enum PagListContextType {
  info('Info', 'info', 'info'),
  infoTp('Info TP', 'info_tp', 'info_tp'),
  usage('Usage', 'usage', 'usage'),
  scada('SCADA', 'scada', 'scada'),
  soa('SOA', 'soa', 'soa'),
  fh('FH', 'fh', 'fh'),
  paymentMatching('Payment Matching', 'payment_matching', 'payment_matching'),
  paymentApply('Payment Apply', 'payment_apply', 'payment_apply'),
  billCompilation('Bill Compilation', 'bill_compilation', 'bill_compilation'),
  jobOption('Job Option', 'job_option', 'job_option'),
  rolePermAssignment(
      'Role Perm Assignment', 'role_perm_assignment', 'role_perm_assignment'),
  linkAssetOp('Link Asset Op', 'link_asset_op', 'link_asset_op'),
  evsMeterGroup('EVS Meter Group', 'evs_meter_group', 'evs_meter_group'),
  emsMeterGroup('EMS Meter Group', 'ems_meter_group', 'ems_meter_group'),
  amMeterGroup('AM Meter Group', 'am_meter_group', 'am_meter_group'),
  none('None', 'none', 'none');

  const PagListContextType(
    this.label,
    this.value,
    this.tag,
  );

  final String label;
  final String value;
  final String tag;

  static PagListContextType byValue(String? value) =>
      enumByValue(
        value,
        values,
        (e) => (e).value,
      ) ??
      none;

  static PagListContextType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagListContextType? byTag(String? tag) => enumByTag(
        tag,
        values,
        (e) => (e).tag,
      );
}

enum PagListTypeName {
  SITE_LIST,
  USER_LIST,
  SCOPE_DEVICE_LIST,
}

final pagUserColConfig = [
  {'title': 'Username', 'fieldKey': 'username', 'width': 120.0},
  {
    'title': 'Fullname',
    'fieldKey': 'fullname',
    'width': 120.0,
    'validator': (value) {
      return validateFullName(value, emptyCallout: 'empty field');
    },
    'disableIf': (row, compareValue) {
      return row['max_rank'] >= compareValue.toInt();
    },
  },
  {
    'title': 'Email',
    'fieldKey': 'email',
    'width': 200.0,
    'validator': (value) {
      return validateEmail(value, emptyCallout: 'empty field');
    },
    'disableIf': (row, compareValue) {
      return row['max_rank'] >= compareValue.toInt();
    },
  },
  {
    'title': 'Phone',
    'fieldKey': 'contact_number',
    'width': 110.0,
    'validator': (value) {
      return validatePhone(value, emptyCallout: 'empty field');
    },
    'disableIf': (row, compareValue) {
      return row['max_rank'] >= compareValue.toInt();
    },
  },
  {
    'title': 'Enabled',
    'fieldKey': 'enabled',
    'width': 80.0,
    'useWidget': 'toggleSwitch',
    'disableIf': (row, compareValue) {
      return row['max_rank'] >= compareValue.toInt();
    },
  },
];

// parse the list config value, to int, double, bool, etc
void parseListConfig(List<Map<String, dynamic>> listConfig) {
  for (var config in listConfig) {
    // go thru the map entries
    for (var key in config.keys) {
      var value = config[key];

      if (value is String) {
        if (value == 'true') {
          config[key] = true;
        } else if (value == 'false') {
          config[key] = false;
        } else if (value.contains('.')) {
          double? doubleValue = double.tryParse(value);
          if (doubleValue != null) {
            config[key] = doubleValue;
          } else {
            config[key] = value;
          }
        } else {
          int? intValue = int.tryParse(value);
          if (intValue != null) {
            config[key] = intValue;
          } else {
            config[key] = value;
          }
        }
      }
    }
  }
}
