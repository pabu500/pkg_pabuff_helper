import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';

import 'mdl_ems_type_usage.dart';
import 'mdl_ems_type_usage_r2.dart';

class PagEmsTypeUsageCalcReleased {
  late final int _costDecimals;
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

  List<PagEmsTypeUsageCalcReleased> _singularCalcList = [];

  //output
  EmsTypeUsageR2? _typeUsageE;
  EmsTypeUsageR2? _typeUsageW;
  EmsTypeUsageR2? _typeUsageB;
  EmsTypeUsageR2? _typeUsageN;
  EmsTypeUsageR2? _typeUsageG;

  final List<Map<String, dynamic>> _trendingE = [];
  final List<Map<String, dynamic>> _trendingW = [];
  final List<Map<String, dynamic>> _trendingB = [];
  final List<Map<String, dynamic>> _trendingN = [];
  final List<Map<String, dynamic>> _trendingG = [];

  double? _subTotalCost;
  double? _gstAmount;
  double? _totalCost;

  EmsTypeUsageR2? get typeUsageE => _typeUsageE;
  EmsTypeUsageR2? get typeUsageW => _typeUsageW;
  EmsTypeUsageR2? get typeUsageB => _typeUsageB;
  EmsTypeUsageR2? get typeUsageN => _typeUsageN;
  EmsTypeUsageR2? get typeUsageG => _typeUsageG;

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

  List<PagEmsTypeUsageCalcReleased> get singularCalcList => _singularCalcList;

  PagEmsTypeUsageCalcReleased({
    required int costDecimals,
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
    List<PagEmsTypeUsageCalcReleased> singularUsageCalcList = const [],
  }) {
    _costDecimals = costDecimals;

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

    if (singularUsageCalcList.isNotEmpty) {
      for (var item in singularUsageCalcList) {
        _singularCalcList.add(item);
      }
    }
  }

  void doCalc() {
    _calcTypeUsage('E');
    _calcTypeUsage('W');
    _calcTypeUsage('B');
    _calcTypeUsage('N');
    _calcTypeUsage('G');

    _calcTotalCost();

    _getUsageTrendingReleased({
      'E': _billedUsageFactorE,
      'W': _billedUsageFactorW,
      'B': _billedUsageFactorB,
      'N': _billedUsageFactorN,
      'G': _billedUsageFactorG,
    });
  }

  void doSingularCalc() {
    _calcTypeUsage('E');
    _calcTypeUsage('W');
    _calcTypeUsage('B');
    _calcTypeUsage('N');
    _calcTypeUsage('G');

    // _calcTotalCost();

    // _sortSubTenantUsage();

    // _getUsageTrending();
  }

  void doCompositeCalc() {
    _calcCompositeTypeUsage();
  }

