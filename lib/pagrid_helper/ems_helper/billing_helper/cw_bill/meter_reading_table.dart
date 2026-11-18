import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const cwMeterReadingRemarks = 'M= Multiplier Factor\n'
    'Reading Time is taken as 00:00hrs, unless otherwise instructed by '
    'building management / landlord.';

pw.Table cwMeterReadingTable({
  required String? unit,
  required pw.TextStyle style,
  required List<List<String>> rows,
}) {
  final headings = [
    'Building',
    'Meter S/N',
    'Unit #',
    'Previous Read',
    'Current Read',
    'M',
    unit == null ? 'Usage' : 'Usage ($unit)',
    r'Amount ($)',
  ];
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
    columnWidths: const {
      0: pw.FixedColumnWidth(135),
      1: pw.FixedColumnWidth(95),
      2: pw.FixedColumnWidth(135),
      3: pw.FixedColumnWidth(85),
      4: pw.FixedColumnWidth(85),
      5: pw.FixedColumnWidth(30),
      6: pw.FixedColumnWidth(80),
      7: pw.FixedColumnWidth(80),
    },
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    children: [
      for (final values in [headings, ...rows])
        pw.TableRow(children: [
          for (final value in values)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              child: pw.Text(value, style: style, textAlign: pw.TextAlign.left),
            ),
        ]),
    ],
  );
}
