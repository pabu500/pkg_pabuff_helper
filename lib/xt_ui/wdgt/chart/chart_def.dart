enum ChartType {
  line,
  bar,
  pie,
  doughnut,
  radar,
  polarArea,
  bubble,
  scatter,
  area,
  mixed,
}

enum HistroyDisplayType {
  chart,
  table,
}

enum DataType {
  total,
  diff,
}

enum LookbackType {
  last_24h,
  last_48h,
  last_72h,
  last_7d,
  last_14d,
  mtd,
  all,
}

enum TopStatType {
  mmsStat,
  activeMeter,
  topup,
  commUsage,
  meterUsage,
}

enum TrendingType {
  activeMeter,
  topup,
  meterUsage,
}

String getLookbackTypeLabel(LookbackType lookbackType) {
  switch (lookbackType) {
    case LookbackType.last_24h:
      return '24h';
    case LookbackType.last_48h:
      return '48h';
    case LookbackType.last_72h:
      return '72h';
    case LookbackType.last_7d:
      return '7d';
    case LookbackType.last_14d:
      return '14d';
    case LookbackType.mtd:
      return 'MTD';
    case LookbackType.all:
      return 'All';
    default:
      return '';
  }
}

String getLookbackTypeTimeFormat(LookbackType lookbackType) {
  switch (lookbackType) {
    case LookbackType.last_24h:
    case LookbackType.last_48h:
    case LookbackType.last_72h:
      return 'HH:mm';
    case LookbackType.last_7d:
    case LookbackType.mtd:
    case LookbackType.all:
      return 'MM-dd';
    default:
      return '';
  }
}
