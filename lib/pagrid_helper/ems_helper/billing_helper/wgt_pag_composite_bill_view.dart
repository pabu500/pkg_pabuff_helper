import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_item_delete_op.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

import '../../../pag_helper/def_helper/pag_item_helper.dart';
import '../../../pag_helper/model/mdl_pag_project_profile.dart';
import '../tenant/pag_ems_type_usage_calc.dart';
import '../tenant/pag_ems_type_usage_calc_rl.dart';
import '../../../pag_helper/wgt/app/ems/wgt_bill_lc_status_op.dart';
import '../tenant/wgt_pag_tenant_composite_usage_summary.dart';
import '../../../pag_helper/comm/comm_pag_billing.dart';
import '../tenant/wgt_pag_tenant_composite_usage_summary_rl.dart';
import '../../../pag_helper/model/acl/mdl_pag_svc_claim.dart';
import '../../../pag_helper/def_helper/dh_pag_bill.dart';
import 'wgt_pag_bill_render_pdf.dart';

class WgtPagCompositeBillView extends StatefulWidget {
  const WgtPagCompositeBillView({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.billingRecIndexStr,
    required this.defaultBillLcStatusStr,
    this.displayContextStr = 'bill_view',
    this.isBillMode = true,
    this.costDecimals = 3,
    this.modes = const ['wgt', 'pdf'],
    this.genTypes = const ['generated', 'released'],
    this.onUpdate,
  });

  final MdlPagUser loggedInUser;
  final MdlPagAppConfig appConfig;
  final bool isBillMode;
  final String displayContextStr;
  final String billingRecIndexStr;
  final int costDecimals;
  final List<String> modes;
  final List<String> genTypes;
  final String defaultBillLcStatusStr;
  final Function? onUpdate;

  @override
  State<WgtPagCompositeBillView> createState() =>
      _WgtPagCompositeBillViewState();
}

class _WgtPagCompositeBillViewState extends State<WgtPagCompositeBillView> {
  final List<String> usageTypeTags = ['E', 'W', 'B', 'N', 'G'];
  final defaultErrorText = 'Error getting bill';

  bool _gettingBill = false;
  int _pullFails = 0;
  bool _isSwitching = false;
  String _errorText = '';

  // the actual lc status of the bill
  late PagBillingLcStatus _billLcStatusActual;
  final Map<String, dynamic> _bill = {};
  String _renderMode = 'wgt'; // wgt, pdf
  // late String _lcStatusDisplay; // released, generated
  late PagBillingLcStatus _billLcStatusDisplay;
  bool _showGenTypeSwitch = false;
  bool _showRenderModeSwitch = false;

  late final String assetFolder;

  UniqueKey? _lcStatusOpsKey;
  bool _isDisabledGn = false;
  bool _isDisabledPvRl = false;

  bool _isDeleting = false;
  String _deleteResultText = '';

  Future<dynamic> _getCompositeBill() async {
    setState(() {
      _errorText = '';
      _gettingBill = true;
      _bill.clear();
    });
    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'billing_rec_index': widget.billingRecIndexStr,
      'is_released_mode': _billLcStatusDisplay == PagBillingLcStatus.released
          ? 'true'
          : 'false',
      'show_release_in_pv_mode': 'true',
    };

