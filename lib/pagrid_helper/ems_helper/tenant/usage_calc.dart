class EmsTypeUsage {
  final String? _typeTag;
  final double? _usage;
  final double? _usageFactored;
  final double? _factor;

  String? get typeTag => _typeTag;
  double? get usage => _usage;
  double? get usageFactored => _usageFactored;
  double? get factor => _factor;

  EmsTypeUsage({
    String? typeTag,
    double? usage,
    double? usageFactored,
    double? factor,
  })  : _typeTag = typeTag,
        _usage = usage,
        _usageFactored = usageFactored,
        _factor = factor;
}

class EmsTypeUsageCalc {
  final List<EmsTypeUsage> _typeUsage = [];
}
