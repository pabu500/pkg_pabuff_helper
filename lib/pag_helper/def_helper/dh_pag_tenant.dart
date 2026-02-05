import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/xt_ui/util/xt_util_InputFieldValidator.dart';
import 'package:flutter/material.dart';

import 'enum_helper.dart';

enum PagTenantLcStatus {
  onbarding('Onboarding', 'onb', 'onb', Colors.lightGreenAccent),
  normal('Normal', 'normal', 'norm', Colors.teal),
  offboarding('Offboarding', 'offb', 'offb', Colors.orange),
  terminated('Terminated', 'terminated', 'term', Colors.red),
  ;

  const PagTenantLcStatus(
    this.label,
    this.value, // the value that is stored in the database
    this.tag,
    this.color,
  );

  final String label;
  final String value;
  final String tag;

  final Color color;

  static PagTenantLcStatus? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagTenantLcStatus byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      normal;

  static PagTenantLcStatus? byTag(String? tag) =>
      enumByTag(
        tag,
        values,
      ) ??
      normal;

  static Widget getTagWidget(PagTenantLcStatus status) {
    Color color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(210),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status.tag,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }
}

T? enumByTag<T extends Enum>(String? tag, List<T> values) {
  if (tag == null) return null;
  for (var value in values) {
    if (value is PagTenantLcStatus && value.tag.replaceAll('.', '') == tag) {
      return value as T;
    }
  }
  return null;
}

enum PagTenantUnitType {
  beautyWellness(
      'Beauty & Wellness', 'beauty_wellness', 'b&w', Colors.lightGreenAccent),
  bookStationery('Book & Stationery', 'book_stationery', 'b&s', Colors.blue),
  childrean('Children', 'children', 'child', Colors.lightBlueAccent),
  convenienceStore(
      'Convenience Store', 'convenience_store', 'cvs', Colors.green),
  deptValueStore(
      'Dept. & Value Store', 'dept_value_store', 'dvs', Colors.amber),
  electronicsTelco(
      'Electronics & Telco', 'electronics_telco', 'e&t', Colors.cyan),
  enetertainment('Entertainment', 'entertainment', 'ent', Colors.deepOrange),
  fashion('Fashion', 'fashion', 'fash', Colors.pink),
  foodBeverage('Food & Beverage', 'food_beverage', 'f&b', Colors.redAccent),
  hobbiesLiving('Hobbies & Living', 'hobbies_living', 'h&l', Colors.indigo),
  homeFurnishing('Home & Furnishing', 'home_furnishing', 'h&f', Colors.brown),
  services('Services', 'services', 'serv', Colors.grey),
  sports('Sports', 'sports', 'sp', Colors.teal),
  office('Office', 'office', 'of', Colors.purple),
  others('Others', 'others', 'oth', Colors.grey),
  ;

  const PagTenantUnitType(
    this.label,
    this.value, // the value that is stored in the database
    this.tag,
    this.color,
  );

  final String label;
  final String value;
  final String tag;
  final Color color;

  static PagTenantUnitType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagTenantUnitType byValue(String value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      others;

  static PagTenantUnitType byTag(String? tag) =>
      enumByTag(
        tag,
        values,
      ) ??
      others;
}

enum PagTenantPaymentMethod {
  giro('GIRO', 'giro', 'giro', Colors.green),
  nonGiro('None GIRO', 'non_giro', 'ngiro', Colors.red),
  cheque('Cheque', 'cheque', 'chq', Colors.blue),
  other('Other', 'other', 'oth', Colors.grey),
  ;

  const PagTenantPaymentMethod(
    this.label,
    this.value, // the value that is stored in the database
    this.tag,
    this.color,
  );

  final String label;
  final String value;
  final String tag;
  final Color color;

