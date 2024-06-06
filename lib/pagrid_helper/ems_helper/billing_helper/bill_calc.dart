import 'package:flutter/foundation.dart';

class BillCalc {
  final List<Map<String, dynamic>> _groupsE = [];
  final List<Map<String, dynamic>> _groupsW = [];
  final List<Map<String, dynamic>> _groupsB = [];
  final List<Map<String, dynamic>> _groupsN = [];
  final List<Map<String, dynamic>> _groupsG = [];

  double? _rateE;
  double? _rateW;
  double? _rateB;
  double? _rateN;
  double? _rateG;

  double? _usageE;
  double? _usageW;
  double? _usageB;
  double? _usageN;
  double? _usageG;

  double? _billedAutoUsageE;
  double? _billedAutoUsageW;
  double? _billedAutoUsageB;
  double? _billedAutoUsageN;
  double? _billedAutoUsageG;

  double? _billedSubTenantUsageE;
  double? _billedSubTenantUsageW;
  double? _billedSubTenantUsageB;
  double? _billedSubTenantUsageN;
  double? _billedSubTenantUsageG;

  double? _subTenantUsageE;
  double? _subTenantUsageW;
  double? _subTenantUsageB;
  double? _subTenantUsageN;
  double? _subTenantUsageG;

  double? _manualUsageE;
  double? _manualUsageW;
  double? _manualUsageB;
  double? _manualUsageN;
  double? _manualUsageG;

  double? _costE;
  double? _costW;
  double? _costB;
  double? _costN;
  double? _costG;

  String? _costLineItemLabel1;
  double? _costLineItemValue1;

  double? _totalAmount;

  double? _billedTotalUsageE;
  double? _billedTotalUsageW;
  double? _billedTotalUsageB;
  double? _billedTotalUsageN;
  double? _billedTotalUsageG;

  final List<Map<String, dynamic>> _trendingE = [];
  final List<Map<String, dynamic>> _trendingW = [];
  final List<Map<String, dynamic>> _trendingB = [];
  final List<Map<String, dynamic>> _trendingN = [];
  final List<Map<String, dynamic>> _trendingG = [];

  get rateE => _rateE;
  get rateW => _rateW;
  get rateB => _rateB;
  get rateN => _rateN;
  get rateG => _rateG;

  get usageE => _usageE;
  get usageW => _usageW;
  get usageB => _usageB;
  get usageN => _usageN;
  get usageG => _usageG;

  get manualUsageE => _manualUsageE;
  get manualUsageW => _manualUsageW;
  get manualUsageB => _manualUsageB;
  get manualUsageN => _manualUsageN;
  get manualUsageG => _manualUsageG;

  get costE => _costE;
  get costW => _costW;
  get costB => _costB;
  get costN => _costN;
  get costG => _costG;

  get costLineItemLabel1 => _costLineItemLabel1;
  get costLineItemValue1 => _costLineItemValue1;

  get totalAmount => _totalAmount;

  get trendingE => _trendingE;
  get trendingW => _trendingW;
  get trendingB => _trendingB;
  get trendingN => _trendingN;
  get trendingG => _trendingG;

