import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import '../../../comm/comm_ex.dart';
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
  });
  final MdlPagAppConfig appConfig;
  final MdlPagUser user;
  final String tenantId;
  final VoidCallback onChanged;
  final ValueChanged<bool> onHoldChanged;
  @override
  State<WgtSoaCorrection> createState() => _WgtSoaCorrectionState();
}

class _WgtSoaCorrectionState extends State<WgtSoaCorrection> {
  Map<String, dynamic> _preview = {};
  String? _correctionId;
  String _error = '';
  bool _busy = false;
  Map<String, dynamic>? _pending;
  Future<dynamic> _call(
    String action, [
    Map<String, dynamic> body = const {},
  ]) => ex(
    endpoint: '/ems/fin/soa_correction/$action',
    crudType: action == 'commit' ? 'update' : 'read',
    opStr: 'manage account correction',
    authenticated: true,
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
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final preview = Map<String, dynamic>.from(await _call('preview') as Map);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _correctionId = preview['correction_op_id']?.toString();
        _error = '';
      });
      widget.onHoldChanged(_correctionId != null);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
  Future<void> _manage() async {
    setState(() => _busy = true);
    await _refresh();
    if (!mounted) return;
    Map<String, dynamic> preview = _preview;
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
    if (!mounted) {
      reason.dispose();
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, change) {
          Future<void> refresh() async {
            final data = Map<String, dynamic>.from(
              await _call('preview') as Map,
            );
            _correctionId = data['correction_op_id']?.toString();
            preview = data;
            history = List<dynamic>.from(await _call('history') as List);
          }

          Future<void> perform(Map<String, dynamic>? action) async {
            change(() {
              working = true;
              message = '';
            });
            try {
              if (pending == null) {
                if (reason.text.trim().isEmpty)
                  throw Exception('Enter a reason for this operation.');
                final op = action?['op_type']?.toString() ?? 'close_correction';
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(_label(op)),
                    content: Text(
                      op == 'close_correction'
                          ? 'Close this correction after checking source statuses and balances? Reason: ${reason.text.trim()}'
                          : '${_label(op)} for SOA entry ${action?['target_soa_id']}? The original entry will be archived. Reason: ${reason.text.trim()}',
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
                  if (_correctionId != null) 'correction_op_id': _correctionId,
                  if (op == 'close_correction') 'outcome': outcome,
                  if (op != 'close_correction') ...{
                    'target_soa_id': action?['target_soa_id'],
                    'expected_top_soa_id': preview['top_soa_id'],
                    'expected_max_soa_id': preview['max_soa_id'],
                  },
                };
              }
              _pending = pending;
              final result = Map<String, dynamic>.from(
                await _call('commit', pending!) as Map,
              );
              if (result['rejected'] == true)
                throw PagRequestRejected(result['message'].toString());
              if (result['uncertain'] == true)
                throw Exception(result['message']);
              pending = null;
              _pending = null;
              _correctionId = result['outcome'] != null
                  ? null
                  : result['correction_op_id']?.toString();
              reason.clear();
              reconciliation = Map<String, dynamic>.from(
                result['reconciliation'] as Map,
              );
              await refresh();
              widget.onChanged();
              widget.onHoldChanged(_correctionId != null);
              message = 'Operation completed.';
            } catch (e) {
              message = e.toString();
              if (e is PagRequestRejected) {
                pending = null;
                _pending = null;
              }
            } finally {
              if (context.mounted) change(() => working = false);
            }
          }

          final actions = (preview['actions'] as List?) ?? [];
          final target = preview['target'] as Map?;
          return AlertDialog(
            title: const Text('Account correction'),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This checks the latest entry across the whole account, including entries outside the displayed dates.',
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
                        'Latest entry: ${target['entry_type']} · ${target['entry_timestamp']} · ${target['id']}',
                      ),
                    for (final block in (preview['reasons'] as List?) ?? [])
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
                            : (value) => change(() => outcome = value!),
                      ),
                    if (message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                            onPressed: working ? null : () => perform(null),
                            child: const Text('Retry operation'),
                          ),
                        if (pending == null)
                          for (final action in actions)
                            FilledButton(
                              onPressed: working
                                  ? null
                                  : () => perform(
                                      Map<String, dynamic>.from(action as Map),
                                    ),
                              child: Text(
                                _label(action['op_type']?.toString()),
                              ),
                            ),
                        if (_correctionId != null && pending == null)
                          FilledButton(
                            onPressed: working ? null : () => perform(null),
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
                                  if (context.mounted)
                                    change(() => working = false);
                                },
                          child: const Text('Refresh'),
                        ),
                        TextButton(
                          onPressed: working
                              ? null
                              : () async {
                                  change(() => working = true);
                                  try {
                                    reconciliation = Map<String, dynamic>.from(
                                      await _call('reconcile') as Map,
                                    );
                                  } catch (e) {
                                    message = e.toString();
                                  }
                                  if (context.mounted)
                                    change(() => working = false);
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
                                const JsonEncoder.withIndent('  ').convert(row),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: working ? null : () => Navigator.pop(dialogContext),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
    reason.dispose();
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      OutlinedButton(
        onPressed: _busy ? null : _manage,
        child: const Text('Account correction'),
      ),
      if (_correctionId != null)
        const Text(
          'Correction in progress — billing, matching and GIRO paused.',
        ),
      if (_error.isNotEmpty)
        Text(
          _error,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    ],
  );
}
