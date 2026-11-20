import 'package:material_ui/material_ui.dart';

class WgtTenantMfdDialog extends StatefulWidget {
  const WgtTenantMfdDialog({
    super.key,
    required this.tenantName,
    required this.info,
  });
  final String tenantName;
  final Map<String, dynamic> info;
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
    return AlertDialog(
      title: Text(
        cancelling
            ? 'Cancel onboarding tenant'
            : 'Mark terminated tenant for deletion',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.tenantName),
              const SizedBox(height: 12),
              if (cancelling) ...[
                const Text("This cancels the tenant and can't be undone."),
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
                decoration: const InputDecoration(
                  labelText: 'Remark (optional',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, {'mfd_remark': _remark.text.trim()}),
          child: Text(cancelling ? 'Cancel tenant' : 'Mark MFD'),
        ),
      ],
    );
  }
}
