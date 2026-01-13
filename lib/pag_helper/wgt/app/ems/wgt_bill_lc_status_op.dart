import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/pag_bill_def.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../pagrid_helper/batch_op_helper/wgt_confirm_box.dart';
import '../../../comm/comm_pag_billing.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../wgt_comm_button.dart';

class WgtPagBillLcStatusOp extends StatefulWidget {
  const WgtPagBillLcStatusOp({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.billInfo,
    required this.initialStatus,
    this.onCommitted,
    this.enableEdit = false,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser? loggedInUser;
  final Map<String, dynamic> billInfo;
  final PagBillingLcStatus initialStatus;
  final Function? onCommitted;
  final bool enableEdit;

  @override
  State<WgtPagBillLcStatusOp> createState() => _WgtPagBillLcStatusOpState();
}

class _WgtPagBillLcStatusOpState extends State<WgtPagBillLcStatusOp> {
  late final tagTextStyle = TextStyle(
    color: Theme.of(context).colorScheme.onPrimary,
  );
  late final tagTextStyleHighLight = TextStyle(
    color: Theme.of(context).colorScheme.onPrimary,
    fontSize: 25,
    fontWeight: FontWeight.bold,
  );

  late PagBillingLcStatus _selectedStatus = widget.initialStatus;

  bool _isCommitting = false;
  String _errorText = '';

  Future<void> _commit() async {
    if (_isCommitting) return;

    final queryMap = {
      'scope': widget.loggedInUser?.selectedScope.toScopeMap(),
      'bill_info': {
        'tenant_id': widget.billInfo['tenant_id'],
        'billing_rec_id': widget.billInfo['billing_rec_id'],
        'bill_date_timestamp': widget.billInfo['bill_date_timestamp'],
        'billed_total_amount': widget.billInfo['billed_total_amount'],
        'billed_interest_amount': widget.billInfo['billed_interest_amount'],
      },
      'target_status': _selectedStatus.value,
    };
    try {
      _isCommitting = true;
      _errorText = '';

      final result = await updateBillLcStatus(
          widget.appConfig,
          queryMap,
          MdlPagSvcClaim(
            scope: '',
            target: '',
            operation: '',
          ));
      dev.log('Bill Lc Status update result: $result');
      final newStatus = result['lc_status'];
      PagBillingLcStatus updatedStatus = PagBillingLcStatus.byValue(newStatus);
      setState(() {
        _selectedStatus = updatedStatus;
      });
      widget.onCommitted?.call(updatedStatus);
    } catch (e) {
      dev.log('Error committing LC status: $e');

      _errorText =
          getErrorText(e, defaultErrorText: 'Error committing LC status');
    } finally {
      _isCommitting = false;
      if (mounted) {
        setState(() {});
        if (_errorText.isNotEmpty) {
          showInfoDialog(context, 'Error', _errorText);
        }
      }
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
              getLcStatusButton(PagBillingLcStatus.mfd),
              horizontalSpaceLarge,
              getLcStatusButton(PagBillingLcStatus.generated),
              Icon(Symbols.chevron_forward, color: Theme.of(context).hintColor),
              getLcStatusButton(PagBillingLcStatus.pv),
              Icon(Symbols.chevron_forward, color: Theme.of(context).hintColor),
              getLcStatusButton(PagBillingLcStatus.released),
              getCommitButton(),
            ],
          ),
          if (_errorText.isNotEmpty)
            getErrorTextPrompt(context: context, errorText: _errorText)
        ],
      ),
    );
  }

  Widget getLcStatusButton(PagBillingLcStatus targetStatus) {
    final tagTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.onPrimary,
    );
    final tagTextStyleHighLight = TextStyle(
      color: Theme.of(context).colorScheme.onPrimary,
      fontSize: 25,
      fontWeight: FontWeight.bold,
    );

    bool clickEnabled = _selectedStatus != targetStatus;
    bool highlighted = _selectedStatus == targetStatus;
    switch (widget.initialStatus) {
      case PagBillingLcStatus.mfd:
        clickEnabled = false;
        break;
      case PagBillingLcStatus.generated:
        if (targetStatus == PagBillingLcStatus.released) {
          clickEnabled = false;
        }
        break;
      case PagBillingLcStatus.pv:
        break;
      case PagBillingLcStatus.released:
        clickEnabled = false;
        break;
      default:
    }

    return InkWell(
      onTap: !widget.enableEdit || !clickEnabled
          ? null
          : () {
              setState(() {
                _selectedStatus = targetStatus;
              });
            },
      child: Opacity(
        opacity: clickEnabled || highlighted ? 1.0 : 0.5,
        child: getBillLcStatusTagWidget(
          context,
          targetStatus,
          style: targetStatus == _selectedStatus
              ? tagTextStyleHighLight
              : tagTextStyle,
        ),
      ),
    );
  }

  Widget getCommitButton() {
    if (_selectedStatus == widget.initialStatus) {
      return Container();
    }

    bool targetIsMfd = _selectedStatus == PagBillingLcStatus.mfd;
    bool targetIsReleased = _selectedStatus == PagBillingLcStatus.released;
    String itemRef =
        widget.billInfo['billing_rec_name'] ?? 'unknown_bill_record';

    return Padding(
      padding: const EdgeInsets.only(left: 21),
      child: WgtCommButton(
        enabled: !_isCommitting && _errorText.isEmpty,
        label: 'Commit',
        onPressed: () async {
          !targetIsMfd && !targetIsReleased
              ? await _commit()
              : showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return WgtConfirmBox(
                      title: targetIsMfd
                          ? 'MFD Confirmation'
                          : 'Release Confirmation',
                      message1:
                          'This operation is not reversible. Are you sure to proceed?',
                      message2:
                          'It\'s recommended to double check before proceeding',
                      opName: targetIsMfd ? 'bill_mfd' : 'bill_release',
                      keyInConfirmStrList: [
                        targetIsMfd ? 'mfd' : 'release',
                        itemRef,
                      ],
                      itemCount: 1,
                      onConfirm: () async {
                        await _commit();
                      },
                    );
                  },
                );
        },
      ),
    );
  }
}
