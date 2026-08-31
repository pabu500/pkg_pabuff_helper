import 'package:buff_helper/pkg_buff_helper.dart';

import 'mdl_ems_type_usage_r2.dart';

class PagEmsTypeUsageCalc2 {
  final int _costDecimals;
  final String? _meterType;
  final double? _rate;
  final double? _gst;
  final Map<String, dynamic> _autoUsageSummary;
  final List<Map<String, dynamic>> _manualUsageList;
  final List<Map<String, dynamic>> _lineItemList;
  final String? _billBarFromMonth;
  final List<PagEmsTypeUsageCalc2> _singularCalcList;
  final Map<String, dynamic>? _miniSoaInfo;
  final Map<String, dynamic>? _interestInfo;
  final List<Map<String, dynamic>>? _effBciInfoList;

  final Map<String, EmsTypeUsageR2> _typeUsageByType = {};

  double? _totalUsageCost;
  double? _subTotalCost;
  double? _gstAmount;
  double? _totalCost;
  double? _principalAmount;
  double? _cycleTotalAmount;
  double? _payableAmount;

  PagEmsTypeUsageCalc2({
    required int costDecimals,
    String? meterType,
    double? rate,
    double? gst,
    Map<String, dynamic> autoUsageSummary = const {},
    List<Map<String, dynamic>> manualUsageList = const [],
    List<Map<String, dynamic>> lineItemList = const [],
    String? billBarFromMonth,
    List<PagEmsTypeUsageCalc2> singularUsageCalcList = const [],
    Map<String, dynamic>? miniSoaInfo,
    Map<String, dynamic>? interestInfo,
    List<Map<String, dynamic>>? effBciInfoList,
  })  : _costDecimals = costDecimals,
        _meterType = meterType?.trim().toUpperCase(),
        _rate = rate,
        _gst = gst,
        _autoUsageSummary = autoUsageSummary,
        _manualUsageList = manualUsageList,
        _lineItemList = lineItemList,
        _billBarFromMonth = billBarFromMonth,
        _singularCalcList = List.of(singularUsageCalcList),
        _miniSoaInfo = miniSoaInfo,
        _interestInfo = interestInfo,
        _effBciInfoList = effBciInfoList;

  Map<String, EmsTypeUsageR2> get typeUsageByType =>
      Map.unmodifiable(_typeUsageByType);
  double? get gst => _gst;
  double? get totalUsageCost => _totalUsageCost;
  double? get subTotalCost => _subTotalCost;
  double? get gstAmount => _gstAmount;
  double? get totalCost => _totalCost;
  double? get principalAmount => _principalAmount;
  double? get cycleTotalAmount => _cycleTotalAmount;
  double? get payableAmount => _payableAmount;
  String? get billBarFromMonth => _billBarFromMonth;
  List<PagEmsTypeUsageCalc2> get singularCalcList => _singularCalcList;
  List<Map<String, dynamic>> get manualUsageList => _manualUsageList;
  List<Map<String, dynamic>> get lineItemList => _lineItemList;
  Map<String, dynamic>? get miniSoaInfo => _miniSoaInfo;
  Map<String, dynamic>? get interestInfo => _interestInfo;
  List<Map<String, dynamic>>? get effBciInfoList => _effBciInfoList;

  EmsTypeUsageR2? getTypeUsage(String meterType) =>
      _typeUsageByType[meterType.trim().toUpperCase()];

  // Gen3 applies multiplier_factor per meter, so there is no bill-level usage
  // factor. This method remains only for the shared generated-bill widget.
  double? getTypeUsageFactor(String meterType) => null;

  void doSingularCalc() {
    final meterType = _meterType;
    if (meterType == null || meterType.isEmpty) {
      throw Exception('meterType is required for singular usage calculation');
    }

    final autoUsage = _getAdjustedAutoUsage(meterType);
    final manualUsage = _getManualUsage(meterType);
    double? totalUsage;
    if (autoUsage != null) {
      totalUsage = autoUsage;
    }
    if (manualUsage != null) {
      totalUsage = (totalUsage ?? 0) + manualUsage;
    }

    _typeUsageByType[meterType] = EmsTypeUsageR2(
      typeTag: meterType,
      usage: totalUsage,
      usageFactored: totalUsage,
      rate: _rate,
      costDecimals: _costDecimals,
    );
  }

