import 'package:flutter/material.dart';

class WgtTenantTerminationDialog extends StatefulWidget {
  const WgtTenantTerminationDialog({
    super.key,
    required this.tenantName,
    required this.info,
  });
  final String tenantName;
  final Map<String, dynamic> info;
  @override
  State<WgtTenantTerminationDialog> createState() => _TerminationDialogState();
}

class _TerminationDialogState extends State<WgtTenantTerminationDialog> {
  bool _returned = false;
  String _remark = '';
  String _typed = '';
  @override
  Widget build(BuildContext context) {
    final bill = widget.info['final_bill'] as Map? ?? {};
    final phrase = 'terminate ${widget.tenantName}';
    return AlertDialog(
      title: const Text('Terminate tenant'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Final bill: ${bill['label'] ?? ''}'),
              Text('Released: ${bill['released_timestamp'] ?? ''}'),
              Text(
                'Unpaid bills: ${(widget.info['unpaid_bills'] as List? ?? []).length}',
              ),
              Text('SOA balance: ${widget.info['soa_balance'] ?? ''}'),
              Text(
                'Deposit amount: ${widget.info['deposit_amount'] ?? 'not recorded'}',
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _returned,
                onChanged: (v) => setState(() => _returned = v ?? false),
                title: const Text(
                  'Deposit returned to tenant (checked manually)',
                ),
              ),
              TextField(
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Remark (optional)',
                ),
                onChanged: (v) => _remark = v,
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Type "$phrase" to confirm',
                ),
                onChanged: (v) => setState(() => _typed = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _returned && _typed == phrase
              ? () => Navigator.of(context).pop({
                  'deposit_return_confirmed': 'true',
                  'deposit_return_remark': _remark,
                })
              : null,
          child: const Text('Terminate'),
        ),
      ],
    );
  }
}
