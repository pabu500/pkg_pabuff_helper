enum PagJobTaskType {
  itemHistory,
  tenantUsageReport,
  billCwNus,
  usageReport,
}

String? getPagJobTaskTypeName(PagJobTaskType jobType) {
  switch (jobType) {
    case PagJobTaskType.itemHistory:
      return 'item-history';
    case PagJobTaskType.tenantUsageReport:
      return 'tenant-usage-report';
    case PagJobTaskType.billCwNus:
      return 'bill-cw-nus';
    case PagJobTaskType.usageReport:
      return 'usage-report';
    default:
      return null;
  }
}

PagJobTaskType? getJobTaskType(String jobType) {
  switch (jobType) {
    case 'item-history':
      return PagJobTaskType.itemHistory;
    case 'tenant-usage-report':
      return PagJobTaskType.tenantUsageReport;
    case 'bill-cw-nus':
      return PagJobTaskType.billCwNus;
    case 'usage-report':
      return PagJobTaskType.usageReport;
  }
  return null;
}

const int minJobTypeLabelLength = 0;
const int maxJobTypeLabelLength = 30;

String? jobTypeLabelValidator(String? val) {
  // if (required) {
  //   if (val == null) {
  //     return 'required';
  //   }
  //   if (val.trim().isEmpty) {
  //     return 'required';
  //   }
  // }
  val = val ?? '';
  if (val.trim().isEmpty) {
    return null;
  }

  if (val.trim().length < minJobTypeLabelLength) {
    return 'must be at least $minJobTypeLabelLength characters';
  }
  if (val.trim().length > maxJobTypeLabelLength) {
    return 'must be less than $maxJobTypeLabelLength characters';
  }
  if (!RegExp(r"^[a-zA-Z0-9()/'@.,& -]+$").hasMatch(val)) {
    return "alphanumeric, (), ', @, ., -, /, &, space, and comma only";
  }

  return null;
}
