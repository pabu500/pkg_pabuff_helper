import 'package:buff_helper/pkg_buff_helper.dart';

import 'mdl_ems_type_usage.dart';

class EmsTypeUsageCalc {
  //input
  late final double _gst;
  late final Map<String, dynamic> _typeRates;
  late final Map<String, dynamic> _usageFactor;

  late final List<Map<String, dynamic>> _autoUsageSummary;
  late final List<Map<String, dynamic>> _subTenantUsageSummary;
  late final List<Map<String, dynamic>> _manualUsageList;
  late final List<Map<String, dynamic>> _lineItemList;

  //output
  late final EmsTypeUsage _typeUsageE;
  late final EmsTypeUsage _typeUsageW;
  late final EmsTypeUsage _typeUsageB;
  late final EmsTypeUsage _typeUsageN;
  late final EmsTypeUsage _typeUsageG;

  late final double? _subTotalCost;
  late final double? _gstAmount;
  late final double? _totalCost;

  EmsTypeUsage get typeUsageE => _typeUsageE;
  EmsTypeUsage get typeUsageW => _typeUsageW;
  EmsTypeUsage get typeUsageB => _typeUsageB;
  EmsTypeUsage get typeUsageN => _typeUsageN;
  EmsTypeUsage get typeUsageG => _typeUsageG;

  double get gst => _gst;
  double? get subTotalCost => _subTotalCost;
  double? get gstAmount => _gstAmount;
  double? get totalCost => _totalCost;

  EmsTypeUsageCalc({
    required double gst,
    Map<String, dynamic> typeRates = const {},
    Map<String, dynamic> usageFactor = const {},
    List<Map<String, dynamic>> autoUsageSummary = const [],
    List<Map<String, dynamic>> subTenantUsageSummary = const [],
    List<Map<String, dynamic>> manualUsageList = const [],
    List<Map<String, dynamic>> lineItemList = const [],
  }) {
    if (usageFactor.isEmpty) {
      throw Exception('usageFactor is empty');
    }

    _gst = gst;
    _typeRates = typeRates;
    _usageFactor = usageFactor;

    _autoUsageSummary = autoUsageSummary;
    _subTenantUsageSummary = subTenantUsageSummary;
    _manualUsageList = manualUsageList;
    _lineItemList = lineItemList;
  }

  void doCalc() {
    _calcTypeUsage('E');
    _calcTypeUsage('W');
    _calcTypeUsage('B');
    _calcTypeUsage('N');
    _calcTypeUsage('G');

    _calcTotalCost();
  }

