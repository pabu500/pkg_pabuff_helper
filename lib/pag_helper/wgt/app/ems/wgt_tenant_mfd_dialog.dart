import 'package:buff_helper/pagrid_helper/batch_op_helper/wgt_confirm_box.dart';
import 'package:material_ui/material_ui.dart';

class WgtTenantMfdDialog extends StatefulWidget {
  const WgtTenantMfdDialog({
    super.key,
    required this.tenantName,
    required this.info,
    required this.onConfirm,
  });
  final String tenantName;
  final Map<String, dynamic> info;
  final ValueChanged<Map<String, dynamic>> onConfirm;
  @override
  State<WgtTenantMfdDialog> createState() => _TenantMfdDialogState();
}

class _TenantMfdDialogState extends State<WgtTenantMfdDialog> {
  final _remark = TextEditingController();
  @override
  void dispose() {
    _remark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cancelling = widget.info['kind'] == 'cancel_onboarding';
    final groups = widget.info['assigned_meter_groups'] as List? ?? [];
    return WgtConfirmBox(
      title: 'MFD Confirmation',
      message1: 'This operation is not reversible. Are you sure to proceed?',
      message2: cancelling
          ? 'This cancels the onboarding tenant.'
          : 'This marks the terminated tenant for deletion.',
      opName: 'tenant_mfd',
      keyInConfirmStrList: ['mfd', widget.tenantName],
      itemCount: 1,
      onConfirm: () => widget.onConfirm({'mfd_remark': _remark.text.trim()}),
      footerWidget: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cancelling) ...[
              Text(
                widget.info['first_readings_saved'] == true
                    ? 'Saved first readings are kept for audit.'
                    : 'No first readings are saved.',
              ),
            ] else ...[
              const Text(
                'This marks a completed tenancy for deletion and unassigns its meter groups:',
              ),
              if (groups.isEmpty) const Text('No assigned meter groups.'),
              for (final group in groups)
                Text('• ${group['name'] ?? group['id']}'),
              const SizedBox(height: 12),
              const Text(
                "Bills, payments, readings and history are kept. Each EMS meter's closing date still applies to its next tenant.",
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _remark,
              decoration: const InputDecoration(labelText: 'Remark (optional)'),
            ),
          ],
        ),
      ),
    );
  }
}
