import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/wgt_pag_composite_bill_view.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/material.dart';

class WgtMatchOnePayment extends StatefulWidget {
  const WgtMatchOnePayment({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.paymentMatchingInfo,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Map<String, dynamic> paymentMatchingInfo;

  @override
  State<WgtMatchOnePayment> createState() => _WgtMatchOnePaymentState();
}

class _WgtMatchOnePaymentState extends State<WgtMatchOnePayment> {
  late final TextStyle mainLabelStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Theme.of(context).hintColor,
  );
  late final TextStyle mainTextStyle = const TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
  );

  late final matchedPaymentInfo =
      widget.paymentMatchingInfo['matched_payment_info'];
  late final String billingRecId = matchedPaymentInfo['billing_rec_id'];
  late final String billingLcStatus = matchedPaymentInfo['lc_status'];
  late final String paymentAmount = matchedPaymentInfo['amount'];
  late final String paymentValueDate = matchedPaymentInfo['value_timestamp'];
  // only get the date from the time
  late final String paymentValueDateOnly = paymentValueDate.split(' ').first;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Payment Amount: ', style: mainLabelStyle),
              Text(paymentAmount, style: mainTextStyle)
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Payment Value Date: ', style: mainLabelStyle),
              Text(paymentValueDateOnly, style: mainTextStyle),
            ],
          ),
          verticalSpaceSmall,
          const Text('Matched Billing Record'),
          const Divider(),
          verticalSpaceSmall,
          WgtPagCompositeBillView(
            costDecimals: 2,
            appConfig: widget.appConfig,
            loggedInUser: widget.loggedInUser,
            billingRecIndexStr: billingRecId,
            defaultBillLcStatus: billingLcStatus,
            modes: const ['widget', 'pdf'],
            genTypes: billingLcStatus == 'released' || billingLcStatus == 'pv'
                ? const ['generated', 'released']
                : const ['generated'],
          ),
        ],
      ),
    );
  }
}