  BillCalc({
    required bool calReleased,
    required Map<String, dynamic> typeRates,
    List<Map<String, dynamic>> autoUsageSummary = const [],
    Map<String, dynamic> billedAutoUsages = const {},
    Map<String, dynamic> billedSubTenantUsages = const {},
    required Map<String, dynamic> manualUsages,
    required List<Map<String, dynamic>> lineItems,
    List<Map<String, dynamic>> billedTrendingSnapShot = const [],
    required double usageFactorE,
    required double usageFactorW,
    required double usageFactorB,
    required double usageFactorN,
    required double usageFactorG,
    List<Map<String, dynamic>> subTenantUsageSummary = const [],
  }) {
    _getRates(typeRates);
    if (!calReleased) {
      _sortGroups(autoUsageSummary, manualUsages);
      _usageE = _calcTypeUsage(
          _groupsE, manualUsages, subTenantUsageSummary, usageFactorE);
      _usageW = _calcTypeUsage(
          _groupsW, manualUsages, subTenantUsageSummary, usageFactorW);
      _usageB = _calcTypeUsage(
          _groupsB, manualUsages, subTenantUsageSummary, usageFactorB);
      _usageN = _calcTypeUsage(
          _groupsN, manualUsages, subTenantUsageSummary, usageFactorN);
      _usageG = _calcTypeUsage(
          _groupsG, manualUsages, subTenantUsageSummary, usageFactorG);
    } else {
      if (billedAutoUsages['billed_auto_usage_e'] != null) {
        _billedAutoUsageE =
            double.tryParse(billedAutoUsages['billed_auto_usage_e']);
        _usageE = _billedAutoUsageE;
      }
      if (billedSubTenantUsages['billed_sub_tenant_usage_e'] != null) {
        _billedSubTenantUsageE =
            double.tryParse(billedSubTenantUsages['billed_sub_tenant_usage_e']);
        if (_usageE == null) {
          _usageE = -1 * _billedSubTenantUsageE!;
        } else {
          _usageE = _usageE! - _billedSubTenantUsageE!;
        }
      }
      if (manualUsages['manual_usage_e'] != null) {
        _manualUsageE = double.tryParse(manualUsages['manual_usage_e']);
        if (_usageE == null) {
          _usageE = _manualUsageE;
        } else {
          _usageE = _usageE! + _manualUsageE!;
        }
      }
      if (billedAutoUsages['billed_auto_usage_w'] != null) {
        _billedAutoUsageW =
            double.tryParse(billedAutoUsages['billed_auto_usage_w']);
        _usageW = _billedAutoUsageW;
      }
      if (billedSubTenantUsages['billed_sub_tenant_usage_w'] != null) {
        _billedSubTenantUsageW =
            double.tryParse(billedSubTenantUsages['billed_sub_tenant_usage_w']);
        if (_usageW == null) {
          _usageW = -1 * _billedSubTenantUsageW!;
        } else {
          _usageW = _usageW! - _billedSubTenantUsageW!;
        }
      }
      if (manualUsages['manual_usage_w'] != null) {
        _manualUsageW = double.tryParse(manualUsages['manual_usage_w']);
        if (_usageW == null) {
          _usageW = _manualUsageW;
        } else {
          _usageW = _usageW! + _manualUsageW!;
        }
      }
      if (billedAutoUsages['billed_auto_usage_b'] != null) {
        _billedAutoUsageB =
            double.tryParse(billedAutoUsages['billed_auto_usage_b']);
        _usageB = _billedAutoUsageB;
      }
      if (billedSubTenantUsages['billed_sub_tenant_usage_b'] != null) {
        _billedSubTenantUsageB =
            double.tryParse(billedSubTenantUsages['billed_sub_tenant_usage_b']);
        if (_usageB == null) {
          _usageB = -1 * _billedSubTenantUsageB!;
        } else {
          _usageB = _usageB! - _billedSubTenantUsageB!;
        }
      }
      if (manualUsages['manual_usage_b'] != null) {
        _manualUsageB = double.tryParse(manualUsages['manual_usage_b']);
        if (_usageB == null) {
          _usageB = _manualUsageB;
        } else {
          _usageB = _usageB! + _manualUsageB!;
        }
      }
      if (billedAutoUsages['billed_auto_usage_n'] != null) {
        _billedAutoUsageN =
            double.tryParse(billedAutoUsages['billed_auto_usage_n']);
        _usageN = _billedAutoUsageN;
      }
      if (billedSubTenantUsages['billed_sub_tenant_usage_n'] != null) {
        _billedSubTenantUsageN =
            double.tryParse(billedSubTenantUsages['billed_sub_tenant_usage_n']);
        if (_usageN == null) {
          _usageN = -1 * _billedSubTenantUsageN!;
        } else {
          _usageN = _usageN! - _billedSubTenantUsageN!;
        }
      }
      if (manualUsages['manual_usage_n'] != null) {
        _manualUsageN = double.tryParse(manualUsages['manual_usage_n']);
        if (_usageN == null) {
          _usageN = _manualUsageN;
        } else {
          _usageN = _usageN! + _manualUsageN!;
        }
      }
      if (billedAutoUsages['billed_auto_usage_g'] != null) {
        _billedAutoUsageG =
            double.tryParse(billedAutoUsages['billed_auto_usage_g']);
        _usageG = _billedAutoUsageG;
      }
      if (billedSubTenantUsages['billed_sub_tenant_usage_g'] != null) {
        _billedSubTenantUsageG =
            double.tryParse(billedSubTenantUsages['billed_sub_tenant_usage_g']);
        if (_usageG == null) {
          _usageG = -1 * _billedSubTenantUsageG!;
        } else {
          _usageG = _usageG! - _billedSubTenantUsageG!;
        }
      }
      if (manualUsages['manual_usage_g'] != null) {
        _manualUsageG = double.tryParse(manualUsages['manual_usage_g']);
        if (_usageG == null) {
          _usageG = _manualUsageG;
        } else {
          _usageG = _usageG! + _manualUsageG!;
        }
      }
    }
    _costE = (_usageE != null && _rateE != null) ? _usageE! * _rateE! : null;
    _costW = (_usageW != null && _rateW != null) ? _usageW! * _rateW! : null;
    _costB = (_usageB != null && _rateB != null) ? _usageB! * _rateB! : null;
    _costN = (_usageN != null && _rateN != null) ? _usageN! * _rateN! : null;
    _costG = (_usageG != null && _rateG != null) ? _usageG! * _rateG! : null;
    _calcLineItems(lineItems);

    if (_costE != null) {
      if (_totalAmount == null) {
        _totalAmount = _costE;
      } else {
        _totalAmount = _totalAmount! + _costE!;
      }
    }
    if (_costW != null) {
      if (_totalAmount == null) {
        _totalAmount = _costW;
      } else {
        _totalAmount = _totalAmount! + _costW!;
      }
    }
    if (_costB != null) {
      if (_totalAmount == null) {
        _totalAmount = _costB;
      } else {
        _totalAmount = _totalAmount! + _costB!;
      }
    }
    if (_costN != null) {
      if (_totalAmount == null) {
        _totalAmount = _costN;
      } else {
        _totalAmount = _totalAmount! + _costN!;
      }
    }
    if (_costG != null) {
      if (_totalAmount == null) {
        _totalAmount = _costG;
      } else {
        _totalAmount = _totalAmount! + _costG!;
      }
    }
    if (_costLineItemValue1 != null) {
      if (_totalAmount == null) {
        _totalAmount = _costLineItemValue1;
      } else {
        _totalAmount = _totalAmount! + _costLineItemValue1!;
      }
    }

    if (calReleased) {
      _getUsageTrendingReleased(billedTrendingSnapShot);
    } else {
      _getUsageTrending(autoUsageSummary);
    }
  }

