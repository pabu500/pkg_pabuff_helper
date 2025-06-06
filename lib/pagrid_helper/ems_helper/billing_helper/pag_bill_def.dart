import 'package:flutter/material.dart';

enum PagBillGenType { manual, auto }

enum PagBillingLcStatus {
  generated('Generated', 'Gn', 'generated', Colors.teal),
  released('Released', 'Rl', 'released', Colors.orangeAccent),
  mfd('Marked for Delete', 'MFD', 'mfd', Colors.redAccent),
  pv('Pending Verification', 'Pv', 'pv', Colors.blue);

  const PagBillingLcStatus([this.label, this.tag, this.value, this.color]);

  final String? label;
  final String? tag;
  final String? value;
  final Color? color;

  static PagBillingLcStatus byLabel(String label) {
    for (var status in values) {
      if (status.label == label) {
        return status;
      }
    }
    throw Exception('Invalid label: $label');
  }

  static PagBillingLcStatus byValue(String value) {
    for (var status in values) {
      if (status.value == value) {
        return status;
      }
    }
    throw Exception('Invalid value: $value');
  }

  static PagBillingLcStatus byTag(String tag) {
    for (var status in values) {
      if (status.tag?.replaceAll('.', '') == tag) {
        return status;
      }
    }
    throw Exception('Invalid tag: $tag');
  }
}

String? getGenTypeTagStr(String? statusStr) {
  if ((statusStr ?? '').isEmpty) {
    return null;
  }
  PagBillGenType? status = PagBillGenType.values.byName(statusStr!);
  return genTypeInfo[status]!['tag'];
}

String getGenTypeMessage(String? statusStr) {
  if (statusStr == null) {
    return 'N/A';
  }
  PagBillGenType? status = PagBillGenType.values.byName(statusStr);

  return genTypeInfo[status]!['tooltip'];
}

Color getGenTypeColor(String? statusStr) {
  if (statusStr == null || statusStr.isEmpty) {
    return Colors.transparent;
  }
  PagBillGenType? status = PagBillGenType.values.byName(statusStr);

  return genTypeInfo[status]!['color'];
}

final Map<PagBillGenType, dynamic> genTypeInfo = {
  PagBillGenType.auto: {
    'tag': 'A',
    'color': Colors.teal,
    'tooltip': 'Auto',
  },
  PagBillGenType.manual: {
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
  PagBillGenType? status = PagBillGenType.values.byName(valueStr);

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
  PagBillingLcStatus? status = PagBillingLcStatus.values.byName(valueStr);

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
  PagBillingLcStatus? status = PagBillingLcStatus.values.byName(statusStr!);
  return billingLcStatusInfo[status]!['tag'];
}

String getBillingLcStatusMessage(String? statusStr) {
  if (statusStr == null) {
    return 'N/A';
  }
  PagBillingLcStatus? status = PagBillingLcStatus.values.byName(statusStr);

  return billingLcStatusInfo[status]!['tooltip'];
}

Color getBillingLcSatusColor(String? statusStr) {
  if (statusStr == null || statusStr.isEmpty) {
    return Colors.transparent;
  }
  PagBillingLcStatus? status = PagBillingLcStatus.values.byName(statusStr);

  return billingLcStatusInfo[status]!['color'];
}

PagBillingLcStatus? getBillingLcStatusFromTagStr(String? tagStr) {
  if ((tagStr ?? '').isEmpty) {
    return PagBillingLcStatus.generated;
  }
  for (var status in PagBillingLcStatus.values) {
    if (billingLcStatusInfo[status]!['tag'] == tagStr) {
      return status;
    }
  }
  return null;
}

final Map<PagBillingLcStatus, dynamic> billingLcStatusInfo = {
  PagBillingLcStatus.generated: {
    'tag': 'Gn',
    'color': Colors.teal.withOpacity(0.8),
    'tooltip': 'Generated',
  },
  PagBillingLcStatus.released: {
    'tag': 'Rl',
    'color': Colors.orangeAccent.withOpacity(0.7),
    'tooltip': 'Released',
  },
  PagBillingLcStatus.pv: {
    'tag': 'Pv',
    'color': Colors.blue.withOpacity(0.7),
    'tooltip': 'Pending Verification',
  },
  PagBillingLcStatus.mfd: {
    'tag': 'Dl',
    'color': Colors.redAccent.shade200.withOpacity(0.7),
    'tooltip': 'Marked for Delete',
  },
};
