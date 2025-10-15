import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:developer' as dev;

import '../../../../xt_ui/wdgt/show_model_bottom_sheet.dart';
import '../../../../xt_ui/wdgt/wgt_pag_wait.dart';
import '../../../model/mdl_pag_app_config.dart';
import 'wgt_match_one_payment2.dart';

class WgtPaymentMatchOpItem extends StatefulWidget {
  const WgtPaymentMatchOpItem({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.tenantInfo,
    required this.paymentMatchInfo,
    this.regFresh,
    this.onUpdate,
    this.onClosed,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Map<String, dynamic> tenantInfo;
  final Map<String, dynamic> paymentMatchInfo;
  final void Function(void Function(bool isComm, bool isEnabled))? regFresh;
  final Function? onUpdate;
  final Function? onClosed;

  @override
  State<WgtPaymentMatchOpItem> createState() => _WgtPaymentMatchOpItemState();
}

class _WgtPaymentMatchOpItemState extends State<WgtPaymentMatchOpItem> {
  late final BoxDecoration matchedDecor = BoxDecoration(
    border: Border.all(color: Colors.purple.shade300.withAlpha(210), width: 2),
    borderRadius: BorderRadius.circular(3),
  );
  late final BoxDecoration hasAppliedPaymentsDecor = BoxDecoration(
    border: Border.all(color: commitColor.withAlpha(210), width: 2),
    borderRadius: BorderRadius.circular(3),
  );
  bool _isComm = false;
  bool _isEnabled = false;

  bool _matchedBillingRecFound = false;
  bool _hasAppliedPayments = false;

  void _refresh(bool isComm, bool isEnabled) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isComm = isComm;
      _isEnabled = isEnabled;
      // dev.log('isComm: $_isComm, isEnabled: $_isEnabled');
      _matchedBillingRecFound =
          widget.paymentMatchInfo['matched_billing_rec_found'] ?? false;
      _hasAppliedPayments =
          widget.paymentMatchInfo['has_applied_payments'] ?? false;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.regFresh?.call(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    // return widget;
    return _isComm
        ? const WgtPagWait(size: 21)
        : InkWell(
            onTap: !_isEnabled
                ? null
                : () {
                    xtShowModelBottomSheet(
                      context,
                      WgtMatchOnePayment2(
                        appConfig: widget.appConfig,
                        loggedInUser: widget.loggedInUser,
                        tenantInfo: widget.tenantInfo,
                        paymentMatchingInfo: widget.paymentMatchInfo,
                        defaultPaymentLcStatusStr:
                            widget.paymentMatchInfo['lc_status'] ?? '',
                        onUpdate: () {
                          // _refresh(isComm, isEnabled);
                          widget.onUpdate?.call(); // to refresh the icon state
                        },
                      ),
                      onClosed: () {
                        // widget.onUpdate?.call();
                        widget.onClosed?.call();
                      },
                    );
                  },
            child: Container(
              decoration: !_matchedBillingRecFound
                  ? !_hasAppliedPayments
                      ? null
                      : hasAppliedPaymentsDecor
                  : matchedDecor,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              child: Icon(Symbols.payments,
                  color: _isEnabled
                      ? Theme.of(context).colorScheme.primary.withAlpha(210)
                      : Theme.of(context).hintColor.withAlpha(50)),
            ),
          );
  }
}
