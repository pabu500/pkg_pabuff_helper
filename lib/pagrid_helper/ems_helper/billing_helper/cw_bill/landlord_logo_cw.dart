import 'dart:convert';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Widget buildCwInvoiceHeaderLogo(String? encoded, pw.ImageProvider? fallback) {
  final landlordLogo = decodeLandlordLogo(encoded);
  final image = landlordLogo ?? fallback;
  final slot = pw.Container(
    alignment: pw.Alignment.topLeft,
    height: 39,
    child: image == null ? pw.PdfLogo() : pw.Image(image),
  );
  if (landlordLogo == null) return slot;
  // PDF coordinates increase upwards. Keep the biller text at its existing baseline.
  return pw.Transform.translate(offset: const PdfPoint(0, 6), child: slot);
}

pw.MemoryImage? decodeLandlordLogo(String? encoded) {
  if (encoded == null || encoded.isEmpty) return null;
  try {
    return pw.MemoryImage(base64Decode(encoded));
  } on Exception {
    return null;
  }
}
