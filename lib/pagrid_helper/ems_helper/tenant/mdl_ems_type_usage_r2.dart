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
    double? cost,
    int? costDecimals,
  })  : _typeTag = typeTag,
        _usage = usage,
        _usageFactored = usageFactored,
        _factor = factor,
        _rate = rate,
        // _cost = cost,
        _costDecimals = costDecimals {
    if (cost != null) {
      // if cost is provided, use it directly
      _cost = cost;
    } else {
      if (rate != null && usageFactored != null /*&& factor != null*/) {
        // auto usage has already been factored
        _cost = rate * usageFactored /* * factor*/;
        // round to _costDecimals
        if (_costDecimals != null) {
          // manual way of rounding a double to _costDecimals decimal places,
          // avoiding floating-point precision issues that can occur with native toStringAsFixed() alone
          // NOTE: rounding issue case:
          // _cost = 2.5 * 253.87 = 634.675 ~634.68
          // but the following will produce = 634.67
          // _cost = double.parse((_cost! * pow(10, _costDecimals)).toStringAsFixed(0)) / pow(10, _costDecimals);

          _cost = rate * usageFactored;
          double factor = pow(10, _costDecimals).toDouble();

          // the case that produces the rounding error (634.675 become 634.68)
          // double cost = 2.5 * 253.87; // → 634.67499999999995
          // 634.67499999999995 * 100 = 63467.499999999996
          // round(63467.499999999996) = 63467
          // 63467 / 100 = 634.67
          // To fix the floating-point imprecision, add a small epsilon before rounding:
          _cost = ((_cost! + 1e-10) * factor).round() / factor;
        }
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
