import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum PtwApplicationStatus {
  NEW,
  APPROVED,
  REJECTED,
  UNKNOWN,
}

enum PtwEventLockOpStatus {
  LOCK_SUCCESS,
  LOCK_FAIL,
  UNLOCK_SUCCESS,
  UNLOCK_FAIL,
  UNKNOWN,
}

final Map<PtwEventLockOpStatus, dynamic> ptwEventLockOpStatusInfo = {
  PtwEventLockOpStatus.LOCK_SUCCESS: {
    'tag': 'L.S',
    'color': Colors.green,
    'tooltip': 'Lock Success',
    'icon': const Icon(Symbols.lock),
  },
  PtwEventLockOpStatus.LOCK_FAIL: {
    'tag': 'L.F',
    'color': Colors.red,
    'tooltip': 'Lock Fail',
    'icon': const Icon(Symbols.lock),
  },
  PtwEventLockOpStatus.UNLOCK_SUCCESS: {
    'tag': 'UL.S',
    'color': Colors.green,
    'tooltip': 'Unlock Success',
    'icon': const Icon(Symbols.lock_open_right),
  },
  PtwEventLockOpStatus.UNLOCK_FAIL: {
    'tag': 'UL.F',
    'color': Colors.red,
    'tooltip': 'Unlock Fail',
    'icon': const Icon(Symbols.lock_open_right),
  },
  PtwEventLockOpStatus.UNKNOWN: {
    'tag': 'UNK.',
    'color': Colors.grey,
    'tooltip': 'Unknown',
    'icon': const Icon(Symbols.unknown_med),
  },
};

final Map<PtwApplicationStatus, dynamic> applicatoinStatusInfo = {
  PtwApplicationStatus.NEW: {
    'tag': 'NEW',
    'color': Colors.orangeAccent,
    'tooltip': 'New',
  },
  PtwApplicationStatus.APPROVED: {
    'tag': 'APPR.',
    'color': Colors.green,
    'tooltip': 'Approved',
  },
  PtwApplicationStatus.REJECTED: {
    'tag': 'REJ.',
    'color': Colors.red,
    'tooltip': 'Rejected',
  },
  PtwApplicationStatus.UNKNOWN: {
    'tag': 'UNK.',
    'color': Colors.grey,
    'tooltip': 'Unknown',
  },
};

Map<String, dynamic> getPtwEventLockOpStatusTag(row, fieldKey) {
  if ((row[fieldKey] ?? '').isEmpty) {
    return {};
  }
  if (row[fieldKey] == '-') {
    return {};
  }
  String valueStr = row[fieldKey].toString().toUpperCase();
  PtwEventLockOpStatus? status = getPtwEventLockOpStatus(valueStr);
  if (status == PtwEventLockOpStatus.UNKNOWN) {
    return {};
  }

  return {
    'tag': ptwEventLockOpStatusInfo[status]!['tag'],
    'color': ptwEventLockOpStatusInfo[status]!['color'],
    'tooltip': ptwEventLockOpStatusInfo[status]!['tooltip'],
  };
}

PtwEventLockOpStatus getPtwEventLockOpStatusFromCode(
    String statusCod, String ressultCode) {
  if (statusCod == '3') {
    //Lock
    if (ressultCode == '5') {
      return PtwEventLockOpStatus.LOCK_SUCCESS;
    } else if (ressultCode == '1') {
      return PtwEventLockOpStatus.LOCK_FAIL;
    }
  } else if (statusCod == '0') {
    //Unlock
    if (ressultCode == '5') {
      return PtwEventLockOpStatus.UNLOCK_SUCCESS;
    } else if (ressultCode == '1') {
      return PtwEventLockOpStatus.UNLOCK_FAIL;
    }
  }
  return PtwEventLockOpStatus.UNKNOWN;
}

PtwEventLockOpStatus getPtwEventLockOpStatus(String? statusStr) {
  switch (statusStr) {
    case 'LOCK_SUCCESS':
      return PtwEventLockOpStatus.LOCK_SUCCESS;
    case 'LOCK_FAIL':
      return PtwEventLockOpStatus.LOCK_FAIL;
    case 'UNLOCK_SUCCESS':
      return PtwEventLockOpStatus.UNLOCK_SUCCESS;
    case 'UNLOCK_FAIL':
      return PtwEventLockOpStatus.UNLOCK_FAIL;
    default:
      return PtwEventLockOpStatus.UNKNOWN;
  }
}

Map<String, dynamic> getPtwApplicationStatusTag(row, fieldKey) {
  if ((row['status'] ?? '').isEmpty) {
    return {};
  }
  if (row['status'] == '-') {
    return {};
  }
  String valueStr = row['status'].toString().toUpperCase();
  PtwApplicationStatus? status = getPtwApplicationStatus(valueStr);
  if (status == PtwApplicationStatus.UNKNOWN) {
    return {};
  }

  Color color = applicatoinStatusInfo[status]!['color'];

  return {
    'tag': getPtwApplicationStatusTagStr(valueStr),
    'color': color,
    'tooltip': getPtwApplicationStatusMessage(status.name),
  };
}

PtwApplicationStatus getPtwApplicationStatus(String? statusStr) {
  switch (statusStr) {
    case 'NEW':
      return PtwApplicationStatus.NEW;
    case 'APPROVED':
      return PtwApplicationStatus.APPROVED;
    case 'REJECTED':
      return PtwApplicationStatus.REJECTED;
    default:
      return PtwApplicationStatus.UNKNOWN;
  }
}

Icon getPtwEventOpStatusIcon(String? statusStr, {double size = 19}) {
  PtwEventLockOpStatus? status = getPtwEventLockOpStatus(statusStr);
  Color color = ptwEventLockOpStatusInfo[status]!['color'];
  Icon icon = ptwEventLockOpStatusInfo[status]!['icon'];

  return Icon(icon.icon, color: color, size: size);
}

String? getPtwApplicationStatusTagStr(String? statusStr) {
  if ((statusStr ?? '').isEmpty) {
    return null;
  }
  PtwApplicationStatus? status = getPtwApplicationStatus(statusStr);

  return applicatoinStatusInfo[status]!['tag'];
}

String getPtwApplicationStatusMessage(String? statusStr) {
  if (statusStr == null) {
    return 'N/A';
  }
  PtwApplicationStatus? status = PtwApplicationStatus.values.byName(statusStr);

  return applicatoinStatusInfo[status]!['tooltip'];
}

Color getPtwApplicationStatusColor(String? statusStr) {
  if (statusStr == null || statusStr.isEmpty) {
    return Colors.transparent;
  }
  PtwApplicationStatus? status = PtwApplicationStatus.values.byName(statusStr);

  return applicatoinStatusInfo[status]!['color'];
}