  static PagTenantPaymentMethod? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagTenantPaymentMethod byValue(String value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      other;

  static PagTenantPaymentMethod byTag(String? tag) =>
      enumByTag(
        tag,
        values,
      ) ??
      other;
}

String? validateTenantLabel(String value) {
  if (value.trim().isEmpty) {
    return 'required';
  }
  //length 5-255, alphanumeric, space, /, ', +, -, #, @, (), ., only
  String pattern = r"^[-a-zA-Z0-9 ./'()+&#@]{5,255}$";
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(value)) {
    return 'alphanumeric, space, /, +, -, #, &, @, (), '
        ', ., only and length 5-255';
  }
  return null;
}

String? validateCompanyTradingName(String value) {
  if (value.trim().isEmpty) {
    return 'required';
  }
  //length 5-255, alphanumeric, space, /, ', +, -, #, @, (), ., only
  String pattern = r"^[-a-zA-Z0-9 ./'()+&#@]{5,255}$";
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(value)) {
    return 'alphanumeric, space, /, +, -, '
        ', #, &, @, (), ., only and length 5-255';
  }
  return null;
}

String? validateBillingAddress(String value) {
  if (value.trim().isEmpty) {
    return 'required';
  }
  //length 5-255, alphanumeric, space, /, ', -, &, #,, @ and line break only
  // String pattern = r"^[-a-zA-Z0-9 ./'#]{5,255}$";
  String pattern = r"^[-a-zA-Z0-9 .,/'&#@\n]{5,255}$";
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(value)) {
    return 'alphanumeric, space, /, &, ., -, #, @, and line break only and length 5-255';
  }
  return null;
}

String? validateBillingAddressLine1(String value) {
  // if (value.trim().isEmpty) {
  //   return 'required';
  // }
  if (value.trim().isEmpty) {
    // return 'required';
    return null;
  }
  //length 5-255, alphanumeric, space, /, ', -,  #, @ only
  String pattern = r"^[-a-zA-Z0-9 .,/'#&@]{5,255}$";
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(value)) {
    return 'alphanumeric, space, /, -, #, ,, &, @ only and length 5-255';
  }
  return null;
}

String? validateBillingAddressLine2(String value) {
  if (value.trim().isEmpty) {
    // return 'required';
    return null;
  }
  //length 5-255, alphanumeric, space, /, ', -, @, #,() only
  String pattern = r"^[-a-zA-Z0-9 ./'#@&()]{5,255}$";
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(value)) {
    return 'alphanumeric, space, /, -, @, #, &,() only and length 5-255';
  }
  return null;
}

String? validateBillingAddressLine3(String value) {
  if (value.trim().isEmpty) {
    // return 'required';
    return null;
  }
  //length 5-21, alphanumeric, space, /, ', -, # only
  String pattern = r"^[-a-zA-Z0-9 ./'#&]{5,21}$";
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(value)) {
    return 'alphanumeric, space, /, -, #, & only and length 5-21';
  }
  return null;
}

String? validateBankAccountNumber(String value) {
  if (value.trim().isEmpty) {
    // return 'required';
    return null;
  }

  // validate number, letter, underscore, and dash,
  // and minimum 5 characters
  String pattern = r'^[a-zA-Z0-9_ -]{5,}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(value)) {
    return 'min length is 5 and letter, number, _, - only';
  }
  return null;
}

String? validatePaymentAmount(String value) {
  if (value.isEmpty) {
    return 'Payment amount is required';
  }
  // Add more validation logic if needed
  // numeric, 0 to 1 billion, up to 2 decimal places
  final RegExp numeric = RegExp(r'^\d{1,9}(\.\d{0,2})?$');
  if (!numeric.hasMatch(value)) {
    return 'Invalid payment amount format';
  }
  return null;
}

String? validateTenantRef(String value) {
  if (value.isEmpty) {
    return 'Tenant reference is required';
  }
  // Add more validation logic if needed
  // alphanumeric, space, - _ / # . + & ( ) ' : @ and 1-255 characters
  final RegExp alphanumeric = RegExp(r"^[a-zA-Z0-9\-\/#_\. +&()/':@]{1,255}$");
  if (!alphanumeric.hasMatch(value)) {
    return 'Invalid tenant reference format';
  }
  return null;
}

