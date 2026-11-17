import 'package:material_ui/material_ui.dart';

/// Detail card shared by chart bars and dashboard stat cards.
///
/// `detail` = {title, status, sections: [{name?, color?, rows: [{label, value, marker?}]}], note?}
/// A row's optional `marker` (a small widget, e.g. a legend swatch) is drawn before its label.
/// `status` picks the chip: partial, incomplete, approximate, otherwise complete.
class WgtStatDetailCard extends StatelessWidget {
  const WgtStatDetailCard({
    super.key,
    required this.detail,
    this.warningColor,
    this.backgroundAlpha = 200,
  });

  final Map<String, dynamic> detail;

  /// Partial / no-total chip colour; defaults to [defaultWarningColor].
  final Color? warningColor;

  /// Card background opacity (0–255). Below 255 the content behind shows through.
  final int backgroundAlpha;

  /// Amber blended ~50% toward green: noticeable without reading as an alarm.
  static Color defaultWarningColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Color.lerp(Colors.amber.shade300, Colors.green.shade300, 0.5)!
          : Color.lerp(Colors.amber.shade800, Colors.green.shade800, 0.5)!;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final warn = warningColor ?? defaultWarningColor(context);
    final primary = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    final (chipLabel, chipColor) = switch (detail['status']) {
      'partial' => ('Partial', warn),
      'incomplete' => ('No total', warn),
      'approximate' => ('Approximate', scheme.primary),
      _ => ('Complete', muted),
    };
    final sections = (detail['sections'] as List? ?? const []).cast<Map>();
    final labelStyle = TextStyle(fontSize: 12, color: muted, height: 1.4);
    final valueStyle = TextStyle(
      fontSize: 12,
      color: primary,
      height: 1.4,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget cellRow(Map cell) => Row(
      crossAxisAlignment: cell['marker'] is Widget
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (cell['marker'] is Widget) ...[
          SizedBox(width: 18, child: Center(child: cell['marker'] as Widget)),
          const SizedBox(width: 6),
        ],
        Text('${cell['label']}', style: labelStyle),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            '${cell['value']}',
            style: valueStyle,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 264,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          // Semi-transparent so the bars stay visible behind the card.
          color: scheme.surfaceContainerHigh.withAlpha(backgroundAlpha),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant.withAlpha(140)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${detail['title'] ?? ''}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    chipLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: chipColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              if (sections[i]['name'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: sections[i]['color'] as Color? ?? muted,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${sections[i]['name']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ),
              for (final cell
                  in (sections[i]['rows'] as List? ?? const []).cast<Map>())
                Padding(
                  padding: EdgeInsets.only(
                    left: sections[i]['name'] != null ? 14 : 0,
                  ),
                  child: cellRow(cell),
                ),
            ],
            if (detail['note'] != null) ...[
              const SizedBox(height: 8),
              Text(
                '${detail['note']}',
                style: TextStyle(fontSize: 11, color: muted, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
