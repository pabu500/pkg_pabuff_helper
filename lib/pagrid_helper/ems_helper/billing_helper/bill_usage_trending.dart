/// Monthly billed usage in display units, newest month first.
/// The selected bill supplies the current month; history only supplies prior
/// released months, so a draft or replacement cannot overwrite its usage.
Map<String, List<Map<String, dynamic>>> prepBillUsageTrending(
  Map<String, dynamic> billInfo,
  Map<String, double?> currentUsageByType,
) {
  String? monthOf(dynamic value) {
    final match = RegExp(
      r'^(\d{4})-(\d{1,2})(?:$|\D)',
    ).firstMatch(value?.toString() ?? '');
    if (match == null) return null;
    final month = int.parse(match[2]!);
    if (month < 1 || month > 12) return null;
    return '${match[1]}-${month.toString().padLeft(2, '0')}';
  }

  var currentMonth = monthOf(billInfo['cycle_str']);
  if (currentMonth == null) {
    final from = DateTime.tryParse(billInfo['from_timestamp'] ?? '');
    final to = DateTime.tryParse(billInfo['to_timestamp'] ?? '');
    if (from != null && to != null) {
      currentMonth = monthOf(
        from.add(
          Duration(microseconds: to.difference(from).inMicroseconds ~/ 2),
        ),
      );
    }
  }
  final firstMonth = monthOf(billInfo['bill_bar_from_timestamp']);
  final history = billInfo['billed_usage_trending'] as List? ?? const [];

  return currentUsageByType.map((type, currentUsage) {
    final byMonth = <String, double>{};
    if (currentMonth != null && currentUsage != null) {
      for (final item in history.whereType<Map>()) {
        final month = monthOf(item['billed_time_label']);
        final raw = item['billed_total_usage_${type.toLowerCase()}'];
        final value = raw is num ? raw.toDouble() : double.tryParse('$raw');
        if (month == null ||
            value == null ||
            !value.isFinite ||
            month.compareTo(currentMonth) >= 0)
          continue;
        byMonth.putIfAbsent(month, () => value);
      }
      byMonth[currentMonth] = currentUsage;
    }
    final months =
        byMonth.keys
            .where(
              (month) => firstMonth == null || month.compareTo(firstMonth) > 0,
            )
            .toList()
          ..sort((a, b) => b.compareTo(a));
    return MapEntry(type, [
      for (final month in months.take(6))
        {'time': month, 'label': month, 'value': byMonth[month]!},
    ]);
  });
}
