import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../comm/comm_fin_ops.dart';
import '../../../def_helper/dh_pag_finance.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../wgt_comm_button.dart';

class WgtPagPaymentLcStatusOp extends StatefulWidget {
  const WgtPagPaymentLcStatusOp({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.paymentInfo,
    required this.initialStatus,
    this.totalAppliedAmount,
    this.onCommitted,
    this.enableEdit = false,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser? loggedInUser;
  final Map<String, dynamic> paymentInfo;
  final PagPaymentLcStatus initialStatus;
  final double? totalAppliedAmount;
  final Function? onCommitted;
  final bool enableEdit;

  @override
  State<WgtPagPaymentLcStatusOp> createState() =>
      _WgtPagPaymentLcStatusOpState();
}

class _WgtPagPaymentLcStatusOpState extends State<WgtPagPaymentLcStatusOp> {
  late final tagTextStyle = TextStyle(
    color: Theme.of(context).colorScheme.onPrimary,
  );
  late final tagTextStyleHighLight = TextStyle(
    color: Theme.of(context).colorScheme.onPrimary,
    fontSize: 25,
    fontWeight: FontWeight.bold,
  );

  late PagPaymentLcStatus _selectedStatus = widget.initialStatus;

  bool _isCommitting = false;
  bool _isCommitted = false;
  String _errorText = '';

  Future<void> _commit() async {
    if (_isCommitting) return;

    _isCommitting = true;
    _isCommitted = false;
    _errorText = '';

    final queryMap = {
      'scope': widget.loggedInUser?.selectedScope.toScopeMap(),
      'item_info': {
        'item_id': widget.paymentInfo['id'],
        'tenant_id': widget.paymentInfo['tenant_id'],
        'value_timestamp': widget.paymentInfo['value_timestamp'],
        'credit_amount': widget.paymentInfo['amount'],
      },
      'target_status': _selectedStatus.value,
      'item_kind': PagItemKind.finance.name,
      'item_type': PagFinanceType.payment.name,
    };
    try {
      final result = await updatePaymentLcStatus(
          widget.appConfig,
          queryMap,
          MdlPagSvcClaim(
            scope: '',
            target: '',
            operation: '',
          ));
      dev.log('Payment Lc Status update result: $result');
      final newStatus = result['lc_status'];
      PagPaymentLcStatus updatedStatus = PagPaymentLcStatus.byValue(newStatus);

      _selectedStatus = updatedStatus;
      _isCommitted = true;

      widget.onCommitted?.call(updatedStatus);
      dev.log('Payment LC status updated to $_selectedStatus');
    } catch (e) {
      if (kDebugMode) {
        print('Error committing LC status: $e');
      }
      _errorText = e.toString();
      if (_errorText.toLowerCase().contains('total applied amount')) {
        _errorText = _errorText.replaceAll('Exception: ', '');
      } else {
        _errorText = 'Error committing LC status';
      }
    } finally {
      _isCommitting = false;

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // return Container();
    return Opacity(
      opacity: widget.enableEdit ? 1.0 : 0.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // getPaymentLcStatusTagWidget(context, PagPaymentLcStatus.mfd, style: tagTextStyle),
              // horizontalSpaceLarge,
              getLcStatusButton(PagPaymentLcStatus.posted),
              Icon(Symbols.chevron_forward, color: Theme.of(context).hintColor),
              getLcStatusButton(PagPaymentLcStatus.released),
              Icon(Symbols.chevron_forward, color: Theme.of(context).hintColor),
              getLcStatusButton(PagPaymentLcStatus.matched),
              getCommitButton(),
            ],
          ),
          if (_errorText.isNotEmpty)
            getErrorTextPrompt(context: context, errorText: _errorText)
        ],
      ),
    );
  }

  Widget getLcStatusButton(PagPaymentLcStatus status) {
    final tagTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.onPrimary,
    );
    final tagTextStyleHighLight = TextStyle(
      color: Theme.of(context).colorScheme.onPrimary,
      fontSize: 25,
      fontWeight: FontWeight.bold,
    );

    bool clickEnabled = _selectedStatus != status;
    bool highlighted = _selectedStatus == status;
    switch (widget.initialStatus) {
      // case PagPaymentLcStatus.mfd:
      //   if (status == PagPaymentLcStatus.released) {
      //     clickEnabled = false;
      //   }
      //   break;
      case PagPaymentLcStatus.posted:
        if (status == PagPaymentLcStatus.matched) {
          clickEnabled = false;
        }
        break;
      case PagPaymentLcStatus.released:
        if (status == PagPaymentLcStatus.posted) {
          clickEnabled = false;
        }
        // matched status is auto set or check by backend
        if (status == PagPaymentLcStatus.matched) {
          // clickEnabled = false;
          if (widget.totalAppliedAmount != null &&
              widget.paymentInfo['amount'] != null) {
            double? amount =
                double.tryParse(widget.paymentInfo['amount'].toString());
            if (amount == null) {
              clickEnabled = false;
            } else {
              if (widget.totalAppliedAmount! < amount) {
                clickEnabled = false;
              }
            }
          } else {
            clickEnabled = false;
          }
        }
        break;
      case PagPaymentLcStatus.matched:
        clickEnabled = false;
        break;
      default:
    }

    return InkWell(
      onTap: !widget.enableEdit || !clickEnabled
          ? null
          : () {
              setState(() {
                _selectedStatus = status;
              });
            },
      child: Opacity(
        opacity: clickEnabled || highlighted ? 1.0 : 0.5,
        child: getPaymentLcStatusTagWidget(
          context,
          status,
          style:
              status == _selectedStatus ? tagTextStyleHighLight : tagTextStyle,
        ),
      ),
    );
  }

  Widget getCommitButton() {
    if (_selectedStatus == widget.initialStatus) {
      return Container();
    }
    if (_isCommitted) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 21),
      child: WgtCommButton(
        enabled: !_isCommitting && _errorText.isEmpty,
        label: 'Commit',
        onPressed: () async {
          await _commit();
        },
      ),
    );
  }
}