  EmsTypeUsageR2 getTypeUsage(String usageType) {
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

    double? billedManualUsagePrefactored;
    if (billedManualUsage != null && billedUsageFactor != null) {
      billedManualUsagePrefactored = billedManualUsage / billedUsageFactor;
    }

    double? typeUsageTotal;
    double? typeUsageFactored;

    if (billedAutoUsage != null) {
      typeUsageTotal = billedAutoUsage;
    }
    if (billedSubTenantUsage != null) {
      typeUsageTotal ??= 0;
      typeUsageTotal = typeUsageTotal - billedSubTenantUsage;
    }

    if (billedManualUsagePrefactored != null) {
      typeUsageTotal ??= 0;
      typeUsageTotal = typeUsageTotal + billedManualUsagePrefactored;

      typeUsageFactored ??= 0;
      typeUsageFactored = typeUsageFactored + billedManualUsagePrefactored;
    }

    if (billedUsageFactor != null && typeUsageTotal != null) {
      typeUsageFactored = typeUsageTotal * billedUsageFactor;
    }

    final typeUsage = EmsTypeUsageR2(
      typeTag: typeTag,
      usage: typeUsageTotal,
      usageFactored: typeUsageFactored,
      factor: billedUsageFactor,
      rate: billedRate,
      // cost: typeUsageFactored != null && billedRate != null
      //     ? typeUsageFactored * billedRate
      //     : null,
      costDecimals: _costDecimals,
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

  void _calcCompositeTypeUsage() {
    double? compositeUsageE;
    double? compositeUsageW;
    double? compositeUsageB;
    double? compositeUsageN;
    double? compositeUsageG;
    double? compositeUsageFactoredE;
    double? compositeUsageFactoredW;
    double? compositeUsageFactoredB;
    double? compositeUsageFactoredN;
    double? compositeUsageFactoredG;
    double? compositeCostE;
    double? compositeCostW;
    double? compositeCostB;
    double? compositeCostN;
    double? compositeCostG;

    for (var singularCalc in _singularCalcList) {
      if (singularCalc.typeUsageE?.usage != null) {
        compositeUsageE ??= 0;
        compositeUsageE += singularCalc.typeUsageE!.usage!;
      }
      if (singularCalc.typeUsageW?.usage != null) {
        compositeUsageW ??= 0;
        compositeUsageW += singularCalc.typeUsageW!.usage!;
      }
      if (singularCalc.typeUsageB?.usage != null) {
        compositeUsageB ??= 0;
        compositeUsageB += singularCalc.typeUsageB!.usage!;
      }
      if (singularCalc.typeUsageN?.usage != null) {
        compositeUsageN ??= 0;
        compositeUsageN += singularCalc.typeUsageN!.usage!;
      }
      if (singularCalc.typeUsageG?.usage != null) {
        compositeUsageG ??= 0;
        compositeUsageG += singularCalc.typeUsageG!.usage!;
      }

      if (singularCalc.typeUsageE?.usageFactored != null) {
        compositeUsageFactoredE ??= 0;
        compositeUsageFactoredE += singularCalc.typeUsageE!.usageFactored!;
      }
      if (singularCalc.typeUsageW?.usageFactored != null) {
        compositeUsageFactoredW ??= 0;
        compositeUsageFactoredW += singularCalc.typeUsageW!.usageFactored!;
      }
      if (singularCalc.typeUsageB?.usageFactored != null) {
        compositeUsageFactoredB ??= 0;
        compositeUsageFactoredB += singularCalc.typeUsageB!.usageFactored!;
      }
      if (singularCalc.typeUsageN?.usageFactored != null) {
        compositeUsageFactoredN ??= 0;
        compositeUsageFactoredN += singularCalc.typeUsageN!.usageFactored!;
      }
      if (singularCalc.typeUsageG?.usageFactored != null) {
        compositeUsageFactoredG ??= 0;
        compositeUsageFactoredG += singularCalc.typeUsageG!.usageFactored!;
      }

      if (singularCalc.typeUsageE?.cost != null) {
        compositeCostE ??= 0;
        compositeCostE += singularCalc.typeUsageE!.cost!;
      }
      if (singularCalc.typeUsageW?.cost != null) {
        compositeCostW ??= 0;
        compositeCostW += singularCalc.typeUsageW!.cost!;
      }
      if (singularCalc.typeUsageB?.cost != null) {
        compositeCostB ??= 0;
        compositeCostB += singularCalc.typeUsageB!.cost!;
      }
      if (singularCalc.typeUsageN?.cost != null) {
        compositeCostN ??= 0;
        compositeCostN += singularCalc.typeUsageN!.cost!;
      }
      if (singularCalc.typeUsageG?.cost != null) {
        compositeCostG ??= 0;
        compositeCostG += singularCalc.typeUsageG!.cost!;
      }
    }

    _typeUsageE = EmsTypeUsageR2(
      typeTag: 'E',
      usage: compositeUsageE,
      usageFactored: compositeUsageFactoredE,
      factor: _billedUsageFactorE,
      // rate: _typeRateInfo['E'],
      cost: compositeCostE,
      costDecimals: _costDecimals,
    );
    _typeUsageW = EmsTypeUsageR2(
      typeTag: 'W',
      usage: compositeUsageW,
      usageFactored: compositeUsageFactoredW,
      factor: _billedUsageFactorW,
      // rate: _typeRateInfo['W'],
      cost: compositeCostW,
      costDecimals: _costDecimals,
    );
    _typeUsageB = EmsTypeUsageR2(
      typeTag: 'B',
      usage: compositeUsageB,
      usageFactored: compositeUsageFactoredB,
      factor: _billedUsageFactorB,
      // rate: _typeRateInfo['B'],
      cost: compositeCostB,
      costDecimals: _costDecimals,
    );
    _typeUsageN = EmsTypeUsageR2(
      typeTag: 'N',
      usage: compositeUsageN,
      usageFactored: compositeUsageFactoredN,
      factor: _billedUsageFactorN,
      // rate: _typeRateInfo['N'],
      cost: compositeCostN,
      costDecimals: _costDecimals,
    );
    _typeUsageG = EmsTypeUsageR2(
      typeTag: 'G',
      usage: compositeUsageG,
      usageFactored: compositeUsageFactoredG,
      factor: _billedUsageFactorG,
      // rate: _typeRateInfo['G'],
      cost: compositeCostG,
      costDecimals: _costDecimals,
    );

    double? subTotalCost;

    for (var singularCalc in _singularCalcList) {
      if (singularCalc.typeUsageE?.hasCost() ?? false) {
        subTotalCost ??= 0;
        subTotalCost += singularCalc.typeUsageE!.cost!;
      }
      if (singularCalc.typeUsageW?.hasCost() ?? false) {
        subTotalCost ??= 0;
        subTotalCost += singularCalc.typeUsageW!.cost!;
      }
      if (singularCalc.typeUsageB?.hasCost() ?? false) {
        subTotalCost ??= 0;
        subTotalCost += singularCalc.typeUsageB!.cost!;
      }
      if (singularCalc.typeUsageN?.hasCost() ?? false) {
        subTotalCost ??= 0;
        subTotalCost += singularCalc.typeUsageN!.cost!;
      }
      if (singularCalc.typeUsageG?.hasCost() ?? false) {
        subTotalCost ??= 0;
        subTotalCost += singularCalc.typeUsageG!.cost!;
      }
    }

    _subTotalCost = subTotalCost;
    if (_subTotalCost != null) {
      _subTotalCost = getRound(_subTotalCost!, 2);
      if (subTotalCost != null && _billedGst != null) {
        _gstAmount = subTotalCost * _billedGst / 100;
      }
      _gstAmount = getRoundUp(_gstAmount!, 2);
      _totalCost = _subTotalCost! + _gstAmount!;
    }
  }

  void _getUsageTrendingReleased(Map<String, dynamic> usageFactor) {
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

      double? usageFactorE = usageFactor['E'];
      double? usageFactorW = usageFactor['W'];
      double? usageFactorB = usageFactor['B'];
      double? usageFactorN = usageFactor['N'];
      double? usageFactorG = usageFactor['G'];

      double? billedTotalUsageFactoredE;
      double? billedTotalUsageFactoredW;
      double? billedTotalUsageFactoredB;
      double? billedTotalUsageFactoredN;
      double? billedTotalUsageFactoredG;

      if (billedTotalUsageE != null && usageFactorE != null) {
        billedTotalUsageFactoredE = billedTotalUsageE * usageFactorE;
      }

      if (billedTotalUsageW != null && usageFactorW != null) {
        billedTotalUsageFactoredW = billedTotalUsageW * usageFactorW;
      }

      if (billedTotalUsageB != null && usageFactorB != null) {
        billedTotalUsageFactoredB = billedTotalUsageB * usageFactorB;
      }

      if (billedTotalUsageN != null && usageFactorN != null) {
        billedTotalUsageFactoredN = billedTotalUsageN * usageFactorN;
      }

      if (billedTotalUsageG != null && usageFactorG != null) {
        billedTotalUsageFactoredG = billedTotalUsageG * usageFactorG;
      }

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
          'value': billedTotalUsageFactoredE,
        });
      }
      if (billedTotalUsageW != null) {
        _trendingW.add({
          'time': item['billed_time_label'],
          'label': item['billed_time_label'],
          'value': billedTotalUsageFactoredW,
        });
      }
      if (billedTotalUsageB != null) {
        _trendingB.add({
          'time': item['billed_time_label'],
          'label': item['billed_time_label'],
          'value': billedTotalUsageFactoredB,
        });
      }
      if (billedTotalUsageN != null) {
        _trendingN.add({
          'time': item['billed_time_label'],
          'label': item['billed_time_label'],
          'value': billedTotalUsageFactoredN,
        });
      }
      if (billedTotalUsageG != null) {
        _trendingG.add({
          'time': item['billed_time_label'],
          'label': item['billed_time_label'],
          'value': billedTotalUsageFactoredG,
        });
      }
    }
  }
}
