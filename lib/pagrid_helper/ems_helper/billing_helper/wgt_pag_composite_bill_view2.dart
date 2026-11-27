import 'dart:async';
import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_item_delete_op.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/cw_bill/pag_gen_pdf_bill_cw2.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:material_ui/material_ui.dart';

import '../../../pag_helper/def_helper/dh_device.dart';
import '../../../pag_helper/def_helper/dh_list.dart';
import '../../../pag_helper/def_helper/dh_pag_item.dart';
import '../../../pag_helper/model/mdl_pag_project_profile.dart';
import '../tenant/pag_ems_type_usage_calc2.dart';
import '../../../pag_helper/wgt/app/ems/wgt_bill_lc_status_op2.dart';
import '../tenant/wgt_pag_tenant_composite_usage_summary.dart';
import '../../../pag_helper/comm/comm_pag_billing2.dart';
import '../tenant/wgt_pag_tenant_composite_usage_summary_rl.dart';
import '../../../pag_helper/model/acl/mdl_pag_svc_claim.dart';
import '../../../pag_helper/def_helper/dh_pag_bill.dart';
import 'billing_helper2.dart';
import 'wgt_pag_invoice_details.dart';
import 'wgt_pag_render_pdf.dart';

double? _billFieldToDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return value == null ? null : double.tryParse(value.toString());
}

class WgtPagCompositeBillView2 extends StatefulWidget {
  const WgtPagCompositeBillView2({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.billingRecIndexStr,
    required this.defaultBillLcStatusStr,
    required this.listContextType,
    this.displayContextStr = 'bill_view',
    this.isBillMode = true,
    this.costDecimals = 3,
    this.modes = const ['wgt', 'pdf'],
    this.genTypes = const ['generated', 'released'],
    this.onUpdate,
  });

  final MdlPagUser loggedInUser;
  final MdlPagAppConfig appConfig;
  final PagListContextType listContextType;
  final bool isBillMode;
  final String displayContextStr;
  final String billingRecIndexStr;
  final int costDecimals;
  final List<String> modes;
  final List<String> genTypes;
  final String defaultBillLcStatusStr;
  final Function? onUpdate;

  @override
  State<WgtPagCompositeBillView2> createState() =>
      _WgtPagCompositeBillView2State();
}

class _WgtPagCompositeBillView2State extends State<WgtPagCompositeBillView2> {
  final defaultErrorText = 'Error getting bill';

  bool _gettingBill = false;
  bool _billLoadFailed = false;

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
  bool _isDisabledPvRl = false;

  bool _isDeleting = false;
  String _deleteResultText = '';

