import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../pagrid_helper/batch_op_helper/wgt_confirm_box.dart';
import '../../../comm/comm_tenant.dart';
import '../../../def_helper/dh_pag_tenant.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../wgt_comm_button.dart';

class WgtPagTenantLcStatusOp extends StatefulWidget {
  const WgtPagTenantLcStatusOp({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.tenantInfo,
    required this.initialStatus,
    this.onCommitted,
    this.enableEdit = false,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser? loggedInUser;
  final Map<String, dynamic> tenantInfo;
  final PagTenantLcStatus initialStatus;
  final Function? onCommitted;
  final bool enableEdit;

  @override
  State<WgtPagTenantLcStatusOp> createState() => _WgtPagTenantLcStatusOpState();
}

class _WgtPagTenantLcStatusOpState extends State<WgtPagTenantLcStatusOp> {
  late final tagTextStyle = TextStyle(
    color: Theme.of(context).colorScheme.onPrimary,
  );
  late final tagTextStyleHighLight = TextStyle(
    color: Theme.of(context).colorScheme.onPrimary,
    fontSize: 25,
    fontWeight: FontWeight.bold,
  );

  late PagTenantLcStatus _selectedLcStatus = widget.initialStatus;

  bool _isCommitting = false;
  String _errorText = '';

  Future<void> _commit() async {
    if (_isCommitting) return;

    final queryMap = {
      'scope': widget.loggedInUser?.selectedScope.toScopeMap(),
      'item_info': {
        'item_id': widget.tenantInfo['id'],
        'tenant_lc_status': widget.tenantInfo['lc_status'],
      },
      'item_kind': PagItemKind.tenant.name,
      'target_lc_status': _selectedLcStatus.value,
    };
    try {
      _isCommitting = true;
      _errorText = '';

      final result = await updateTenantLcStatus(
          widget.appConfig,
          queryMap,
          MdlPagSvcClaim(
            scope: '',
            target: '',
            operation: '',
          ));
      dev.log('Tenant Lc Status update result: $result');
      final newStatus = result['lc_status'];
      PagTenantLcStatus updatedStatus = PagTenantLcStatus.byValue(newStatus);
      setState(() {
        _selectedLcStatus = updatedStatus;
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
              getLcStatusButton(PagTenantLcStatus.mfd),
              horizontalSpaceLarge,
              getLcStatusButton(PagTenantLcStatus.onboarding),
              Icon(Symbols.chevron_forward, color: Theme.of(context).hintColor),
              getLcStatusButton(PagTenantLcStatus.normal),
              Icon(Symbols.chevron_forward, color: Theme.of(context).hintColor),
              getLcStatusButton(PagTenantLcStatus.offboarding),
              Icon(Symbols.chevron_forward, color: Theme.of(context).hintColor),
              getLcStatusButton(PagTenantLcStatus.terminated),
              getCommitButton(),
            ],
          ),
          if (_errorText.isNotEmpty)
            getErrorTextPrompt(context: context, errorText: _errorText)
        ],
      ),
    );
  }

  Widget getLcStatusButton(PagTenantLcStatus targetStatus) {
    final tagTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.onPrimary,
    );
    final tagTextStyleHighLight = TextStyle(
      color: Theme.of(context).colorScheme.onPrimary,
      fontSize: 25,
      fontWeight: FontWeight.bold,
    );

    bool clickEnabled = _selectedLcStatus != targetStatus;
    bool highlighted = _selectedLcStatus == targetStatus;
    switch (widget.initialStatus) {
      case PagTenantLcStatus.mfd:
        clickEnabled = false;
        break;
      case PagTenantLcStatus.onboarding:
        clickEnabled = false;
        break;
      case PagTenantLcStatus.normal:
        // clickEnabled = targetStatus != PagTenantLcStatus.onboarding;
        clickEnabled = false; // requires offboarding flow
        break;
      case PagTenantLcStatus.offboarding:
        // clickEnabled = targetStatus != PagTenantLcStatus.onboarding;
        clickEnabled = targetStatus == PagTenantLcStatus.normal;
        break;
      case PagTenantLcStatus.terminated:
        clickEnabled = false;
        break;
      default:
    }

    return InkWell(
      onTap: !widget.enableEdit || !clickEnabled
          ? null
          : () {
              setState(() {
                _selectedLcStatus = targetStatus;
              });
            },
      child: Opacity(
        opacity: clickEnabled || highlighted ? 1.0 : 0.5,
        child: getTenantLcStatusTagWidget(
          context,
          targetStatus,
          style: targetStatus == _selectedLcStatus
              ? tagTextStyleHighLight
              : tagTextStyle,
        ),
      ),
    );
  }

  Widget getCommitButton() {
    if (_selectedLcStatus == widget.initialStatus) {
      return Container();
    }

    bool targetIsMfd = _selectedLcStatus == PagTenantLcStatus.mfd;
    bool targetIsTerminated = _selectedLcStatus == PagTenantLcStatus.terminated;
    String itemRef = widget.tenantInfo['name'] ?? 'unknown_tenant_name';

    return Padding(
      padding: const EdgeInsets.only(left: 21),
      child: WgtCommButton(
        enabled: !_isCommitting && _errorText.isEmpty,
        label: 'Commit',
        onPressed: () async {
          !targetIsMfd && !targetIsTerminated
              ? await _commit()
              : showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return WgtConfirmBox(
                      title: targetIsMfd
                          ? 'MFD Confirmation'
                          : 'Terminate Confirmation',
                      message1:
                          'This operation is not reversible. Are you sure to proceed?',
                      message2:
                          'It\'s recommended to double check before proceeding',
                      opName: targetIsMfd ? 'tenant_mfd' : 'tenant_terminate',
                      keyInConfirmStrList: [
                        targetIsMfd ? 'mfd' : 'terminate',
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
