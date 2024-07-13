import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';

import 'mdl_ems_type_usage.dart';

class EmsTypeUsageCalc {
  //input
  late final double? _gst;
  late final Map<String, dynamic> _typeRates;
  late final Map<String, dynamic> _usageFactor;

  late final List<Map<String, dynamic>> _autoUsageSummary;
  late final List<Map<String, dynamic>> _subTenantUsageSummary;
  late final List<Map<String, dynamic>> _manualUsageList;
  late final List<Map<String, dynamic>> _lineItemList;

  //output
  EmsTypeUsage? _typeUsageE;
  EmsTypeUsage? _typeUsageW;
  EmsTypeUsage? _typeUsageB;
  EmsTypeUsage? _typeUsageN;
  EmsTypeUsage? _typeUsageG;

  final List<Map<String, dynamic>> _subTenantUsage = [];

  final List<Map<String, dynamic>> _trendingE = [];
  final List<Map<String, dynamic>> _trendingW = [];
  final List<Map<String, dynamic>> _trendingB = [];
  final List<Map<String, dynamic>> _trendingN = [];
  final List<Map<String, dynamic>> _trendingG = [];

  double? _subTotalCost;
  double? _gstAmount;
  double? _totalCost;

  String? _billBarFromMonth;

  EmsTypeUsage? get typeUsageE => _typeUsageE;
  EmsTypeUsage? get typeUsageW => _typeUsageW;
  EmsTypeUsage? get typeUsageB => _typeUsageB;
  EmsTypeUsage? get typeUsageN => _typeUsageN;
  EmsTypeUsage? get typeUsageG => _typeUsageG;

  List<Map<String, dynamic>> get subTenantUsage => _subTenantUsage;

  List<Map<String, dynamic>> get lineItemList => _lineItemList;

  List<Map<String, dynamic>> get trendingE => _trendingE;
  List<Map<String, dynamic>> get trendingW => _trendingW;
  List<Map<String, dynamic>> get trendingB => _trendingB;
  List<Map<String, dynamic>> get trendingN => _trendingN;
  List<Map<String, dynamic>> get trendingG => _trendingG;

  double? get gst => _gst;
  double? get subTotalCost => _subTotalCost;
  double? get gstAmount => _gstAmount;
  double? get totalCost => _totalCost;

  String? get billBarFromMonth => _billBarFromMonth;

