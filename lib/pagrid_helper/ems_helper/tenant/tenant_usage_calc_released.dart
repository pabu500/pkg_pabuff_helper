import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';

import 'mdl_ems_type_usage.dart';

class EmsTypeUsageCalcReleased {
  //input
  final double? _billedAutoUsageE;
  final double? _billedAutoUsageW;
  final double? _billedAutoUsageB;
  final double? _billedAutoUsageN;
  final double? _billedAutoUsageG;

  final double? _billedSubTenantUsageE;
  final double? _billedSubTenantUsageW;
  final double? _billedSubTenantUsageB;
  final double? _billedSubTenantUsageN;
  final double? _billedSubTenantUsageG;

  final double? _billedManualUsageE;
  final double? _billedManualUsageW;
  final double? _billedManualUsageB;
  final double? _billedManualUsageN;
  final double? _billedManualUsageG;

  final double? _billedUsageFactorE;
  final double? _billedUsageFactorW;
  final double? _billedUsageFactorB;
  final double? _billedUsageFactorN;
  final double? _billedUsageFactorG;

  final double? _billedRateE;
  final double? _billedRateW;
  final double? _billedRateB;
  final double? _billedRateN;
  final double? _billedRateG;

  final double? _billedGst;

  late final List<Map<String, dynamic>> _lineItemList;

  final List<Map<String, dynamic>>? _billedTrendingSnapShot;

  //output
  EmsTypeUsage? _typeUsageE;
  EmsTypeUsage? _typeUsageW;
  EmsTypeUsage? _typeUsageB;
  EmsTypeUsage? _typeUsageN;
  EmsTypeUsage? _typeUsageG;

  final List<Map<String, dynamic>> _trendingE = [];
  final List<Map<String, dynamic>> _trendingW = [];
  final List<Map<String, dynamic>> _trendingB = [];
  final List<Map<String, dynamic>> _trendingN = [];
  final List<Map<String, dynamic>> _trendingG = [];

  double? _subTotalCost;
  double? _gstAmount;
  double? _totalCost;

  EmsTypeUsage? get typeUsageE => _typeUsageE;
  EmsTypeUsage? get typeUsageW => _typeUsageW;
  EmsTypeUsage? get typeUsageB => _typeUsageB;
  EmsTypeUsage? get typeUsageN => _typeUsageN;
  EmsTypeUsage? get typeUsageG => _typeUsageG;

  List<Map<String, dynamic>> get trendingE => _trendingE;
  List<Map<String, dynamic>> get trendingW => _trendingW;
  List<Map<String, dynamic>> get trendingB => _trendingB;
  List<Map<String, dynamic>> get trendingN => _trendingN;
  List<Map<String, dynamic>> get trendingG => _trendingG;

  double? get billedGst => _billedGst;
  double? get subTotalCost => _subTotalCost;
  double? get gstAmount => _gstAmount;
  double? get totalCost => _totalCost;