  void _sortGroups(List<Map<String, dynamic>> autoUsageSummary,
      Map<String, dynamic> manualUsage) {
    _groupsE.clear();
    _groupsW.clear();
    _groupsB.clear();
    _groupsN.clear();
    _groupsG.clear();

    for (var item in autoUsageSummary) {
      switch (item['meter_type']) {
        case 'E':
          _groupsE.add(item);
          break;
        case 'W':
          _groupsW.add(item);
          break;
        case 'B':
          _groupsB.add(item);
          break;
        case 'N':
          _groupsN.add(item);
          break;
        case 'G':
          _groupsG.add(item);
          break;
        default:
      }
    }
    //add manual usage to the groups
    for (var item in manualUsage.entries) {
      String key = item.key;
      String value = item.value;
      if (key.contains('manual_usage_e')) {
        if (_groupsE.isEmpty) {
          _groupsE.add({'meter_type': 'E'});
        }
      } else if (key.contains('manual_usage_w')) {
        if (_groupsW.isEmpty) {
          _groupsW.add({'meter_type': 'W'});
        }
      } else if (key.contains('manual_usage_b')) {
        if (_groupsB.isEmpty) {
          _groupsB.add({'meter_type': 'B'});
        }
      } else if (key.contains('manual_usage_n')) {
        if (_groupsN.isEmpty) {
          _groupsN.add({'meter_type': 'N'});
        }
      } else if (key.contains('manual_usage_g')) {
        if (_groupsG.isEmpty) {
          _groupsG.add({'meter_type': 'G'});
        }
      }
    }
  }

