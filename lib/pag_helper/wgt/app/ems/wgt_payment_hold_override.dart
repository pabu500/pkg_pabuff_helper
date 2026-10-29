import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Shared presentation for the payment-application and bill-generation overrides.
class WgtPaymentHoldOverride extends StatelessWidget {
  const WgtPaymentHoldOverride({
    super.key,
    required this.authorized,
    required this.enabled,
    required this.selected,
    required this.busy,
    required this.accessError,
    required this.reason,
    required this.onRetry,
    required this.onChanged,
    required this.label,
    required this.description,
    required this.warning,
    required this.reasonHint,
  });
  final bool authorized, enabled, selected, busy;
  final String accessError, label, description, warning, reasonHint;
  final TextEditingController reason;
  final VoidCallback onRetry;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final hintColor = Theme.of(context).hintColor;
    final errorColor = Theme.of(context).colorScheme.error;
    final cautionColor = Colors.amber.shade600;

    if (accessError.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(13, 6, 13, 6),
        child: Row(
          children: [
            Icon(Symbols.error, size: 18, color: errorColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Could not check payment override access: $accessError',
                style: TextStyle(fontSize: 13, color: errorColor),
              ),
            ),
            TextButton(
              onPressed: busy ? null : onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (!authorized) return const SizedBox.shrink();

    final canToggle = enabled && !busy;
    final subtitle = enabled
        ? description
        : 'Payment override is currently disabled.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(2, 14, 2, 6),
      padding: const EdgeInsets.fromLTRB(2, 8, 13, 8),
      decoration: BoxDecoration(
        color: selected ? cautionColor.withAlpha(22) : null,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: selected ? cautionColor.withAlpha(150) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: canToggle ? () => onChanged(!selected) : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: selected,
                  activeColor: cautionColor,
                  onChanged: canToggle
                      ? (value) => onChanged(value ?? false)
                      : null,
                ),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: enabled ? null : hintColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: hintColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (selected) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(42, 6, 0, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Symbols.warning, size: 18, color: cautionColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      warning,
                      style: TextStyle(fontSize: 13, color: cautionColor),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(42, 10, 0, 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: TextField(
                  controller: reason,
                  enabled: !busy,
                  maxLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Reason (required)',
                    alignLabelWithHint: true,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    hintText: reasonHint,
                    helperText: 'Saved with the override audit record.',
                    helperMaxLines: 2,
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