String? validatePaymentMethod(String value) {
  if (value.isEmpty) {
    return 'Payment method is required';
  }
  // PagTenantPaymentMethod.values
  if (!PagTenantPaymentMethod.values.any((e) => e.value == value)) {
    return 'Invalid payment method';
  }
  return null;
}

String? validateCreditTerm(String value) {
  if (value.isEmpty) {
    return 'Credit term is required';
  }
  // 1 to 30
  final int? term = int.tryParse(value);
  if (term == null || term < 1 || term > 30) {
    return 'Credit term must be a positive integer between 1 and 30';
  }
  return null;
}

String? validateGfa(String value) {
  if (value.isEmpty) {
    // return 'GFA is required';
    return null;
  }
  // numeric, 0 to 1 billion, up to 2 decimal places
  final RegExp numeric = RegExp(r'^\d{1,9}(\.\d{0,2})?$');
  if (!numeric.hasMatch(value)) {
    return 'Invalid GFA format';
  }
  return '';
}

// String? validateLabel(String value) {
//   if (value.trim().isEmpty) {
//     return 'required';
//   }

//   // validate number, letter, underscore, and dash, space,
//   // and minimum 5 characters
//   String pattern = r'^[a-zA-Z0-9_ -]{5,}$';
//   RegExp regExp = RegExp(pattern);
//   if (!regExp.hasMatch(value)) {
//     return 'min length is 5 and letter, number, space, _, - only';
//   }
//   return null;
// }

String? validateAccountNumber(String value) {
  // if (value.trim().isEmpty) {
  //   return 'required';
  // }
  if (value.trim().isEmpty) {
    return null;
  }
  // validate number, letter, underscore, and dash,
  // and minimum 5 characters
  String pattern = r'^[a-zA-Z0-9_ -]{5,}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(value)) {
    return 'min length is 5 and letter, number, _, - only';
  }
  return null;
}

String? validateAccountNumber2(String value) {
  if (value.trim().isEmpty) {
    return 'required';
  }
  // if (value.trim().isEmpty) {
  //   return null;
  // }
  // validate number, letter, underscore, and dash,
  // and minimum 5 characters
  String pattern = r'^[a-zA-Z0-9_ -]{5,}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(value)) {
    return 'min length is 5 and letter, number, _, - only';
  }
  return null;
}

String? validateDepositAmount(String value) {
  if (value.trim().isEmpty) {
    // return 'required';
    return null;
  }
  //must be a number
  if (double.tryParse(value) == null) {
    return 'must be a number';
  }
  return null;
}

String? validateFloorArea(String value) {
  double max = 1000000;
  if (value.trim().isEmpty) {
    return 'required';
  }
  //must be a number
  if (double.tryParse(value) == null) {
    return 'must be a number';
  }
  // min max
  double floorArea = double.parse(value);
  if (floorArea < 1 || floorArea > max) {
    return 'must be between 1 and $max';
  }
  return null;
}

String? validateBillingContactName(String value) {
  return validateFullName(value);
}

String? validateBillingContactEmail(String value) {
  return validateEmail(value);
}

// String? validateBillingContactPhone(String value) {
//   return validatePhone(value);
// }

String? validateSupplyCapKva(String value) {
  if (value.trim().isEmpty) {
    // return 'required';
    return null;
  }
  double max = 10000;
  //must be a number
  if (double.tryParse(value) == null) {
    return 'must be a number';
  }
  // min max
  double supplyCapKva = double.parse(value);
  if (supplyCapKva < 1 || supplyCapKva > max) {
    return 'must be between 1 and $max';
  }
  return null;
}

