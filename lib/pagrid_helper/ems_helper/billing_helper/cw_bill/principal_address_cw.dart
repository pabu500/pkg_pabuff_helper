import 'package:pdf/widgets.dart' as pw;

String cwPrincipalAddress(Map<String, dynamic> billInfo) =>
    [
          billInfo['tenant_building_address_line_1'],
          billInfo['tenant_building_address_line_2'],
          billInfo['tenant_location_label'],
          billInfo['tenant_building_address_line_3'],
        ]
        .map((value) => value?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .join(', ');

pw.Widget cwMeterDetailsHeader({
  required String invoiceNumber,
  required String principalAddress,
  required pw.TextStyle style,
}) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text(
      'Meter details for $invoiceNumber',
      style: style.copyWith(fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 12),
    if (principalAddress.isNotEmpty) ...[
      pw.Text(
        'This tax invoice is issued based on the meters associated with the principal address:',
        style: style,
      ),
      pw.Text(
        principalAddress,
        style: style.copyWith(fontWeight: pw.FontWeight.bold),
      ),
    ],
    pw.Text('Refer to table below for the meter list breakdown', style: style),
    pw.SizedBox(height: 12),
  ],
);