  EmsTypeUsageCalcReleased({
    double? billedAutoUsageE,
    double? billedAutoUsageW,
    double? billedAutoUsageB,
    double? billedAutoUsageN,
    double? billedAutoUsageG,
    double? billedSubTenantUsageE,
    double? billedSubTenantUsageW,
    double? billedSubTenantUsageB,
    double? billedSubTenantUsageN,
    double? billedSubTenantUsageG,
    double? billedManualUsageE,
    double? billedManualUsageW,
    double? billedManualUsageB,
    double? billedManualUsageN,
    double? billedManualUsageG,
    double? billedUsageFactorE,
    double? billedUsageFactorW,
    double? billedUsageFactorB,
    double? billedUsageFactorN,
    double? billedUsageFactorG,
    double? billedRateE,
    double? billedRateW,
    double? billedRateB,
    double? billedRateN,
    double? billedRateG,
    double? billedGst,
    required List<Map<String, dynamic>>? lineItemList,
    List<Map<String, dynamic>>? billedTrendingSnapShot,
  })  : _billedAutoUsageE = billedAutoUsageE,
        _billedAutoUsageW = billedAutoUsageW,
        _billedAutoUsageB = billedAutoUsageB,
        _billedAutoUsageN = billedAutoUsageN,
        _billedAutoUsageG = billedAutoUsageG,
        _billedSubTenantUsageE = billedSubTenantUsageE,
        _billedSubTenantUsageW = billedSubTenantUsageW,
        _billedSubTenantUsageB = billedSubTenantUsageB,
        _billedSubTenantUsageN = billedSubTenantUsageN,
        _billedSubTenantUsageG = billedSubTenantUsageG,
        _billedManualUsageE = billedManualUsageE,
        _billedManualUsageW = billedManualUsageW,
        _billedManualUsageB = billedManualUsageB,
        _billedManualUsageN = billedManualUsageN,
        _billedManualUsageG = billedManualUsageG,
        _billedUsageFactorE = billedUsageFactorE,
        _billedUsageFactorW = billedUsageFactorW,
        _billedUsageFactorB = billedUsageFactorB,
        _billedUsageFactorN = billedUsageFactorN,
        _billedUsageFactorG = billedUsageFactorG,
        _billedRateE = billedRateE,
        _billedRateW = billedRateW,
        _billedRateB = billedRateB,
        _billedRateN = billedRateN,
        _billedRateG = billedRateG,
        _billedGst = billedGst,
        _billedTrendingSnapShot = billedTrendingSnapShot;

