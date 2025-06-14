import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../pag_helper/model/mdl_pag_project_profile.dart';
import '../tenant/pag_ems_type_usage_calc.dart';
import '../tenant/wgt_pag_tenant_composite_usage_summary.dart';
import 'comm_pag_billing.dart';
import '../tenant/tenant_usage_calc_released_r2.dart';
import '../tenant/wgt_pag_tenant_usage_summary_released.dart';
import '../../../pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'wgt_pag_bill_render_pdf.dart';

class WgtPagCompositeBillView extends StatefulWidget {
  const WgtPagCompositeBillView({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.billingRecIndexStr,
    required this.defaultBillLcStatus,
    this.isBillMode = true,
    this.costDecimals = 3,
    this.modes = const ['wgt', 'pdf'],
    this.genTypes = const ['generated', 'released'],
  });

  final MdlPagUser loggedInUser;
  final MdlPagAppConfig appConfig;
  final bool isBillMode;
  final String billingRecIndexStr;
  final int costDecimals;
  final List<String> modes;
  final List<String> genTypes;
  final String defaultBillLcStatus;

  @override
  State<WgtPagCompositeBillView> createState() =>
      _WgtPagCompositeBillViewState();
}

class _WgtPagCompositeBillViewState extends State<WgtPagCompositeBillView> {
  final List<String> usageTypeTags = ['E', 'W', 'B', 'N', 'G'];

  bool _gettingBill = false;
  int _pullFails = 0;
  bool _isSwitching = false;
  String _errorText = '';

  final Map<String, dynamic> _bill = {};
  String _renderMode = 'wgt'; // wgt, pdf
  late String _lcStatusDisplay; // released, generated
  bool _showGenTypeSwitch = false;
  bool _showRenderModeSwitch = false;

  late final String assetFolder;

  Future<dynamic> _getCompositeBill() async {
    setState(() {
      _errorText = '';
      _gettingBill = true;
      _bill.clear();
    });
    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'billing_rec_index': widget.billingRecIndexStr,
      'is_released_mode': _lcStatusDisplay == 'released' ? 'true' : 'false',
      'show_release_in_pv_mode': 'true',
    };

    try {
      Map<String, dynamic> billResult = await getPagCompositeBill(
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          target: getAclTargetStr(AclTarget.bill_p_info),
          scope: '',
          operation: AclOperation.read.name,
        ),
      );
      _bill.addAll(billResult);
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
    if (_lcStatusDisplay == 'pv') {
      _lcStatusDisplay = 'released';
    }

    _showGenTypeSwitch = widget.genTypes.length > 1;
    _showRenderModeSwitch = widget.modes.length > 1;
    _renderMode = widget.modes[0];
    if (_lcStatusDisplay == 'released') {
      _renderMode = 'pdf';
    }

