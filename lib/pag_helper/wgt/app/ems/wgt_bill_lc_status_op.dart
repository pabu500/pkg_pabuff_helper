import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/pag_bill_def.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
        'billing_rec_id': widget.billInfo['billing_rec_id'],
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
      if (kDebugMode) {
        print('Error committing LC status: $e');
      }
      _errorText = 'Error committing LC status';
    } finally {
      _isCommitting = false;
      if (mounted) {
        setState(() {});
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
              getBillLcStatusTagWidget(context, PagBillingLcStatus.mfd,
                  style: tagTextStyle),
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

  Widget getLcStatusButton(PagBillingLcStatus status) {
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
      case PagBillingLcStatus.mfd:
        if (status == PagBillingLcStatus.released) {
          clickEnabled = false;
        }
        break;
      case PagBillingLcStatus.generated:
        if (status == PagBillingLcStatus.released) {
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
                _selectedStatus = status;
              });
            },
      child: Opacity(
        opacity: clickEnabled || highlighted ? 1.0 : 0.5,
        child: getBillLcStatusTagWidget(
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

    return Padding(
      padding: const EdgeInsets.only(left: 21),
      child: WgtCommButton(
        label: 'Commit',
        onPressed: () async {
          await _commit();
        },
      ),
    );
  }
}
