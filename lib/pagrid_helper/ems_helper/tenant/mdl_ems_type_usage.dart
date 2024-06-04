class EmsTypeUsage {
  final String? _typeTag;
  final double? _usage;
  final double? _usageFactored;
  final double? _factor;
  final double? _rate;
  final double? _cost;

  String? get typeTag => _typeTag;
  double? get usage => _usage;
  double? get usageFactored => _usageFactored;
  double? get factor => _factor;
  double? get rate => _rate;
  double? get cost => _cost;

  EmsTypeUsage({
    String? typeTag,
    double? usage,
    double? usageFactored,
    double? factor,
    double? rate,
    double? cost,
  })  : _typeTag = typeTag,
        _usage = usage,
        _usageFactored = usageFactored,
        _factor = factor,
        _rate = rate,
        _cost = cost;

  bool isEmpty() {
    return _usage == null;
  }

  bool isNotEmpty() {
    return _usage != null;
  }

  bool hasCost() {
    return _cost != null;
  }
}