    MdlPagProjectProfile selectedProjectProfile =
        widget.loggedInUser.selectedScope.projectProfile!;
    assetFolder = selectedProjectProfile.assetFolder!;
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
          child: getErrorTextPrompt(context: context, errorText: _errorText),
        ),
      );
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
                  color: Theme.of(context).hintColor.withAlpha(130),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: pullData
                    ? FutureBuilder(
                        future: _getCompositeBill(),
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
                  color: Theme.of(context).hintColor.withAlpha(130),
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
    String tenantType = _bill['tenant_type'] ?? '';
    String fromTimestampStr = _bill['from_timestamp'];
    DateTime fromDatetime = getTargetDatetimeFromTargetStr(fromTimestampStr);
    String toTimestampStr = _bill['to_timestamp'];
    DateTime toDatetime = getTargetDatetimeFromTargetStr(toTimestampStr);
    String billBarFromMonth = _bill['bill_bar_from_timestamp'] ?? '';

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
          billBarFromMonth);
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
          billBarFromMonth);
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
    String billBarFromMonth,
  ) {
    // sort time
    bool isMonthly = true;
    // _bill['is_monthly'] == 'true' ? true : false;
    String billTimeRangeStr = getTimeRangeStr(
      fromDatetime,
      toDatetime,
      targetInterval: 'monthly',
      useMiddle: isMonthly ? true : false,
    );

    // sort usage factor
    Map<String, dynamic> usageFactor = {};
    if (_bill['usage_factor_list'] != null) {
      for (var item in _bill['usage_factor_list']) {
        String meterType = item['meter_type'];
        String valueStr = item['usage_factor'];
        double? value = double.tryParse(valueStr);
        usageFactor[meterType] = value;
      }
    }

    List<Map<String, dynamic>> singularUsageList = [];

    if (_bill['singular_billing_rec_list'] != null) {
      for (var singularUsage in _bill['singular_billing_rec_list']) {
        singularUsageList.add(singularUsage);
      }
    }

    List<PagEmsTypeUsageCalc> singularUsageCalcList = [];

    for (Map<String, dynamic> singularUsage in singularUsageList) {
      //sort auto usage
      List<Map<String, dynamic>> meterGroupUsageList = [];
      final tenantUsageSummary = singularUsage['tenant_usage_summary'];
      if (tenantUsageSummary != null) {
        if (tenantUsageSummary['meter_group_usage_list'] != null) {
          for (var meterGroupUsage
              in tenantUsageSummary['meter_group_usage_list']) {
            meterGroupUsageList.add(meterGroupUsage);
          }
        }
      }
      //sort type rates
      final meterTypeRateInfo = singularUsage['meter_type_rate_info'];
      Map<String, dynamic> typeRates = {};
      double? gst;
      for (String typeTag in usageTypeTags) {
        if (meterTypeRateInfo[typeTag] != null) {
          String typeRateStr = meterTypeRateInfo[typeTag]['result']['rate'];
          double? typeRate = double.tryParse(typeRateStr);
          typeRates[typeTag] = typeRate;

          if (gst == null) {
            String gstStr = meterTypeRateInfo[typeTag]['result']['gst'];
            gst = double.tryParse(gstStr);
          }
          if (gst == null) {
            throw Exception('gst is null');
          }
        }
      }

      PagEmsTypeUsageCalc emsTypeUsageCalc = PagEmsTypeUsageCalc(
        costDecimals: widget.costDecimals,
        gst: gst,
        typeRates: typeRates,
        usageFactor: usageFactor,
        autoUsageSummary: tenantUsageSummary,
        subTenantUsageSummary: [],
        manualUsageList: [],
        lineItemList: [],
        billBarFromMonth: billBarFromMonth,
        //use billed trending snapshot
        billedTrendingSnapShot: [],
      );
      emsTypeUsageCalc.doSingularCalc();
      singularUsageCalcList.add(emsTypeUsageCalc);

      singularUsage['usage_calc'] = emsTypeUsageCalc;
    }

    PagEmsTypeUsageCalc compositeUsageCalc = PagEmsTypeUsageCalc(
      costDecimals: widget.costDecimals,
      gst: 9.0,
      typeRates: {},
      usageFactor: usageFactor,
      autoUsageSummary: {},
      subTenantUsageSummary: [],
      manualUsageList: [],
      lineItemList: [],
      billBarFromMonth: billBarFromMonth,
      //use billed trending snapshot
      billedTrendingSnapShot: [],
      singularUsageCalcList: singularUsageCalcList,
    );
    compositeUsageCalc.doCompositeCalc();

    //sort manual usage
    List<Map<String, dynamic>> manualUsage = [];
    for (var typeTag in usageTypeTags) {
      if (_bill['manual_usage_$typeTag'.toLowerCase()] != null) {
        String usageStr = _bill['manual_usage_$typeTag'.toLowerCase()];
        double? usage = double.tryParse(usageStr);
        manualUsage.add({
          'meter_type': typeTag,
          'usage': usage,
        });
      }
    }

    //sort sub tenant usage
    List<Map<String, dynamic>> subTenantListUsageSummary = [];
    if (_bill['sub_tenant_list_usage_summary'] != null) {
      for (var tenant in _bill['sub_tenant_list_usage_summary']) {
        subTenantListUsageSummary.add(tenant);
      }
    }

    //sort line items
    List<Map<String, dynamic>> lineItems = [];
    if (_bill['line_item_label_1'] != null) {
      lineItems.add({
        'label': _bill['line_item_label_1'],
        'amount': _bill['line_item_amount_1'],
      });
    }

    //use billed trending snapshot
    List<Map<String, dynamic>> billedTrendingSnapShot = [];
    if (_bill['billed_trending_snapshot'] != null) {
      for (var item in _bill['billed_trending_snapshot']) {
        billedTrendingSnapShot.add(item);
      }
    }

    PagEmsTypeUsageCalc emsTypeUsageCalc = PagEmsTypeUsageCalc(
      costDecimals: widget.costDecimals,
      gst: 9.0,
      typeRates: {},
      usageFactor: usageFactor,
      autoUsageSummary: {},
      subTenantUsageSummary: subTenantListUsageSummary,
      manualUsageList: manualUsage,
      lineItemList: lineItems,
      billBarFromMonth: billBarFromMonth,
      //use billed trending snapshot
      billedTrendingSnapShot: billedTrendingSnapShot,
    );
    // emsTypeUsageCalc.doCalc();

    return _renderMode == 'pdf'
        ? WgtPagBillRenderPdf(
            billingInfo: {
              'customerName': tenantName,
              'customerAccountId': accountId,
              'customerLabel': tenantLabel,
              'customerType': tenantType,
              'gst': '9',
              'billingRecName': _bill['billing_rec_name'],
              'billFrom': fromTimestampStr,
              'billTo': toTimestampStr,
              'billDate': _bill['released_bill_timestamp'] ??
                  _bill['created_timestamp'],
              'billTimeRangeStr': billTimeRangeStr,
              'tenantUsageSummary': {},
              'subTotalAmount': emsTypeUsageCalc.subTotalCost,
              'gstAmount': emsTypeUsageCalc.gstAmount,
              'totalAmount': emsTypeUsageCalc.totalCost,
              'typeRateE': emsTypeUsageCalc.typeUsageE?.rate,
              'typeRateW': emsTypeUsageCalc.typeUsageW?.rate,
              'typeRateB': emsTypeUsageCalc.typeUsageB?.rate,
              'typeRateN': emsTypeUsageCalc.typeUsageN?.rate,
              'typeRateG': emsTypeUsageCalc.typeUsageG?.rate,
              'typeUsageE': emsTypeUsageCalc.typeUsageE?.usageFactored,
              'typeUsageW': emsTypeUsageCalc.typeUsageW?.usageFactored,
              'typeUsageB': emsTypeUsageCalc.typeUsageB?.usageFactored,
              'typeUsageN': emsTypeUsageCalc.typeUsageN?.usageFactored,
              'typeUsageG': emsTypeUsageCalc.typeUsageG?.usageFactored,
              'typeCostE': emsTypeUsageCalc.typeUsageE?.cost,
              'typeCostW': emsTypeUsageCalc.typeUsageW?.cost,
              'typeCostB': emsTypeUsageCalc.typeUsageB?.cost,
              'typeCostN': emsTypeUsageCalc.typeUsageN?.cost,
              'typeCostG': emsTypeUsageCalc.typeUsageG?.cost,
              'trendingE': emsTypeUsageCalc.trendingE,
              'trendingW': emsTypeUsageCalc.trendingW,
              'trendingB': emsTypeUsageCalc.trendingB,
              'trendingN': emsTypeUsageCalc.trendingN,
              'trendingG': emsTypeUsageCalc.trendingG,
              'lineItemLabel1': emsTypeUsageCalc.getLineItem(0)?['label'],
              'lineItemValue1': emsTypeUsageCalc.getLineItem(0)?['amount'],
              'assetFolder': assetFolder,
            },
          )
        : WgtPagTenantCompositeUsageSummary(
            costDecimals: widget.costDecimals,
            appConfig: widget.appConfig,
            loggedInUser: widget.loggedInUser,
            displayContextStr: '',
            tenantSingularUsageInfoList: singularUsageList,
            compositeUsageCalc: compositeUsageCalc,
            isBillMode: widget.isBillMode,
            showRenderModeSwitch: true,
            itemType: ItemType.meter_iwow,
            isMonthly: isMonthly,
            fromDatetime: fromDatetime,
            toDatetime: toDatetime,
            tenantName: tenantName,
            tenantLabel: tenantLabel,
            tenantAccountId: accountId,
            tenantType: tenantType,
            subTenantListUsageSummary: subTenantListUsageSummary,
            manualUsages: manualUsage,
            lineItems: lineItems,
            excludeAutoUsage:
                _bill['exclude_auto_usage'] == 'true' ? true : false,
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
    String billBarFromMonth,
  ) {
    bool isMonthly = _bill['is_monthly'] == 'true' ? true : false;
    String billTimeRangeStr = getTimeRangeStr(
      fromDatetime,
      toDatetime,
      targetInterval: 'monthly',
      useMiddle: isMonthly ? true : false,
    );

    Map<String, dynamic> billedAutoUsages = _bill['billed_auto_usages'] ?? {};
    Map<String, dynamic> billedSubTenantUsages =
        _bill['billed_sub_tenant_usages'] ?? {};
    Map<String, dynamic> billedManualUsages =
        _bill['billed_manual_usages'] ?? {};
    Map<String, dynamic> billedUsageFactors =
        _bill['billed_usage_factors'] ?? {};
    Map<String, dynamic> billedRates = _bill['billed_rates'] ?? {};
    double? billedGst;
    for (String typeTag in usageTypeTags) {
      typeTag = typeTag.toLowerCase();

      var valueObj = billedAutoUsages['billed_auto_usage_$typeTag'] ?? '';
      double? value;
      if (valueObj is String) {
        value = double.tryParse(valueObj);
        billedAutoUsages['billed_auto_usage_$typeTag'] = value;
      }

      valueObj =
          billedSubTenantUsages['billed_sub_tenant_usage_$typeTag'] ?? '';
      if (valueObj is String) {
        value = double.tryParse(valueObj);
        billedSubTenantUsages['billed_sub_tenant_usage_$typeTag'] = value;
      }

      valueObj = billedManualUsages['manual_usage_$typeTag'] ?? '';
      if (valueObj is String) {
        value = double.tryParse(valueObj);
        billedManualUsages['manual_usage_$typeTag'] = value;
      }

      valueObj = billedUsageFactors['billed_usage_factor_$typeTag'] ?? '';
      if (valueObj is String) {
        value = double.tryParse(valueObj);
        billedUsageFactors['billed_usage_factor_$typeTag'] = value;
      }

      valueObj = billedRates['billed_rate_$typeTag'] ?? '';
      if (valueObj is String) {
        value = double.tryParse(valueObj);
        billedRates['billed_rate_$typeTag'] = value;
      }

      if (billedGst == null) {
        var gstObj = billedRates['billed_gst'] ?? '';
        if (gstObj is String) {
          billedGst = double.tryParse(gstObj);
          if (billedGst == null) {
            throw Exception('billed gst is null');
          } else {
            billedRates['billed_gst'] = billedGst;
          }
        } else if (gstObj is double) {
          billedGst = gstObj;
        }
      }
    }

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

    List<Map<String, dynamic>> billedTrendingSnapShot = [];
    if (_bill['billed_trending_snapshot'] != null) {
      for (var item in _bill['billed_trending_snapshot']) {
        billedTrendingSnapShot.add(item);
      }
    }

    EmsTypeUsageCalcReleasedR2 emsTypeUsageCalcReleased =
        EmsTypeUsageCalcReleasedR2(
      costDecimals: widget.costDecimals,
      billedAutoUsageE: billedAutoUsages['billed_auto_usage_e'],
      billedAutoUsageW: billedAutoUsages['billed_auto_usage_w'],
      billedAutoUsageB: billedAutoUsages['billed_auto_usage_b'],
      billedAutoUsageN: billedAutoUsages['billed_auto_usage_n'],
      billedAutoUsageG: billedAutoUsages['billed_auto_usage_g'],
      billedSubTenantUsageE: billedSubTenantUsages['billed_sub_tenant_usage_e'],
      billedSubTenantUsageW: billedSubTenantUsages['billed_sub_tenant_usage_w'],
      billedSubTenantUsageB: billedSubTenantUsages['billed_sub_tenant_usage_b'],
      billedSubTenantUsageN: billedSubTenantUsages['billed_sub_tenant_usage_n'],
      billedSubTenantUsageG: billedSubTenantUsages['billed_sub_tenant_usage_g'],
      billedManualUsageE: billedManualUsages['manual_usage_e'],
      billedManualUsageW: billedManualUsages['manual_usage_w'],
      billedManualUsageB: billedManualUsages['manual_usage_b'],
      billedManualUsageN: billedManualUsages['manual_usage_n'],
      billedManualUsageG: billedManualUsages['manual_usage_g'],
      billedUsageFactorE: billedUsageFactors['billed_usage_factor_e'],
      billedUsageFactorW: billedUsageFactors['billed_usage_factor_w'],
      billedUsageFactorB: billedUsageFactors['billed_usage_factor_b'],
      billedUsageFactorN: billedUsageFactors['billed_usage_factor_n'],
      billedUsageFactorG: billedUsageFactors['billed_usage_factor_g'],
      billedRateE: billedRates['billed_rate_e'],
      billedRateW: billedRates['billed_rate_w'],
      billedRateB: billedRates['billed_rate_b'],
      billedRateN: billedRates['billed_rate_n'],
      billedRateG: billedRates['billed_rate_g'],
      billedGst: billedGst,
      lineItemList: [lineItem],
      billedTrendingSnapShot: billedTrendingSnapShot,
      billBarFromMonth: billBarFromMonth,
    );
    emsTypeUsageCalcReleased.doCalc();

    return _renderMode == 'pdf'
        ? WgtBillRenderPdf(
            billingInfo: {
              'customerName': tenantName,
              'customerAccountId': accountId,
              'customerLabel': tenantLabel,
              'customerType': tenantType,
              'gst': billedGst,
              'billingRecName': _bill['billing_rec_name'],
              'billFrom': fromTimestampStr,
              'billTo': toTimestampStr,
              'billDate': _bill['released_bill_timestamp'] ??
                  _bill['created_timestamp'],
              'billTimeRangeStr': billTimeRangeStr,
              'tenantUsageSummary': const [],
              'subTotalAmount': emsTypeUsageCalcReleased.subTotalCost,
              'gstAmount': emsTypeUsageCalcReleased.gstAmount,
              'totalAmount': emsTypeUsageCalcReleased.totalCost,
              'typeRateE': emsTypeUsageCalcReleased.typeUsageE?.rate,
              'typeRateW': emsTypeUsageCalcReleased.typeUsageW?.rate,
              'typeRateB': emsTypeUsageCalcReleased.typeUsageB?.rate,
              'typeRateN': emsTypeUsageCalcReleased.typeUsageN?.rate,
              'typeRateG': emsTypeUsageCalcReleased.typeUsageG?.rate,
              'typeUsageE': emsTypeUsageCalcReleased.typeUsageE?.usageFactored,
              'typeUsageW': emsTypeUsageCalcReleased.typeUsageW?.usageFactored,
              'typeUsageB': emsTypeUsageCalcReleased.typeUsageB?.usageFactored,
              'typeUsageN': emsTypeUsageCalcReleased.typeUsageN?.usageFactored,
              'typeUsageG': emsTypeUsageCalcReleased.typeUsageG?.usageFactored,
              'typeCostE': emsTypeUsageCalcReleased.typeUsageE?.cost,
              'typeCostW': emsTypeUsageCalcReleased.typeUsageW?.cost,
              'typeCostB': emsTypeUsageCalcReleased.typeUsageB?.cost,
              'typeCostN': emsTypeUsageCalcReleased.typeUsageN?.cost,
              'typeCostG': emsTypeUsageCalcReleased.typeUsageG?.cost,
              'trendingE': emsTypeUsageCalcReleased.trendingE,
              'trendingW': emsTypeUsageCalcReleased.trendingW,
              'trendingB': emsTypeUsageCalcReleased.trendingB,
              'trendingN': emsTypeUsageCalcReleased.trendingN,
              'trendingG': emsTypeUsageCalcReleased.trendingG,
              'lineItemLabel1':
                  emsTypeUsageCalcReleased.getLineItem(0)?['label'],
              'lineItemValue1':
                  emsTypeUsageCalcReleased.getLineItem(0)?['amount'],
            },
          )
        : WgtPagTenantUsageSummaryReleased(
            costDecimals: widget.costDecimals,
            appConfig: widget.appConfig,
            loggedInUser: widget.loggedInUser,
            displayContextStr: '',
            isBillMode: widget.isBillMode,
            usageCalc: emsTypeUsageCalcReleased,
            showRenderModeSwitch: true,
            itemType: ItemType.meter_iwow,
            isMonthly: isMonthly,
            fromDatetime: fromDatetime,
            toDatetime: toDatetime,
            tenantName: tenantName,
            tenantLabel: tenantLabel,
            tenantAccountId: accountId,
            tenantType: tenantType,
            billedAutoUsages: billedAutoUsages,
            billedSubTenantUsages: billedSubTenantUsages,
            billedUsageFactor: billedUsageFactors,
            manualUsages: billedManualUsages,
            lineItems: [lineItem],
            excludeAutoUsage:
                _bill['exclude_auto_usage'] == 'true' ? true : false,
            meterTypeRates: billedRates,
            gst: billedGst,
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
