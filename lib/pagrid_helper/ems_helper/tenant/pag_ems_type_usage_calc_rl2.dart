import 'package:buff_helper/pkg_buff_helper.dart';

import 'mdl_ems_type_usage_r2.dart';

class PagEmsTypeUsageCalcRl2 {
  final int _costDecimals;
  final String? _meterType;
  final double? _billedAutoUsage;
  final double? _billedManualUsage;
  final double? _billedRate;
  final double? _billedGst;
  final List<Map<String, dynamic>> _lineItemList;
  final String? _billBarFromMonth;
  final List<PagEmsTypeUsageCalcRl2> _singularCalcList;
  final Map<String, dynamic>? _miniSoaInfo;
  final Map<String, dynamic>? _interestInfo;
  final Map<String, dynamic>? _billedBciInfo;
  final double? _billedTotalBciAmount;
  final List<Map<String, dynamic>> _billedEffBciInfoList = [];
  final Map<String, EmsTypeUsageR2> _typeUsageByType = {};

  double? _totalUsageCost;
  double? _subTotalCost;
  double? _billedGstAmount;
  double? _totalCost;
  double? _principalAmount;
  double? _cycleTotalAmount;
  double? _payableAmount;

  PagEmsTypeUsageCalcRl2({
    required int costDecimals,
    String? meterType,
    double? billedAutoUsage,
    double? billedManualUsage,
    double? billedRate,
    required List<Map<String, dynamic>> lineItemList,
    String? billBarFromMonth,
    List<PagEmsTypeUsageCalcRl2> singularUsageCalcList = const [],
    Map<String, dynamic>? miniSoaInfo,
    Map<String, dynamic>? interestInfo,
    double? billedUsageCostAmount,
    double? billedGst,
    double? billedGstAmount,
    double? billedPrincipalAmount,
    double? billedCycleTotalAmount,
    double? billedPayableAmount,
    Map<String, dynamic>? billedBciInfo,
    double? billedTotalBciAmount,
  })  : _costDecimals = costDecimals,
        _meterType = meterType?.trim().toUpperCase(),
        _billedAutoUsage = billedAutoUsage,
        _billedManualUsage = billedManualUsage,
        _billedRate = billedRate,
        _lineItemList = lineItemList,
        _billBarFromMonth = billBarFromMonth,
        _singularCalcList = List.of(singularUsageCalcList),
        _miniSoaInfo = miniSoaInfo,
        _interestInfo = interestInfo,
        _totalUsageCost = billedUsageCostAmount,
        _billedGst = billedGst,
        _billedGstAmount = billedGstAmount,
        _principalAmount = billedPrincipalAmount,
        _cycleTotalAmount = billedCycleTotalAmount,
        _payableAmount = billedPayableAmount,
        _billedBciInfo = billedBciInfo,
        _billedTotalBciAmount = billedTotalBciAmount;

  Map<String, EmsTypeUsageR2> get typeUsageByType =>
      Map.unmodifiable(_typeUsageByType);
  double? get billedGst => _billedGst;
  double? get totalUsageCost => _totalUsageCost;
  double? get subTotalCost => _subTotalCost;
  double? get billedGstAmount => _billedGstAmount;
  double? get totalCost => _totalCost;
  double? get principalAmount => _principalAmount;
  double? get cycleTotalAmount => _cycleTotalAmount;
  double? get payableAmount => _payableAmount;
  String? get billBarFromMonth => _billBarFromMonth;
  List<PagEmsTypeUsageCalcRl2> get singularCalcList => _singularCalcList;
  List<Map<String, dynamic>> get lineItemList => _lineItemList;
  Map<String, dynamic>? get miniSoaInfo => _miniSoaInfo;
  Map<String, dynamic>? get interestInfo => _interestInfo;
  Map<String, dynamic>? get billedBciInfo => _billedBciInfo;
  List<Map<String, dynamic>> get billedEffBciInfoList => _billedEffBciInfoList;
  double? get billedTotalBciAmount => _billedTotalBciAmount;

  EmsTypeUsageR2? getTypeUsage(String meterType) =>
      _typeUsageByType[meterType.trim().toUpperCase()];

  void doSingularCalc() {
    final meterType = _meterType;
    if (meterType == null || meterType.isEmpty) {
      throw Exception('meterType is required for singular usage calculation');
    }
    double? totalUsage;
    if (_billedAutoUsage != null) {
      totalUsage = _billedAutoUsage;
    }
    if (_billedManualUsage != null) {
      totalUsage = (totalUsage ?? 0) + _billedManualUsage;
    }
    _typeUsageByType[meterType] = EmsTypeUsageR2(
      typeTag: meterType,
      usage: totalUsage,
      usageFactored: totalUsage,
      rate: _billedRate,
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
    _getBilledTotalCost();
  }

  Map<String, dynamic>? getLineItemInfo(
      bool subjectToTax, bool subjectToInterest) {
    for (final item in _lineItemList) {
      if ((item['subjectToTax'] as bool? ?? false) == subjectToTax &&
          (item['subjectToInterest'] as bool? ?? false) == subjectToInterest) {
        return item;
      }
    }
    return null;
  }

  String? getLineItemLabel(bool subjectToTax, bool subjectToInterest) =>
      getLineItemInfo(subjectToTax, subjectToInterest)?['label']?.toString();

  double? getLineItemAmount(bool subjectToTax, bool subjectToInterest) =>
      _toDouble(getLineItemInfo(subjectToTax, subjectToInterest)?['amount']);

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

  void _getBilledTotalCost() {
    double? subTotalCost = _totalUsageCost;
    if (subTotalCost != null) {
      subTotalCost += _billedTotalBciAmount ?? 0;
    }

    final effectiveBciList =
        _billedBciInfo?['effective_bci_info_list'] as List?;
    for (final item in effectiveBciList ?? const []) {
      if (item is! Map) {
        continue;
      }
      _billedEffBciInfoList.add({
        'billing_cost_item_name': item['billing_cost_item_name'],
        'billing_cost_item_label': item['billing_cost_item_label'],
        'billing_cost_item_amount': _toDouble(item['billing_cost_item_amount']),
      });
    }

    for (final item in _lineItemList) {
      if (item['subjectToTax'] as bool? ?? false) {
        subTotalCost = (subTotalCost ?? 0) + (_toDouble(item['amount']) ?? 0);
      }
    }
    _subTotalCost = subTotalCost == null ? null : getRound(subTotalCost, 2);
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
