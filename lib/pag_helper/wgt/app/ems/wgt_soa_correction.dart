import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/pagrid_helper/batch_op_helper/wgt_confirm_box.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../comm/comm_ex.dart';
import '../../../def_helper/dh_pag_finance.dart';
import '../../wgt_comm_button.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';

class WgtSoaCorrection extends StatefulWidget {
  const WgtSoaCorrection({
    super.key,
    required this.appConfig,
    required this.user,
    required this.tenantId,
    required this.onChanged,
    required this.onActionsChanged,
    this.request,
  });
  final MdlPagAppConfig appConfig;
  final MdlPagUser user;
  final String tenantId;
  final VoidCallback onChanged;
  final ValueChanged<Map<String, Map<String, dynamic>>> onActionsChanged;
  final Future<dynamic> Function(String, Map<String, dynamic>)? request;
  @override
  State<WgtSoaCorrection> createState() => WgtSoaCorrectionState();
}

class WgtSoaCorrectionState extends State<WgtSoaCorrection> {
  Map<String, dynamic> _preview = {};
  String _error = '';
  bool _busy = false;
  bool _sheetOpen = false;
  Map<String, dynamic>? _pending;
  List<Map<String, dynamic>> _visibleRows = [];
  Map<String, dynamic> _listQuery = {};
  bool _latestShown = false;
  int _viewRevision = 0;
  Future<dynamic> _call(String action, [Map<String, dynamic> body = const {}]) {
    if (widget.request != null) return widget.request!(action, body);
    return ex(
      endpoint: '/ems/fin/soa_correction/$action',
      crudType: action == 'commit' ? 'update' : 'read',
      opStr: 'review SOA reversal',
      structuredErrors: true,
      appConfig: widget.appConfig,
      queryMap: {
        'scope': widget.user.selectedScope.toScopeMap(),
        'tenant_id': widget.tenantId,
        ...body,
      },
      svcClaim: MdlPagSvcClaim(
        username: widget.user.username,
        userId: widget.user.id,
        roleId: widget.user.selectedRole?.id,
        roleName: widget.user.selectedRole?.name,
        roleLabel: widget.user.selectedRole?.label,
        scope: '',
        target: 'ems.finance.soaCorrection',
        operation: action == 'commit' ? 'update' : 'read',
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void invalidateList() {
    _viewRevision++;
    if (!mounted) return;
    setState(() => _latestShown = false);
    widget.onActionsChanged({});
  }

  Future<void> updateList(Map<String, dynamic> result) async {
    invalidateList();
    final revision = _viewRevision;
    _visibleRows = ((result['item_list'] as List?) ?? [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    _listQuery = Map<String, dynamic>.from((result['query_map'] as Map?) ?? {});
    _listQuery['current_page'] =
        result['current_page'] ?? _listQuery['current_page'];
    if (result['error'] != null || _visibleRows.isEmpty) return;
    try {
      final preview = Map<String, dynamic>.from(await _call('preview') as Map);
      if (!mounted || revision != _viewRevision) return;
      setState(() {
        _preview = preview;
        _latestShown = soaListShowsLatest(
          _visibleRows,
          _listQuery,
          preview['top_soa_id'],
        );
        _error = '';
      });
    } catch (e) {
      if (mounted && revision == _viewRevision) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _checkEntries() async {
    if (!_latestShown || _busy) return;
    final revision = _viewRevision;
    String checkError = '';
    widget.onActionsChanged({});
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      final preview = Map<String, dynamic>.from(await _call('preview') as Map);
      if (!mounted || revision != _viewRevision) return;
      final latest = soaListShowsLatest(
        _visibleRows,
        _listQuery,
        preview['top_soa_id'],
      );
      final actions = latest
          ? soaActionsByRow(preview, _visibleRows)
          : <String, Map<String, dynamic>>{};
      final reasons = (preview['reasons'] as List?) ?? [];
      checkError = !latest
          ? 'The latest entries changed. Refresh the list and check again.'
          : actions.isNotEmpty
          ? ''
          : (preview['actions'] as List?)?.isNotEmpty == true
          ? 'The reversible entry is outside this page. Show more entries and check again.'
          : reasons.isEmpty
          ? 'No reversible entry found.'
          : reasons.join('\n');
      setState(() {
        _preview = preview;
        _latestShown = latest;
      });
      widget.onActionsChanged(actions);
    } catch (e) {
      if (mounted && revision == _viewRevision) {
        checkError = _soaCorrectionError(e);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (revision == _viewRevision && checkError.isNotEmpty) {
          showInfoDialog(
            context,
            'Cannot reverse entry',
            checkError.replaceAll(
              'Regenerate or remove the later draft bill first',
              'Delete the un-released or draft bill before reversing further.',
            ),
          );
        }
      }
    }
  }

  Future<void> openEntry(
    Map<String, dynamic> action,
    Map<String, dynamic> row,
  ) async {
    if (!_latestShown || _busy || _pending != null) return;
    await _manage(action: action, row: row);
  }

  Future<void> _refresh() async {
    final revision = _viewRevision;
    try {
      final preview = Map<String, dynamic>.from(await _call('preview') as Map);
      if (!mounted || revision != _viewRevision) return;
      setState(() {
        _preview = preview;
        _error = '';
      });
    } catch (e) {
      if (mounted && revision == _viewRevision) {
        setState(() => _error = e.toString());
      }
    }
  }

  String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  String _money(dynamic value, {bool debt = false}) {
    final amount = num.tryParse(value?.toString() ?? '');
    return amount == null ? '—' : (debt ? -amount : amount).toStringAsFixed(2);
  }

  String _label(String? op) => switch (op) {
    'unrelease_bill' => 'Un-release bill',
    'unrelease_payment' => 'Un-release payment',
    'remove_payment_apply' => 'Remove application',
    'close_correction' => 'Legacy workflow completed',
    _ => 'Reverse entry',
  };
  Future<void> _manage({
    Map<String, dynamic>? action,
    Map<String, dynamic>? row,
  }) async {
    final revision = _viewRevision;
    setState(() => _busy = true);
    if (action == null) await _refresh();
    if (!mounted) return;
    Map<String, dynamic> preview = _preview;
    if (action != null) {
      try {
        final checked = Map<String, dynamic>.from(
          await _call('preview', {'target_soa_id': action['target_soa_id']})
              as Map,
        );
        if (!mounted) return;
        if (revision != _viewRevision) {
          setState(() => _busy = false);
          return;
        }
        if (checked['top_soa_id']?.toString() !=
                preview['top_soa_id']?.toString() ||
            checked['max_soa_id']?.toString() !=
                preview['max_soa_id']?.toString() ||
            checked['allowed'] != true ||
            checked['op_type'] != action['op_type']) {
          throw PagRequestRejected(
            'This entry changed or is no longer reversible. Refresh the list and check again.',
          );
        }
        preview = checked;
      } catch (e) {
        if (mounted) {
          setState(() {
            _busy = false;
            _error = e.toString();
          });
        }
        widget.onActionsChanged({});
        return;
      }
    }
    // Retain the selected entry when an account refresh moves to the next SOA row.
    Map<String, dynamic> entryPreview = Map<String, dynamic>.from(preview);
    List<dynamic> history = [];
    Map<String, dynamic>? reconciliation;
    bool reconciliationFromRejectedOperation = false;
    Map<String, dynamic>? pending = _pending;
    String message = _error;
    bool working = false;
    bool awaitingConfirmation = false;
    bool operationCompleted = false;
    String completionMessage = '';
    final reason = TextEditingController();
    try {
      history = List<dynamic>.from(await _call('history') as List);
    } catch (e) {
      message = e.toString();
    }
    if (!mounted || (action != null && revision != _viewRevision)) {
      if (mounted) setState(() => _busy = false);
      reason.dispose();
      return;
    }
    setState(() => _sheetOpen = true);
    ModalRoute<void>? sheetRoute;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: false,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      constraints: const BoxConstraints(maxWidth: 760),
      builder: (dialogContext) {
        sheetRoute = ModalRoute.of<void>(dialogContext);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(dialogContext).bottom,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: min(860, constraints.maxHeight * .94),
              ),
              child: Theme(
                data: _soaSheetTheme(context),
                child: StatefulBuilder(
                  builder: (context, change) {
                    Future<void> refresh() async {
                      final data = Map<String, dynamic>.from(
                        await _call('preview', {
                              if (action != null && !operationCompleted)
                                'target_soa_id': action['target_soa_id'],
                            })
                            as Map,
                      );
                      preview = data;
                      if (action != null && !operationCompleted) {
                        entryPreview = data;
                      }
                      history = List<dynamic>.from(
                        await _call('history') as List,
                      );
                    }

                    Future<void> perform(
                      Map<String, dynamic>? operationAction,
                    ) async {
                      change(() {
                        working = true;
                        message = '';
                        reconciliation = null;
                        reconciliationFromRejectedOperation = false;
                      });
                      try {
                        if (pending == null) {
                          if (reason.text.trim().isEmpty) {
                            throw Exception(
                              'Enter a reason for this operation.',
                            );
                          }
                          if (operationAction == null) {
                            throw Exception('Select an entry to reverse.');
                          }
                          final op = operationAction['op_type'].toString();
                          awaitingConfirmation = true;
                          var confirmed = false;
                          await showDialog<void>(
                            context: context,
                            builder: (ctx) => WgtConfirmBox(
                              title: _label(op),
                              titleWidget: Row(
                                children: [
                                  Icon(
                                    Symbols.undo,
                                    color: Theme.of(ctx).colorScheme.error,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _label(op),
                                      style: TextStyle(
                                        color: Theme.of(ctx).colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              opName: op,
                              itemCount: 1,
                              contentWidget: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_label(op)} for SOA entry ${operationAction['target_soa_id']}? The original entry will be archived.',
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Reason: ${reason.text.trim()}'),
                                ],
                              ),
                              onConfirm: () => confirmed = true,
                            ),
                          );
                          awaitingConfirmation = false;
                          if (!confirmed) return;
                          pending = {
                            'op_id': _uuid(),
                            'op_type': op,
                            'reason': reason.text.trim(),
                            'target_soa_id': operationAction['target_soa_id'],
                            'expected_top_soa_id': preview['top_soa_id'],
                            'expected_max_soa_id': preview['max_soa_id'],
                          };
                        }
                        _pending = pending;
                        final result = Map<String, dynamic>.from(
                          await _call('commit', pending!) as Map,
                        );
                        if (result['rejected'] == true) {
                          throw PagRequestRejected(
                            result['message'].toString(),
                          );
                        }
                        if (result['uncertain'] == true) {
                          throw Exception(result['message']);
                        }
                        pending = null;
                        _pending = null;
                        operationCompleted = true;
                        reason.clear();
                        reconciliation = Map<String, dynamic>.from(
                          result['reconciliation'] as Map,
                        );
                        preview = {
                          ...preview,
                          'allowed': false,
                          'actions': <dynamic>[],
                          'reasons': <dynamic>[],
                        };
                        widget.onActionsChanged({});
                        widget.onChanged();
                        final completedAction = switch (result['op_type']) {
                          'unrelease_payment' => 'Payment un-released',
                          'unrelease_bill' => 'Bill un-released',
                          'remove_payment_apply' => 'Payment Apply removed',
                          _ => null,
                        };
                        message =
                            result['outcome'] == 'completed' &&
                                completedAction != null
                            ? 'Operation completed. $completedAction.'
                            : 'Operation completed.';
                        completionMessage = message;
                        try {
                          await refresh();
                        } catch (e) {
                          message =
                              'Operation completed. Could not refresh details: $e';
                        }
                      } catch (e) {
                        message = _soaCorrectionError(e);
                        reconciliation = _soaReconciliationFailure(e);
                        reconciliationFromRejectedOperation =
                            e is PagRequestRejected && reconciliation != null;
                        if (e is PagRequestRejected) {
                          pending = null;
                          _pending = null;
                          widget.onActionsChanged({});
                          try {
                            await refresh();
                          } catch (refreshError) {
                            message =
                                '$message\nCould not refresh details: $refreshError';
                            preview = {...preview, 'allowed': false};
                          }
                        }
                      } finally {
                        awaitingConfirmation = false;
                        if (context.mounted) change(() => working = false);
                      }
                    }

                    final actions = action == null
                        ? <dynamic>[]
                        : <dynamic>[action];
                    final target = entryPreview['target'] as Map?;
                    final selectedEntry = <String, dynamic>{
                      ...?row,
                      if (target != null) ...Map<String, dynamic>.from(target),
                    };
                    final theme = Theme.of(context);
                    final colors = theme.colorScheme;
                    final showCompletedNotice =
                        operationCompleted &&
                        message.startsWith('Operation completed');
                    final primaryActions = <Widget>[
                      if (pending != null)
                        _SoaActionButton(
                          onPressed: working ? null : () => perform(null),
                          working: working && !awaitingConfirmation,
                          label: 'Retry operation',
                        ),
                      if (pending == null &&
                          !operationCompleted &&
                          preview['allowed'] == true)
                        for (final operation in actions)
                          _SoaActionButton(
                            onPressed: working
                                ? null
                                : () => perform(
                                    Map<String, dynamic>.from(operation as Map),
                                  ),
                            working: working && !awaitingConfirmation,
                            label: _label(operation['op_type']?.toString()),
                          ),
                    ];
                    final secondaryActions = <Widget>[
                      TextButton.icon(
                        onPressed: working
                            ? null
                            : () async {
                                change(() => working = true);
                                try {
                                  await refresh();
                                  message = operationCompleted
                                      ? completionMessage
                                      : '';
                                } catch (e) {
                                  message = e.toString();
                                }
                                if (context.mounted) {
                                  change(() => working = false);
                                }
                              },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Refresh'),
                      ),
                      TextButton.icon(
                        onPressed: working
                            ? null
                            : () async {
                                change(() {
                                  working = true;
                                  message = '';
                                  reconciliation = null;
                                  reconciliationFromRejectedOperation = false;
                                });
                                try {
                                  reconciliation = Map<String, dynamic>.from(
                                    await _call('reconcile') as Map,
                                  );
                                } catch (e) {
                                  message = _soaCorrectionError(e);
                                  reconciliation = _soaReconciliationFailure(e);
                                }
                                if (context.mounted) {
                                  change(() => working = false);
                                }
                              },
                        icon: const Icon(Icons.fact_check_outlined, size: 18),
                        label: const Text('Check balances'),
                      ),
                    ];
                    return PopScope(
                      canPop: !working,
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withValues(
                                        alpha: .12,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Icon(
                                      Symbols.undo,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          action == null
                                              ? 'Reversal history'
                                              : 'Reverse SOA entry',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          action == null
                                              ? 'View reversals and check account balances.'
                                              : 'Review the entry and provide a reason.',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            if (working && !awaitingConfirmation)
                              const LinearProgressIndicator(minHeight: 2),
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (action != null) ...[
                                      _SoaEntrySummary(
                                        entry: selectedEntry,
                                        operation: _label(
                                          action['op_type']?.toString(),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (showCompletedNotice) ...[
                                      _SoaNotice(
                                        icon: Icons.check_circle_outline,
                                        text: message,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (action != null && !operationCompleted)
                                      for (final block
                                          in (preview['reasons'] as List?) ??
                                              []) ...[
                                        _SoaNotice(
                                          icon: Icons.info_outline,
                                          text: block.toString(),
                                          attention: true,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    if (action != null && !operationCompleted)
                                      for (final application
                                          in (preview['applications']
                                                  as List?) ??
                                              []) ...[
                                        _SoaNotice(
                                          icon: Icons.link_rounded,
                                          text:
                                              'Application ${application['payment_apply_id']}: principal ${_money(application['principal'])}, interest ${_money(application['interest'])}',
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    if (action != null || pending != null) ...[
                                      TextField(
                                        controller: reason,
                                        enabled: !working && pending == null,
                                        maxLines: 1,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        decoration: InputDecoration(
                                          labelText: 'Reason (required)',
                                          alignLabelWithHint: true,
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.always,
                                          hintText:
                                              'Explain why this entry needs to be reversed.',
                                          helperText:
                                              'Saved with the reversal history.',
                                          helperMaxLines: 2,
                                          filled: true,
                                          fillColor: colors.surfaceContainerLow,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                            borderSide: BorderSide(
                                              color: colors.outlineVariant,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Eligibility is checked again when you confirm. The original entry will be archived.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                    if (message.isNotEmpty &&
                                        !showCompletedNotice) ...[
                                      const SizedBox(height: 12),
                                      _SoaNotice(
                                        icon:
                                            message.startsWith(
                                              'Operation completed',
                                            )
                                            ? Icons.check_circle_outline
                                            : Icons.info_outline,
                                        text: message,
                                        attention: !message.startsWith(
                                          'Operation completed',
                                        ),
                                      ),
                                    ],
                                    if (pending != null) ...[
                                      const SizedBox(height: 12),
                                      const _SoaNotice(
                                        icon: Icons.pending_outlined,
                                        text:
                                            'The operation has not been confirmed. Retry to confirm the result before starting another operation.',
                                        attention: true,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    if (action != null) ...[
                                      _SoaDetails(
                                        title: 'Entry details',
                                        tooltip:
                                            'View all fields for the selected SOA entry.',
                                        details: selectedEntry,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (action != null &&
                                        entryPreview['source'] != null) ...[
                                      _SoaDetails(
                                        title: 'Source details',
                                        tooltip: operationCompleted
                                            ? 'View the source details captured before this reversal.'
                                            : 'View the bill, payment or application linked to this entry.',
                                        details: entryPreview['source'],
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (reconciliation != null) ...[
                                      _SoaPanel(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              '${reconciliationFromRejectedOperation ? 'Attempted operation balance check' : 'Balance check'}: ${reconciliation!['passed'] == true ? 'Passed' : 'Needs attention'}',
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    color:
                                                        reconciliation!['passed'] ==
                                                            true
                                                        ? null
                                                        : colors.error,
                                                  ),
                                            ),
                                            const SizedBox(height: 12),
                                            if (reconciliationFromRejectedOperation) ...[
                                              const Text(
                                                'The operation was rejected and no changes were saved. These figures describe the attempted change.',
                                              ),
                                              const SizedBox(height: 12),
                                            ],
                                            _SoaValues(
                                              values: {
                                                'Balance owed': _money(
                                                  reconciliation!['total'],
                                                  debt: true,
                                                ),
                                                'Principal': _money(
                                                  reconciliation!['principal'],
                                                  debt: true,
                                                ),
                                                'Interest': _money(
                                                  reconciliation!['interest'],
                                                  debt: true,
                                                ),
                                                'Unapplied funds': _money(
                                                  reconciliation!['unapplied'],
                                                ),
                                              },
                                            ),
                                            for (final issue
                                                in (reconciliation!['issues']
                                                        as List?) ??
                                                    [])
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 12,
                                                ),
                                                child: _SoaNotice(
                                                  icon: Icons.info_outline,
                                                  text: _soaReconciliationIssue(
                                                    issue,
                                                  ),
                                                  attention: true,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    _SoaPanel(
                                      padding: EdgeInsets.zero,
                                      child: ExpansionTile(
                                        tilePadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        childrenPadding:
                                            const EdgeInsets.fromLTRB(
                                              12,
                                              0,
                                              12,
                                              12,
                                            ),
                                        shape: const Border(),
                                        collapsedShape: const Border(),
                                        title: Tooltip(
                                          waitDuration: const Duration(
                                            milliseconds: 500,
                                          ),
                                          message:
                                              'View previous reversals, including who made them and why.',
                                          child: Text(
                                            'Reversal history',
                                            style: theme.textTheme.titleSmall,
                                          ),
                                        ),
                                        subtitle: Text(
                                          history.isEmpty
                                              ? 'No reversals recorded'
                                              : '${history.length} recorded ${history.length == 1 ? 'operation' : 'operations'}',
                                        ),
                                        children: [
                                          if (history.isEmpty)
                                            const Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Completed operations will appear here.',
                                              ),
                                            ),
                                          for (final record in history)
                                            ExpansionTile(
                                              tilePadding: EdgeInsets.zero,
                                              childrenPadding:
                                                  const EdgeInsets.only(
                                                    bottom: 12,
                                                  ),
                                              title: Text(
                                                _label(
                                                  record['op_type']?.toString(),
                                                ),
                                              ),
                                              subtitle: Text(
                                                '${_soaDate(record['op_timestamp'])} · ${record['op_username']}\n${record['reason']}',
                                              ),
                                              children: [
                                                if (record['billing_rec_id'] !=
                                                    null)
                                                  Text(
                                                    'Bill: ${record['billing_rec_id']}',
                                                  ),
                                                if (record['payment_id'] !=
                                                    null)
                                                  Text(
                                                    'Payment: ${record['payment_id']}',
                                                  ),
                                                if (record['source_status_before'] !=
                                                    null)
                                                  Text(
                                                    'Status: ${record['source_status_before']} → ${record['source_status_after']}',
                                                  ),
                                                if (record['outcome'] != null)
                                                  Text(
                                                    'Outcome: ${record['outcome']}',
                                                  ),
                                                _SoaDetails(
                                                  title: 'Archived details',
                                                  details: record,
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _SoaFooter(
                              primaryActions: primaryActions,
                              secondaryActions: secondaryActions,
                              onDone: working
                                  ? null
                                  : () => Navigator.pop(dialogContext),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    // Keep the controller alive until the closing animation removes the field.
    await sheetRoute?.completed;
    reason.dispose();
    if (mounted && action == null) await _refresh();
    if (mounted) {
      setState(() {
        _busy = false;
        _sheetOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          WgtCommButton(
            label: _pending != null ? 'Retry operation' : 'History / balances',
            enabled: !_busy,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSecondary,
              fontSize: 13.5,
            ),
            onPressed: () {
              unawaited(_manage());
            },
          ),
          Tooltip(
            waitDuration: const Duration(milliseconds: 500),
            message: !_latestShown && _error.isEmpty
                ? 'Show the latest entries to check for a reversal.'
                : '',
            child: WgtCommButton(
              label: 'Check reversible entry',
              enabled: _latestShown && !_busy && _pending == null,
              inComm: _busy && !_sheetOpen,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSecondary,
                fontSize: 13.5,
              ),
              onPressed: _checkEntries,
            ),
          ),
        ],
      ),
      if (_error.isNotEmpty)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            _error,
            softWrap: true,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ],
  );
}

ThemeData _soaSheetTheme(BuildContext context) {
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  final border = colors.onSurface.withValues(alpha: .16);
  final primary = colors.brightness == Brightness.light
      ? Color.alphaBlend(Colors.black.withValues(alpha: .32), colors.primary)
      : colors.primary;
  return theme.copyWith(
    colorScheme: colors.copyWith(
      primary: primary,
      onPrimary: primary.computeLuminance() > .4 ? Colors.black : Colors.white,
      onSurfaceVariant: colors.onSurface.withValues(alpha: .65),
      outlineVariant: border,
      surfaceContainerLow: Color.alphaBlend(
        colors.onSurface.withValues(alpha: .045),
        colors.surface,
      ),
    ),
    dividerColor: border,
    textButtonTheme: TextButtonThemeData(
      style: (theme.textButtonTheme.style ?? const ButtonStyle()).copyWith(
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
        ),
      ),
    ),
    tooltipTheme: theme.tooltipTheme.copyWith(
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(5),
      ),
    ),
  );
}

class _SoaPanel extends StatelessWidget {
  const _SoaPanel({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 5,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: child,
  );
}

class _SoaNotice extends StatelessWidget {
  const _SoaNotice({
    required this.icon,
    required this.text,
    this.attention = false,
  });
  final IconData icon;
  final String text;
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = attention ? colors.error : colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

const _soaReconciliationErrorPrefixes = [
  'Reconciliation failed:',
  'Reconciliation must pass before closing:',
];

Map<String, dynamic>? _soaReconciliationFailure(Object error) {
  final message = error.toString();
  for (final prefix in _soaReconciliationErrorPrefixes) {
    final start = message.indexOf(prefix);
    if (start < 0) continue;
    try {
      final value = jsonDecode(message.substring(start + prefix.length).trim());
      if (value is Map && value['passed'] == false && value['issues'] is List) {
        return Map<String, dynamic>.from(value);
      }
    } on FormatException {
      return null;
    }
  }
  return null;
}

String _soaReconciliationIssue(dynamic issue) {
  if (issue is! Map) return issue.toString();
  final source = switch (issue['table']) {
    'billing_rec' => 'Bill',
    'payment' => 'Payment',
    'payment_apply' => 'Payment Apply',
    'tenant_soa' => 'SOA entry',
    _ => 'Record',
  };
  final message = switch (issue['message']) {
    'Invoice remaining amount differs' =>
      'Remaining amount does not match the bill total minus applied payments.',
    'Balance or bucket projection differs' =>
      'Stored balances do not match the SOA entries.',
    'Payment status or availability differs' =>
      'Payment status or available amount does not match its applications.',
    final value => value?.toString() ?? 'Balance check needs attention.',
  };
  return '$source${issue['id'] == null ? '' : ' #${issue['id']}'}: $message';
}

String _soaCorrectionError(Object error) {
  final failure = _soaReconciliationFailure(error);
  if (failure != null) {
    return 'Balance check failed.\n${(failure['issues'] as List).map(_soaReconciliationIssue).join('\n')}';
  }
  if (_soaReconciliationErrorPrefixes.any(error.toString().contains)) {
    return 'Balance check failed. Refresh the account and check balances for details.';
  }
  return error.toString();
}

String _soaDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return value?.toString() ?? '—';
  return DateFormat(
    date.hour == 0 && date.minute == 0 && date.second == 0
        ? 'dd MMM yyyy'
        : 'dd MMM yyyy · HH:mm',
  ).format(date);
}

String _soaValue(String field, dynamic value) {
  if (field.contains('timestamp')) return _soaDate(value);
  if (const {
    'credit_amount',
    'debit_amount',
    'change_usage',
    'change_interest',
    'balance',
    'balance_usage',
    'balance_interest',
    'principal',
    'interest',
  }.contains(field)) {
    return num.tryParse(value?.toString() ?? '')?.toStringAsFixed(2) ?? '—';
  }
  if (value is Map || value is List) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }
  return value?.toString() ?? '—';
}

class _SoaEntrySummary extends StatelessWidget {
  const _SoaEntrySummary({required this.entry, required this.operation});
  final Map<String, dynamic> entry;
  final String operation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entryValue = entry['entry_type']?.toString();
    final entryType = PagSoaEntryType.values
        .where((type) => type.value == entryValue || type.tag == entryValue)
        .firstOrNull;
    final type = switch (entry['entry_type']?.toString()) {
      'payment' => 'Payment',
      'bill' => 'Bill',
      'pya' || 'payment_apply' => 'Payment Apply',
      final value => value ?? 'Entry',
    };
    return _SoaPanel(
      borderRadius: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Action: $operation',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          Text(
            'SELECTED ENTRY',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (entryType != null) ...[
                Container(
                  constraints: const BoxConstraints(minHeight: 23),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: entryType.color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    entryType.tag,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  '$type · #${entry['id'] ?? '—'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _soaDate(entry['entry_timestamp']),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final field in [
                'billing_rec_id',
                'payment_id',
                'payment_apply_id',
                'credit_amount',
                'debit_amount',
                'change_usage',
                'change_interest',
                'balance',
                'balance_usage',
                'balance_interest',
              ])
                if (entry[field] != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 130),
                    child: Semantics(
                      label:
                          '${_fieldLabel(field)}: ${_soaValue(field, entry[field])}',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fieldLabel(field),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _soaValue(field, entry[field]),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SoaValues extends StatelessWidget {
  const _SoaValues({required this.values});
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final entry in values.entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: SelectableText(entry.value.toString())),
            ],
          ),
        ),
    ],
  );
}

class _SoaDetails extends StatelessWidget {
  const _SoaDetails({required this.title, required this.details, this.tooltip});
  final String title;
  final dynamic details;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => _SoaPanel(
    padding: EdgeInsets.zero,
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Tooltip(
        message: tooltip ?? '',
        waitDuration: const Duration(milliseconds: 500),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      children: [
        if (details is Map)
          _SoaValues(
            values: {
              for (final entry in (details as Map).entries)
                _fieldLabel(entry.key.toString()): _soaValue(
                  entry.key.toString(),
                  entry.value,
                ),
            },
          )
        else
          SelectableText(_soaValue('', details)),
      ],
    ),
  );
}

class _SoaActionButton extends StatelessWidget {
  const _SoaActionButton({
    required this.label,
    required this.working,
    required this.onPressed,
  });
  final String label;
  final bool working;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(
      TextStyle(
        color: Theme.of(context).colorScheme.onSecondary,
        fontSize: 13.5,
      ),
    );
    final labelSize = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = labelSize.width + 26 + (working ? 29 : 0);
    labelSize.dispose();
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: LayoutBuilder(
        builder: (context, constraints) => WgtCommButton(
          label: label,
          width: min(width, constraints.maxWidth),
          enabled: onPressed != null,
          inComm: working,
          labelStyle: style,
          labelWidget: Flexible(
            child: Text(label, style: style, textAlign: TextAlign.center),
          ),
          // The sheet owns the busy state, including the confirmation dialog.
          onPressed: onPressed == null
              ? null
              : () {
                  onPressed!();
                },
        ),
      ),
    );
  }
}

class _SoaFooter extends StatelessWidget {
  const _SoaFooter({
    required this.primaryActions,
    required this.secondaryActions,
    required this.onDone,
  });
  final List<Widget> primaryActions;
  final List<Widget> secondaryActions;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final done = TextButton(onPressed: onDone, child: const Text('Done'));
        final primary = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: primaryActions,
        );
        final secondary = Wrap(
          spacing: 4,
          runSpacing: 4,
          children: secondaryActions,
        );
        if (constraints.maxWidth < 600 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.2) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              secondary,
              const SizedBox(height: 8),
              Row(
                children: [
                  done,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: primary,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: secondary),
            done,
            const SizedBox(width: 8),
            primary,
          ],
        );
      },
    ),
  );
}

String _fieldLabel(String field) =>
    const {
      'billing_rec_id': 'Bill ID',
      'payment_id': 'Payment ID',
      'payment_apply_id': 'Application ID',
      'credit_amount': 'Credit',
      'debit_amount': 'Debit',
      'change_usage': 'Principal movement',
      'change_interest': 'Interest movement',
      'balance': 'Balance',
      'balance_usage': 'Principal balance',
      'balance_interest': 'Interest balance',
      'id': 'ID',
      'entry_type': 'Entry type',
      'entry_timestamp': 'Entry date',
      'op_timestamp': 'Operation date',
      'principal': 'Principal',
      'interest': 'Interest',
    }[field] ??
    field.replaceAll('_', ' ');

bool soaListShowsLatest(
  List<Map<String, dynamic>> rows,
  Map<String, dynamic> query,
  dynamic topId,
) {
  if (topId == null || rows.isEmpty) return false;
  if (int.tryParse(query['current_page']?.toString() ?? '') != 1) return false;
  if (query['sort_by']?.toString() != 'entry_timestamp' ||
      query['sort_order']?.toString() != 'desc') {
    return false;
  }
  return rows.any((row) => row['id']?.toString() == topId.toString());
}

Map<String, Map<String, dynamic>> soaActionsByRow(
  Map<String, dynamic> preview,
  List<Map<String, dynamic>> rows,
) {
  final visibleIds = rows.map((row) => row['id']?.toString()).toSet();
  final result = <String, Map<String, dynamic>>{};
  for (final value in (preview['actions'] as List?) ?? []) {
    final action = Map<String, dynamic>.from(value as Map);
    final id = action['target_soa_id']?.toString();
    if (id != null && visibleIds.contains(id)) result[id] = action;
  }
  return result;
}
