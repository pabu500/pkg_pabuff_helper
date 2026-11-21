import 'dart:async';

import 'tenant_lifecycle_changes.dart';
import 'wgt_tenant_mfd_dialog.dart';
import 'wgt_tenant_termination_dialog.dart';

import 'package:material_ui/material_ui.dart';
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
  bool _confirming = false;
  StreamSubscription<({String project, String tenant})>? _assignmentChanges;
  @override
  void initState() {
    super.initState();
    _assignmentChanges = TenantLifecycleChanges.stream.listen((change) {
      if (change.tenant == widget.tenantInfo['id'].toString() &&
          change.project ==
              widget.loggedInUser?.selectedScope.toScopeMap()['project_name']) {
        _loadCheck();
      }
    });
    _loadCheck();
  }

  @override
  void dispose() {
    _assignmentChanges?.cancel();
    super.dispose();
  }

  bool get _hasManualTargets => const [
    PagTenantLcStatus.offboarding,
    PagTenantLcStatus.onboarding,
    PagTenantLcStatus.terminated,
  ].contains(_current);

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
    if (!_hasManualTargets || !widget.enableEdit) {
      setState(() {
        _loading = false;
        _targets = {};
        _error = '';
      });
      return;
    }
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
      ((_current == PagTenantLcStatus.offboarding &&
              (status == PagTenantLcStatus.normal ||
                  status == PagTenantLcStatus.terminated)) ||
          (status == PagTenantLcStatus.mfd &&
              (_current == PagTenantLcStatus.onboarding ||
                  _current == PagTenantLcStatus.terminated))) &&
      _target(status)['eligible'] == true;
  Future<void> _commit() async {
    if (_confirming || !_eligible(_selected)) return;
    final tenantId = widget.tenantInfo['id'].toString();
    final selected = _selected;
    Map<String, dynamic> confirmation = {};
    if (_selected == PagTenantLcStatus.terminated ||
        _selected == PagTenantLcStatus.mfd) {
      await _loadCheck();
      if (!mounted ||
          _selected != selected ||
          tenantId != widget.tenantInfo['id'].toString() ||
          !_eligible(selected)) {
        return;
      }
      final version = _version;
      _confirming = true;
      Map<String, dynamic>? result;
      try {
        if (selected == PagTenantLcStatus.mfd) {
          await showDialog<void>(
            context: context,
            builder: (_) => WgtTenantMfdDialog(
              tenantName: widget.tenantInfo['name']?.toString() ?? '',
              info: _target(selected),
              onConfirm: (value) => result = value,
            ),
          );
        } else {
          result = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (_) => WgtTenantTerminationDialog(
              tenantName: widget.tenantInfo['name']?.toString() ?? '',
              info: _target(selected),
            ),
          );
        }
      } finally {
        _confirming = false;
      }
      final confirmedResult = result;
      if (confirmedResult == null ||
          !mounted ||
          version != _version ||
          tenantId != widget.tenantInfo['id'].toString() ||
          !_eligible(selected)) {
        return;
      }
      confirmation = confirmedResult;
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
          'item_info': {'item_id': tenantId},
          'item_kind': PagItemKind.tenant.value,
          'target_lc_status': selected.value,
          ...confirmation,
        },
        MdlPagSvcClaim(
          username: user.username,
          userId: user.id,
          roleId: user.selectedRole?.id,
        ),
        user: user,
      );
      if (!mounted || tenantId != widget.tenantInfo['id'].toString()) return;
      final status = PagTenantLcStatus.byValue(result['lc_status']);
      setState(() {
        _current = status;
        _selected = status;
      });
      widget.onCommitted?.call(status);
      if (mounted) await _loadCheck();
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

  Widget _statusButton(BuildContext context, PagTenantLcStatus status) =>
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
      );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statusButton(context, PagTenantLcStatus.mfd),
              horizontalSpaceLarge,
            ],
          ),
          for (final status in [
            PagTenantLcStatus.onboarding,
            PagTenantLcStatus.normal,
            PagTenantLcStatus.offboarding,
            PagTenantLcStatus.terminated,
          ])
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status != PagTenantLcStatus.onboarding)
                  Icon(
                    Symbols.chevron_forward,
                    color: Theme.of(context).hintColor,
                  ),
                _statusButton(context, status),
              ],
            ),
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
          if (widget.enableEdit && _hasManualTargets)
            IconButton(
              onPressed: _loading || _committing ? null : _loadCheck,
              tooltip: 'Refresh eligibility',
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      if (_error.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _TenantLcNotice.error(message: _error),
        ),
      for (final status in [
        if (_current == PagTenantLcStatus.offboarding) ...[
          PagTenantLcStatus.normal,
          PagTenantLcStatus.terminated,
        ],
        if (_current == PagTenantLcStatus.onboarding ||
            _current == PagTenantLcStatus.terminated)
          PagTenantLcStatus.mfd,
      ])
        if (_reasons(status).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _TenantLcNotice.blocked(
              key: ValueKey('lc-notice-${status.value}'),
              title: status == PagTenantLcStatus.mfd
                  ? 'Mark for deletion unavailable'
                  : status == PagTenantLcStatus.normal
                  ? 'Return to Normal unavailable'
                  : 'Termination unavailable',
              reasons: _reasons(status),
            ),
          ),
    ],
  );
}

