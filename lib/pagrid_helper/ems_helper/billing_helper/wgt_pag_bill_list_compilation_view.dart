import 'package:flutter/material.dart';
import 'dart:developer' as dev;

import 'cw_bill/pag_gen_pdf_bill_compilation_cw.dart';
import 'wgt_pag_render_pdf.dart';

class WgtPagBillListCompilationView extends StatelessWidget {
  const WgtPagBillListCompilationView(
      {super.key, required this.billingInfoList});

  final List<Map<String, dynamic>> billingInfoList;

  @override
  Widget build(BuildContext context) {
    dev.log('Building WgtPagBillListCompilationView');
    return WgtPagRenderPdf(
      itemInfo: {'bill_info_list': billingInfoList},
      builder: generatePagInvoiceCompilation,
    );
  }
}
