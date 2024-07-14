import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';

import 'mdl_ems_type_usage.dart';

class EmsTypeUsageCalcReleased {
  //input
  late final double? _billedAutoUsageE;
  late final double? _billedAutoUsageW;
  late final double? _billedAutoUsageB;
  late final double? _billedAutoUsageN;
  late final double? _billedAutoUsageG;

  late final double? _billedSubTenantUsageE;
  late final double? _billedSubTenantUsageW;
  late final double? _billedSubTenantUsageB;
  late final double? _billedSubTenantUsageN;
  late final double? _billedSubTenantUsageG;

  late final double? _billedManualUsageE;
  late final double? _billedManualUsageW;
  late final double? _billedManualUsageB;
  late final double? _billedManualUsageN;
  late final double? _billedManualUsageG;

  late final double? _billedUsageFactorE;
  late final double? _billedUsageFactorW;
  late final double? _billedUsageFactorB;
  late final double? _billedUsageFactorN;
  late final double? _billedUsageFactorG;

  late final double? _billedRateE;
  late final double? _billedRateW;
  late final double? _billedRateB;
  late final double? _billedRateN;
  late final double? _billedRateG;

  late final double? _billedGst;

  late final List<Map<String, dynamic>>? _lineItemList;

  late final List<Map<String, dynamic>>? _billedTrendingSnapShot;

  late final String? _billBarFromMonth;

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

  String? get billBarFromMonth => _billBarFromMonth;

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
    String? billBarFromMonth,
  }) {
    _billedAutoUsageE = billedAutoUsageE;
    _billedAutoUsageW = billedAutoUsageW;
    _billedAutoUsageB = billedAutoUsageB;
    _billedAutoUsageN = billedAutoUsageN;
    _billedAutoUsageG = billedAutoUsageG;
    _billedSubTenantUsageE = billedSubTenantUsageE;
    _billedSubTenantUsageW = billedSubTenantUsageW;
    _billedSubTenantUsageB = billedSubTenantUsageB;
    _billedSubTenantUsageN = billedSubTenantUsageN;
    _billedSubTenantUsageG = billedSubTenantUsageG;
    _billedManualUsageE = billedManualUsageE;
    _billedManualUsageW = billedManualUsageW;
    _billedManualUsageB = billedManualUsageB;
    _billedManualUsageN = billedManualUsageN;
    _billedManualUsageG = billedManualUsageG;
    _billedUsageFactorE = billedUsageFactorE;
    _billedUsageFactorW = billedUsageFactorW;
    _billedUsageFactorB = billedUsageFactorB;
    _billedUsageFactorN = billedUsageFactorN;
    _billedUsageFactorG = billedUsageFactorG;
    _billedRateE = billedRateE;
    _billedRateW = billedRateW;
    _billedRateB = billedRateB;
    _billedRateN = billedRateN;
    _billedRateG = billedRateG;
    _billedGst = billedGst;
    _billedTrendingSnapShot = billedTrendingSnapShot;

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

    _getUsageTrendingReleased();
  }

  EmsTypeUsage getTypeUsage(String usageType) {
    switch (usageType) {
      case 'E':
        return _typeUsageE!;
      case 'W':
        return _typeUsageW!;
      case 'B':
        return _typeUsageB!;
      case 'N':
        return _typeUsageN!;
      case 'G':
        return _typeUsageG!;
      default:
        throw Exception('Invalid usage type');
    }
  }

  Map<String, dynamic>? getLineItem(int index) {
    if (_lineItemList == null || _lineItemList.isEmpty) {
      return null;
    }
    int length = _lineItemList.length;
    if (index > length - 1) {
      return null;
    }
    if (_lineItemList[index].isEmpty) {
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

    if (billedUsageFactor != null && typeUsageTotal != null) {
      typeUsageFactored = typeUsageTotal * billedUsageFactor;
    }

    // NOTE: manual usage is not factored
    if (billedManualUsage != null) {
      typeUsageTotal ??= 0;
      typeUsageTotal = typeUsageTotal + billedManualUsage;

      typeUsageFactored ??= 0;
      typeUsageFactored = typeUsageFactored + billedManualUsage;
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
      if (_typeUsageE!.cost != null) {
        subTotalCost ??= 0;
        subTotalCost = subTotalCost + _typeUsageE!.cost!;
      }
    }
    if (_typeUsageW != null) {
      if (_typeUsageW!.cost != null) {
        subTotalCost ??= 0;
        subTotalCost = subTotalCost + _typeUsageW!.cost!;
      }
    }
    if (_typeUsageB != null) {
      if (_typeUsageB!.cost != null) {
        subTotalCost ??= 0;
        subTotalCost = subTotalCost + _typeUsageB!.cost!;
      }
    }
    if (_typeUsageN != null) {
      if (_typeUsageN!.cost != null) {
        subTotalCost ??= 0;
        subTotalCost = subTotalCost + _typeUsageN!.cost!;
      }
    }
    if (_typeUsageG != null) {
      if (_typeUsageG!.cost != null) {
        subTotalCost ??= 0;
        subTotalCost = subTotalCost + _typeUsageG!.cost!;
      }
    }

    //line items
    if (_lineItemList != null) {
      for (var item in _lineItemList) {
        String amtStr = item['amount'] ?? '';
        double? amt = double.tryParse(amtStr);
        if (amt != null) {
          subTotalCost ??= 0;
          subTotalCost = subTotalCost + amt;
        }
      }
    }

    if (_billedGst != null) {
      gstAmount = subTotalCost! * _billedGst / 100;
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
      if (item['billed_time_label'] == null) {
        continue;
      }
      double? billedTotalUsageE = item['billed_total_usage_e'];
      double? billedTotalUsageW = item['billed_total_usage_w'];
      double? billedTotalUsageB = item['billed_total_usage_b'];
      double? billedTotalUsageN = item['billed_total_usage_n'];
      double? billedTotalUsageG = item['billed_total_usage_g'];

      if (item['billed_time_label'] != null) {
        if (item['billed_time_label'].toString().contains('2024-01') ||
            item['billed_time_label'].toString().contains('2024-02') ||
            item['billed_time_label'].toString().contains('2024-03') ||
            item['billed_time_label'].toString().contains('2024-04')) {
          continue;
        }
      }
      if ((_billBarFromMonth ?? '').isNotEmpty) {
        String timeLabel = item['billed_time_label'];
        if (!takeMonth(timeLabel, _billBarFromMonth!)) {
          continue;
        }
      }

      if ((_billBarFromMonth ?? '').isNotEmpty) {
        String monthLabel = _billBarFromMonth!.substring(0, 7);
        if (item['billed_time_label'].toString().contains(monthLabel)) {
          continue;
        }
      }

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
