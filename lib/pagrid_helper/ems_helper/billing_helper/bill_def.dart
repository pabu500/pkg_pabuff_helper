import 'package:flutter/material.dart';

enum BillGenType { manual, auto }

enum BillingLcStatus { generated, released, mfd }

String? getGenTypeTagStr(String? statusStr) {
  if ((statusStr ?? '').isEmpty) {
    return null;
  }
  BillGenType? status = BillGenType.values.byName(statusStr!);
  return genTypeInfo[status]!['tag'];
}

String getGenTypeMessage(String? statusStr) {
  if (statusStr == null) {
    return 'N/A';
  }
  BillGenType? status = BillGenType.values.byName(statusStr);

  return genTypeInfo[status]!['tooltip'];
}

Color getGenTypeColor(String? statusStr) {
  if (statusStr == null || statusStr.isEmpty) {
    return Colors.transparent;
  }
  BillGenType? status = BillGenType.values.byName(statusStr);

  return genTypeInfo[status]!['color'];
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

String? getBillingLcStatusTagStr(String? statusStr) {
  if ((statusStr ?? '').isEmpty) {
    return null;
  }
  BillingLcStatus? status = BillingLcStatus.values.byName(statusStr!);
  return billingLcStatusInfo[status]!['tag'];
}

String getBillingLcStatusMessage(String? statusStr) {
  if (statusStr == null) {
    return 'N/A';
  }
  BillingLcStatus? status = BillingLcStatus.values.byName(statusStr);

  return billingLcStatusInfo[status]!['tooltip'];
}

Color getBillingLcSatusColor(String? statusStr) {
  if (statusStr == null || statusStr.isEmpty) {
    return Colors.transparent;
  }
  BillingLcStatus? status = BillingLcStatus.values.byName(statusStr);

  return billingLcStatusInfo[status]!['color'];
}

BillingLcStatus? getBillingLcStatusFromTagStr(String? tagStr) {
  if ((tagStr ?? '').isEmpty) {
    return BillingLcStatus.generated;
  }
  for (var status in BillingLcStatus.values) {
    if (billingLcStatusInfo[status]!['tag'] == tagStr) {
      return status;
    }
  }
  return null;
}

final Map<BillingLcStatus, dynamic> billingLcStatusInfo = {
  BillingLcStatus.generated: {
    'tag': 'Gn',
    'color': Colors.teal.withOpacity(0.8),
    'tooltip': 'Generated',
  },
  BillingLcStatus.released: {
    'tag': 'Rl',
    'color': Colors.orangeAccent.withOpacity(0.7),
    'tooltip': 'Released',
  },
  BillingLcStatus.mfd: {
    'tag': 'Dl',
    'color': Colors.redAccent.shade200.withOpacity(0.7),
    'tooltip': 'Marked for Delete',
  },
};