    try {
      final billResult = await getPagCompositeBill(
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

      // dev.log(err.toString());

      // String errMsg = err.toString();
      // if (errMsg.contains('valid tariff rate entry') ||
      //     errMsg.toLowerCase().contains('inconsistent usage info') ||
      //     errMsg.toLowerCase().contains('no tariff found')) {
      //   _errorText = err.toString().replaceFirst('Exception: ', '');
      //   _errorText = 'Vill Bill Error: $_errorText';
      // } else {
      //   _errorText = 'Error getting bill';
      // }
      dev.log('Error generating bill: $err');

      _errorText = getErrorText(err, defaultErrorText: defaultErrorText);
    } finally {
      setState(() {
        _gettingBill = false;
        if (_errorText.isNotEmpty) {
          showInfoDialog(context, 'Error', _errorText);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _pullFails = 0;
    _billLcStatusActual =
        PagBillingLcStatus.byValue(widget.defaultBillLcStatusStr);
    // if (_lcStatusDisplay == PagBillingLcStatus.pv) {
    //   _lcStatusDisplay = PagBillingLcStatus.released;
    // }
    _billLcStatusDisplay = _billLcStatusActual == PagBillingLcStatus.pv
        ? PagBillingLcStatus.released
        : _billLcStatusActual;

    _showGenTypeSwitch = widget.genTypes.length > 1;
    _showRenderModeSwitch = widget.modes.length > 1 &&
        _billLcStatusDisplay == PagBillingLcStatus.released;
    _renderMode = widget.modes[0];

    if (_billLcStatusDisplay == PagBillingLcStatus.released) {
      // _renderMode = 'pdf';
      // temp to put wgt till pdf template is ready
      _renderMode = 'wgt';
    }

    MdlPagProjectProfile selectedProjectProfile =
        widget.loggedInUser.selectedScope.projectProfile!;
    assetFolder = selectedProjectProfile.assetFolder!;
  }

  @override
  Widget build(BuildContext context) {
    bool pullData = _bill.isEmpty && !_gettingBill;

    if (_pullFails > 0) {
      dev.log('item_group: pull fails more than $_pullFails times');

      pullData = false;
      return SizedBox(
        height: 60,
        child: Center(
          child:
              getErrorTextPrompt(context: context, errorText: defaultErrorText),
        ),
      );
    }

    bool isItemMFD = false;
    if (_bill.isNotEmpty) {
      String lcStatusStr = _bill['lc_status'] ?? '';
      if (lcStatusStr == PagBillingLcStatus.mfd.value) {
        isItemMFD = true;
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          verticalSpaceSmall,
          isItemMFD && _deleteResultText.isNotEmpty
              ? _deleteResultText.contains('deleted')
                  ? getInfoTextPrompt(
                      context: context, infoText: _deleteResultText)
                  : getErrorTextPrompt(
                      context: context, errorText: _deleteResultText)
              : Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_showRenderModeSwitch && !_gettingBill)
                          getSwitchRenderMode(),
                        horizontalSpaceRegular,
                        // if (_lcStatusDisplay == 'released') getSwitchGenType(),
                        if (_showGenTypeSwitch) getSwitchGenType(),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        horizontalSpaceRegular,
                        if (_billLcStatusDisplay == PagBillingLcStatus.mfd)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: WgtItemDeleteOp(
                              appConfig: widget.appConfig,
                              itemKind: PagItemKind.bill,
                              itemType: '',
                              itemIndexStr: widget.billingRecIndexStr,
                              itemDeleteRef: _bill['billing_rec_name'] ?? '',
                              onDeleting: () {
                                setState(() {
                                  _isDeleting = true;
                                });
                              },
                              onDeleted: (Map<String, dynamic> result) {
                                setState(() {
                                  _isDeleting = false;
                                  if (result['error'] != null) {
                                    setState(() {
                                      _deleteResultText = result['error'];
                                    });
                                  } else {
                                    setState(() {
                                      _deleteResultText = 'Item deleted';
                                    });
                                  }
                                });
                                widget.onUpdate?.call();
                              },
                            ),
                          ),
                        WgtPagBillLcStatusOp(
                          key: _lcStatusOpsKey,
                          appConfig: widget.appConfig,
                          loggedInUser: widget.loggedInUser,
                          enableEdit: widget.displayContextStr == 'bill_view',
                          billInfo: _bill,
                          initialStatus: _billLcStatusActual,
                          onCommitted: (newStatus) {
                            setState(() {
                              _lcStatusOpsKey = UniqueKey();
                              _bill['lc_status'] = newStatus.value;
                              _isDisabledGn =
                                      false /*
                                  newStatus == PagBillingLcStatus.pv ||
                                      newStatus == PagBillingLcStatus.released*/
                                  ;
                              _isDisabledPvRl =
                                  newStatus == PagBillingLcStatus.generated;
                              _billLcStatusActual = newStatus;
                              _showGenTypeSwitch =
                                  newStatus == PagBillingLcStatus.pv ||
                                      newStatus == PagBillingLcStatus.released;
                              _showRenderModeSwitch =
                                  newStatus == PagBillingLcStatus.pv ||
                                      newStatus == PagBillingLcStatus.released;
                            });
                            widget.onUpdate?.call();
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        horizontalSpaceMedium,
                      ],
                    ),
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
                              dev.log('gen bill: pulling data');
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
    String? genType = _bill['gen_type'];
    String tenantName = _bill['tenant_name'];
    String tenantLabel = _bill['tenant_label'];
    String tenantAccountNumber = _bill['tenant_account_number'] ?? '';
    String tenantType = _bill['tenant_type'] ?? '';
    String depositAmountStr = _bill['deposit_amount'] ?? '';
    String paymentMethod = _bill['payment_method'] ?? '';
    if (paymentMethod.toLowerCase() != 'giro') {
      paymentMethod = 'Non-Giro';
    }
    String tenantBillingAddressLine1 =
        _bill['tenant_billing_address_line_1'] ?? '';
    String tenantBillingAddressLine2 =
        _bill['tenant_billing_address_line_2'] ?? '';
    String tenantBillingAddressLine3 =
        _bill['tenant_billing_address_line_3'] ?? '';
    String strFromTimestamp = _bill['from_timestamp'];
    DateTime? fromDatetime = getTargetDatetimeFromTargetStr(strFromTimestamp);
    String strToTimestamp = _bill['to_timestamp'];
    DateTime? toDatetime = getTargetDatetimeFromTargetStr(strToTimestamp);
    String strEffectiveToTimestamp = _bill['effective_to_timestamp'] ?? '';
    DateTime? effectiveToDatetime =
        getTargetDatetimeFromTargetStr(strEffectiveToTimestamp);
    String billBarFromMonth = _bill['bill_bar_from_timestamp'] ?? '';

    final miniSoaInfo = _bill['mini_soa_info'] ?? {};
    final strCollectionStartDateTimestamp =
        miniSoaInfo['collection_start_date_timestamp'] ?? '';
    final strCollectionEndDateTimestamp =
        miniSoaInfo['collection_end_date_timestamp'] ?? '';
    final interestInfo = _bill['interest_info'] ?? {};
    String cycleStr = _bill['cycle_str'] ?? '';
    String billDate = _bill['bill_date_timestamp'] ?? '';
    String? strBilledTotalAmount = _bill['billed_total_amount'];
    String billName = _bill['billing_rec_name'] ?? '';

    String tenantLcs = _bill['tenant_lcs'] ?? '';

    final billedGstAmount = _bill['billed_gst_amount'] ?? '';
    double billedGstAmountDouble = 0.0;
    if (billedGstAmount is String) {
      billedGstAmountDouble = double.tryParse(billedGstAmount) ?? 0.0;
    } else if (billedGstAmount is num) {
      billedGstAmountDouble = billedGstAmount.toDouble();
    }

    String strBilledUsageCostAmount = _bill['billed_usage_cost_amount'] ?? '';
    String strBilledInterestAmount = _bill['billed_interest_amount'] ?? '';
    String strBilledPayableAmount = _bill['billed_payable_amount'] ?? '';

    String billedAmgrCompanyTradingName =
        _bill['billed_amgr_company_trading_name'] ?? '';
    String billedAmgrCompanyRegNumber =
        _bill['billed_amgr_company_reg_number'] ?? '';
    String billedAmgrGstRegNumber = _bill['billed_amgr_gst_reg_number'] ?? '';
    String amgrAddressLine1 = _bill['amgr_address_line_1'] ?? '';
    String amgrAddressLine2 = _bill['amgr_address_line_2'] ?? '';
    String amgrAddressLine3 = _bill['amgr_address_line_3'] ?? '';
    String billedTpNote = _bill['billed_tp_note'] ?? '';
    String billedTptNote = _bill['billed_tpt_note'] ?? '';

    List<Map<String, dynamic>> lineItemList = [];
    final lineItemInfo = _bill['line_item_info'] ?? {};
    if (lineItemInfo['line_item_label_1'] != null &&
        lineItemInfo['line_item_amount_1'] != null) {
      lineItemList.add({
        'label': lineItemInfo['line_item_label_1'],
        'amount': lineItemInfo['line_item_amount_1'],
        'subjectToTax': true,
        'subjectToInterest': true,
      });
    }
    if (lineItemInfo['line_item_label_2'] != null &&
        lineItemInfo['line_item_amount_2'] != null) {
      lineItemList.add({
        'label': lineItemInfo['line_item_label_2'],
        'amount': lineItemInfo['line_item_amount_2'],
        'subjectToTax': false,
        'subjectToInterest': true,
      });
    }
    if (lineItemInfo['line_item_label_3'] != null &&
        lineItemInfo['line_item_amount_3'] != null) {
      lineItemList.add({
        'label': lineItemInfo['line_item_label_3'],
        'amount': lineItemInfo['line_item_amount_3'],
        'subjectToTax': false,
        'subjectToInterest': false,
      });
    }

    if ('initial_balance' == genType) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              Text(
                'Initial Balance Bill',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
              ),
              verticalSpaceSmall,
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    billName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  SizedBox(
                      width: 40,
                      child:
                          getCopyButton(context, billName, direction: 'left')),
                ],
              ),
              verticalSpaceSmall,
              Text(
                'Total Amount: ${strBilledTotalAmount ?? '0.0'}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final Map<String, dynamic> scopeMap =
        widget.loggedInUser.selectedScope.toScopeMap();

    if (_billLcStatusDisplay == PagBillingLcStatus.released
        // ||  _billLcStatusDisplay == PagBillingLcStatus.pv
        ) {
      return getReleaseRender(
          tenantName,
          tenantLabel,
          tenantAccountNumber,
          tenantType,
          tenantBillingAddressLine1,
          tenantBillingAddressLine2,
          tenantBillingAddressLine3,
          depositAmountStr,
          paymentMethod,
          tenantLcs,
          fromDatetime!,
          toDatetime!,
          effectiveToDatetime,
          cycleStr,
          billDate,
          billBarFromMonth,
          billedGstAmountDouble,
          lineItemList,
          miniSoaInfo,
          strCollectionStartDateTimestamp,
          strCollectionEndDateTimestamp,
          interestInfo,
          billedAmgrCompanyTradingName,
          billedAmgrCompanyRegNumber,
          billedAmgrGstRegNumber,
          amgrAddressLine1,
          amgrAddressLine2,
          amgrAddressLine3,
          billedTpNote,
          billedTptNote);
    } else {
      return getGeneratedRender(
          tenantName,
          tenantLabel,
          tenantAccountNumber,
          tenantType,
          tenantLcs,
          fromDatetime!,
          toDatetime!,
          effectiveToDatetime,
          cycleStr,
          billDate,
          billBarFromMonth,
          lineItemList,
          miniSoaInfo,
          strCollectionStartDateTimestamp,
          strCollectionEndDateTimestamp,
          interestInfo);
    }
  }

  Widget getGeneratedRender(
    String tenantName,
    String tenantLabel,
    String accountId,
    String tenantType,
    String? tenantLcs,
    DateTime fromDatetime,
    DateTime toDatetime,
    DateTime? effectiveToDatetime,
    String cycleStr,
    String billDate,
    String billBarFromMonth,
    List<Map<String, dynamic>> lineItemList,
    Map<String, dynamic>? miniSoaInfo,
    String strCollectionStartDateTimestamp,
    String strCollectionEndDateTimestamp,
    Map<String, dynamic>? interestInfo,
  ) {
    // sort time
    bool isMonthly = true;
    // _bill['is_monthly'] == 'true' ? true : false;
    // String billTimeRangeStr = getTimeRangeStr(
    //   fromDatetime,
    //   toDatetime,
    //   targetInterval: 'monthly',
    //   useMiddle: isMonthly ? true : false,
    // );

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
      final autoUsageSummary = singularUsage['tenant_usage_summary'];
      if (autoUsageSummary != null) {
        if (autoUsageSummary['meter_group_usage_list'] != null) {
          for (var meterGroupUsage
              in autoUsageSummary['meter_group_usage_list']) {
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

      List<Map<String, dynamic>> manualUsageList = [];
      final manualUsageInfo = singularUsage['manual_usage_info'] ?? {};
      final manualUsageE = manualUsageInfo['manual_usage_e'];
      final manualUsageW = manualUsageInfo['manual_usage_w'];
      final manualUsageB = manualUsageInfo['manual_usage_b'];
      final manualUsageN = manualUsageInfo['manual_usage_n'];
      final manualUsageG = manualUsageInfo['manual_usage_g'];
      if (manualUsageE != null) {
        double? usage = double.tryParse(manualUsageE);
        manualUsageList.add({
          'meter_type': 'E',
          'usage': usage,
        });
      }
      if (manualUsageW != null) {
        double? usage = double.tryParse(manualUsageW);
        manualUsageList.add({
          'meter_type': 'W',
          'usage': usage,
        });
      }
      if (manualUsageB != null) {
        double? usage = double.tryParse(manualUsageB);
        manualUsageList.add({
          'meter_type': 'B',
          'usage': usage,
        });
      }
      if (manualUsageN != null) {
        double? usage = double.tryParse(manualUsageN);
        manualUsageList.add({
          'meter_type': 'N',
          'usage': usage,
        });
      }
      if (manualUsageG != null) {
        double? usage = double.tryParse(manualUsageG);
        manualUsageList.add({
          'meter_type': 'G',
          'usage': usage,
        });
      }

      PagEmsTypeUsageCalc emsTypeUsageCalc = PagEmsTypeUsageCalc(
        costDecimals: widget.costDecimals,
        gst: gst,
        typeRates: typeRates,
        usageFactor: usageFactor,
        autoUsageSummary: autoUsageSummary ?? {},
        subTenantUsageSummary: [],
        manualUsageList: manualUsageList,
        lineItemList: lineItemList,
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
      lineItemList: lineItemList,
      billBarFromMonth: billBarFromMonth,
      //use billed trending snapshot
      billedTrendingSnapShot: [],
      singularUsageCalcList: singularUsageCalcList,
      miniSoaInfo: miniSoaInfo,
      interestInfo: interestInfo,
    );
    compositeUsageCalc.doCompositeCalc();

    //sort manual usage
    // List<Map<String, dynamic>> manualUsage = [];
    // for (var typeTag in usageTypeTags) {
    //   if (_bill['manual_usage_$typeTag'.toLowerCase()] != null) {
    //     String usageStr = _bill['manual_usage_$typeTag'.toLowerCase()];
    //     double? usage = double.tryParse(usageStr);
    //     manualUsage.add({
    //       'meter_type': typeTag,
    //       'usage': usage,
    //     });
    //   }
    // }

    // //sort sub tenant usage
    List<Map<String, dynamic>> subTenantListUsageSummary = [];
    // if (_bill['sub_tenant_list_usage_summary'] != null) {
    //   for (var tenant in _bill['sub_tenant_list_usage_summary']) {
    //     subTenantListUsageSummary.add(tenant);
    //   }
    // }

    // //sort line items
    // List<Map<String, dynamic>> lineItems = [];
    // if (_bill['line_item_label_1'] != null) {
    //   lineItems.add({
    //     'label': _bill['line_item_label_1'],
    //     'amount': _bill['line_item_amount_1'],
    //   });
    // }

    // //use billed trending snapshot
    // List<Map<String, dynamic>> billedTrendingSnapShot = [];
    // if (_bill['billed_trending_snapshot'] != null) {
    //   for (var item in _bill['billed_trending_snapshot']) {
    //     billedTrendingSnapShot.add(item);
    //   }
    // }

    // PagEmsTypeUsageCalc emsTypeUsageCalc = PagEmsTypeUsageCalc(
    //   costDecimals: widget.costDecimals,
    //   gst: 9.0,
    //   typeRates: {},
    //   usageFactor: usageFactor,
    //   autoUsageSummary: {},
    //   subTenantUsageSummary: subTenantListUsageSummary,
    //   manualUsageList: manualUsage,
    //   lineItemList: lineItems,
    //   billBarFromMonth: billBarFromMonth,
    //   //use billed trending snapshot
    //   billedTrendingSnapShot: billedTrendingSnapShot,
    // );
    // emsTypeUsageCalc.doCalc();

    return _renderMode == 'pdf'
        ? Container()
        : WgtPagTenantCompositeUsageSummary(
            isDisabled: _isDisabledGn,
            costDecimals: widget.costDecimals,
            appConfig: widget.appConfig,
            loggedInUser: widget.loggedInUser,
            displayContextStr: widget.displayContextStr,
            tenantSingularUsageInfoList: singularUsageList,
            compositeUsageCalc: compositeUsageCalc,
            strCollectionStartDateTimestamp: strCollectionStartDateTimestamp,
            strCollectionEndDateTimestamp: strCollectionEndDateTimestamp,
            isBillMode: widget.isBillMode,
            billInfo: _bill,
            showRenderModeSwitch: true,
            itemType: ItemType.meter_iwow,
            isMonthly: isMonthly,
            tenantLcs: tenantLcs,
            fromDatetime: fromDatetime,
            toDatetime: toDatetime,
            effectiveToDatetime: effectiveToDatetime,
            tenantName: tenantName,
            tenantLabel: tenantLabel,
            tenantAccountId: accountId,
            tenantType: tenantType,
            cycleStr: cycleStr,
            billDate: billDate,
            subTenantListUsageSummary: subTenantListUsageSummary,
            // manualUsages: manualUsage,
            lineItems: lineItemList,
            // excludeAutoUsage: _bill['exclude_auto_usage'] == 'true' ? true : false,
            interestInfo: interestInfo!,
            onUpdate: () {
              widget.onUpdate?.call();
              setState(() {
                // _lcStatusDisplay = _bill['lc_status'];
              });
            },
          );
  }

  Widget getReleaseRender(
    String tenantName,
    String tenantLabel,
    String accountId,
    String tenantType,
    String tenantBillingAddressLine1,
    String tenantBillingAddressLine2,
    String tenantBillingAddressLine3,
    String depositAmountStr,
    String paymentMethod,
    String? tenantLcs,
    DateTime fromDatetime,
    DateTime toDatetime,
    DateTime? effectiveToDatetime,
    String cycleStr,
    String billDate,
    String billBarFromMonth,
    double? billedGstAmount,
    List<Map<String, dynamic>> lineItemList,
    Map<String, dynamic> miniSoaInfo,
    String previousCollectionDateTimestampStr,
    String currentCollectionDateTimestampStr,
    Map<String, dynamic> interestInfo,
    String? billedAmgrCompanyTradingName,
    String? billedAmgrCompanyRegNumber,
    String? billedAmgrGstRegNumber,
    String? amgrAddressLine1,
    String? amgrAddressLine2,
    String? amgrAddressLine3,
    String? billedTpNote,
    String? billedTptNote,
  ) {
    bool isMonthly = true; //_bill['is_monthly'] == 'true' ? true : false;
    String billTimeRangeStr = getTimeRangeStr(
      fromDatetime,
      toDatetime,
      targetInterval: 'monthly',
      useMiddle: isMonthly ? true : false,
    );

    List<Map<String, dynamic>> singularUsageList = [];

    if (_bill['singular_billing_rec_list'] != null) {
      for (var singularUsage in _bill['singular_billing_rec_list']) {
        singularUsageList.add(singularUsage);
      }
    }

    List<PagEmsTypeUsageCalcRl> singularUsageCalcList = [];

    List<String> usageTypeTags = ['E', 'W', 'B', 'N', 'G'];

    for (Map<String, dynamic> singularUsage in singularUsageList) {
      Map<String, dynamic> billedAutoUsageInfo = {};
      for (String typeTag in usageTypeTags) {
        typeTag = typeTag.toLowerCase();
        String typebilledAutoUsageStr =
            singularUsage['billed_auto_usage_$typeTag'] ?? '';
        double? usage = double.tryParse(typebilledAutoUsageStr);
        if (usage != null) {
          billedAutoUsageInfo['billed_auto_usage_$typeTag'] = usage;
        }
      }

      Map<String, dynamic> billedUsageFactorInfo = {};
      if (_bill['usage_factor_list'] != null) {
        for (var item in _bill['usage_factor_list']) {
          String meterType = item['meter_type'];
          meterType = meterType.toLowerCase();
          String valueStr = item['usage_factor'];
          double? value = double.tryParse(valueStr);
          billedUsageFactorInfo['billed_usage_factor_$meterType'] = value;
        }
      }

      Map<String, dynamic> billedRateInfo = {};
      for (String typeTag in usageTypeTags) {
        typeTag = typeTag.toLowerCase();
        String typebilledRateStr = singularUsage['billed_rate_$typeTag'] ?? '';
        double? rate = double.tryParse(typebilledRateStr);
        if (rate != null) {
          billedRateInfo['billed_rate_$typeTag'] = rate;
        }
      }

      Map<String, dynamic> billedSubTenantUsages = {};
      Map<String, dynamic> billedManualUsages = {};
      List<Map<String, dynamic>> billedTrendingSnapShot = [];

      double? billedGst;
      if (singularUsage['billed_gst'] != null) {
        billedGst = double.tryParse(singularUsage['billed_gst']);
      }
      double? billedGstAmount;
      if (singularUsage['billed_gst_amount'] != null) {
        billedGstAmount = double.tryParse(singularUsage['billed_gst_amount']);
      }

      PagEmsTypeUsageCalcRl emsTypeUsageCalcRl = PagEmsTypeUsageCalcRl(
        costDecimals: widget.costDecimals,
        billedAutoUsageE: billedAutoUsageInfo['billed_auto_usage_e'],
        billedAutoUsageW: billedAutoUsageInfo['billed_auto_usage_w'],
        billedAutoUsageB: billedAutoUsageInfo['billed_auto_usage_b'],
        billedAutoUsageN: billedAutoUsageInfo['billed_auto_usage_n'],
        billedAutoUsageG: billedAutoUsageInfo['billed_auto_usage_g'],
        billedSubTenantUsageE:
            billedSubTenantUsages['billed_sub_tenant_usage_e'],
        billedSubTenantUsageW:
            billedSubTenantUsages['billed_sub_tenant_usage_w'],
        billedSubTenantUsageB:
            billedSubTenantUsages['billed_sub_tenant_usage_b'],
        billedSubTenantUsageN:
            billedSubTenantUsages['billed_sub_tenant_usage_n'],
        billedSubTenantUsageG:
            billedSubTenantUsages['billed_sub_tenant_usage_g'],
        billedManualUsageE: billedManualUsages['manual_usage_e'],
        billedManualUsageW: billedManualUsages['manual_usage_w'],
        billedManualUsageB: billedManualUsages['manual_usage_b'],
        billedManualUsageN: billedManualUsages['manual_usage_n'],
        billedManualUsageG: billedManualUsages['manual_usage_g'],
        billedUsageFactorE: billedUsageFactorInfo['billed_usage_factor_e'],
        billedUsageFactorW: billedUsageFactorInfo['billed_usage_factor_w'],
        billedUsageFactorB: billedUsageFactorInfo['billed_usage_factor_b'],
        billedUsageFactorN: billedUsageFactorInfo['billed_usage_factor_n'],
        billedUsageFactorG: billedUsageFactorInfo['billed_usage_factor_g'],
        billedRateE: billedRateInfo['billed_rate_e'],
        billedRateW: billedRateInfo['billed_rate_w'],
        billedRateB: billedRateInfo['billed_rate_b'],
        billedRateN: billedRateInfo['billed_rate_n'],
        billedRateG: billedRateInfo['billed_rate_g'],
        billedGst: billedGst,
        billedGstAmount: billedGstAmount,
        lineItemList: [], //lineItemList,
        billedTrendingSnapShot: billedTrendingSnapShot,
        billBarFromMonth: billBarFromMonth,
      );
      emsTypeUsageCalcRl.doSingularCalc();
      singularUsageCalcList.add(emsTypeUsageCalcRl);

      singularUsage['usage_calc'] = emsTypeUsageCalcRl;
    }

    // double balBf = double.tryParse(balBfStr) ?? 0.0;
    // double balBfUsage = double.tryParse(balBfUsageStr) ?? 0.0;
    // double balBfInterest = double.tryParse(balBfInterestStr) ?? 0.0;

    PagEmsTypeUsageCalcRl compositeUsageCalcRl = PagEmsTypeUsageCalcRl(
      costDecimals: widget.costDecimals,
      billedGst: 9.0,
      billedRateE: _bill['billed_rate_e'],
      billedRateW: _bill['billed_rate_w'],
      billedRateB: _bill['billed_rate_b'],
      billedRateN: _bill['billed_rate_n'],
      billedRateG: _bill['billed_rate_g'],
      billedAutoUsageE: _bill['billed_auto_usage_e'],
      billedAutoUsageW: _bill['billed_auto_usage_w'],
      billedAutoUsageB: _bill['billed_auto_usage_b'],
      billedAutoUsageN: _bill['billed_auto_usage_n'],
      billedAutoUsageG: _bill['billed_auto_usage_g'],
      billedSubTenantUsageE: _bill['billed_sub_tenant_usage_e'],
      billedSubTenantUsageW: _bill['billed_sub_tenant_usage_w'],
      billedSubTenantUsageB: _bill['billed_sub_tenant_usage_b'],
      billedSubTenantUsageN: _bill['billed_sub_tenant_usage_n'],
      billedSubTenantUsageG: _bill['billed_sub_tenant_usage_g'],
      billedManualUsageE: _bill['manual_usage_e'],
      billedManualUsageW: _bill['manual_usage_w'],
      billedManualUsageB: _bill['manual_usage_b'],
      billedManualUsageN: _bill['manual_usage_n'],
      billedManualUsageG: _bill['manual_usage_g'],
      billedUsageFactorE: _bill['billed_usage_factor_e'],
      billedUsageFactorW: _bill['billed_usage_factor_w'],
      billedUsageFactorB: _bill['billed_usage_factor_b'],
      billedUsageFactorN: _bill['billed_usage_factor_n'],
      billedUsageFactorG: _bill['billed_usage_factor_g'],
      billedTrendingSnapShot: _bill['billed_trending_snapshot'] ?? [],
      billedGstAmount: billedGstAmount,
      lineItemList: lineItemList,
      billBarFromMonth: billBarFromMonth,
      singularUsageCalcList: singularUsageCalcList,
      miniSoaInfo: miniSoaInfo,
      interestInfo: interestInfo,
    );
    compositeUsageCalcRl.doCompositeCalc();

    return _renderMode == 'pdf'
        ? WgtPagBillRenderPdf(
            billingInfo: {
              'customerName': tenantName,
              'customerAccountId': accountId,
              'customerLabel': tenantLabel,
              'customerType': tenantType,
              'depositAmountStr': depositAmountStr,
              'paymentMethod': paymentMethod,
              'tenantBillingAddressLine1': tenantBillingAddressLine1,
              'tenantBillingAddressLine2': tenantBillingAddressLine2,
              'tenantBillingAddressLine3': tenantBillingAddressLine3,
              'gst': compositeUsageCalcRl.billedGst,
              'billedGstAmount': compositeUsageCalcRl.billedGstAmount,
              'billingRecName': _bill['billing_rec_name'],
              'billLabel': _bill['bill_label'],
              'billFrom': fromDatetime.toIso8601String(),
              'billTo': toDatetime.toIso8601String(),
              'effectiveTo': effectiveToDatetime?.toIso8601String(),
              'tenantLcs': tenantLcs,
              'billDate': _bill['released_bill_timestamp'] ??
                  _bill['created_timestamp'],
              'dueDate': _bill['billed_due_date_timestamp'] ?? '',
              'billTimeRangeStr': billTimeRangeStr,
              'tenantUsageSummary': const [],
              'totalUsageCost': compositeUsageCalcRl.totalUsageCost,
              'subTotalAmount': compositeUsageCalcRl.subTotalCost,
              'gstAmount': compositeUsageCalcRl.billedGstAmount,
              'totalAmount': compositeUsageCalcRl.totalCost,
              'payableAmount': compositeUsageCalcRl.payableAmount,
              'miniSoaInfo': compositeUsageCalcRl.miniSoaInfo,
              'typeRateE': compositeUsageCalcRl.typeUsageE?.rate,
              'typeRateW': compositeUsageCalcRl.typeUsageW?.rate,
              'typeRateB': compositeUsageCalcRl.typeUsageB?.rate,
              'typeRateN': compositeUsageCalcRl.typeUsageN?.rate,
              'typeRateG': compositeUsageCalcRl.typeUsageG?.rate,
              'typeUsageE': compositeUsageCalcRl.typeUsageE?.usageFactored,
              'typeUsageW': compositeUsageCalcRl.typeUsageW?.usageFactored,
              'typeUsageB': compositeUsageCalcRl.typeUsageB?.usageFactored,
              'typeUsageN': compositeUsageCalcRl.typeUsageN?.usageFactored,
              'typeUsageG': compositeUsageCalcRl.typeUsageG?.usageFactored,
              'typeCostE': compositeUsageCalcRl.typeUsageE?.cost,
              'typeCostW': compositeUsageCalcRl.typeUsageW?.cost,
              'typeCostB': compositeUsageCalcRl.typeUsageB?.cost,
              'typeCostN': compositeUsageCalcRl.typeUsageN?.cost,
              'typeCostG': compositeUsageCalcRl.typeUsageG?.cost,
              'trendingE': compositeUsageCalcRl.trendingE,
              'trendingW': compositeUsageCalcRl.trendingW,
              'trendingB': compositeUsageCalcRl.trendingB,
              'trendingN': compositeUsageCalcRl.trendingN,
              'trendingG': compositeUsageCalcRl.trendingG,
              'interestInfo': interestInfo,
              'lineItemLabel1': compositeUsageCalcRl.getLineItem(0)?['label'],
              'lineItemValue1': compositeUsageCalcRl.getLineItem(0)?['amount'],
              'lineItemLabel2': compositeUsageCalcRl.getLineItem(1)?['label'],
              'lineItemValue2': compositeUsageCalcRl.getLineItem(1)?['amount'],
              'assetFolder': assetFolder,
              'tenantSingularUsageInfoList': singularUsageList,
              'billedAmgrCompanyTradingName': billedAmgrCompanyTradingName,
              'billedAmgrCompanyRegNumber': billedAmgrCompanyRegNumber,
              'billedAmgrGstRegNumber': billedAmgrGstRegNumber,
              'amgrAddressLine1': amgrAddressLine1,
              'amgrAddressLine2': amgrAddressLine2,
              'amgrAddressLine3': amgrAddressLine3,
              'billedTptNote': billedTptNote,
            },
          )
        : WgtPagTenantCompositeUsageSummaryRl(
            isDisabled: _isDisabledPvRl,
            costDecimals: widget.costDecimals,
            appConfig: widget.appConfig,
            loggedInUser: widget.loggedInUser,
            displayContextStr: widget.displayContextStr,
            isBillMode: widget.isBillMode,
            billInfo: _bill,
            // usageCalc: compositeUsageCalc,
            showRenderModeSwitch: true,
            itemType: ItemType.meter_iwow,
            isMonthly: isMonthly,
            // cycleStr: cycleStr,
            // billDate: billDate,
            tenantLcs: tenantLcs,
            fromDatetime: fromDatetime,
            toDatetime: toDatetime,
            effectiveToDatetime: effectiveToDatetime,
            tenantName: tenantName,
            tenantLabel: tenantLabel,
            tenantAccountId: accountId,
            tenantType: tenantType,
            // billedAutoUsages: billedAutoUsages,
            // billedSubTenantUsages: billedSubTenantUsages,
            // billedUsageFactor: billedUsageFactors,
            // manualUsages: billedManualUsages,
            lineItems: lineItemList,
            // meterTypeRates: billedRates,
            tenantSingularUsageInfoList: singularUsageList,
            compositeUsageCalc: compositeUsageCalcRl,
            previousCollectionDateTimestampStr:
                previousCollectionDateTimestampStr,
            currentCollectionDateTimestampStr:
                currentCollectionDateTimestampStr,
            excludeAutoUsage:
                _bill['exclude_auto_usage'] == 'true' ? true : false,
            gst: compositeUsageCalcRl.billedGst,
            interestInfo: interestInfo,
            onUpdate: () {
              widget.onUpdate?.call();
              setState(() {
                // _lcStatusDisplay = _bill['lc_status'];
              });
            },
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
                    if (_renderMode == 'pdf') {
                      _showGenTypeSwitch = false;
                    } else {
                      _showGenTypeSwitch = true;
                    }
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
          value: _billLcStatusDisplay == PagBillingLcStatus.released ||
                  _billLcStatusDisplay == PagBillingLcStatus.pv
              ? true
              : false,
          onChanged: _gettingBill
              ? null
              : (value) {
                  setState(() {
                    _isSwitching = true;
                    _lcStatusOpsKey = UniqueKey();
                    value
                        ? _billLcStatusDisplay = PagBillingLcStatus.released
                        : _billLcStatusDisplay = PagBillingLcStatus.generated;
                    if (_billLcStatusDisplay == PagBillingLcStatus.generated) {
                      _showRenderModeSwitch = false;
                    } else {
                      _showRenderModeSwitch = true;
                    }
                    _bill.clear();
                  });
                },
        ),
        const Text('View in Rl Mode'),
      ],
    );
  }
}
