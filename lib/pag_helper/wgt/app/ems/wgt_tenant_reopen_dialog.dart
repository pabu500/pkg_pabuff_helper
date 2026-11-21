import 'package:material_ui/material_ui.dart';

class WgtTenantReopenDialog extends StatefulWidget {
  const WgtTenantReopenDialog({
    super.key,
    required this.tenantName,
    required this.info,
  });
  final String tenantName;
  final Map<String, dynamic> info;
  @override
  State<WgtTenantReopenDialog> createState() => _ReopenDialogState();
}

class _ReopenDialogState extends State<WgtTenantReopenDialog> {
  String _reason = '';
  bool _acknowledged = false;
  final Map<String, dynamic> _choices = {};
  List get _groups => widget.info['groups_without_snapshot'] as List? ?? [];
  bool get _needsAck => widget.info['requires_naming_acknowledgement'] == true;
  bool get _valid =>
      widget.info['eligible'] == true &&
      _reason.trim().length >= 10 &&
      _reason.trim().length <= 500 &&
      (!_needsAck || _acknowledged) &&
      _groups.every((g) => _choices.containsKey(g['id'].toString()));

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Reopen (back to Offboarding)'),
    content: SingleChildScrollView(
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reopen ${widget.tenantName} to correct its final bill or undo a mistaken termination. Closing readings will be kept. Terminating again requires deposit confirmation again.',
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
            for (final group in _groups)
              Builder(
                builder: (context) {
                  final values = group['allowed_values'] as List? ?? [];
                  return DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Restore ${group['name'] ?? group['id']} to',
                    ),
                    items: [
                      for (var i = 0; i < values.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(
                            values[i]?.toString() ?? 'No status (NULL)',
                          ),
                        ),
                    ],
                    onChanged: (index) {
                      if (index != null) {
                        setState(
                          () =>
                              _choices[group['id'].toString()] = values[index],
                        );
                      }
                    },
                  );
                },
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
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: !_valid
            ? null
            : () => Navigator.pop(context, <String, dynamic>{
                'termination_token': widget.info['termination_token'],
                'reason': _reason.trim(),
                'group_status_choices': _choices,
                'acknowledge_naming': _acknowledged,
              }),
        child: const Text('Reopen'),
      ),
    ],
  );
}