  void _getRates(Map<String, dynamic> typeRates) {
    // String rateEStr = typeRates['E'] ?? 'x';
    // _rateE = double.tryParse(rateEStr);
    _rateE = typeRates['E'];

    // String rateWStr = typeRates['W'] ?? 'x';
    // _rateW = double.tryParse(rateWStr);
    _rateW = typeRates['W'];

    // String rateBStr = typeRates['B'] ?? 'x';
    // _rateB = double.tryParse(rateBStr);
    _rateB = typeRates['B'];

    // String rateNStr = typeRates['N'] ?? 'x';
    // _rateN = double.tryParse(rateNStr);
    _rateN = typeRates['N'];

    // String rateGStr = typeRates['G'] ?? 'x';
    // _rateG = double.tryParse(rateGStr);
    _rateG = typeRates['G'];
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

  double _calcTypeUsage(
    List<Map<String, dynamic>> typeGroupList,
    Map<String, dynamic> manualUsage,
    List<Map<String, dynamic>> subTenantUsageSummary,
    double usageFactor,
  ) {
    double typeUsageTotal = 0;
    String typeTag = '';
    for (var item in typeGroupList) {
      typeTag = item['meter_type'] ?? '';
      final meterGroupUsageSummary = item['meter_group_usage_summary'] ?? [];
      if (meterGroupUsageSummary.isNotEmpty) {
        List<Map<String, dynamic>> meterListUsageSummary = [];
        for (var mg in meterGroupUsageSummary['meter_list_usage_summary']) {
          meterListUsageSummary.add(mg);
        }

        double groupUsageTotal =
            _calcMeterGroupUsageTotal(meterListUsageSummary) ?? 0;
        typeUsageTotal += groupUsageTotal;

        // for (var meter in meterListUsageSummary) {
        //   String usageStr = meter['usage'] ?? '';
        //   double? usageVal = double.tryParse(usageStr);
        //   double? percentage = meter['percentage'];

        //   if (usageVal != null) {
        //     if (percentage != null) {
        //       usage += usageVal * (percentage / 100);
        //     } else {
        //       usage += usageVal;
        //     }
        //   }
        // }
      }
    }

    if (typeGroupList.isNotEmpty) {
      for (var item in subTenantUsageSummary) {
        final tenantUsageSummary = item['tenant_usage_summary'] ?? [];
        for (var tenant in tenantUsageSummary) {
          String usageType = tenant['meter_type'] ?? '';
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
            double subUsasgeTotal =
                _calcMeterGroupUsageTotal(meterListUsageSummary) ?? 0;
            typeUsageTotal -= subUsasgeTotal;
          }
        }
      }
    }

    typeUsageTotal = typeUsageTotal * usageFactor;

    if (manualUsage.isNotEmpty) {
      String key = 'manual_usage_$typeTag'.toLowerCase();
      String manualUsageStr = manualUsage[key] ?? '';
      double? manualUsageVal = double.tryParse(manualUsageStr);
      if (manualUsageVal != null) {
        typeUsageTotal += manualUsageVal;
      }
    }

    return typeUsageTotal;
  }

  void _calcLineItems(List<Map<String, dynamic>> lineItems) {
    if (lineItems.isEmpty) {
      return;
    }
    _costLineItemLabel1 = lineItems[0]['label'] ?? '';
    String costLineItemValue1Str = lineItems[0]['amount'] ?? 'x';
    _costLineItemValue1 = double.tryParse(costLineItemValue1Str);
  }

  void _getUsageTrending(
    List<Map<String, dynamic>> usageSummary,
  ) {
    for (var item in usageSummary) {
      List<Map<String, dynamic>> conlidatedHistoryList = [];
      String meterType = item['meter_type'] ?? '';
      final mgTrendingSnapShot = item['meter_group_trending_snapshot'] ?? [];
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

  void _getUsageTrendingReleased(
    List<Map<String, dynamic>> billedTrendingSnapShot,
  ) {
    for (var item in billedTrendingSnapShot) {
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
