import 'package:flutter/material.dart';

enum BillGenType { manual, auto }

enum BillingLcStatus { generated, released }

String? getGenTypeTagStr(String? statusStr) {
  if ((statusStr ?? '').isEmpty) {
    return null;
  }
  BillGenType? status = BillGenType.values.byName(statusStr!);
  switch (status) {
    case BillGenType.auto:
      return 'A';
    case BillGenType.manual:
      return 'M';
  }
}

String getGenTypeMessage(String? statusStr) {
  if (statusStr == null) {
    return 'N/A';
  }
  BillGenType? status = BillGenType.values.byName(statusStr);

  switch (status) {
    case BillGenType.auto:
      return 'Auto';
    case BillGenType.manual:
      return 'Manual';
    default:
      return 'N/A';
  }
}

Color getGenTypeColor(String? statusStr) {
  if (statusStr == null || statusStr.isEmpty) {
    return Colors.transparent;
  }
  BillGenType? status = BillGenType.values.byName(statusStr);

  switch (status) {
    case BillGenType.auto:
      return Colors.teal;
    case BillGenType.manual:
      return Colors.orangeAccent.withOpacity(0.7);
    default:
      return Colors.transparent;
  }
}

final Map<BillGenType, dynamic> genTypeInfo = {
  BillGenType.auto: {
    'tag': 'A',
    'color': Colors.teal,
    'tooltip': 'Auto',
  },
  BillGenType.manual: {
    'tag': 'M',
    'color': Colors.orangeAccent.withOpacity(0.7),
    'tooltip': 'Manual',
  },
};

Map<String, dynamic> getGenTypeTag(row, fieldKey) {
  if ((row['gen_type'] ?? '').isEmpty) {
    return {};
  }
  if (row['gen_type'] == '-') {
    return {};
  }
  String valueStr = row['gen_type'].toString().toLowerCase();
  BillGenType? status = BillGenType.values.byName(valueStr);

  return {
    'tag': getGenTypeTagStr(valueStr),
    'color': getGenTypeColor(status.name),
    'tooltip': getGenTypeMessage(status.name),
  };
}

String? getBillingLcStatusTagStr(String? statusStr) {
  if ((statusStr ?? '').isEmpty) {
    return null;
  }
  BillingLcStatus? status = BillingLcStatus.values.byName(statusStr!);
  switch (status) {
    case BillingLcStatus.generated:
      return 'Gn';
    case BillingLcStatus.released:
      return 'Rl';
  }
}

String getBillingLcStatusMessage(String? statusStr) {
  if (statusStr == null) {
    return 'N/A';
  }
  BillingLcStatus? status = BillingLcStatus.values.byName(statusStr);

  switch (status) {
    case BillingLcStatus.generated:
      return 'Generated';
    case BillingLcStatus.released:
      return 'Released';
    default:
      return 'N/A';
  }
}

Color getBillingLcSatusColor(String? statusStr) {
  if (statusStr == null || statusStr.isEmpty) {
    return Colors.transparent;
  }
  BillingLcStatus? status = BillingLcStatus.values.byName(statusStr);

  switch (status) {
    case BillingLcStatus.generated:
      return Colors.teal.withOpacity(0.8);
    case BillingLcStatus.released:
      return Colors.orangeAccent.withOpacity(0.7);
    default:
      return Colors.transparent;
  }
}

Map<String, dynamic> getBillingLcStatusTag(row, fieldKey) {
  if ((row['lc_status'] ?? '').isEmpty) {
    return {};
  }
  if (row['lc_status'] == '-') {
    return {};
  }
  String valueStr = row['lc_status'].toString().toLowerCase();
  BillingLcStatus? status = BillingLcStatus.values.byName(valueStr);

  return {
    'tag': getBillingLcStatusTagStr(valueStr),
    'color': getBillingLcSatusColor(status.name),
    'tooltip': getBillingLcStatusMessage(status.name),
  };
}
