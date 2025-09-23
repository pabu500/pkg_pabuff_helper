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

  // late final matchedPaymentInfo =
  //     widget.paymentMatchingInfo['matched_payment_info'];
  // late final String billingRecId = matchedPaymentInfo['billing_rec_id'];
  // late final String billingLcStatusStr =
  //     matchedPaymentInfo['billing_lc_status'];
  // late final String paymentLcStatusStr = matchedPaymentInfo['lc_status'];
  // late final String paymentAmount = matchedPaymentInfo['amount'];
  // late final String paymentValueDate = matchedPaymentInfo['value_timestamp'];
  // // only get the date from the time
  // late final String paymentValueDateOnly = paymentValueDate.split(' ').first;
  late final String tenantName = widget.tenantInfo['tenant_name'];

  bool _isFetchingBillList = false;
  bool _billListFetchTried = false;
  String _errorText = '';

  final List<Map<String, dynamic>> _billList = [];
  late PagPaymentLcStatus _lcStatusDisplay;
  UniqueKey? _lcStatusOpsKey;
  late Map<String, dynamic> _paymentInfo = widget.paymentMatchingInfo ?? {};

  bool _isApplied = false;

  Future<void> _fetchBillList() async {
    if (_isFetchingBillList || _billListFetchTried) return;

    _isFetchingBillList = true;
    _errorText = '';

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'item_kind': PagItemKind.bill.name,
      't.name': tenantName,
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

  @override
  void initState() {
    super.initState();
    _lcStatusDisplay =
        PagPaymentLcStatus.byValue(widget.defaultPaymentLcStatusStr);
    _isApplied = _lcStatusDisplay == PagPaymentLcStatus.released;
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
                      widget.paymentMatchingInfo?['matched_payment_info']
                              ?['amount'] ??
                          '',
                      style: mainTextStyle),
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
                future: _fetchBillList(),
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

  Widget getNewApply() {
    bool isEnabled = false;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: isEnabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor.withAlpha(130)),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 95,
            child: WgtTextField(
              appConfig: widget.appConfig,
              loggedInUser: widget.loggedInUser,
              hintText: 'Usage',
              labelText: 'Usage',
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
              appConfig: widget.appConfig,
              loggedInUser: widget.loggedInUser,
              hintText: 'Interest',
              labelText: 'Interest',
              onChanged: (value) {
                // setState(() {
                //   _paymentApply = value;
                // });
              },
            ),
          ),
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
    PagBillingLcStatus billLcStatus =
        PagBillingLcStatus.values.byName(billingLcStatusStr);

    bool isMatchedBill = false;
    if (widget.paymentMatchingInfo != null) {
      isMatchedBill = widget.paymentMatchingInfo!['matched_payment_info']
              ?['billing_rec_id'] ==
          billingRecId;
    }

    // final lcStatusStr = widget.paymentMatchingInfo?['lc_status'] ?? '';
    // PagPaymentLcStatus lcStatus = PagPaymentLcStatus.byValue(lcStatusStr);

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
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _isApplied ? getAppliedPayment() : getNewApply(),
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

  Widget getAppliedPayment() {
    bool isEnabled = false;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: isEnabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor.withAlpha(130)),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Applied', style: billLabelStyle),
          horizontalSpaceSmall,
          Icon(Symbols.check_circle,
              color: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }
}
