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
    'color': Colors.orangeAccent.withAlpha(210),
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
    'color': getBillingLcStatusColor(status.name),
    'tooltip': getBillingLcStatusMessage(status.name),
  };
}

String? getBillingLcStatusTagStr(String? statusStr) {
  if ((statusStr ?? '').isEmpty) {
    return null;
  }
  PagBillingLcStatus? status = PagBillingLcStatus.values.byName(statusStr!);
  return status.tag;
}

String getBillingLcStatusMessage(String? statusStr) {
  if (statusStr == null) {
    return 'N/A';
  }
  PagBillingLcStatus? status = PagBillingLcStatus.values.byName(statusStr);

  return status.label!;
}

Color getBillingLcStatusColor(String? statusStr) {
  if (statusStr == null || statusStr.isEmpty) {
    return Colors.transparent;
  }
  PagBillingLcStatus? status = PagBillingLcStatus.values.byName(statusStr);

  return status.color!;
}

PagBillingLcStatus? getBillingLcStatusFromTagStr(String? tagStr) {
  if ((tagStr ?? '').isEmpty) {
    return PagBillingLcStatus.generated;
  }
  for (var status in PagBillingLcStatus.values) {
    if (status.tag == tagStr) {
      return status;
    }
  }
  return null;
}

Widget getBillLcStatusTagWidget(
  BuildContext ctx,
  PagBillingLcStatus status, {
  TextStyle? style,
}) {
  Color bgColor = status.color!;
  return Container(
    decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: Theme.of(ctx).hintColor,
        )),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    child: Text(
      status.tag!,
      style: style ??
          const TextStyle(
            color: Colors.white,
            fontSize: 13.5,
          ),
    ),
  );
}

// final Map<PagBillingLcStatus, dynamic> billingLcStatusInfo = {
//   PagBillingLcStatus.generated: {
//     'tag': 'Gn',
//     'color': Colors.teal.withAlpha(210),
//     'tooltip': 'Generated',
//   },
//   PagBillingLcStatus.released: {
//     'tag': 'Rl',
//     'color': Colors.orangeAccent.withAlpha(210),
//     'tooltip': 'Released',
//   },
//   PagBillingLcStatus.pv: {
//     'tag': 'Pv',
//     'color': Colors.blue.withAlpha(210),
//     'tooltip': 'Pending Verification',
//   },
//   PagBillingLcStatus.mfd: {
//     'tag': 'Dl',
//     'color': Colors.redAccent.shade200.withAlpha(210),
//     'tooltip': 'Marked for Delete',
//   },
// };