  void doCompositeCalc() {
    _typeUsageByType.clear();
    for (final singularCalc in _singularCalcList) {
      for (final entry in singularCalc._typeUsageByType.entries) {
        final current = _typeUsageByType[entry.key];
        final singular = entry.value;
        _typeUsageByType[entry.key] = EmsTypeUsageR2(
          typeTag: entry.key,
          usage: _addNullable(current?.usage, singular.usage),
          usageFactored:
              _addNullable(current?.usageFactored, singular.usageFactored),
          cost: _addNullable(current?.cost, singular.cost),
          costDecimals: _costDecimals,
        );
      }
    }
    _calcTotalCost();
  }

  Map<String, dynamic>? getLineItem(int index) {
    if (index < 0 || index >= _lineItemList.length) {
      return null;
    }
    final amount = _toDouble(_lineItemList[index]['amount']);
    if (amount == null) {
      throw Exception('Invalid amount');
    }
    return {
      'label': _lineItemList[index]['label'],
      'amount': getRound(amount, _costDecimals),
    };
  }

  double? _getAdjustedAutoUsage(String meterType) {
    double? total;
    final groupList = _autoUsageSummary['meter_group_usage_list'];
    if (groupList is! List) {
      return null;
    }

    for (final group in groupList) {
      if (group is! Map) {
        continue;
      }
      final groupType = group['meter_type']?.toString().toUpperCase();
      if (groupType != meterType) {
        continue;
      }
      final meterList = group['meter_group_usage_summary']?['meter_usage_list'];
      if (meterList is! List) {
        continue;
      }
      for (final meter in meterList) {
        if (meter is! Map) {
          continue;
        }
        final summary = meter['meter_usage_summary'];
        if (summary is! Map) {
          continue;
        }
        final usage = _toDouble(summary['usage']);
        if (usage == null) {
          continue;
        }
        final percentage = _toDouble(summary['percentage']) ?? 100;
        final multiplier = _toDouble(summary['multiplier_factor']) ?? 1;
        total = (total ?? 0) + usage * percentage / 100 * multiplier;
      }
    }
    return total;
  }

  double? _getManualUsage(String meterType) {
    double? total;
    for (final item in _manualUsageList) {
      if (item['meter_type']?.toString().toUpperCase() != meterType) {
        continue;
      }
      final usage = _toDouble(item['usage']);
      if (usage != null) {
        total = (total ?? 0) + usage;
      }
    }
    return total;
  }

  void _calcTotalCost() {
    for (final typeUsage in _typeUsageByType.values) {
      final cost = typeUsage.cost;
      if (cost != null) {
        _totalUsageCost = (_totalUsageCost ?? 0) + cost;
      }
    }

    double subTotalCost = _totalUsageCost ?? 0;
    double notTaxableButInterestBearing = 0;
    for (final item in _lineItemList) {
      final amount = _toDouble(item['amount']);
      if (amount == null) {
        continue;
      }
      final subjectToTax = item['subjectToTax'] as bool? ?? false;
      final subjectToInterest = item['subjectToInterest'] as bool? ?? false;
      if (subjectToTax && subjectToInterest) {
        subTotalCost += amount;
      } else if (!subjectToTax && subjectToInterest) {
        notTaxableButInterestBearing += amount;
      }
    }
    for (final bciInfo in _effBciInfoList ?? const []) {
      subTotalCost += _toDouble(bciInfo['billing_cost_item_amount']) ?? 0;
    }

    _subTotalCost = getRound(subTotalCost, 2);
    _gstAmount = getRoundUp(_subTotalCost! * (_gst ?? 0) / 100, 2);
    _totalCost = _subTotalCost! + _gstAmount!;
    _principalAmount = _totalCost! + notTaxableButInterestBearing;
    _cycleTotalAmount = _principalAmount! +
        (_toDouble(_interestInfo?['total_interest_amount']) ?? 0);
    _payableAmount = _cycleTotalAmount;

    final closingBalance = _toDouble(_miniSoaInfo?['closing_balance']);
    if (closingBalance != null) {
      _payableAmount = _payableAmount! - closingBalance;
    }
    _payableAmount = getRound(_payableAmount!, 2);
  }

  static double? _addNullable(double? left, double? right) {
    if (left == null && right == null) {
      return null;
    }
    return (left ?? 0) + (right ?? 0);
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return value == null ? null : double.tryParse(value.toString());
  }
}
