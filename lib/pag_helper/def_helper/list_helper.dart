import 'package:buff_helper/pkg_buff_helper.dart';

enum PagListContextType {
  info,
  usage,
  scada,
  soa,
  none,
  fh,
  paymentMatching,
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
