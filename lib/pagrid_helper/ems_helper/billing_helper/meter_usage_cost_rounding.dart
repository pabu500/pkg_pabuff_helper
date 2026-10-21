/// Rounds successive meter costs so their displayed cents add up to the
/// rounded usage total, rather than accumulating a cent error per meter.
class MeterUsageCostRounding {
  double _unroundedTotal = 0;
  int _displayedCents = 0;

  double? add(double? usage, double? rate) {
    if (usage == null || rate == null) return null;
    _unroundedTotal += usage * rate;
    // Match EmsTypeUsageR2's billing rounding at half-cent boundaries.
    final totalCents = ((_unroundedTotal + 1e-10) * 100).round();
    final rowCents = totalCents - _displayedCents;
    _displayedCents = totalCents;
    return rowCents / 100;
  }
}