  Future<void> _getCompositeBill() async {
    setState(() {
      _gettingBill = true;
      _billLoadFailed = false;
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
      final billResult = await getPagCompositeBill2(
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
      if (!mounted) return;
      setState(() {
        _bill.addAll(billResult);
        _gettingBill = false;
      });
    } catch (err) {
      dev.log('Error loading bill: $err');
      if (!mounted) return;
      setState(() {
        _billLoadFailed = true;
        _gettingBill = false;
      });
      showInfoDialog(
        context,
        'Error',
        getErrorText(err, defaultErrorText: defaultErrorText),
      );
    }
  }

  @override
  void initState() {
    super.initState();

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

    if (widget.listContextType == PagListContextType.infoTp) {
      _showGenTypeSwitch = false;
      _showRenderModeSwitch = false;
      _renderMode = 'pdf';
    }

    MdlPagProjectProfile selectedProjectProfile =
        widget.loggedInUser.selectedScope.projectProfile!;
    assetFolder = selectedProjectProfile.assetFolder!;
    unawaited(_getCompositeBill());
  }

  @override
  Widget build(BuildContext context) {
    if (_billLoadFailed) {
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

    bool enableEditLcStatus = widget.displayContextStr == 'bill_view';
    if (widget.loggedInUser.selectedRole?.name.contains('project-ops-') ??
        false) {
      enableEditLcStatus = false;
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
                        if (_billLcStatusDisplay == PagBillingLcStatus.mfd &&
                            widget.listContextType != PagListContextType.infoTp)
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
                        if (widget.listContextType != PagListContextType.infoTp)
                          WgtPagBillLcStatusOp2(
                            key: _lcStatusOpsKey,
                            appConfig: widget.appConfig,
                            loggedInUser: widget.loggedInUser,
                            enableEdit: enableEditLcStatus && !_gettingBill,
                            billInfo: _bill,
                            initialStatus: _billLcStatusActual,
                            onCommitted: (newStatus) {
                              setState(() {
                                _lcStatusOpsKey = UniqueKey();
                                _isDisabledPvRl =
                                    newStatus == PagBillingLcStatus.generated;
                                _billLcStatusActual = newStatus;
                                final canShowReleased =
                                    newStatus == PagBillingLcStatus.pv ||
                                    newStatus == PagBillingLcStatus.released;
                                if (!canShowReleased) {
                                  _billLcStatusDisplay = newStatus;
                                  _renderMode = 'wgt';
                                }
                                _showGenTypeSwitch =
                                    canShowReleased && _renderMode != 'pdf';
                                _showRenderModeSwitch = canShowReleased &&
                                    _billLcStatusDisplay ==
                                        PagBillingLcStatus.released;
                              });
                              // The server may just have frozen or unfrozen
                              // invoice values, so discard the previous payload.
                              unawaited(_getCompositeBill());
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
            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).hintColor.withAlpha(130),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: _gettingBill
                    ? SizedBox(
                        height: 200,
                        child: Center(
                          child: xtWait(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    : completedWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _showInvoiceDetails =>
      _bill['gen_type'] != 'initial_balance' &&
      (_bill['lc_status'] == PagBillingLcStatus.generated.value ||
          _bill['lc_status'] == PagBillingLcStatus.pv.value ||
          _bill['lc_status'] == PagBillingLcStatus.released.value);

  Widget? get _totalsFooter => widget.isBillMode && _showInvoiceDetails
      ? WgtPagInvoiceDetails(billInfo: _bill)
      : null;

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
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            child: Column(
              children: [
                getBillRender(),
                if (_showInvoiceDetails &&
                    (_renderMode == 'pdf' || !widget.isBillMode)) ...[
                  const Divider(height: 24),
                  WgtPagInvoiceDetails(billInfo: _bill),
                ],
              ],
            ),
          );
  }

  Widget getBillRender() {
    String? genType = _bill['gen_type'];
    String tenantName = _bill['tenant_name'];
    String tenantLabel = _bill['tenant_label'];
    String tenantAccountNumber = _bill['tenant_account_number'] ?? '';
    String tenantType = _bill['tenant_type'] ?? '';
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

    // final billedGstStr = _bill['billed_gst'] ?? '';
    // double? billedGst = double.tryParse(billedGstStr);

    // final billedGstAmount = _bill['billed_gst_amount'] ?? '';
    // double billedGstAmountDouble = 0.0;
    // if (billedGstAmount is String) {
    //   billedGstAmountDouble = double.tryParse(billedGstAmount) ?? 0.0;
    // } else if (billedGstAmount is num) {
    //   billedGstAmountDouble = billedGstAmount.toDouble();
    // }

    // final billedUsageCostAmountStr = _bill['billed_usage_cost_amount'] ?? '';
    // double? billedUsageCostAmount =
    //     double.tryParse(billedUsageCostAmountStr) ?? 0.0;

    // final billedInterestAmountStr = _bill['billed_interest_amount'] ?? '';
    // double? billedInterestAmount =
    //     double.tryParse(billedInterestAmountStr) ?? 0.0;

    // final billedPrincipalAmountStr = _bill['billed_principal_amount'] ?? '';
    // double? billedPrincipalAmount =
    //     double.tryParse(billedPrincipalAmountStr) ?? 0.0;

    // final billedCycleTotalAmountStr = _bill['billed_cycle_total_amount'] ?? '';
    // double? billedCycleTotalAmount =
    //     double.tryParse(billedCycleTotalAmountStr) ?? 0.0;

    // final billedPayableAmountStr = _bill['billed_payable_amount'] ?? '';
    // double? billedPayableAmount =
    // double.tryParse(billedPayableAmountStr) ?? 0.0;

    // String strBilledUsageCostAmount = _bill['billed_usage_cost_amount'] ?? '';
    // String strBilledInterestAmount = _bill['billed_interest_amount'] ?? '';
    // String strBilledPayableAmount = _bill['billed_payable_amount'] ?? '';

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

    final billedBciInfo = _bill['billed_bci_info'] ?? {};
    List<Map<String, dynamic>> effBciInfoList = [];
    if (billedBciInfo['effective_bci_info_list'] != null) {
      effBciInfoList = List<Map<String, dynamic>>.from(
          billedBciInfo['effective_bci_info_list']);
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

    if (_billLcStatusDisplay == PagBillingLcStatus.released) {
      return getReleaseRender2(_bill);
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
          interestInfo,
          effBciInfoList);
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
    List<Map<String, dynamic>>? effBciInfoList,
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

    List<Map<String, dynamic>> singularUsageList = [];
    if (_bill['singular_billing_rec_list'] != null) {
      for (var singularUsage in _bill['singular_billing_rec_list']) {
        singularUsageList.add(singularUsage);
      }
    }
    String billedGstStr = _bill['billed_gst'] ?? '';
    double? billedGst = double.tryParse(billedGstStr);

    List<PagEmsTypeUsageCalc2> singularUsageCalcList = [];
    for (Map<String, dynamic> singularUsage in singularUsageList) {
      final meterType =
          singularUsage['meter_type']?.toString().trim().toUpperCase() ?? '';
      if (meterType.isEmpty) {
        continue;
      }

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
      // Sort the one rate carried by this Gen3 singular billing record.
      final meterTypeRateInfo = singularUsage['meter_type_rate_info'];
      double? rate;
      double? gst;
      final rateResult = meterTypeRateInfo?[meterType]?['result'];
      if (rateResult != null) {
        rate = _billFieldToDouble(rateResult['rate']);
        gst = _billFieldToDouble(rateResult['gst']);
      }
      if (gst == null) {
        throw Exception('gst is null for meter type $meterType');
      }

      List<Map<String, dynamic>> manualUsageList = [];
      final manualUsage = _billFieldToDouble(singularUsage['manual_usage']);
      if (manualUsage != null) {
        manualUsageList.add({
          'meter_type': meterType,
          'usage': manualUsage,
        });
      }

      PagEmsTypeUsageCalc2 emsTypeUsageCalc = PagEmsTypeUsageCalc2(
        costDecimals: widget.costDecimals,
        meterType: meterType,
        rate: rate,
        gst: gst,
        autoUsageSummary: autoUsageSummary ?? {},
        manualUsageList: manualUsageList,
        lineItemList: lineItemList,
        billBarFromMonth: billBarFromMonth,
      );
      emsTypeUsageCalc.doSingularCalc();

      singularUsageCalcList.add(emsTypeUsageCalc);

      singularUsage['usage_calc2'] = emsTypeUsageCalc;
    }

    PagEmsTypeUsageCalc2 compositeUsageCalc = PagEmsTypeUsageCalc2(
      costDecimals: widget.costDecimals,
      gst: billedGst,
      lineItemList: lineItemList,
      billBarFromMonth: billBarFromMonth,
      singularUsageCalcList: singularUsageCalcList,
      miniSoaInfo: miniSoaInfo,
      interestInfo: interestInfo,
      effBciInfoList: effBciInfoList,
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
            costDecimals: widget.costDecimals,
            appConfig: widget.appConfig,
            loggedInUser: widget.loggedInUser,
            displayContextStr: widget.displayContextStr,
            tenantSingularUsageInfoList: singularUsageList,
            compositeUsageCalc2: compositeUsageCalc,
            strCollectionStartDateTimestamp: strCollectionStartDateTimestamp,
            strCollectionEndDateTimestamp: strCollectionEndDateTimestamp,
            isBillMode: widget.isBillMode,
            totalsFooter: _totalsFooter,
            billInfo: _bill,
            useMeterMultiplierFactor: true,
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
            bciInfoList: effBciInfoList ?? [],
            interestInfo: interestInfo!,
            onUpdate: () {
              widget.onUpdate?.call();
              setState(() {
                // _lcStatusDisplay = _bill['lc_status'];
              });
            },
          );
  }

  Widget getReleaseRender2(Map<String, dynamic> billInfo) {
    final calcedBillInfoRl = prepCalcedBillInfoRl2(billInfo);

    return _renderMode == 'pdf'
        ? WgtPagRenderPdf(
            loggedInUser: widget.loggedInUser,
            builder: generatePagInvoice2,
            itemInfo: calcedBillInfoRl,
          )
        : WgtPagTenantCompositeUsageSummaryRl(
            isDisabled: _isDisabledPvRl,
            costDecimals: widget.costDecimals,
            appConfig: widget.appConfig,
            loggedInUser: widget.loggedInUser,
            displayContextStr: widget.displayContextStr,
            isBillMode: widget.isBillMode,
            totalsFooter: _totalsFooter,
            billInfo: _bill,
            showRenderModeSwitch: true,
            itemType: PagDeviceCat.meter,
            isMonthly: true,
            tenantLcs: calcedBillInfoRl['tenantLcs'] ?? '',
            fromDatetime: DateTime.parse(calcedBillInfoRl['strFrom']),
            toDatetime: DateTime.parse(calcedBillInfoRl['strTo']),
            effectiveToDatetime:
                DateTime.tryParse(calcedBillInfoRl['strEffectiveTo']),
            tenantName: calcedBillInfoRl['customerName'] ?? '',
            tenantLabel: calcedBillInfoRl['customerLabel'] ?? '',
            tenantAccountId: calcedBillInfoRl['tenantAccountNumber'] ?? '',
            tenantType: calcedBillInfoRl['tenantType'] ?? '',
            lineItems: calcedBillInfoRl['lineItemList'] ?? [],
            billedBciInfoList: calcedBillInfoRl['billedBciInfoList'] ?? [],
            tenantSingularUsageInfoList:
                calcedBillInfoRl['singularUsageList'] ?? [],
            compositeUsageCalcRl2: calcedBillInfoRl['compositeUsageCalc'],
            collectionStartDateTimestampStr:
                calcedBillInfoRl['strCollectionStartDate'],
            collectionEndDateTimestampStr:
                calcedBillInfoRl['strCollectionEndDate'],
            excludeAutoUsage:
                _bill['exclude_auto_usage'] == 'true' ? true : false,
            gst: calcedBillInfoRl['gst'],
            interestInfo: calcedBillInfoRl['interestInfo'] ?? {},
            onUpdate: () {
              widget.onUpdate?.call();
              setState(() {
                // _lcStatusDisplay = _bill['lc_status'];
              });
            },
          );
  }

  Widget getSwitchRenderMode() {
    String genType = _bill['gen_type'] ?? '';
    if (genType == 'initial_balance') {
      return Container();
    }
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
    String genType = _bill['gen_type'] ?? '';
    if (genType == 'initial_balance') {
      return Container();
    }
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
                    _lcStatusOpsKey = UniqueKey();
                    _billLcStatusDisplay = value
                        ? PagBillingLcStatus.released
                        : PagBillingLcStatus.generated;
                    _showRenderModeSwitch = value;
                  });
                  unawaited(_getCompositeBill());
                },
        ),
        const Text('View in Rl Mode'),
      ],
    );
  }
}
