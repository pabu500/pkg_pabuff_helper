import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'dh_pag_tenant.dart';
import 'enum_helper.dart';

enum PagFinanceType {
  tenantSoa('Statement of Account', 'tenant_soa', 'soa', Symbols.contract),
  payment('Payment', 'payment', 'pyt', Symbols.attach_money),
  paymentApply('Payment Apply', 'payment_apply', 'pya', Symbols.bucket_check),
  none('None', 'none', 'none', Symbols.block);

  const PagFinanceType(
    this.label,
    this.value,
    this.tag,
    this.iconData,
  );

  final String label;
  final String value;
  final String tag;
  final IconData iconData;

  static PagFinanceType byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      none;

  static PagFinanceType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagFinanceType? byTag(String? tag) => enumByTag(
        tag,
        values,
        (e) => (e).tag,
      );
}

// T? enumByTag<T extends Enum>(String? tag, List<T> values) {
//   if (tag == null) return null;
//   for (var value in values) {
//     if (value is PagFinanceType && value.tag.replaceAll('.', '') == tag) {
//       return value as T;
//     }
//   }
//   return null;
// }

String getPagFinanceTypeStr(dynamic itemType) {
  switch (itemType) {
    case PagFinanceType.tenantSoa:
      return PagFinanceType.tenantSoa.value;
    case PagFinanceType.payment:
      return PagFinanceType.payment.value;
    case PagFinanceType.paymentApply:
      return PagFinanceType.paymentApply.value;
    default:
      return '';
  }
}

enum PagPaymentLcStatus {
  posted('posted', 'Posted', 'pt', Colors.lightBlue),
  matched('matched', 'Matched', 'mt', Colors.teal),
  released('released', 'Released', 'rl', Colors.orangeAccent),
  mfd('mfd', 'MFD', 'mfd', Colors.redAccent),
  unknown('unknown', 'Unknown', 'un', Colors.grey),
  ;

  const PagPaymentLcStatus(this.value, this.label, this.tag, this.color);

  final String label;
  final String value;
  final String tag;
  final Color color;

  static PagPaymentLcStatus byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      unknown;
}

Widget getPaymentLcStatusTagWidget(
  BuildContext ctx,
  PagPaymentLcStatus status, {
  TextStyle? style,
}) {
  Color bgColor = status.color;
  return Container(
    decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: Theme.of(ctx).hintColor,
        )),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    child: Text(
      status.tag,
      style: style ??
          const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
          ),
    ),
  );
}

enum PaymentSoaType {
  normal('normal', 'normal', 'nm', Colors.green),
  initialBalance(
      'initial_balance', 'initial_balance', 'ini', Colors.deepOrangeAccent),
  ;

  const PaymentSoaType(this.value, this.label, this.tag, this.color);

  final String label;
  final String value;
  final String tag;
  final Color color;

  static PaymentSoaType byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      normal;
}

Widget getPaymentSoaTypeTagWidget(
  BuildContext ctx,
  PaymentSoaType type, {
  TextStyle? style,
}) {
  Color bgColor = type.color;
  return Container(
    decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: Theme.of(ctx).hintColor,
        )),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    child: Text(
      type.tag,
      style: style ??
          const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
          ),
    ),
  );
}

enum PagSoaEntryType {
  initialBalance('Initial Balance', 'initial_balance', 'init', Colors.teal),
  tenantSoa('Bill', 'bill', 'bill', Colors.deepOrangeAccent),
  payment('Payment', 'payment', 'pmt', Colors.green),
  paymentApply('Payment Apply', 'payment_apply', 'pya', Colors.orangeAccent),
  adjustment('Adjustment', 'adjustment', 'adj', Colors.blueAccent),
  ;

  const PagSoaEntryType(
    this.label,
    this.value,
    this.tag,
    this.color,
  );

  final String label;
  final String value;
  final String tag;
  final Color color;

  static PagSoaEntryType byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      tenantSoa;

  static PagSoaEntryType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagSoaEntryType? byTag(String? tag) => enumByTag(
        tag,
        values,
        (e) => (e).tag,
      );
}

enum PagPaymentOpType {
  postPayment('Post Payment', 'pp', Symbols.contract),
  matchPayment('Match Payment', 'pm', Symbols.attach_money),
  none('None', 'none', Symbols.block),
  ;

  const PagPaymentOpType(
    this.label,
    this.tag,
    this.iconData,
  );

  final String label;
  final String tag;
  final IconData iconData;

  static PagPaymentOpType byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).tag,
      ) ??
      none;

  static PagPaymentOpType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagPaymentOpType? byTag(String? tag) => enumByTag(
        tag,
        values,
        (e) => (e).tag,
      );
}

String? soaTypeValidator(String? value) {
  // only 'normal' or 'initial_balance' allowed
  if (value == null || value.isEmpty) {
    return 'Type is required';
  }
  final allowedTypes = ['normal', 'initial_balance'];
  if (!allowedTypes.contains(value.toLowerCase())) {
    return 'Invalid type, allowed: normal, initial_balance';
  }
  return null;
}

String? validatePaymentLcStatus(String value) {
  if (value.trim().isEmpty) {
    return 'required';
  }
  PagPaymentLcStatus? status = PagPaymentLcStatus.byValue(value);
  if (status == PagPaymentLcStatus.unknown) {
    return 'Invalid LC status';
  }
  return null;
}

String? paymentMethodValidator(String? value) {
  // only 'giro' or 'non-giro' allowed
  if (value == null || value.isEmpty) {
    return 'Payment method is required';
  }
  final allowedTypes = ['giro', 'non_giro'];
  if (!allowedTypes.contains(value.toLowerCase())) {
    return 'Invalid payment method, allowed: giro, non_giro';
  }
  return null;
}

String? dateValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Date is required';
  }
  // Add more validation logic if needed
  // date format: yyyy-MM-dd or yyyyMMdd
  // final RegExp dateFormat = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  final RegExp dateFormat = RegExp(r'^\d{4}[-]?\d{2}[-]?\d{2}$');
  if (!dateFormat.hasMatch(value)) {
    return 'Invalid date format, expected yyyy-MM-dd or yyyyMMdd';
  }
  return null;
}

String? validateDateIgnoreTime(String? value) {
  if (value == null || value.isEmpty) {
    return 'Date is required';
  }
  // date format: yyyy-MM-dd or yyyyMMdd, ignore time part if present
  final RegExp dateFormat = RegExp(r'^\d{4}[-]?\d{2}[-]?\d{2}');
  if (!dateFormat.hasMatch(value)) {
    return 'Invalid date format, expected yyyy-MM-dd or yyyyMMdd';
  }
  return null;
}

List<Map<String, dynamic>> listConfigPostPayment = [
  {
    'col_key': 'landlord_bank_account_util',
    'title': 'Landlord Acc.',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateBankAccountNumber,
  },
  {
    'col_key': 'tenant_ref_1',
    'title': 'Tenant Ref 1',
    'col_type': 'string',
    'width': 180,
    'is_mapping_required': true,
    'validator': validateTenantRef,
  },
  {
    'col_key': 'tenant_ref_2',
    'title': 'Tenant Ref 2',
    'col_type': 'string',
    'width': 180,
    'is_mapping_required': false,
    'validator': validateTenantRef,
  },
  {
    'col_key': 'credit_amount',
    'title': 'Credit Amount',
    'col_type': 'double',
    'width': 120,
    'is_mapping_required': true,
    'validator': validatePaymentAmount,
  },
  {
    'col_key': 'value_date',
    'title': 'Value Date',
    'col_type': 'date',
    'width': 120,
    'is_mapping_required': true,
    'validator': dateValidator,
  },
  {
    'col_key': 'soa_type',
    'title': 'SoA Type',
    'col_type': 'string',
    'width': 120,
    'is_mapping_required': true,
    'validator': soaTypeValidator,
  },
  {
    'col_key': 'payment_method',
    'title': 'Payment Method',
    'col_type': 'string',
    'width': 120,
    'is_mapping_required': true,
    'validator': paymentMethodValidator,
  },
];

List<Map<String, dynamic>> listConfigMatchPayment = [
  {
    'col_key': 'tenant_name',
    'title': 'Tenant Name',
    'col_type': 'string',
    'width': 150,
    'is_mapping_required': true,
    'validator': validateTenantName,
  },
  {
    'col_key': 'tenant_label',
    'title': 'Tenant Label',
    'col_type': 'string',
    'width': 180,
    'is_mapping_required': true,
    'validator': validateTenantLabel,
  },
  {
    'col_key': 'payment_id',
    'title': 'Payment ID',
    'col_type': 'string',
    'width': 180,
    'is_mapping_required': false,
    'validator': validateItemId,
  },
  {
    'col_key': 'soa_type',
    'title': 'SoA Type',
    'col_type': 'string',
    'width': 120,
    'is_mapping_required': true,
    'validator': soaTypeValidator,
  },
  {
    'col_key': 'payment_lc_status',
    'title': 'Payment LC Status',
    'col_type': 'string',
    'width': 120,
    'is_mapping_required': true,
    'validator': validatePaymentLcStatus,
  },
  {
    'col_key': 'value_date',
    'title': 'Value Date',
    'col_type': 'date',
    'width': 120,
    'is_mapping_required': true,
    'validator': validateDateIgnoreTime,
  },
  {
    'col_key': 'amount',
    'title': 'Amount',
    'col_type': 'double',
    'width': 120,
    'is_mapping_required': true,
    'validator': validatePaymentAmount,
  },
  {
    'col_key': 'bill_id_1',
    'title': 'Bill ID 1',
    'col_type': 'string',
    'width': 120,
    'is_mapping_required': true,
    'validator': validateItemIdNotRequired,
  },
  {
    'col_key': 'cycle_total_1',
    'title': 'Cycle Total 1',
    'col_type': 'string',
    'width': 120,
    'is_mapping_required': true,
    'validator': validatePaymentAmountNotRequired,
  },
  {
    'col_key': 'remaining_1',
    'title': 'Remaining 1',
    'col_type': 'string',
    'width': 120,
    'is_mapping_required': true,
    'validator': validatePaymentAmountNotRequired,
  },
  {
    'col_key': 'principal_1',
    'title': 'Principal 1',
    'col_type': 'string',
    'width': 120,
    'is_mapping_required': true,
    'validator': validatePaymentAmountNotRequired,
  },
  {
    'col_key': 'interest_1',
    'title': 'Interest 1',
    'col_type': 'string',
    'width': 120,
    'is_mapping_required': true,
    'validator': validatePaymentAmountNotRequired,
  },
];

List<Map<String, dynamic>> getListConfigBaseByPaymentOpType(
    PagPaymentOpType opType) {
  final List<Map<String, dynamic>> list = [];
  switch (opType) {
    case PagPaymentOpType.postPayment:
      list.addAll(listConfigPostPayment);
      break;
    case PagPaymentOpType.matchPayment:
      list.addAll(listConfigMatchPayment);
      break;
    default:
      list.addAll(listConfigPostPayment);
  }
  //remove empty maps
  list.removeWhere((map) => map.isEmpty);
  return list;
}
