import 'package:material_ui/material_ui.dart';

import '../../../../xt_ui/style/evs2_colors.dart';

/// Use the application's amber palette with tones appropriate to the theme.
class WgtMeterAllocationWarning extends StatelessWidget {
  const WgtMeterAllocationWarning(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: commitColor,
      brightness: Theme.of(context).brightness,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber,
              size: 16,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
