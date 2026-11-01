import 'wgt_tenant_termination_dialog.dart';
import 'package:flutter/material.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../comm/comm_tenant.dart';
import '../../../comm/comm_tenant_auth.dart';
import '../../../def_helper/dh_pag_tenant.dart';
import '../../../def_helper/dh_pag_item.dart';
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
  State<WgtPagTenantLcStatusOp> createState() => _TenantLcStatusState();
}

class _TenantLcStatusState extends State<WgtPagTenantLcStatusOp> {
  late PagTenantLcStatus _current = widget.initialStatus;
  late PagTenantLcStatus _selected = widget.initialStatus;
  Map<String, dynamic> _targets = {};
  bool _loading = false;
  bool _committing = false;
  String _error = '';
  int _version = 0;
  @override
  void initState() {
    super.initState();
    _loadCheck();
  }

  @override
  void didUpdateWidget(covariant WgtPagTenantLcStatusOp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tenantInfo['id'] != widget.tenantInfo['id'] ||
        oldWidget.initialStatus != widget.initialStatus ||
        oldWidget.enableEdit != widget.enableEdit) {
      _current = widget.initialStatus;
      _selected = _current;
      _targets = {};
      _loadCheck();
    }
  }

  Future<void> _loadCheck() async {
    final version = ++_version;
    if (_current != PagTenantLcStatus.offboarding || !widget.enableEdit) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final user = widget.loggedInUser;
      if (user == null) throw Exception('Please sign in again');
      final result = await getTenantLcTransitionCheck(widget.appConfig, user, {
        'scope': user.selectedScope.toScopeMap(),
        'tenant_id': widget.tenantInfo['id'].toString(),
      });
      if (mounted && version == _version) {
        setState(() {
          _targets = Map<String, dynamic>.from(result['targets'] as Map);
        });
      }
    } catch (e) {
      if (mounted && version == _version) {
        setState(() {
          _targets = {};
          _error = getErrorText(
            e,
            defaultErrorText: 'Unable to check tenant transitions',
          );
        });
      }
    } finally {
      if (mounted && version == _version) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Map<String, dynamic> _target(PagTenantLcStatus status) =>
      Map<String, dynamic>.from(_targets[status.value] as Map? ?? {});
  List<String> _reasons(PagTenantLcStatus status) =>
      (_target(status)['reasons'] as List? ?? [])
          .map((e) => e.toString())
          .toList();
  bool _eligible(PagTenantLcStatus status) =>
      widget.enableEdit &&
      !_loading &&
      !_committing &&
      _current == PagTenantLcStatus.offboarding &&
      (status == PagTenantLcStatus.normal ||
          status == PagTenantLcStatus.terminated) &&
      _target(status)['eligible'] == true;
  Future<void> _commit() async {
    if (!_eligible(_selected)) return;
    Map<String, dynamic> confirmation = {};
    if (_selected == PagTenantLcStatus.terminated) {
      await _loadCheck();
      if (!mounted || !_eligible(_selected)) return;
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => WgtTenantTerminationDialog(
          tenantName: widget.tenantInfo['name']?.toString() ?? '',
          info: _target(_selected),
        ),
      );
      if (result == null || !mounted) return;
      confirmation = result;
    }
    final user = widget.loggedInUser;
    if (user == null) return;
    setState(() {
      _committing = true;
      _error = '';
    });
    try {
      final result = await updateTenantLcStatus(
        widget.appConfig,
        {
          'scope': user.selectedScope.toScopeMap(),
          'item_info': {'item_id': widget.tenantInfo['id'].toString()},
          'item_kind': PagItemKind.tenant.value,
          'target_lc_status': _selected.value,
          ...confirmation,
        },
        MdlPagSvcClaim(
          username: user.username,
          userId: user.id,
          roleId: user.selectedRole?.id,
        ),
        user: user,
      );
      if (!mounted) return;
      final status = PagTenantLcStatus.byValue(result['lc_status']);
      setState(() {
        _current = status;
        _selected = status;
      });
      widget.onCommitted?.call(status);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = getErrorText(
            e,
            defaultErrorText: 'Unable to update tenant status',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _committing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          for (final status in [
            PagTenantLcStatus.mfd,
            PagTenantLcStatus.onboarding,
            PagTenantLcStatus.normal,
            PagTenantLcStatus.offboarding,
            PagTenantLcStatus.terminated,
          ]) ...[
            if (status != PagTenantLcStatus.mfd)
              Icon(Symbols.chevron_forward, color: Theme.of(context).hintColor),
            Tooltip(
              message: _reasons(status).join('\n'),
              child: InkWell(
                onTap: _eligible(status)
                    ? () => setState(() => _selected = status)
                    : null,
                child: Opacity(
                  opacity: _eligible(status) || _selected == status ? 1 : 0.5,
                  child: getTenantLcStatusTagWidget(
                    context,
                    status,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: _selected == status ? 25 : null,
                      fontWeight: _selected == status ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (_selected != _current)
            Padding(
              padding: const EdgeInsets.only(left: 21),
              child: WgtCommButton(
                enabled: _eligible(_selected),
                label: 'Commit',
                onPressed: _commit,
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(),
              ),
            ),
          if (widget.enableEdit && _current == PagTenantLcStatus.offboarding)
            IconButton(
              onPressed: _loading || _committing ? null : _loadCheck,
              tooltip: 'Refresh eligibility',
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      if (_error.isNotEmpty)
        getErrorTextPrompt(context: context, errorText: _error),
      for (final status in [
        PagTenantLcStatus.normal,
        PagTenantLcStatus.terminated,
      ])
        if (_reasons(status).isNotEmpty)
          Text('${status.value}: ${_reasons(status).join('; ')}'),
    ],
  );
}
