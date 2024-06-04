import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'bill_calc.dart';

class WgtBillView extends StatefulWidget {
  const WgtBillView({
    super.key,
    required this.activePortalProjectScope,
    required this.scopeProfile,
    required this.loggedInUser,
    required this.billingRecIndexStr,
    required this.defaultBillLcStatus,
    // this.showRenderModeSwitch = true,
    this.modes = const ['wgt', 'pdf'],
    this.genTypes = const ['generated', 'released'],
  });

  final ScopeProfile scopeProfile;
  final Evs2User loggedInUser;
  final ProjectScope activePortalProjectScope;
  final String billingRecIndexStr;
  // final bool showRenderModeSwitch;
  final List<String> modes;
  final List<String> genTypes;
  final String defaultBillLcStatus;

  @override
  _WgtBillViewState createState() => _WgtBillViewState();
}

class _WgtBillViewState extends State<WgtBillView> {
  bool _gettingBill = false;
  bool _gettingTrendings = false;
  int _pullFails = 0;
  bool _isSwitching = false;
  String _errorText = '';

  final Map<String, dynamic> _bill = {};
  String _renderMode = 'wgt'; // wgt, pdf
  late String _lcStatusDisplay; // released, generated
  bool _showGenTypeSwitch = false;
  bool _showRenderModeSwitch = false;

  double? _usageFactorE;
  double? _usageFactorW;
  double? _usageFactorB;
  double? _usageFactorN;
  double? _usageFactorG;

  bool _gettingUsageFactor = false;
  int _pullFailed = 0;

  Future<dynamic> _getUsageFactor(
      DateTime fromDateTime, DateTime toDateTime) async {
    // setState(() {
    //   _gettingUsageFactor = true;
    // });
    try {
      List<String> types = ['E', 'W', 'B', 'N', 'G'];

      for (var type in types) {
        final usageFactorStr = await getSysVar(
            widget.activePortalProjectScope,
            {
              'name': 'usage_factor_$type'.toLowerCase(),
              'scope_str':
                  widget.scopeProfile.getEffectiveScopeStr().toLowerCase(),
              'from_timestamp': fromDateTime.toIso8601String(),
              'to_timestamp': toDateTime.toIso8601String(),
            },
            SvcClaim(
              scope: AclScope.global.name,
              target: getAclTargetStr(AclTarget.bill_p_info),
              operation: AclOperation.read.name,
            ));

        double? usageFactor = double.tryParse(usageFactorStr);
        if (usageFactor == null) {
          throw Exception('Invalid usage factor');
        }

        switch (type) {
          case 'E':
            _usageFactorE = usageFactor;
            break;
          case 'W':
            _usageFactorW = usageFactor;
            break;
          case 'B':
            _usageFactorB = usageFactor;
            break;
          case 'N':
            _usageFactorN = usageFactor;
            break;
          case 'G':
            _usageFactorG = usageFactor;
            break;
          default:
        }
      }
    } catch (e) {
      _pullFailed++;
      if (kDebugMode) {
        print('Error: $e');
      }
    } finally {
      // setState(() {
      //   _gettingUsageFactor = false;
      // });
    }
  }

