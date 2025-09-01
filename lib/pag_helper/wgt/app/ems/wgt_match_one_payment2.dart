import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/wgt_pag_composite_bill_view.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

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
  late final String tenantIdStr = widget.tenantInfo['tenant_id'];

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
      'tenant_id': tenantIdStr,
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

    return fetchingBillList
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
        : completedWidget();
  }

  Widget completedWidget() {
    return SizedBox(
      height: 500,
      child: ListView.builder(
        itemCount: 1,
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
    Map<String, dynamic> billInfo = _billList[index];
    return ListTile(
      title: Text('Payment Amount: ${billInfo['amount']}'),
      subtitle: Text('Payment Value Date: ${billInfo['value_timestamp']}'),
      // trailing:
      // WgtPagCompositeBillView(
      //   costDecimals: 2,
      //   appConfig: widget.appConfig,
      //   loggedInUser: widget.loggedInUser,
      //   billingRecIndexStr: billingRecId,
      //   defaultBillLcStatusStr: billingLcStatusStr,
      //   modes: const ['wgt', 'pdf'],
      //   genTypes: const ['released'],
      // ),
    );
  }
}