/// Compact, theme-aware panel for lifecycle transition messages.
///
/// [blocked] is the neutral treatment for normal eligibility guidance (what
/// must happen before a transition is allowed). [error] is reserved for
/// actual request failures and uses the theme's error container colors.
/// Blocked panels start collapsed (title + reason count) and expand from
/// their header to show every reason.
class _TenantLcNotice extends StatefulWidget {
  const _TenantLcNotice.blocked({
    super.key,
    required String this.title,
    required this.reasons,
  }) : message = null,
       isError = false;
  const _TenantLcNotice.error({required String this.message})
    : title = null,
      reasons = const [],
      isError = true;

  final String? title;
  final List<String> reasons;
  final String? message;
  final bool isError;

  @override
  State<_TenantLcNotice> createState() => _TenantLcNoticeState();
}

class _TenantLcNoticeState extends State<_TenantLcNotice> {
  bool _expanded = false;

  String? get title => widget.title;
  List<String> get reasons => widget.reasons;
  String? get message => widget.message;
  bool get isError => widget.isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final background = isError
        ? cs.errorContainer
        : cs.surfaceContainerHighest.withValues(alpha: 0.5);
    final border = isError
        ? cs.error.withValues(alpha: 0.5)
        : cs.outlineVariant;
    final foreground = isError ? cs.onErrorContainer : cs.onSurface;
    final secondary = isError ? cs.onErrorContainer : cs.onSurfaceVariant;
    final iconColor = isError ? cs.error : cs.onSurfaceVariant;
    final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: secondary, height: 1.35);

    final icon = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Icon(
        isError ? Symbols.error : Symbols.info,
        size: 18,
        color: iconColor,
      ),
    );

    if (isError) {
      return _frame(
        background: background,
        border: border,
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              Expanded(
                child: Text(
                  message ?? '',
                  style: bodyStyle.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final header = Semantics(
      button: true,
      expanded: _expanded,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: _expanded
            ? const BorderRadius.vertical(top: Radius.circular(8))
            : BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          child: Row(
            children: [
              icon,
              Expanded(
                child: Text(
                  title ?? '',
                  style: (theme.textTheme.titleSmall ?? const TextStyle())
                      .copyWith(color: foreground, fontWeight: FontWeight.w600),
                ),
              ),
              if (!_expanded)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    reasons.length == 1
                        ? '1 reason'
                        : '${reasons.length} reasons',
                    style: (theme.textTheme.labelMedium ?? const TextStyle())
                        .copyWith(color: secondary),
                  ),
                ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  Symbols.expand_more,
                  size: 20,
                  color: secondary,
                  semanticLabel: _expanded ? 'Hide reasons' : 'Show reasons',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final body = Padding(
      // Align reasons with the title text (past the 18px icon + 8px gap).
      padding: const EdgeInsets.fromLTRB(36, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, reason) in reasons.indexed)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
              child: _bullet(reason, bodyStyle, secondary),
            ),
        ],
      ),
    );

    return _frame(
      background: background,
      border: border,
      liveRegion: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.topCenter,
            child: _expanded ? body : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String reason, TextStyle bodyStyle, Color dotColor) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        // Centre the dot on the first line of wrapped text.
        padding: EdgeInsets.only(
          top: ((bodyStyle.fontSize ?? 14) * 1.35 - 5) / 2,
          right: 8,
        ),
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: dotColor.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Expanded(child: Text(reason, style: bodyStyle)),
    ],
  );

  Widget _frame({
    required Color background,
    required Color border,
    required bool liveRegion,
    required Widget child,
  }) {
    final panel = Semantics(
      container: true,
      liveRegion: liveRegion,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
    // Stretch to the available width so stacked panels align; fall back to
    // a sensible width if ever placed in an unbounded parent.
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.hasBoundedWidth ? constraints.maxWidth : 480,
        child: panel,
      ),
    );
  }
}
