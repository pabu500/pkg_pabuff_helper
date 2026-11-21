import 'package:material_ui/material_ui.dart';
import 'package:buff_helper/pagrid_helper/batch_op_helper/wgt_confirm_box.dart';

class WgtTenantReopenDialog extends StatefulWidget {
  const WgtTenantReopenDialog({
    super.key,
    required this.tenantName,
    required this.info,
    required this.onConfirm,
  });
  final String tenantName;
  final Map<String, dynamic> info;
  final ValueChanged<Map<String, dynamic>> onConfirm;
  @override
  State<WgtTenantReopenDialog> createState() => _ReopenDialogState();
}

class _ReopenDialogState extends State<WgtTenantReopenDialog> {
  String _reason = '';
  bool _acknowledged = false;
  bool get _needsAck => widget.info['requires_naming_acknowledgement'] == true;
  bool get _valid =>
      widget.info['eligible'] == true &&
      _reason.trim().length >= 10 &&
      _reason.trim().length <= 500 &&
      (!_needsAck || _acknowledged);

  @override
  Widget build(BuildContext context) => WgtConfirmBox(
    title: 'Reopen Confirmation',
    opName: 'tenant_reopen',
    itemCount: 1,
    confirmEnabled: _valid,
    onConfirm: () => widget.onConfirm({
      'termination_token': widget.info['termination_token'],
      'reason': _reason.trim(),
      'acknowledge_naming': _acknowledged,
    }),
    footerWidget: SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reopen ${widget.tenantName} back to Offboarding to correct its final bill or undo a mistaken termination. Closing readings will be kept. Terminating again requires deposit confirmation again.',
          ),
          for (final reason in widget.info['reasons'] as List? ?? [])
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(reason.toString()),
            ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Reason (10–500 characters)',
            ),
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            onChanged: (value) => setState(() => _reason = value),
          ),
          for (final handover
              in widget.info['handovers_to_name'] as List? ?? []) ...[
            const SizedBox(height: 16),
            Text(
              'Meter ${handover['meter_name'] ?? handover['meter_id']} → ${handover['to_tenant_label'] ?? handover['to_tenant_id']} (handover ${handover['id']}, usage start: ${handover['usage_start'] ?? 'not saved yet'})',
            ),
            const Text(
              'This older handover will be assumed to name this tenant as a former holder.',
            ),
            for (final effect in handover['effects'] as List? ?? [])
              Text('• $effect'),
          ],
          if (_needsAck)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _acknowledged,
              onChanged: (value) =>
                  setState(() => _acknowledged = value ?? false),
              title: const Text(
                'I understand the effects of naming this tenant on these handovers',
              ),
            ),
        ],
      ),
    ),
  );
}