  void _calcTypeUsage(String typeTag) {
    double? typeUsageTotal;
    double? typeUsageFactored;
    String typeTag = '';

    // auto usage
    double? typeAutoUsageTotal;
    for (var item in _autoUsageSummary) {
      String? usageType = item['meter_type'];
      if (usageType != typeTag) {
        continue;
      }
      final meterGroupUsageSummary = item['meter_group_usage_summary'] ?? [];
      if (meterGroupUsageSummary.isNotEmpty) {
        List<Map<String, dynamic>> meterListUsageSummary = [];
        for (var mg in meterGroupUsageSummary['meter_list_usage_summary']) {
          meterListUsageSummary.add(mg);
        }

        double? groupUsageTotal =
            _calcMeterGroupUsageTotal(meterListUsageSummary);
        if (groupUsageTotal != null) {
          typeAutoUsageTotal ??= 0;
          typeAutoUsageTotal += groupUsageTotal;
        }
      }
    }

    double? typeSubTenantUsageTotal;
    for (var item in _subTenantUsageSummary) {
      final tenantUsageSummary = item['tenant_usage_summary'] ?? [];
      for (var tenant in tenantUsageSummary) {
        String? usageType = tenant['meter_type'];
        if (usageType != typeTag) {
          continue;
        }
        final meterGroupUsageSummary =
            tenant['meter_group_usage_summary'] ?? [];
        if (meterGroupUsageSummary.isNotEmpty) {
          List<Map<String, dynamic>> meterListUsageSummary = [];
          for (var mg in meterGroupUsageSummary['meter_list_usage_summary']) {
            meterListUsageSummary.add(mg);
          }
          double? subUsasgeTotal =
              _calcMeterGroupUsageTotal(meterListUsageSummary);
          if (subUsasgeTotal != null) {
            typeSubTenantUsageTotal ??= 0;
            typeSubTenantUsageTotal += subUsasgeTotal;
          }
        }
      }
    }

    double? typeManualUsageTotal;
    for (var item in _manualUsageList) {
      String? usageType = item['meter_type'];
      if (usageType != typeTag) {
        continue;
      }

      double? manualUsageVal = item['usage'];
      if (manualUsageVal != null) {
        typeManualUsageTotal ??= 0;
        typeManualUsageTotal += manualUsageVal;
      }
    }

    if (typeAutoUsageTotal != null) {
      typeUsageTotal ??= 0;
      typeUsageTotal += typeAutoUsageTotal;

      // only apply sub tenant usage if auto usage is available
      if (typeSubTenantUsageTotal != null) {
        typeUsageTotal += typeSubTenantUsageTotal;
      }

      // apply usage factor
      double usageFactor = _usageFactor[typeTag];
      typeUsageFactored = typeUsageTotal * usageFactor;
    }

    // apply manual usage
    // usage factor is not applied to manual usage
    if (typeManualUsageTotal != null) {
      typeUsageFactored ??= 0;
      typeUsageTotal = typeUsageFactored + typeManualUsageTotal;
    }

    _typeUsageE = EmsTypeUsage(
      typeTag: typeTag,
      usage: typeUsageTotal,
      usageFactored: typeUsageFactored,
      factor: _usageFactor[typeTag],
      rate: _typeRates[typeTag],
      cost: typeUsageTotal == null || _typeRates[typeTag] == null
          ? null
          : typeUsageTotal * _typeRates[typeTag],
    );
  }

  void _calcTotalCost() {
    double? subTotalCost;

    if (_typeUsageE.hasCost()) {
      subTotalCost ??= 0;
      subTotalCost += _typeUsageE.cost!;
    }
    if (_typeUsageW.hasCost()) {
      subTotalCost ??= 0;
      subTotalCost += _typeUsageW.cost!;
    }
    if (_typeUsageB.hasCost()) {
      subTotalCost ??= 0;
      subTotalCost += _typeUsageB.cost!;
    }
    if (_typeUsageN.hasCost()) {
      subTotalCost ??= 0;
      subTotalCost += _typeUsageN.cost!;
    }
    if (_typeUsageG.hasCost()) {
      subTotalCost ??= 0;
      subTotalCost += _typeUsageG.cost!;
    }

    for (var item in _lineItemList) {
      double? cost = item['amount'];
      if (cost != null) {
        subTotalCost ??= 0;
        subTotalCost += cost;
      }
    }
    _subTotalCost = subTotalCost;
    _subTotalCost = getRound(_subTotalCost!, 2);
    if (subTotalCost != null && _gst != null) {
      _gstAmount = subTotalCost * _gst / 100;
    }
    _gstAmount = getRoundUp(_gstAmount!, 2);
    _totalCost = _subTotalCost + _gstAmount;
  }

  double? _calcMeterGroupUsageTotal(
      List<Map<String, dynamic>> meterListUsageSummary) {
    double? usage;
    for (var meter in meterListUsageSummary) {
      String usageStr = meter['usage'] ?? '';
      double? usageVal = double.tryParse(usageStr);
      double? percentage = meter['percentage'];

      if (usageVal != null) {
        usage ??= 0;

        if (percentage != null) {
          usage += usageVal * (percentage / 100);
        } else {
          usage += usageVal;
        }
      }
    }
    return usage;
  }
}