  Future<dynamic> _getBill() async {
    setState(() {
      _errorText = '';
      _gettingBill = true;
      _bill.clear();
    });
    Map<String, String> queryMap = {
      'billing_rec_index': widget.billingRecIndexStr,
      'is_released_mode': _lcStatusDisplay == 'released' ? 'true' : 'false',
    };

    try {
      Map<String, dynamic> billResult = await getBill(
        widget.activePortalProjectScope,
        queryMap,
        SvcClaim(
          username: widget.loggedInUser.username,
          target: getAclTargetStr(AclTarget.bill_p_info),
          scope: widget.scopeProfile.getEffectiveScope().name,
          operation: AclOperation.read.name,
        ),
      );
      if (billResult['result'] != null) {
        _bill.addAll(billResult['result']);
      }

      if (_bill.isNotEmpty) {
        DateTime fromDatetime =
            getTargetDatetimeFromTargetStr(_bill['from_timestamp']);
        DateTime toDatetime =
            getTargetDatetimeFromTargetStr(_bill['to_timestamp']);
        await _getUsageFactor(fromDatetime, toDatetime);
      }
    } catch (err) {
      _pullFails++;
      if (kDebugMode) {
        print(err);
      }
      String errMsg = err.toString();
      if (errMsg.contains('valid tariff rate entry') ||
          errMsg.toLowerCase().contains('inconsistent usage info') ||
          errMsg.toLowerCase().contains('no tariff found')) {
        _errorText = err.toString().replaceFirst('Exception: ', '');
        _errorText = 'Vill Bill Error: $_errorText';
      } else {
        _errorText = 'Error getting bill';
      }
    } finally {
      setState(() {
        _gettingBill = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _pullFails = 0;
    _lcStatusDisplay = widget.defaultBillLcStatus;

    _showGenTypeSwitch = /*_lcStatusDisplay == 'released'*/
        widget.genTypes.length > 1;
    _showRenderModeSwitch = widget.modes.length > 1;
    _renderMode = widget.modes[0];
  }

  @override
  Widget build(BuildContext context) {
    bool pullData = _bill.isEmpty && !_gettingBill;

    if (_pullFails > 2) {
      if (kDebugMode) {
        print('item_group: pull fails more than $_pullFails times');
      }
      pullData = false;
      return SizedBox(
          height: 60,
          child: Center(
              child:
                  getErrorTextPrompt(context: context, errorText: _errorText)));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          verticalSpaceSmall,
          if (_showRenderModeSwitch && !_gettingBill)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                getSwitchRenderMode(),
                horizontalSpaceRegular,
                // if (_lcStatusDisplay == 'released') getSwitchGenType(),
                if (_showGenTypeSwitch) getSwitchGenType(),
              ],
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 13),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).hintColor.withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: pullData
                    ? FutureBuilder(
                        future: _getBill(),
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          switch (snapshot.connectionState) {
                            case ConnectionState.waiting:
                              if (kDebugMode) {
                                print('gen bill: pulling data');
                              }
                              return SizedBox(
                                height: 200,
                                child: Align(
                                  alignment: Alignment.center,
                                  child: xtWait(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              );
                            default:
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else {
                                return completedWidget();
                              }
                          }
                        },
                      )
                    : completedWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget completedWidget() {
    return _bill.isEmpty
        ? Center(
            child: Text(
              'No bill found',
              style: TextStyle(
                  color: Theme.of(context).hintColor.withOpacity(0.5),
                  fontSize: 34,
                  fontWeight: FontWeight.bold),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 13),
            child: getBillRender(),
          );
  }

  Widget getBillRender() {
    String tenantName = _bill['tenant_name'];
    String tenantLabel = _bill['tenant_label'];
    String accountId = _bill['tenant_alt_name'] ?? '';
    String tenantType = _bill['tenant_type'];
    String fromTimestampStr = _bill['from_timestamp'];
    DateTime fromDatetime = getTargetDatetimeFromTargetStr(fromTimestampStr);
    String toTimestampStr = _bill['to_timestamp'];
    DateTime toDatetime = getTargetDatetimeFromTargetStr(toTimestampStr);

    if (_lcStatusDisplay == 'released') {
      return getReleaseRender(
        tenantName,
        tenantLabel,
        accountId,
        tenantType,
        fromTimestampStr,
        toTimestampStr,
        fromDatetime,
        toDatetime,
      );
    } else {
      return getGeneratedRender(
        tenantName,
        tenantLabel,
        accountId,
        tenantType,
        fromTimestampStr,
        toTimestampStr,
        fromDatetime,
        toDatetime,
      );
    }
  }

  Widget getGeneratedRender(
    String tenantName,
    String tenantLabel,
    String accountId,
    String tenantType,
    String fromTimestampStr,
    String toTimestampStr,
    DateTime fromDatetime,
    DateTime toDatetime,
  ) {
    List<Map<String, dynamic>> usageSummary = [];
    if (_bill['tenant_usage_summary'] != null) {
      for (var item in _bill['tenant_usage_summary']) {
        usageSummary.add(item);
      }
    }
    Map<String, dynamic> tariffRates = _bill['meter_type_rates'];
    Map<String, dynamic> manualUsage = {};
    if (_bill['manual_usage_e'] != null) {
      manualUsage['manual_usage_e'] = _bill['manual_usage_e'];
    }
    if (_bill['manual_usage_w'] != null) {
      manualUsage['manual_usage_w'] = _bill['manual_usage_w'];
    }
    if (_bill['manual_usage_b'] != null) {
      manualUsage['manual_usage_b'] = _bill['manual_usage_b'];
    }
    if (_bill['manual_usage_n'] != null) {
      manualUsage['manual_usage_n'] = _bill['manual_usage_n'];
    }
    if (_bill['manual_usage_g'] != null) {
      manualUsage['manual_usage_g'] = _bill['manual_usage_g'];
    }
    Map<String, dynamic> lineItem = {};
    if (_bill['line_item_label_1'] != null) {
      lineItem['label'] = _bill['line_item_label_1'];
    }
    if (_bill['line_item_amount_1'] != null) {
      lineItem['amount'] = _bill['line_item_amount_1'];
    }

    List<Map<String, dynamic>> subTenantListUsageSummary = [];
    if (_bill['sub_tenant_list_usage_summary'] != null) {
      for (var item in _bill['sub_tenant_list_usage_summary']) {
        subTenantListUsageSummary.add(item);
      }
    }

    bool isMonthly = _bill['is_monthly'] == 'true' ? true : false;
    String billTimeRangeStr = getTimeRangeStr(
      fromDatetime,
      toDatetime,
      targetInterval: 'monthly',
      useMiddle: isMonthly ? true : false,
    );

    String? typeRateE;
    String? gst;
    if (tariffRates['E'] != null) {
      typeRateE = tariffRates['E']['result']['rate'];
      gst = tariffRates['E']['result']['gst'];
    }
    String? typeRateW;
    if (tariffRates['W'] != null) {
      typeRateW = tariffRates['W']['result']['rate'];
      gst = tariffRates['W']['result']['gst'];
    }
    String? typeRateB;
    if (tariffRates['B'] != null) {
      typeRateB = tariffRates['B']['result']['rate'];
      gst = tariffRates['B']['result']['gst'];
    }
    String? typeRateN;
    if (tariffRates['N'] != null) {
      typeRateN = tariffRates['N']['result']['rate'];
      gst = tariffRates['N']['result']['gst'];
    }
    String? typeRateG;
    if (tariffRates['G'] != null) {
      typeRateG = tariffRates['G']['result']['rate'];
      gst = tariffRates['G']['result']['gst'];
    }

    // String? gst = _bill['gst'];

    Map<String, dynamic> typeRates = {};
    if (typeRateE != null) {
      typeRates['E'] = typeRateE;
    }
    if (typeRateW != null) {
      typeRates['W'] = typeRateW;
    }
    if (typeRateB != null) {
      typeRates['B'] = typeRateB;
    }
    if (typeRateN != null) {
      typeRates['N'] = typeRateN;
    }
    if (typeRateG != null) {
      typeRates['G'] = typeRateG;
    }

    BillCalc billCalc = BillCalc(
      calReleased: false,
      typeRates: typeRates,
      manualUsages: manualUsage,
      autoUsageSummary: usageSummary,
      subTenantUsageSummary: subTenantListUsageSummary,
      lineItems: [lineItem],
      usageFactorE: _usageFactorE!,
      usageFactorW: _usageFactorW!,
      usageFactorB: _usageFactorB!,
      usageFactorN: _usageFactorN!,
      usageFactorG: _usageFactorG!,
    );

    return _renderMode == 'pdf'
        ? WgtBillRenderPdf(
            billingInfo: {
              'customerName': tenantName,
              'customerAccountId': accountId,
              'customerLabel': tenantLabel,
              'customerType': tenantType,
              'gst': double.tryParse(gst ?? ''),
              'billingRecName': _bill['billing_rec_name'],
              'billFrom': fromTimestampStr,
              'billTo': toTimestampStr,
              'billDate': _bill['created_timestamp'],
              'billTimeRangeStr': billTimeRangeStr,
              'tenantUsageSummary': usageSummary,
              'totalAmount': billCalc.totalAmount,
              'typeRateE': billCalc.rateE,
              'typeRateW': billCalc.rateW,
              'typeRateB': billCalc.rateB,
              'typeRateN': billCalc.rateN,
              'typeRateG': billCalc.rateG,
              'typeUsageE': billCalc.usageE,
              'typeUsageW': billCalc.usageW,
              'typeUsageB': billCalc.usageB,
              'typeUsageN': billCalc.usageN,
              'typeUsageG': billCalc.usageG,
              'typeCostE': billCalc.costE,
              'typeCostW': billCalc.costW,
              'typeCostB': billCalc.costB,
              'typeCostN': billCalc.costN,
              'typeCostG': billCalc.costG,
              'trendingE': billCalc.trendingE,
              'trendingW': billCalc.trendingW,
              'trendingB': billCalc.trendingB,
              'trendingN': billCalc.trendingN,
              'trendingG': billCalc.trendingG,
              'lineItemLabel1': billCalc.costLineItemLabel1,
              'lineItemValue1': billCalc.costLineItemValue1,
            },
          )
        : WgtTenantUsageSummary(
            activePortalProjectScope: widget.activePortalProjectScope,
            loggedInUser: widget.loggedInUser,
            scopeProfile: widget.scopeProfile,
            isBillMode: true,
            showRenderModeSwitch: true,
            itemType: ItemType.meter_iwow,
            isMonthly: isMonthly,
            fromDatetime: fromDatetime,
            toDatetime: toDatetime,
            tenantName: tenantName,
            tenantLabel: tenantLabel,
            tenantAccountId: accountId,
            tenantType: tenantType,
            tenantUsageSummary: usageSummary,
            subTenantListUsageSummary: subTenantListUsageSummary,
            manualUsages: manualUsage,
            lineItems: [lineItem],
            excludeAutoUsage:
                _bill['exclude_auto_usage'] == 'true' ? true : false,
            meterTypeRates: tariffRates,
            gst: double.tryParse(gst ?? ''),
            usageFactor: {
              'E': _usageFactorE,
              'W': _usageFactorW,
              'B': _usageFactorB,
              'N': _usageFactorN,
              'G': _usageFactorG,
            },
          );
  }

  Widget getReleaseRender(
    String tenantName,
    String tenantLabel,
    String accountId,
    String tenantType,
    String fromTimestampStr,
    String toTimestampStr,
    DateTime fromDatetime,
    DateTime toDatetime,
  ) {
    Map<String, dynamic> autoUsages = {};
    Map<String, dynamic> billedAutoUsages = _bill['billed_auto_usages'];

    autoUsages['billed_auto_usage_e'] = billedAutoUsages['billed_auto_usage_e'];
    autoUsages['billed_auto_usage_w'] = billedAutoUsages['billed_auto_usage_w'];
    autoUsages['billed_auto_usage_b'] = billedAutoUsages['billed_auto_usage_b'];
    autoUsages['billed_auto_usage_n'] = billedAutoUsages['billed_auto_usage_n'];
    autoUsages['billed_auto_usage_g'] = billedAutoUsages['billed_auto_usage_g'];

    Map<String, dynamic> billedUsageFactors = _bill['billed_usage_factor'];
    Map<String, dynamic> usageFactor = {};
    usageFactor['billed_usage_factor_e'] =
        double.tryParse(billedUsageFactors['billed_usage_factor_e']);
    usageFactor['billed_usage_factor_w'] =
        double.tryParse(billedUsageFactors['billed_usage_factor_w']);
    usageFactor['billed_usage_factor_b'] =
        double.tryParse(billedUsageFactors['billed_usage_factor_b']);
    usageFactor['billed_usage_factor_n'] =
        double.tryParse(billedUsageFactors['billed_usage_factor_n']);
    usageFactor['billed_usage_factor_g'] =
        double.tryParse(billedUsageFactors['billed_usage_factor_g']);

    if (autoUsages['billed_auto_usage_e'] != null) {
      double billedAutoUsageE =
          double.tryParse(autoUsages['billed_auto_usage_e'])!;
      autoUsages['billed_auto_usage_e'] =
          (billedAutoUsageE * usageFactor['billed_usage_factor_e']).toString();
    }
    if (autoUsages['billed_auto_usage_w'] != null) {
      double billedAutoUsageW =
          double.tryParse(autoUsages['billed_auto_usage_w'])!;
      autoUsages['billed_auto_usage_w'] =
          (billedAutoUsageW * usageFactor['billed_usage_factor_w']).toString();
    }
    if (autoUsages['billed_auto_usage_b'] != null) {
      double billedAutoUsageB =
          double.tryParse(autoUsages['billed_auto_usage_b'])!;
      autoUsages['billed_auto_usage_b'] =
          (billedAutoUsageB * usageFactor['billed_usage_factor_b']).toString();
    }
    if (autoUsages['billed_auto_usage_n'] != null) {
      double billedAutoUsageN =
          double.tryParse(autoUsages['billed_auto_usage_n'])!;
      autoUsages['billed_auto_usage_n'] =
          (billedAutoUsageN * usageFactor['billed_usage_factor_n']).toString();
    }
    if (autoUsages['billed_auto_usage_g'] != null) {
      double billedAutoUsageG =
          double.tryParse(autoUsages['billed_auto_usage_g'])!;
      autoUsages['billed_auto_usage_g'] =
          (billedAutoUsageG * usageFactor['billed_usage_factor_g']).toString();
    }

    Map<String, dynamic> subTenantUsages = {};
    Map<String, dynamic> billedSubTenantUsages =
        _bill['billed_sub_tenant_usages'];

    subTenantUsages['billed_sub_tenant_usage_e'] =
        billedSubTenantUsages['billed_sub_tenant_usage_e'];
    subTenantUsages['billed_sub_tenant_usage_w'] =
        billedSubTenantUsages['billed_sub_tenant_usage_w'];
    subTenantUsages['billed_sub_tenant_usage_b'] =
        billedSubTenantUsages['billed_sub_tenant_usage_b'];
    subTenantUsages['billed_sub_tenant_usage_n'] =
        billedSubTenantUsages['billed_sub_tenant_usage_n'];
    subTenantUsages['billed_sub_tenant_usage_g'] =
        billedSubTenantUsages['billed_sub_tenant_usage_g'];
    if (subTenantUsages['billed_sub_tenant_usage_e'] != null) {
      double billedSubTenantUsageE =
          double.tryParse(subTenantUsages['billed_sub_tenant_usage_e'])!;
      subTenantUsages['billed_sub_tenant_usage_e'] =
          (billedSubTenantUsageE * usageFactor['billed_usage_factor_e'])
              .toString();
    }
    if (subTenantUsages['billed_sub_tenant_usage_w'] != null) {
      double billedSubTenantUsageW =
          double.tryParse(subTenantUsages['billed_sub_tenant_usage_w'])!;
      subTenantUsages['billed_sub_tenant_usage_w'] =
          (billedSubTenantUsageW * usageFactor['billed_usage_factor_w'])
              .toString();
    }
    if (subTenantUsages['billed_sub_tenant_usage_b'] != null) {
      double billedSubTenantUsageB =
          double.tryParse(subTenantUsages['billed_sub_tenant_usage_b'])!;
      subTenantUsages['billed_sub_tenant_usage_b'] =
          (billedSubTenantUsageB * usageFactor['billed_usage_factor_b'])
              .toString();
    }
    if (subTenantUsages['billed_sub_tenant_usage_n'] != null) {
      double billedSubTenantUsageN =
          double.tryParse(subTenantUsages['billed_sub_tenant_usage_n'])!;
      subTenantUsages['billed_sub_tenant_usage_n'] =
          (billedSubTenantUsageN * usageFactor['billed_usage_factor_n'])
              .toString();
    }
    if (subTenantUsages['billed_sub_tenant_usage_g'] != null) {
      double billedSubTenantUsageG =
          double.tryParse(subTenantUsages['billed_sub_tenant_usage_g'])!;
      subTenantUsages['billed_sub_tenant_usage_g'] =
          (billedSubTenantUsageG * usageFactor['billed_usage_factor_g'])
              .toString();
    }

    Map<String, dynamic> manualUsage = {};
    Map<String, dynamic> billedManualUsages = _bill['billed_manual_usages'];

    manualUsage['manual_usage_e'] = billedManualUsages['manual_usage_e'];
    manualUsage['manual_usage_w'] = billedManualUsages['manual_usage_w'];
    manualUsage['manual_usage_b'] = billedManualUsages['manual_usage_b'];
    manualUsage['manual_usage_n'] = billedManualUsages['manual_usage_n'];
    manualUsage['manual_usage_g'] = billedManualUsages['manual_usage_g'];

    Map<String, dynamic> lineItem = {};
    Map<String, dynamic> lineItemInfo = _bill['line_item_info'];
    if (lineItemInfo['line_item_label_1'] != null) {
      lineItem['label'] = lineItemInfo['line_item_label_1'];
    }
    if (lineItemInfo['line_item_amount_1'] != null) {
      lineItem['amount'] = lineItemInfo['line_item_amount_1'];
    }

    List<Map<String, dynamic>> subTenantListUsageSummary = [];
    if (_bill['sub_tenant_list_usage_summary'] != null) {
      for (var item in _bill['sub_tenant_list_usage_summary']) {
        subTenantListUsageSummary.add(item);
      }
    }

    bool isMonthly = _bill['is_monthly'] == 'true' ? true : false;
    String billTimeRangeStr = getTimeRangeStr(
      fromDatetime,
      toDatetime,
      targetInterval: 'monthly',
      useMiddle: isMonthly ? true : false,
    );

    // return Container();
    Map<String, dynamic> typeRates = {};
    Map<String, dynamic> billedRates = _bill['billed_rates'];

    String? typeRateE;
    String? gst;
    typeRateE = billedRates['billed_rate_e'];
    String? typeRateW;
    typeRateW = billedRates['billed_rate_w'];
    String? typeRateB;
    typeRateB = billedRates['billed_rate_b'];
    String? typeRateN;
    typeRateN = billedRates['billed_rate_n'];
    String? typeRateG;
    typeRateG = billedRates['billed_rate_g'];

    if (typeRateE != null) {
      typeRates['E'] = typeRateE;
      gst = billedRates['billed_gst'];
    }
    if (typeRateW != null) {
      typeRates['W'] = typeRateW;
      gst = billedRates['billed_gst'];
    }
    if (typeRateB != null) {
      typeRates['B'] = typeRateB;
      gst = billedRates['billed_gst'];
    }
    if (typeRateN != null) {
      typeRates['N'] = typeRateN;
      gst = billedRates['billed_gst'];
    }
    if (typeRateG != null) {
      typeRates['G'] = typeRateG;
      gst = billedRates['billed_gst'];
    }

    List<Map<String, dynamic>> billedTrendingSnapShot = [];
    if (_bill['billed_trending_snapshot'] != null) {
      for (var item in _bill['billed_trending_snapshot']) {
        billedTrendingSnapShot.add(item);
      }
    }

    BillCalc billCalc = BillCalc(
      calReleased: true,
      typeRates: typeRates,
      manualUsages: manualUsage,
      billedAutoUsages: autoUsages,
      billedSubTenantUsages: subTenantUsages,
      lineItems: [lineItem],
      billedTrendingSnapShot: billedTrendingSnapShot,
      usageFactorE: usageFactor['billed_usage_factor_e'],
      usageFactorW: usageFactor['billed_usage_factor_w'],
      usageFactorB: usageFactor['billed_usage_factor_b'],
      usageFactorN: usageFactor['billed_usage_factor_n'],
      usageFactorG: usageFactor['billed_usage_factor_g'],
    );

    return _renderMode == 'pdf'
        ? WgtBillRenderPdf(
            billingInfo: {
              'customerName': tenantName,
              'customerAccountId': accountId,
              'customerLabel': tenantLabel,
              'customerType': tenantType,
              'gst': double.tryParse(gst ?? ''),
              'billingRecName': _bill['billing_rec_name'],
              'billFrom': fromTimestampStr,
              'billTo': toTimestampStr,
              'billDate': _bill['created_timestamp'],
              'billTimeRangeStr': billTimeRangeStr,
              'tenantUsageSummary': const [],
              'totalAmount': billCalc.totalAmount,
              'typeRateE': billCalc.rateE,
              'typeRateW': billCalc.rateW,
              'typeRateB': billCalc.rateB,
              'typeRateN': billCalc.rateN,
              'typeRateG': billCalc.rateG,
              'typeUsageE': billCalc.usageE,
              'typeUsageW': billCalc.usageW,
              'typeUsageB': billCalc.usageB,
              'typeUsageN': billCalc.usageN,
              'typeUsageG': billCalc.usageG,
              'typeCostE': billCalc.costE,
              'typeCostW': billCalc.costW,
              'typeCostB': billCalc.costB,
              'typeCostN': billCalc.costN,
              'typeCostG': billCalc.costG,
              'trendingE': billCalc.trendingE,
              'trendingW': billCalc.trendingW,
              'trendingB': billCalc.trendingB,
              'trendingN': billCalc.trendingN,
              'trendingG': billCalc.trendingG,
              'lineItemLabel1': billCalc.costLineItemLabel1,
              'lineItemValue1': billCalc.costLineItemValue1,
            },
          )
        : WgtTenantUsageSummaryReleased(
            activePortalProjectScope: widget.activePortalProjectScope,
            loggedInUser: widget.loggedInUser,
            scopeProfile: widget.scopeProfile,
            isBillMode: true,
            showRenderModeSwitch: true,
            itemType: ItemType.meter_iwow,
            isMonthly: isMonthly,
            fromDatetime: fromDatetime,
            toDatetime: toDatetime,
            tenantName: tenantName,
            tenantLabel: tenantLabel,
            tenantAccountId: accountId,
            tenantType: tenantType,
            billedAutoUsages: autoUsages,
            billedSubTenantUsages: subTenantUsages,
            billedUsageFactor: usageFactor,
            manualUsages: manualUsage,
            lineItems: [lineItem],
            excludeAutoUsage:
                _bill['exclude_auto_usage'] == 'true' ? true : false,
            meterTypeRates: typeRates,
            gst: double.tryParse(gst ?? ''),
          );
  }

  Widget getSwitchRenderMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Render'),
        horizontalSpaceTiny,
        Switch(
          value: _renderMode == 'pdf' ? true : false,
          onChanged: _gettingBill
              ? null
              : (value) {
                  setState(() {
                    _isSwitching = true;
                    value ? _renderMode = 'pdf' : _renderMode = 'wgt';
                  });
                },
        ),
        const Text('PDF'),
      ],
    );
  }

  Widget getSwitchGenType() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('View in Gn Mode'),
        horizontalSpaceTiny,
        Switch(
          value: _lcStatusDisplay == 'released' ? true : false,
          onChanged: _gettingBill
              ? null
              : (value) {
                  setState(() {
                    _isSwitching = true;
                    value
                        ? _lcStatusDisplay = 'released'
                        : _lcStatusDisplay = 'generated';
                    _bill.clear();
                  });
                },
        ),
        const Text('View in Rl Mode'),
      ],
    );
  }
}