  void doCalc() {
    _calcTypeUsage('E');
    _calcTypeUsage('W');
    _calcTypeUsage('B');
    _calcTypeUsage('N');
    _calcTypeUsage('G');

    _calcTotalCost();

    _getUsageTrendingReleased();
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

  double? _getBilledAutoUsage(String type) {
    switch (type) {
      case 'E':
        return _billedAutoUsageE;
      case 'W':
        return _billedAutoUsageW;
      case 'B':
        return _billedAutoUsageB;
      case 'N':
        return _billedAutoUsageN;
      case 'G':
        return _billedAutoUsageG;
      default:
        return null;
    }
  }

  double? _getBilledSubTenantUsage(String type) {
    switch (type) {
      case 'E':
        return _billedSubTenantUsageE;
      case 'W':
        return _billedSubTenantUsageW;
      case 'B':
        return _billedSubTenantUsageB;
      case 'N':
        return _billedSubTenantUsageN;
      case 'G':
        return _billedSubTenantUsageG;
      default:
        return null;
    }
  }

  double? _getBilledManualUsage(String type) {
    switch (type) {
      case 'E':
        return _billedManualUsageE;
      case 'W':
        return _billedManualUsageW;
      case 'B':
        return _billedManualUsageB;
      case 'N':
        return _billedManualUsageN;
      case 'G':
        return _billedManualUsageG;
      default:
        return null;
    }
  }

  double? _getBilledUsageFactor(String type) {
    switch (type) {
      case 'E':
        return _billedUsageFactorE;
      case 'W':
        return _billedUsageFactorW;
      case 'B':
        return _billedUsageFactorB;
      case 'N':
        return _billedUsageFactorN;
      case 'G':
        return _billedUsageFactorG;
      default:
        return null;
    }
  }

  double? _getBilledRate(String type) {
    switch (type) {
      case 'E':
        return _billedRateE;
      case 'W':
        return _billedRateW;
      case 'B':
        return _billedRateB;
      case 'N':
        return _billedRateN;
      case 'G':
        return _billedRateG;
      default:
        return null;
    }
  }

  void _calcTypeUsage(String typeTag) {
    final billedAutoUsage = _getBilledAutoUsage(typeTag);
    final billedSubTenantUsage = _getBilledSubTenantUsage(typeTag);
    final billedManualUsage = _getBilledManualUsage(typeTag);
    final billedUsageFactor = _getBilledUsageFactor(typeTag);
    final billedRate = _getBilledRate(typeTag);

    double? typeUsageTotal;
    double? typeUsageFactored;

    if (billedAutoUsage != null) {
      typeUsageTotal = billedAutoUsage;
    }
    if (billedSubTenantUsage != null) {
      typeUsageTotal ??= 0;
      typeUsageTotal = typeUsageTotal - billedSubTenantUsage;
    }
    if (billedManualUsage != null) {
      typeUsageTotal ??= 0;
      typeUsageTotal = typeUsageTotal + billedManualUsage;
    }
    if (billedUsageFactor != null && typeUsageTotal != null) {
      typeUsageFactored = typeUsageTotal * billedUsageFactor;
    }

    final typeUsage = EmsTypeUsage(
      typeTag: typeTag,
      usage: typeUsageTotal,
      usageFactored: typeUsageFactored,
      factor: billedUsageFactor,
      rate: billedRate,
      cost: typeUsageFactored != null && billedRate != null
          ? typeUsageFactored * billedRate
          : null,
    );

    switch (typeTag) {
      case 'E':
        _typeUsageE = typeUsage;
        break;
      case 'W':
        _typeUsageW = typeUsage;
        break;
      case 'B':
        _typeUsageB = typeUsage;
        break;
      case 'N':
        _typeUsageN = typeUsage;
        break;
      case 'G':
        _typeUsageG = typeUsage;
        break;
    }
  }

  void _calcTotalCost() {
    double? subTotalCost;
    double? gstAmount;

    if (_typeUsageE != null) {
      subTotalCost ??= 0;
      subTotalCost = subTotalCost + _typeUsageE!.usageFactored!;
    }
    if (_typeUsageW != null) {
      subTotalCost ??= 0;
      subTotalCost = subTotalCost + _typeUsageW!.usageFactored!;
    }
    if (_typeUsageB != null) {
      subTotalCost ??= 0;
      subTotalCost = subTotalCost + _typeUsageB!.usageFactored!;
    }
    if (_typeUsageN != null) {
      subTotalCost ??= 0;
      subTotalCost = subTotalCost + _typeUsageN!.usageFactored!;
    }
    if (_typeUsageG != null) {
      subTotalCost ??= 0;
      subTotalCost = subTotalCost + _typeUsageG!.usageFactored!;
    }

    if (_billedGst != null) {
      gstAmount = subTotalCost! * _billedGst;
    } else {
      throw Exception('GST is not defined');
    }

    _subTotalCost = getRound(subTotalCost, 2);
    _gstAmount = getRoundUp(gstAmount, 2);
    _totalCost = _subTotalCost! + _gstAmount!;
  }

  void _getUsageTrendingReleased() {
    if (_billedTrendingSnapShot == null) {
      return;
    }
    for (var item in _billedTrendingSnapShot) {
      double? billedTotalUsageE = item['billed_total_usage_e'];
      double? billedTotalUsageW = item['billed_total_usage_w'];
      double? billedTotalUsageB = item['billed_total_usage_b'];
      double? billedTotalUsageN = item['billed_total_usage_n'];
      double? billedTotalUsageG = item['billed_total_usage_g'];

      if (billedTotalUsageE != null) {
        _trendingE.add({
          'time': item['billed_time_label'],
          'label': item['billed_time_label'],
          'value': billedTotalUsageE,
        });
      }
      if (billedTotalUsageW != null) {
        _trendingW.add({
          'time': item['billed_time_label'],
          'label': item['billed_time_label'],
          'value': billedTotalUsageW,
        });
      }
      if (billedTotalUsageB != null) {
        _trendingB.add({
          'time': item['billed_time_label'],
          'label': item['billed_time_label'],
          'value': billedTotalUsageB,
        });
      }
      if (billedTotalUsageN != null) {
        _trendingN.add({
          'time': item['billed_time_label'],
          'label': item['billed_time_label'],
          'value': billedTotalUsageN,
        });
      }
      if (billedTotalUsageG != null) {
        _trendingG.add({
          'time': item['billed_time_label'],
          'label': item['billed_time_label'],
          'value': billedTotalUsageG,
        });
      }
    }
  }
}
