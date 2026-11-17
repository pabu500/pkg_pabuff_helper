import 'package:material_ui/material_ui.dart';

class WgtPreviousSystemDebtorDialog extends StatefulWidget {
  const WgtPreviousSystemDebtorDialog({
    super.key,
    required this.tenantName,
    required this.bill,
    required this.serviceEndDate,
  });
  final String tenantName;
  final Map<String, dynamic> bill;
  final String serviceEndDate;
  @override
  State<WgtPreviousSystemDebtorDialog> createState() => _DialogState();
}

class _DialogState extends State<WgtPreviousSystemDebtorDialog> {
  String _typed = '';
  @override
  Widget build(BuildContext context) {
    final phrase = 'convert ${widget.tenantName}';
    return AlertDialog(
      title: const Text('Convert tenant'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 395,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Opening bill: ${widget.bill['label'] ?? ''}'),
              Text('Released: ${widget.bill['bill_release_timestamp'] ?? ''}'),
              Text(
                'Outstanding: ${widget.bill['cycle_remaining_balance'] ?? ''}',
              ),
              Text('Termination date: ${widget.serviceEndDate}'),
              const Text(
                "The opening bill becomes the final bill. This can't be undone.",
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Type "$phrase" to confirm',
                ),
                onChanged: (value) => setState(() => _typed = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _typed == phrase
              ? () => Navigator.of(context).pop(true)
              : null,
          child: const Text('Convert'),
        ),
      ],
    );
  }
}