  EmsTypeUsageCalc({
    double? gst,
    Map<String, dynamic> typeRates = const {},
    Map<String, dynamic> usageFactor = const {},
    List<Map<String, dynamic>> autoUsageSummary = const [],
    List<Map<String, dynamic>> subTenantUsageSummary = const [],
    List<Map<String, dynamic>> manualUsageList = const [],
    List<Map<String, dynamic>> lineItemList = const [],
    billBarFromMonth,
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
    _billBarFromMonth = billBarFromMonth;
  }

  void doCalc() {
    _calcTypeUsage('E');
    _calcTypeUsage('W');
    _calcTypeUsage('B');
    _calcTypeUsage('N');
    _calcTypeUsage('G');

    _calcTotalCost();

    _sortSubTenantUsage();

    _getUsageTrending();
  }

  Map<String, dynamic>? getLineItem(int index) {
    int length = _lineItemList.length;
    if (index > length - 1) {
      return null;
    }

    Map<String, dynamic> lineItem = {};
    lineItem['label'] = _lineItemList[index]['label'];

    String amtStr = _lineItemList[index]['amount'];
    double? amt = double.tryParse(amtStr);
    if (amt != null) {
      amt = getRound(amt, 3);
      lineItem['amount'] = amt;
    } else {
      throw Exception('Invalid amount');
    }

    return lineItem;
  }

  double? getTypeUsageFactor(String typeTag) {
    return _usageFactor[typeTag];
  }

  void _sortSubTenantUsage() {
    for (var tenant in _subTenantUsageSummary) {
      final tenantUsageSummary = tenant['tenant_usage_summary'] ?? [];
      Map<String, dynamic> tenantUsageInfo = {
        'tenant_name': tenant['tenant_name'],
        'tenant_label': tenant['tenant_label'],
      };

      List<EmsTypeUsage> typeUsageList = [];
      for (var tenantUsage in tenantUsageSummary) {
        String usageType = tenantUsage['meter_type'].toUpperCase();

        final meterGroupUsageSummary =
            tenantUsage['meter_group_usage_summary'] ?? [];
        if (meterGroupUsageSummary.isNotEmpty) {
          List<Map<String, dynamic>> meterListUsageSummary = [];
          for (var mg in meterGroupUsageSummary['meter_list_usage_summary']) {
            meterListUsageSummary.add(mg);
          }
          double? subUsasgeTotal =
              _calcMeterGroupUsageTotal(meterListUsageSummary);
          double? subUsasgeTotalFactored;
          if (subUsasgeTotal != null) {
            subUsasgeTotalFactored = subUsasgeTotal * _usageFactor[usageType];
          }

          EmsTypeUsage typeUsage = EmsTypeUsage(
            typeTag: usageType,
            usage: subUsasgeTotal,
            usageFactored: subUsasgeTotalFactored,
            factor: _usageFactor[usageType],
            rate: _typeRates[usageType],
            cost:
                subUsasgeTotalFactored == null || _typeRates[usageType] == null
                    ? null
                    : subUsasgeTotalFactored * _typeRates[usageType],
          );
          if (subUsasgeTotal != null) {
            typeUsageList.add(typeUsage);
          }
        }
      }
      tenantUsageInfo['type_usage_list'] = typeUsageList;
      _subTenantUsage.add(tenantUsageInfo);
    }
  }

  void _calcTypeUsage(String typeTag) {
    double? typeUsageTotal;
    double? typeUsageFactored;

    // auto usage
    double? typeAutoUsageTotal;
    for (var item in _autoUsageSummary) {
      String? usageType = item['meter_type'].toUpperCase();
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
    for (var tenant in _subTenantUsageSummary) {
      final tenantUsageSummary = tenant['tenant_usage_summary'] ?? [];
      for (var tenantUsage in tenantUsageSummary) {
        String? usageType = tenantUsage['meter_type'].toUpperCase();
        if (usageType != typeTag) {
          continue;
        }
        final meterGroupUsageSummary =
            tenantUsage['meter_group_usage_summary'] ?? [];
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
      String? usageType = item['meter_type'].toUpperCase();
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
        typeUsageTotal -= typeSubTenantUsageTotal;
      }

      // apply usage factor
      double usageFactor = _usageFactor[typeTag];
      typeUsageFactored = typeUsageTotal * usageFactor;
    }

    // apply manual usage
    // usage factor is not applied to manual usage
    if (typeManualUsageTotal != null) {
      typeUsageFactored ??= 0;
      // typeUsageTotal = typeUsageFactored + typeManualUsageTotal;
      typeUsageFactored = typeUsageFactored + typeManualUsageTotal;
      typeUsageTotal ??= typeUsageFactored;
    }

    EmsTypeUsage emsTypeUsage = EmsTypeUsage(
      typeTag: typeTag,
      usage: typeUsageTotal,
      usageFactored: typeUsageFactored,
      factor: _usageFactor[typeTag],
      rate: _typeRates[typeTag],
      cost: typeUsageFactored == null || _typeRates[typeTag] == null
          ? null
          : typeUsageFactored * _typeRates[typeTag],
    );

    switch (typeTag) {
      case 'E':
        _typeUsageE = emsTypeUsage;
        break;
      case 'W':
        _typeUsageW = emsTypeUsage;
        break;
      case 'B':
        _typeUsageB = emsTypeUsage;
        break;
      case 'N':
        _typeUsageN = emsTypeUsage;
        break;
      case 'G':
        _typeUsageG = emsTypeUsage;
        break;
    }
  }

  void _calcTotalCost() {
    double? subTotalCost;

    if (_typeUsageE?.hasCost() ?? false) {
      subTotalCost ??= 0;
      subTotalCost += _typeUsageE!.cost!;
    }
    if (_typeUsageW?.hasCost() ?? false) {
      subTotalCost ??= 0;
      subTotalCost += _typeUsageW!.cost!;
    }
    if (_typeUsageB?.hasCost() ?? false) {
      subTotalCost ??= 0;
      subTotalCost += _typeUsageB!.cost!;
    }
    if (_typeUsageN?.hasCost() ?? false) {
      subTotalCost ??= 0;
      subTotalCost += _typeUsageN!.cost!;
    }
    if (_typeUsageG?.hasCost() ?? false) {
      subTotalCost ??= 0;
      subTotalCost += _typeUsageG!.cost!;
    }

    for (var item in _lineItemList) {
      String? costStr = item['amount'];
      double? cost = double.tryParse(costStr ?? '');
      if (cost != null) {
        subTotalCost ??= 0;
        subTotalCost += cost;
      }
    }
    _subTotalCost = subTotalCost;
    if (_subTotalCost != null) {
      _subTotalCost = getRound(_subTotalCost!, 2);
      if (subTotalCost != null && _gst != null) {
        _gstAmount = subTotalCost * _gst / 100;
      }
      _gstAmount = getRoundUp(_gstAmount!, 2);
      _totalCost = _subTotalCost! + _gstAmount!;
    }
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

  void _getUsageTrending() {
    for (var item in _autoUsageSummary) {
      List<Map<String, dynamic>> conlidatedHistoryList = [];
      String meterType = item['meter_type'] ?? '';
      final mgTrendingSnapShot = item['meter_group_trending_snapshot'] ?? [];
      if (mgTrendingSnapShot.isEmpty) {
        continue;
      }
      final mgConsolidatedUsageHistory =
          mgTrendingSnapShot['meter_list_consolidated_usage_history'] ?? [];

      for (var meterHistory in mgConsolidatedUsageHistory) {
        String meterId = meterHistory['meter_id'];
        double percentage = meterHistory['percentage'];

        if (meterHistory['meter_usage_history'].isEmpty) {
          if (kDebugMode) {
            print('No history for meter $meterId');
          }
          continue;
        }

        for (var history in meterHistory['meter_usage_history']) {
          String consolidatedTimeLabel = history['consolidated_time_label'];

          if ((_billBarFromMonth ?? '').isNotEmpty) {
            if (!takeMonth(consolidatedTimeLabel, _billBarFromMonth!)) {
              continue;
            }
          }

          double? usage = double.tryParse(history['usage']);
          usage = usage == null ? 0 : usage * (percentage / 100);

          //check if the time label is already in the list
          bool isExist = false;
          for (var item in conlidatedHistoryList) {
            if (item['time'] == consolidatedTimeLabel) {
              isExist = true;
              break;
            }
          }
          if (!isExist) {
            conlidatedHistoryList.add({
              'time': consolidatedTimeLabel,
              'label': consolidatedTimeLabel,
              'value': usage,
            });
          } else {
            //add the consumption to the existing time label
            for (var item in conlidatedHistoryList) {
              if (item['time'] == consolidatedTimeLabel) {
                item['value'] += usage;
                break;
              }
            }
          }
        }
      }
      if (meterType == 'E') {
        _trendingE.clear();
        _trendingE.addAll(conlidatedHistoryList);
      } else if (meterType == 'W') {
        _trendingW.clear();
        _trendingW.addAll(conlidatedHistoryList);
      } else if (meterType == 'B') {
        _trendingB.clear();
        _trendingB.addAll(conlidatedHistoryList);
      } else if (meterType == 'N') {
        _trendingN.clear();
        _trendingN.addAll(conlidatedHistoryList);
      } else if (meterType == 'G') {
        _trendingG.clear();
        _trendingG.addAll(conlidatedHistoryList);
      }
    }
  }
}

bool takeMonth(String monthLabel, String billBarFrom) {
  //label is YYYY-MM
  //if monthLabel is greater than or equal to billBarFrom, return true
  List<String> monthLabelList = monthLabel.split('-');
  List<String> billBarFromList = billBarFrom.split('-');

  if (int.parse(monthLabelList[0]) > int.parse(billBarFromList[0])) {
    return true;
  } else if (int.parse(monthLabelList[0]) == int.parse(billBarFromList[0])) {
    if (int.parse(monthLabelList[1]) >= int.parse(billBarFromList[1])) {
      return true;
    }
  }
  return false;
}