String? validateSupplyCapV(String value) {
  double max = 1000;
  if (value.trim().isEmpty) {
    // return 'required';
    return null;
  }
  //must be a number
  if (double.tryParse(value) == null) {
    return 'must be a number';
  }
  // min max
  double supplyCapV = double.parse(value);
  if (supplyCapV < 1 || supplyCapV > max) {
    return 'must be between 1 and $max';
  }
  return null;
}

String? validateSupplyCapAmp(String value) {
  double max = 3000;
  if (value.trim().isEmpty) {
    // return 'required';
    return null;
  }
  //must be a number
  if (double.tryParse(value) == null) {
    return 'must be a number';
  }
  // min max
  double supplyCapAmps = double.parse(value);
  if (supplyCapAmps < 1 || supplyCapAmps > max) {
    return 'must be between 1 and $max';
  }
  return null;
}

String? validateRequestedTurnOnDate(String value) {
  if (value.trim().isEmpty) {
    return 'required';
  }
  //must be a timestamp
  if (DateTime.tryParse(value) == null) {
    return 'must be a timestamp';
  }
  // must be in the future
  DateTime requestedTurnOnDate = DateTime.parse(value);
  if (requestedTurnOnDate.isBefore(DateTime.now())) {
    return 'must be in the future';
  }
  return null;
}

String? validateFtfStartDate(String value) {
  // if (value.trim().isEmpty) {
  //   return 'required';
  // }
  if (value.trim().isEmpty) {
    return null;
  }
  //must be a timestamp
  if (DateTime.tryParse(value) == null) {
    return 'must be a timestamp';
  }
  // must be in the future
  DateTime ftfStartDate = DateTime.parse(value);
  if (ftfStartDate.isBefore(DateTime.now())) {
    return 'must be in the future';
  }
  return null;
}

String? validateDdaNumber(String value) {
  // if (value.trim().isEmpty) {
  //   return 'required';
  // }
  if (value.trim().isEmpty) {
    return null;
  }
  // validate number, letter, underscore, and dash,
  // and minimum 5 characters
  String pattern = r'^[a-zA-Z0-9_ -]{5,}$';
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(value)) {
    return 'min length is 5 and letter, number, space, _, - only';
  }
  return null;
}

String? validateUnitType(String value) {
  if (value.isEmpty) {
    return 'Unit type is required';
  }
  // PagTenantUnitType.values
  if (!PagTenantUnitType.values.any((e) => e.value == value)) {
    return 'Invalid unit type';
  }
  return null;
}

String? validateFirstReadingValue(String value) {
  if (value.trim().isEmpty) {
    return 'required';
  }
  //must be a number
  if (double.tryParse(value) == null) {
    return 'must be a number';
  }
  return null;
}

String? validateFirstReadingTimestamp(String value) {
  if (value.trim().isEmpty) {
    return 'required';
  }
  //must be a timestamp
  if (DateTime.tryParse(value) == null) {
    return 'must be a timestamp';
  }

  return null;
}

String? validateLastReadingValue(String value) {
  if (value.trim().isEmpty) {
    // return 'required';
  }
  //must be a number
  if (double.tryParse(value) == null) {
    return 'must be a number';
  }

  return null;
}

String? validateBillingDid(String value) {
  if (value.trim().isEmpty) {
    // return 'required';
    return null;
  }
  return validatePhone(value);
}

String? validateBillingContactDid(String value) {
  if (value.trim().isEmpty) {
    // return 'required';
    return null;
  }
  return validatePhone(value);
}

String? validateInitialBalance(String value) {
  if (value.trim().isEmpty) {
    // return 'required';
  }
  //must be a number
  if (double.tryParse(value) == null) {
    return 'must be a number';
  }

  return null;
}
// String? validateLastReadingTimestamp(
//     String? val, String? firstReadingTimestampStr) {
//   if (val == null || val.trim().isEmpty) {
//     // return 'required';
//   } else {
//     //must be a timestamp
//     if (DateTime.tryParse(val) == null) {
//       return 'must be a timestamp';
//     }

