import 'dart:math';

class EmsTypeUsageR2 {
  final String? _typeTag;
  final double? _usage;
  final double? _usageFactored;
  final double? _factor;
  final double? _rate;
  double? _cost;
  final int? _costDecimals;

  String? get typeTag => _typeTag;
  double? get usage => _usage;
  double? get usageFactored => _usageFactored;
  double? get factor => _factor;
  double? get rate => _rate;
  double? get cost => _cost;
  int? get costDecimals => _costDecimals;

  EmsTypeUsageR2({
    String? typeTag,
    double? usage,
    double? usageFactored,
    double? factor,
    double? rate,
    // double? cost,
    int? costDecimals,
  })  : _typeTag = typeTag,
        _usage = usage,
        _usageFactored = usageFactored,
        _factor = factor,
        _rate = rate,
        // _cost = cost,
        _costDecimals = costDecimals {
    if (rate != null && usageFactored != null /*&& factor != null*/) {
      // auto usage has already been factored
      _cost = rate * usageFactored /* * factor*/;
      // round to _costDecimals
      if (_costDecimals != null) {
        _cost =
            double.parse((_cost! * pow(10, _costDecimals)).toStringAsFixed(0)) /
                pow(10, _costDecimals);
      }
    }
  }

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
