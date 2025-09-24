import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/pag_bill_def.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:developer' as dev;

import '../../../../pagrid_helper/ems_helper/billing_helper/wgt_pag_composite_bill_view.dart';
import '../../../../xt_ui/wdgt/info/get_error_text_prompt.dart';
import '../../../../xt_ui/wdgt/wgt_pag_wait.dart';
import '../../../comm/comm_fin_ops.dart';
import '../../../def_helper/dh_pag_finance_type.dart';
import 'wgt_payment_lc_status_op.dart';

class WgtMatchOnePayment2 extends StatefulWidget {
  const WgtMatchOnePayment2({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.tenantInfo,
    required this.defaultPaymentLcStatusStr,
    this.paymentMatchingInfo,
    this.onUpdate,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Map<String, dynamic> tenantInfo;
  final Map<String, dynamic>? paymentMatchingInfo;
  final String defaultPaymentLcStatusStr;
  final Function? onUpdate;

  @override
  State<WgtMatchOnePayment2> createState() => _WgtMatchOnePayment2State();
}

class _WgtMatchOnePayment2State extends State<WgtMatchOnePayment2> {
  late final TextStyle mainLabelStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Theme.of(context).hintColor,
  );
  late final TextStyle mainTextStyle = const TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
  );

  late final TextStyle billLabelStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
    // color: Theme.of(context).colorScheme.primary,
  );
  late final TextStyle billKeyStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Theme.of(context).hintColor,
  );

  late final String tenantName = widget.tenantInfo['tenant_name'];

  bool _isFetchingBillList = false;
  bool _billListFetchTried = false;
  String _errorText = '';

  final List<Map<String, dynamic>> _billList = [];
  late PagPaymentLcStatus _lcStatusDisplay;
  UniqueKey? _lcStatusOpsKey;
  late final Map<String, dynamic> _paymentInfo =
      widget.paymentMatchingInfo ?? {};
  late final double? _paymentAmount =
      double.tryParse(_paymentInfo['amount'] ?? '');

  // info from payment_billing_rec mapping
  final List<Map<String, dynamic>> _paymentApplyInfoListExisting = [];
  final List<Map<String, dynamic>> _paymentApplyInfoListNew = [];

  double? _availableAmountToApply;

  Future<void> _fetchBillList() async {
    if (_isFetchingBillList || _billListFetchTried) return;

    _isFetchingBillList = true;
    _errorText = '';

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'item_kind': PagItemKind.bill.name,
      't.name': tenantName,
      'sort_by': 'from_timestamp',
      'sort_order': 'DESC',
    };

    try {
      final result = await fetchItemList(
          widget.loggedInUser,
          widget.appConfig,
          queryMap,
          MdlPagSvcClaim(
            userId: widget.loggedInUser.id,
            username: widget.loggedInUser.username,
            scope: '',
            target: '',
            operation: '',
          ));
      final itemList = result['item_list'] ?? [];
      _billList.clear();
      _billList.addAll(itemList);
    } catch (e) {
      dev.log('Error fetching bill list: $e');
      _errorText = 'Failed to fetch bills';
    } finally {
      setState(() {
        _isFetchingBillList = false;
        _billListFetchTried = true;
      });
    }
  }

  Future<void> _fetchPaymentMatchOpInfo() async {
    if (_isFetchingBillList || _billListFetchTried) return;

    _isFetchingBillList = true;
    _errorText = '';

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'item_kind': PagItemKind.bill.name,
      't.name': tenantName,
      'payment_id': _paymentInfo['id'] ?? '',
    };

    try {
      final result = await fetchPaymentMatchOpInfo(
          widget.appConfig,
          queryMap,
          MdlPagSvcClaim(
            userId: widget.loggedInUser.id,
            username: widget.loggedInUser.username,
            scope: '',
            target: '',
            operation: '',
          ));
      final itemList = result['bill_list'] ?? [];
      // final itemList = result['item_list'] ?? [];
      _billList.clear();
      // _billList.addAll(itemList);
      for (var item in itemList) {
        Map<String, dynamic> billItem = item;
        _billList.add(billItem);
      }
      final paymentApplyInfoList = result['payment_apply_info_list'] ?? {};

      // double paymentAmount =  double.tryParse(_paymentInfo['amount'] ?? '0.0') ?? 0.0;
      _availableAmountToApply = _paymentAmount;
      for (var item in paymentApplyInfoList) {
        _paymentApplyInfoListExisting.add(item);
        final appliedAmountUsage =
            double.tryParse(item['applied_usage_amount'] ?? '0.0') ?? 0.0;
        final appliedAmountInterest =
            double.tryParse(item['applied_interest_amount'] ?? '0.0') ?? 0.0;
        double totalApplied = appliedAmountUsage + appliedAmountInterest;

        _availableAmountToApply = _availableAmountToApply! - totalApplied;
      }
    } catch (e) {
      dev.log('Error fetching bill list: $e');
      _errorText = 'Failed to fetch bills';
    } finally {
      setState(() {
        _isFetchingBillList = false;
        _billListFetchTried = true;
      });
    }
  }

  void _populateApply() {
    if (_availableAmountToApply == null || _availableAmountToApply! <= 0.0) {
      return;
    }
    if (_billList.isEmpty) {
      return;
    }

    double remainingAmount = _availableAmountToApply!;
    _paymentApplyInfoListNew.clear();

    // rule 1: pay oldest bill first
    // rule 2: pay interest first, then usage
    final billList = [];
    billList.addAll(_billList);
    billList.sort((a, b) {
      final aTimestamp = a['from_timestamp'] ?? '';
      final bTimestamp = b['from_timestamp'] ?? '';
      return aTimestamp.compareTo(bTimestamp);
    });

    for (var bill in billList) {
      if (remainingAmount <= 0.0) {
        break;
      }
      final billingRecId = bill['id'] ?? '';
      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }
      final billedInterestAmount =
          double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
      final billedUsageAmount = billedTotalCost - billedInterestAmount;

      double appliedInterest = 0.0;
      double appliedUsage = 0.0;
      if (billedInterestAmount > 0.0) {
        if (remainingAmount >= billedInterestAmount) {
          appliedInterest = billedInterestAmount;
          remainingAmount -= billedInterestAmount;
        } else {
          appliedInterest = remainingAmount;
          remainingAmount = 0.0;
        }
      }
      if (billedUsageAmount > 0.0) {
        if (remainingAmount >= billedUsageAmount) {
          appliedUsage = billedUsageAmount;
          remainingAmount -= billedUsageAmount;
        } else {
          appliedUsage = remainingAmount;
          remainingAmount = 0.0;
        }
      }
      if (appliedInterest > 0.0 || appliedUsage > 0.0) {
        _paymentApplyInfoListNew.add({
          'billing_rec_id': billingRecId,
          'applied_interest_amount': appliedInterest.toStringAsFixed(2),
          'applied_usage_amount': appliedUsage.toStringAsFixed(2),
        });
      }
      if (remainingAmount <= 0.0) {
        break;
      }

      dev.log(
          'Bill $billingRecId: applied interest $appliedInterest, usage $appliedUsage');
    }

    setState(() {
      _availableAmountToApply = remainingAmount;
    });
  }

  @override
  void initState() {
    super.initState();
    _lcStatusDisplay =
        PagPaymentLcStatus.byValue(widget.defaultPaymentLcStatusStr);
  }

  @override
  Widget build(BuildContext context) {
    bool fetchingBillList = _billList.isEmpty && !_billListFetchTried;

    final tenantLabel = widget.tenantInfo['tenant_label'] ?? '';

    bool showPaymentLcStatusOp = false;
    final lcStatusStr = widget.paymentMatchingInfo?['lc_status'] ?? '';
    PagPaymentLcStatus lcStatus = PagPaymentLcStatus.byValue(lcStatusStr);

    bool hasMatchedBill = false;
    for (var bill in _billList) {
      if (widget.paymentMatchingInfo != null &&
          widget.paymentMatchingInfo!['matched_payment_info'] != null &&
          widget.paymentMatchingInfo!['matched_payment_info']
                  ['billing_rec_id'] ==
              bill['id']) {
        hasMatchedBill = true;
        break;
      }
    }
    if (hasMatchedBill) {
      showPaymentLcStatusOp = true;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PagItemKind.tenant.iconData),
                  Text(' $tenantLabel', style: billLabelStyle),
                  Icon(Symbols.chevron_forward,
                      color: Theme.of(context).hintColor),
                  Text('Payment: ', style: mainLabelStyle),
                  Text(
                      _paymentAmount != null
                          ? _paymentAmount.toStringAsFixed(2)
                          : '-',
                      style: mainTextStyle),
                  horizontalSpaceSmall,
                  // Text('Matched at: ', style: mainLabelStyle),
                  // Text(
                  //     widget.paymentMatchingInfo?['matched_payment_info']
                  //                 ?['value_timestamp']
                  //             .toString()
                  //             .split(' ')
                  //             .first ??
                  //         '',
                  //     style: mainTextStyle),
                  // horizontalSpaceSmall,
                  Text('Available: ',
                      style: billKeyStyle.copyWith(fontSize: 16)),
                  Text(
                      _availableAmountToApply != null
                          ? _availableAmountToApply!.toStringAsFixed(2)
                          : '0.00',
                      style: mainTextStyle.copyWith(fontSize: 24)),
                  horizontalSpaceSmall,
                  getPopulateApply(),
                  getCommitApply(),
                  const Spacer(),
                  if (hasMatchedBill)
                    WgtPagPaymentLcStatusOp(
                      key: _lcStatusOpsKey,
                      appConfig: widget.appConfig,
                      loggedInUser: widget.loggedInUser,
                      enableEdit: true,
                      paymentInfo: widget.paymentMatchingInfo ?? {},
                      initialStatus: _lcStatusDisplay,
                      onCommitted: (newStatus) {
                        setState(() {
                          _lcStatusOpsKey = UniqueKey();
                          // _bill['lc_status'] = newStatus.value;
                          _paymentInfo['lc_status'] = newStatus.value;

                          // _isDisabledGn = newStatus == PagBillingLcStatus.pv ||
                          //     newStatus == PagBillingLcStatus.released;
                          _lcStatusDisplay = newStatus;
                        });
                        dev.log('on committed: $newStatus');
                        widget.onUpdate?.call();
                      },
                    ),
                  const Padding(padding: EdgeInsets.only(right: 60)),
                ]),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Symbols.close))
              ],
            ),
          ],
        ),
        fetchingBillList
            ? FutureBuilder(
                // future: _fetchBillList(),
                future: _fetchPaymentMatchOpInfo(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return const WgtPagWait();
                    default:
                      if (snapshot.hasError) {
                        return getErrorTextPrompt(
                          context: context,
                          errorText: 'Error fetching data',
                        );
                      } else {
                        return completedWidget();
                      }
                  }
                },
              )
            : completedWidget(),
      ],
    );
  }

  Widget completedWidget() {
    return SizedBox(
      height: 500,
      child: ListView.builder(
        itemCount: _billList.length,
        itemBuilder: (context, index) {
          return getListItem(index);
        },
      ),
    );
  }

  Widget getListItem(int index) {
    if (index < 0 || index >= _billList.length) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: getBillItem(index),
    );
  }

  Widget getApplyOp(
      bool isMatchedBill,
      double? availableAmountToApply,
      double? appliedAmountUsage,
      double? appliedAmountInterest,
      String? appliedByOpUsername,
      String? appliedTimestampStr) {
    bool isEnabled = true;
    if (!isMatchedBill) {
      if (availableAmountToApply == null || availableAmountToApply <= 0.0) {
        isEnabled = false;
      }
    }

    if (_lcStatusDisplay == PagPaymentLcStatus.released) {
      isEnabled = false;
    }

    final initialValueUsage =
        isMatchedBill ? appliedAmountUsage?.toString() : null;
    final initialValueInterest =
        isMatchedBill ? appliedAmountInterest?.toString() : null;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: isEnabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor.withAlpha(130)),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 95,
                child: WgtTextField(
                  key: UniqueKey(),
                  appConfig: widget.appConfig,
                  loggedInUser: widget.loggedInUser,
                  hintText: 'Usage',
                  labelText: 'Usage',
                  enabled: isEnabled,
                  initialValue: initialValueUsage,
                  onChanged: (value) {
                    // setState(() {
                    //   _paymentApply = value;
                    // });
                  },
                ),
              ),
              horizontalSpaceSmall, // interest bucket
              SizedBox(
                width: 95,
                child: WgtTextField(
                  key: UniqueKey(),
                  appConfig: widget.appConfig,
                  loggedInUser: widget.loggedInUser,
                  hintText: 'Interest',
                  labelText: 'Interest',
                  enabled: isEnabled,
                  initialValue: initialValueInterest,
                  onChanged: (value) {
                    // setState(() {
                    //   _paymentApply = value;
                    // });
                  },
                ),
              ),
            ],
          ),
          if (appliedTimestampStr != null && appliedByOpUsername != null) ...[
            const SizedBox(height: 5),
            Text('Applied by $appliedByOpUsername at $appliedTimestampStr',
                style: billKeyStyle.copyWith(fontSize: 12)),
          ]
        ],
      ),
    );
  }

  Widget getBillItem(int index) {
    Map<String, dynamic> billInfo = _billList[index];
    final billingRecId = billInfo['id'] ?? '';
    final billLabel = billInfo['label'] ?? '';
    final cycleStr = billInfo['cycle_str'] ?? '';
    final billedTotalCost = billInfo['billed_total_cost'] ?? '';
    final billingLcStatusStr = billInfo['lc_status'] ?? '';
    final usageAmount =
        double.tryParse(billInfo['billed_total_cost'] ?? '0.0') ?? 0.0;
    final interestAmount =
        double.tryParse(billInfo['billed_interest_amount'] ?? '0.0') ?? 0.0;
    final totalAmount = usageAmount + interestAmount;

    PagBillingLcStatus billLcStatus =
        PagBillingLcStatus.values.byName(billingLcStatusStr);

    bool isMatchedBill = false;
    if (widget.paymentMatchingInfo != null) {
      isMatchedBill = widget.paymentMatchingInfo!['matched_payment_info']
              ?['billing_rec_id'] ==
          billingRecId;
    }

    double? availableAmountToApply;
    double? appliedAmountUsage;
    double? appliedAmountInterest;
    String? appliedByOpUsername;
    String? appliedTimestampStr;

    final applyInfoList = [];
    applyInfoList.addAll(_paymentApplyInfoListNew);
    if (applyInfoList.isEmpty) {
      applyInfoList.addAll(_paymentApplyInfoListExisting);
    }

    double balanceAmount = totalAmount;
    for (var item in applyInfoList) {
      if (item['billing_rec_id'] == billingRecId) {
        appliedAmountUsage =
            double.tryParse(item['applied_usage_amount'] ?? '0.0') ?? 0.0;
        appliedAmountInterest =
            double.tryParse(item['applied_interest_amount'] ?? '0.0') ?? 0.0;
        appliedByOpUsername = item['applied_by_op_username'];
        appliedTimestampStr = item['applied_timestamp'];
        isMatchedBill = true;
        balanceAmount =
            balanceAmount - (appliedAmountUsage + appliedAmountInterest);
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: isMatchedBill
            ? Border.all(color: commitColor.withAlpha(130), width: 2)
            : Border.all(color: Theme.of(context).hintColor.withAlpha(130)),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 13),
      child: Column(
        children: [
          Row(
            children: [
              getBillLcStatusTagWidget(context, billLcStatus),
              horizontalSpaceSmall,
              InkWell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$billLabel', style: billLabelStyle),
                    Text('$cycleStr', style: billLabelStyle),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _billList[index]['show_bill'] =
                        !(_billList[index]['show_bill'] ?? false);
                  });
                },
              ),
              horizontalSpaceSmall,
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Total: ',
                        style: billKeyStyle,
                      ),
                      Text('$billedTotalCost',
                          style: billLabelStyle.copyWith(fontSize: 34)),
                      horizontalSpaceSmall,
                      Text('Usage: ', style: billKeyStyle),
                      Text(
                        usageAmount.toStringAsFixed(2),
                        style: mainTextStyle.copyWith(fontSize: 24),
                      ),
                      horizontalSpaceSmall,
                      Text('Interest: ', style: billKeyStyle),
                      Text(
                        interestAmount.toStringAsFixed(2),
                        style: mainTextStyle.copyWith(fontSize: 24),
                      ),
                      horizontalSpaceSmall,
                      Text('Balance: ', style: billKeyStyle),
                      Text(
                        balanceAmount.toStringAsFixed(2),
                        style: mainTextStyle.copyWith(fontSize: 24),
                      ),
                      horizontalSpaceSmall,
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // _isApplied ? getAppliedPayment() : getApplyOp(),
              getApplyOp(
                  isMatchedBill,
                  availableAmountToApply,
                  appliedAmountUsage,
                  appliedAmountInterest,
                  appliedByOpUsername,
                  appliedTimestampStr),
              horizontalSpaceSmall,
            ],
          ),
          if (billInfo['show_bill'] ?? false) const Divider(),
          if (billInfo['show_bill'] ?? false)
            WgtPagCompositeBillView(
              costDecimals: 2,
              appConfig: widget.appConfig,
              loggedInUser: widget.loggedInUser,
              displayContextStr: 'match_one_paymment',
              billingRecIndexStr: billingRecId,
              defaultBillLcStatusStr: billingLcStatusStr,
              modes: const ['wgt', 'pdf'],
              genTypes: billLcStatus == PagBillingLcStatus.generated
                  ? ['generated']
                  : ['released'],
            ),
        ],
      ),
    );
  }

  Widget getPopulateApply() {
    if (_lcStatusDisplay == PagPaymentLcStatus.released) {
      return const SizedBox.shrink();
    }
    if (_availableAmountToApply == null || _availableAmountToApply! <= 0.0) {
      return const SizedBox.shrink();
    }
    return InkWell(
      onTap: () {
        _populateApply();
      },
      child: Container(
        decoration: BoxDecoration(
          // border: Border.all(color: Theme.of(context).colorScheme.primary),
          color: Theme.of(context).colorScheme.secondary.withAlpha(210),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        child: Text('Populate Apply',
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
      ),
    );
  }

  Widget getCommitApply() {
    if (_paymentApplyInfoListNew.isEmpty) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 21),
      child: IconButton(
        onPressed: () {
          // commit the apply info
        },
        icon: Icon(Icons.cloud_upload, color: commitColor),
      ),
    );
  }
}