//     // must be greater than first reading timestamp
//     if (firstReadingTimestampStr != null) {
//       DateTime firstReadingDatetime = DateTime.parse(firstReadingTimestampStr!);
//       DateTime lastReadingDatetime = DateTime.parse(val);
//       if (lastReadingDatetime.isBefore(firstReadingDatetime)) {
//         return 'must be greater than first reading timestamp';
//       }
//     }
//   }
//   return null;
// }

enum PagTenantOpType {
  onboarding,
  mgAssign1on1,
  update,
  none,
}

/*
company_trading_name
billing_address,
billing_address_line_1,
billing_address_line_2,
billing_address_line_3,
label,
account_number,
billing_contact_name,
billing_email,
billing_did,
payment_method,
credit_term,
bank_account_number,
deposit_amount,
unit_type,
gfa,
supply_cap_kva,
supply_cap_v,
supply_cap_amp,
requested_turn_on_date,
ftf_start_date,
dda_number,
site_label,
building_label,
location_label,
initial_balance,
initial_balance_timestamp
 */
final List<Map<String, dynamic>> listConfigBaseTenant = [
  {
    'col_key': 'account_number',
    'title': 'Account Number',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': false,
    'validator': validateAccountNumber,
  },
];
final List<Map<String, dynamic>> listConfigBaseTenantExt = [
  {
    'col_key': 'company_trading_name',
    'title': 'Company Trading Name',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': true,
    'validator': validateCompanyTradingName,
  },
  {
    'col_key': 'label',
    'title': 'Label',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateTenantLabel,
  },
  // {
  //   'col_key': 'billing_address',
  //   'title': 'Billing Address',
  //   'col_type': 'string',
  //   'width': 200,
  //   'is_mapping_required': false,
  //   'validator': validateBillingAddress,
  // },

  {
    'col_key': 'billing_address_line_1',
    'title': 'Billing Address Line 1',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': true,
    'validator': validateBillingAddressLine1
  },
  {
    'col_key': 'billing_address_line_2',
    'title': 'Billing Address Line 2',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': false,
    'validator': validateBillingAddressLine2,
  },
  {
    'col_key': 'billing_address_line_3',
    'title': 'Billing Address Line 3',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': false,
    'validator': validateBillingAddressLine3,
  },
  // {
  //   'col_key': 'account_number',
  //   'title': 'Account Number',
  //   'col_type': 'string',
  //   'width': 150,
  //   'is_mapping_required': true,
  //   'validator': validateBankAccountNumber,
  // },
  {
    'col_key': 'giro_account_number',
    'title': 'Giro',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateBankAccountNumber,
  },
  {
    'col_key': 'billing_contact_name',
    'title': 'Billing Contact Name',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateFullName,
  },
  {
    'col_key': 'billing_email',
    'title': 'Billing Email',
    'col_type': 'email',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateEmail,
  },
  {
    'col_key': 'billing_did',
    'title': 'Billing DID',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateBillingDid,
  },
  {
    'col_key': 'payment_method',
    'title': 'Payment Method',
    'col_type': 'enum',
    'width': 150,
    'is_mapping_required': true,
    // 'enum_values': PagTenantPaymentMethod.values
    //     .map((e) => {'label': e.label, 'value': e.value})
    //     .toList(),
    'validator': validatePaymentMethod,
  },
  {
    'col_key': 'credit_term',
    'title': 'Credit Term',
    'col_type': 'int',
    'width': 100,
    'is_mapping_required': true,
    'validator': validateCreditTerm,
  },
  {
    'col_key': 'bank_account_number',
    'title': 'Bank Account Number',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateBankAccountNumber,
  },
  {
    'col_key': 'deposit_amount',
    'title': 'Deposit Amount',
    'col_type': 'double',
    'width': 120,
    'is_mapping_required': true,
    'validator': validateDepositAmount,
  },
  {
    'col_key': 'unit_type',
    'title': 'Unit Type',
    'col_type': 'enum',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateUnitType,
  },
  {
    'col_key': 'gfa',
    'title': 'GFA',
    'col_type': 'double',
    'width': 120,
    'is_mapping_required': false,
    'validator': validateGfa
  },
  {
    'col_key': 'supply_cap_kva',
    'title': 'Supply Cap KVA',
    'col_type': 'double',
    'width': 120,
    'is_mapping_required': false,
    'validator': validateSupplyCapKva,
  },
  {
    'col_key': 'supply_cap_v',
    'title': 'Supply Cap V',
    'col_type': 'double',
    'width': 120,
    'is_mapping_required': false,
    'validator': validateSupplyCapV,
  },
  {
    'col_key': 'supply_cap_amp',
    'title': 'Supply Cap Amp',
    'col_type': 'double',
    'width': 120,
    'is_mapping_required': false,
    'validator': validateSupplyCapAmp,
  },
  {
    'col_key': 'requested_turn_on_date',
    'title': 'Requested Turn On Date',
    'col_type': 'date',
    'width': 120,
    'is_mapping_required': false,
    'validator': validateRequestedTurnOnDate,
  },
  {
    'col_key': 'ftf_start_date',
    'title': 'FTF Start Date',
    'col_type': 'date',
    'width': 120,
    'is_mapping_required': false,
    'validator': validateFtfStartDate,
  },
  {
    'col_key': 'dda_number',
    'title': 'DDA Number',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': false,
    'validator': validateDdaNumber,
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
  // {
  //   'col_key': 'initial_balance',
  //   'title': 'Initial Balance',
  //   'col_type': 'double',
  //   'width': 150,
  //   'is_mapping_required': false,
  //   'validator': validateInitialBalance,
  // },
  // {
  //   'col_key': 'initial_balance_timestamp',
  //   'title': 'Initial Balance Date',
  //   'col_type': 'date',
  //   'width': 150,
  //   'is_mapping_required': false,
  //   'validator': validateDate,
  // },
];

// must be 'mg-1-on-1'
String? validateMgAssign1on1Type(dynamic value) {
  if (value == null || value.toString().isEmpty) {
    return 'Onb Type is required';
  }
  final validTypes = ['auto-1-on-1'];
  if (!validTypes.contains(value.toString())) {
    return 'Invalid Onb Type';
  }
  return null;
}

final List<Map<String, dynamic>> listConfigMgAssign1on1 = [
  // {
  //   'col_key': 'location_label',
  //   'title': 'Location Label',
  //   'col_type': 'string',
  //   'width': 200,
  //   'is_mapping_required': true,
  //   'validator': validateLabelScope,
  // },
  {
    'col_key': 'mg_assign_type',
    'title': 'MG Type',
    'col_type': 'string',
    'width': 200,
    'is_mapping_required': true,
    'validator': validateMgAssign1on1Type,
  },
];

List<Map<String, dynamic>> getListConfigBaseByOpType(PagTenantOpType opType) {
  final List<Map<String, dynamic>> list = [];
  switch (opType) {
    case PagTenantOpType.onboarding:
      list.addAll(listConfigBaseTenant + listConfigBaseTenantExt);
      break;
    case PagTenantOpType.update:
      list.addAll(listConfigBaseTenant + listConfigBaseTenantExt);
      break;
    case PagTenantOpType.mgAssign1on1:
      final accountNumberConfig = listConfigBaseTenant
          .firstWhere((element) => element['col_key'] == 'account_number');
      accountNumberConfig['validator'] = validateAccountNumber2;
      list.addAll(listConfigBaseTenant + listConfigMgAssign1on1);
      break;
    default:
      list.addAll(listConfigBaseTenant + []);
  }
  //remove empty maps
  list.removeWhere((map) => map.isEmpty);
  return list;
}
