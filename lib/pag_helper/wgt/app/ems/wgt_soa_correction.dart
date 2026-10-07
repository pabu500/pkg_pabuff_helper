import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import '../../../comm/comm_ex.dart';
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
    required this.onHoldChanged,
    required this.onActionsChanged,
    this.request,
  });
  final MdlPagAppConfig appConfig;
  final MdlPagUser user;
  final String tenantId;
  final VoidCallback onChanged;
  final ValueChanged<bool> onHoldChanged;
  final ValueChanged<Map<String, Map<String, dynamic>>> onActionsChanged;
  final Future<dynamic> Function(String, Map<String, dynamic>)? request;
  @override
  State<WgtSoaCorrection> createState() => WgtSoaCorrectionState();
}

class WgtSoaCorrectionState extends State<WgtSoaCorrection> {
  Map<String, dynamic> _preview = {};
  String? _correctionId;
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
      opStr: 'manage account correction',
      structuredErrors: true,
      appConfig: widget.appConfig,
      queryMap: {
        'scope': widget.user.selectedScope.toScopeMap(),
        'tenant_id': widget.tenantId,
        if (_correctionId != null && action != 'commit')
          'correction_op_id': _correctionId,
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
        _correctionId = preview['correction_op_id']?.toString();
        _latestShown = soaListShowsLatest(
          _visibleRows,
          _listQuery,
          preview['top_soa_id'],
        );
        _error = '';
      });
      widget.onHoldChanged(_correctionId != null);
    } catch (e) {
      if (mounted && revision == _viewRevision) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _checkEntries() async {
    if (!_latestShown || _busy) return;
    final revision = _viewRevision;
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
      setState(() {
        _preview = preview;
        _correctionId = preview['correction_op_id']?.toString();
        _latestShown = latest;
        _error = !latest
            ? 'The latest entries changed. Refresh the list and check again.'
            : actions.isNotEmpty
            ? ''
            : (preview['actions'] as List?)?.isNotEmpty == true
            ? 'The reversible entry is outside this page. Show more entries and check again.'
            : ((preview['reasons'] as List?) ?? ['No reversible entry found.'])
                  .join('\n');
      });
      widget.onActionsChanged(actions);
      widget.onHoldChanged(_correctionId != null);
    } catch (e) {
      if (mounted && revision == _viewRevision) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
        _correctionId = preview['correction_op_id']?.toString();
        _error = '';
      });
      widget.onHoldChanged(_correctionId != null);
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
    _ => 'Close correction',
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
    List<dynamic> history = [];
    Map<String, dynamic>? reconciliation;
    Map<String, dynamic>? pending = _pending;
    String message = _error;
    bool working = false;
    final reason = TextEditingController();
    String outcome = 'completed';
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 1000),
      builder: (dialogContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(dialogContext).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(dialogContext).height * .85,
          child: StatefulBuilder(
            builder: (context, change) {
              Future<void> refresh() async {
                final data = Map<String, dynamic>.from(
                  await _call('preview', {
                        if (action != null)
                          'target_soa_id': action['target_soa_id'],
                      })
                      as Map,
                );
                _correctionId = data['correction_op_id']?.toString();
                preview = data;
                history = List<dynamic>.from(await _call('history') as List);
              }

              Future<void> perform(
                Map<String, dynamic>? operationAction,
              ) async {
                change(() {
                  working = true;
                  message = '';
                });
                try {
                  if (pending == null) {
                    if (reason.text.trim().isEmpty) {
                      throw Exception('Enter a reason for this operation.');
                    }
                    final op =
                        operationAction?['op_type']?.toString() ??
                        'close_correction';
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(_label(op)),
                        content: Text(
                          op == 'close_correction'
                              ? 'Close this correction after checking source statuses and balances? Reason: ${reason.text.trim()}'
                              : '${_label(op)} for SOA entry ${operationAction?['target_soa_id']}? The original entry will be archived. Reason: ${reason.text.trim()}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    pending = {
                      'op_id': _uuid(),
                      'op_type': op,
                      'reason': reason.text.trim(),
                      if (_correctionId != null)
                        'correction_op_id': _correctionId,
                      if (op == 'close_correction') 'outcome': outcome,
                      if (op != 'close_correction') ...{
                        'target_soa_id': operationAction?['target_soa_id'],
                        'expected_top_soa_id': preview['top_soa_id'],
                        'expected_max_soa_id': preview['max_soa_id'],
                      },
                    };
                  }
                  _pending = pending;
                  final result = Map<String, dynamic>.from(
                    await _call('commit', pending!) as Map,
                  );
                  if (result['rejected'] == true) {
                    throw PagRequestRejected(result['message'].toString());
                  }
                  if (result['uncertain'] == true) {
                    throw Exception(result['message']);
                  }
                  pending = null;
                  _pending = null;
                  _correctionId = result['outcome'] != null
                      ? null
                      : result['correction_op_id']?.toString();
                  reason.clear();
                  reconciliation = Map<String, dynamic>.from(
                    result['reconciliation'] as Map,
                  );
                  preview = {
                    ...preview,
                    'allowed': false,
                    'actions': <dynamic>[],
                  };
                  widget.onActionsChanged({});
                  widget.onHoldChanged(_correctionId != null);
                  widget.onChanged();
                  message = 'Operation completed.';
                  try {
                    await refresh();
                  } catch (e) {
                    message =
                        'Operation completed. Could not refresh details: $e';
                  }
                } catch (e) {
                  message = e.toString();
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
                  if (context.mounted) change(() => working = false);
                }
              }

              final actions = action == null ? <dynamic>[] : <dynamic>[action];
              final target = preview['target'] as Map?;
              final selectedEntry = <String, dynamic>{
                ...?row,
                if (target != null) ...Map<String, dynamic>.from(target),
              };
              return PopScope(
                canPop: !working,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        action == null
                            ? 'Manage correction'
                            : 'Reverse SOA entry',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Eligibility is checked again on the server when you confirm the reversal.',
                              ),
                              if (_correctionId != null)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'Correction in progress. Automatic billing, matching and GIRO are paused. Delete or re-release the affected bill, and re-release affected payments in date order, before closing. To reapply a payment now, open its matching form and confirm that it is part of this correction. Unapplied funds may remain when closing.',
                                  ),
                                ),
                              if (target != null)
                                Text(
                                  'Entry: ${target['entry_type']} · ${target['entry_timestamp']} · ${target['id']}',
                                ),
                              for (final block
                                  in (preview['reasons'] as List?) ?? [])
                                Text(
                                  block.toString(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              for (final application
                                  in (preview['applications'] as List?) ?? [])
                                Text(
                                  'Application ${application['payment_apply_id']}: principal ${application['principal']}, interest ${application['interest']}',
                                ),
                              if (action != null && row != null) ...[
                                const Divider(),
                                Text(
                                  'Selected entry: ${selectedEntry['entry_type']} · ${selectedEntry['entry_timestamp']} · ${selectedEntry['id']}',
                                ),
                                Text(
                                  'Action: ${_label(action['op_type']?.toString())}',
                                ),
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
                                  if (selectedEntry[field] != null)
                                    Text(
                                      '${_fieldLabel(field)}: ${selectedEntry[field]}',
                                    ),
                              ],
                              if (action != null)
                                ExpansionTile(
                                  title: const Text('Entry details'),
                                  children: [
                                    SelectableText(
                                      const JsonEncoder.withIndent(
                                        '  ',
                                      ).convert(selectedEntry),
                                    ),
                                  ],
                                ),
                              if (action != null && preview['source'] != null)
                                ExpansionTile(
                                  title: const Text('Source details'),
                                  children: [
                                    SelectableText(
                                      const JsonEncoder.withIndent(
                                        '  ',
                                      ).convert(preview['source']),
                                    ),
                                  ],
                                ),
                              TextField(
                                controller: reason,
                                enabled: !working && pending == null,
                                minLines: 1,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Reason (required)',
                                ),
                              ),
                              if (_correctionId != null)
                                DropdownButton<String>(
                                  value: outcome,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'completed',
                                      child: Text('Completed'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'abandoned',
                                      child: Text('Abandoned'),
                                    ),
                                  ],
                                  onChanged: working || pending != null
                                      ? null
                                      : (value) =>
                                            change(() => outcome = value!),
                                ),
                              if (message.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: SelectableText(message),
                                ),
                              if (pending != null)
                                const Text(
                                  'The operation has not been confirmed. Retry uses the same operation ID. Retry to confirm the result before starting another operation.',
                                ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (pending != null)
                                    FilledButton(
                                      onPressed: working
                                          ? null
                                          : () => perform(null),
                                      child: const Text('Retry operation'),
                                    ),
                                  if (pending == null &&
                                      preview['allowed'] == true)
                                    for (final action in actions)
                                      FilledButton(
                                        onPressed: working
                                            ? null
                                            : () => perform(
                                                Map<String, dynamic>.from(
                                                  action as Map,
                                                ),
                                              ),
                                        child: Text(
                                          _label(action['op_type']?.toString()),
                                        ),
                                      ),
                                  if (action == null &&
                                      _correctionId != null &&
                                      pending == null)
                                    FilledButton(
                                      onPressed: working
                                          ? null
                                          : () => perform(null),
                                      child: const Text('Close correction'),
                                    ),
                                  TextButton(
                                    onPressed: working
                                        ? null
                                        : () async {
                                            change(() => working = true);
                                            try {
                                              await refresh();
                                              message = '';
                                            } catch (e) {
                                              message = e.toString();
                                            }
                                            if (context.mounted) {
                                              change(() => working = false);
                                            }
                                          },
                                    child: const Text('Refresh'),
                                  ),
                                  TextButton(
                                    onPressed: working
                                        ? null
                                        : () async {
                                            change(() => working = true);
                                            try {
                                              reconciliation =
                                                  Map<String, dynamic>.from(
                                                    await _call('reconcile')
                                                        as Map,
                                                  );
                                            } catch (e) {
                                              message = e.toString();
                                            }
                                            if (context.mounted) {
                                              change(() => working = false);
                                            }
                                          },
                                    child: const Text('Check balances'),
                                  ),
                                ],
                              ),
                              if (reconciliation != null)
                                SelectableText(
                                  'Balance check: ${reconciliation!['passed'] == true ? 'Passed' : 'Needs attention'}\nBalance owed: ${_money(reconciliation!['total'], debt: true)} · Principal: ${_money(reconciliation!['principal'], debt: true)} · Interest: ${_money(reconciliation!['interest'], debt: true)} · Unapplied funds: ${_money(reconciliation!['unapplied'])}\n${(reconciliation!['issues'] as List?)?.isEmpty == true ? '' : reconciliation!['issues']}',
                                ),
                              const Divider(),
                              const Text('Correction history'),
                              for (final row in history)
                                ExpansionTile(
                                  title: Text(
                                    '${_label(row['op_type']?.toString())} · ${row['op_timestamp']}',
                                  ),
                                  subtitle: Text(
                                    '${row['op_username']} · ${row['reason']}',
                                  ),
                                  children: [
                                    if (row['billing_rec_id'] != null)
                                      Text('Bill: ${row['billing_rec_id']}'),
                                    if (row['payment_id'] != null)
                                      Text('Payment: ${row['payment_id']}'),
                                    if (row['source_status_before'] != null)
                                      Text(
                                        'Status: ${row['source_status_before']} → ${row['source_status_after']}',
                                      ),
                                    if (row['outcome'] != null)
                                      Text('Outcome: ${row['outcome']}'),
                                    ExpansionTile(
                                      title: const Text('Archived details'),
                                      children: [
                                        SelectableText(
                                          const JsonEncoder.withIndent(
                                            '  ',
                                          ).convert(row),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: working
                              ? null
                              : () => Navigator.pop(dialogContext),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
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
      WgtCommButton(
        label: 'Check reversible entry',
        enabled: _latestShown && !_busy && _pending == null,
        inComm: _busy && !_sheetOpen,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSecondary,
          fontSize: 13.5,
        ),
        onPressed: _checkEntries,
      ),
      if (_pending != null || _correctionId != null)
        TextButton(
          onPressed: _busy ? null : () => _manage(),
          child: Text(
            _pending != null ? 'Retry operation' : 'Manage correction',
          ),
        ),
      if (!_latestShown && _error.isEmpty)
        const Text('Show the latest entries to check for a reversal.'),
      if (_correctionId != null)
        const Text(
          'Correction in progress — billing, matching and GIRO paused.',
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
    }[field] ??
    field;

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
