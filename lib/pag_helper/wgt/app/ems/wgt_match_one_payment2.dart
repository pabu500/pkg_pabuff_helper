import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/pag_bill_def.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:developer' as dev;

import '../../../../pagrid_helper/ems_helper/billing_helper/wgt_pag_composite_bill_view.dart';
import '../../../../xt_ui/wdgt/info/get_error_text_prompt.dart';
import '../../../../xt_ui/wdgt/wgt_pag_wait.dart';

class WgtMatchOnePayment2 extends StatefulWidget {
  const WgtMatchOnePayment2({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.tenantInfo,
    this.paymentMatchingInfo,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Map<String, dynamic> tenantInfo;
  final Map<String, dynamic>? paymentMatchingInfo;

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

  late final TextStyle billLabelStyle = TextStyle(
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
  Widget build(BuildContext context) {
    bool fetchingBillList = _billList.isEmpty && !_billListFetchTried;

    final tenantLabel = widget.tenantInfo['tenant_label'] ?? '';
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
                  horizontalSpaceSmall,
                  Text('Payment Amount: ', style: mainLabelStyle),
                  Text(
                      widget.paymentMatchingInfo?['matched_payment_info']
                              ?['amount'] ??
                          '',
                      style: mainTextStyle)
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
      child: InkWell(
        child: getBillItem(index),
        onTap: () {
          setState(() {
            _billList[index]['show_bill'] =
                !(_billList[index]['show_bill'] ?? false);
          });
        },
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$billLabel', style: billLabelStyle),
                  Text('$cycleStr', style: billLabelStyle),
                ],
              ),
              horizontalSpaceSmall,
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Billed Total Cost: ',
                        style: billKeyStyle,
                      ),
                      Text('$billedTotalCost',
                          style: billLabelStyle.copyWith(fontSize: 34)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (billInfo['show_bill'] ?? false) const Divider(),
          if (billInfo['show_bill'] ?? false)
            WgtPagCompositeBillView(
              costDecimals: 2,
              appConfig: widget.appConfig,
              loggedInUser: widget.loggedInUser,
              displayContext: 'match_one_paymment',
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
}
