import 'dart:convert';
import 'dart:developer' as dev;

import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:web/web.dart' as web;

class WgtPagRenderPdf extends StatefulWidget {
  const WgtPagRenderPdf({
    super.key,
    required this.loggedInUser,
    required this.itemInfo,
    // required this.invoice,
    required this.builder,
  });

  final MdlPagUser loggedInUser;
  // final Map<String, dynamic> billingInfo;
  final Map<String, dynamic> itemInfo;
  // final PagBill invoice;
  final Future<Uint8List> Function(
    MdlPagUser loggedInUser,
    PdfPageFormat pageFormat,
    Map<String, dynamic> itemInfo,
    // PagBill invoice,
  ) builder;

  @override
  State<WgtPagRenderPdf> createState() => _WgtPagRenderPdfState();
}

class _WgtPagRenderPdfState extends State<WgtPagRenderPdf> {
  String _fileName = 'bill';

  late final actions = <PdfPreviewAction>[
    // if (!kIsWeb)
    //   const PdfPreviewAction(
    //     icon: Icon(Icons.cloud_download),
    //     onPressed: _saveAsFile,
    //   )
    PdfPreviewAction(
      icon: const Icon(Icons.cloud_download),
      onPressed: _savePdf,
    )
  ];

  Future<String> _savePdf(
    BuildContext context,
    LayoutCallback build,
    PdfPageFormat pageFormat,
  ) async {
    String suffix = '';
    //if web
    if (kIsWeb) {
      await generateAndSavePdfWeb(
        build,
        pageFormat,
        '$_fileName$suffix',
      );
    } else {
      await generateAndSavePdfMobile(
        build,
        pageFormat,
        '$_fileName$suffix',
      );
    }
    return 'ok';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 1000,
      ),
      child: PdfPreview(
        maxPageWidth: 700,
        previewPageMargin: const EdgeInsets.all(3),
        allowSharing: false,
        canChangeOrientation: false,
        initialPageFormat: PdfPageFormat.a4,
        canChangePageFormat: false,
        canDebug: kDebugMode,
        // build: (format) => generatePagInvoice(format, widget.billingInfo),
        build: (format) =>
            widget.builder(widget.loggedInUser, format, widget.itemInfo),
        actions: actions,
        loadingWidget: xtWait(
          size: 34,
          color: Theme.of(context).colorScheme.primary,
        ),
        onPrinted: (context) {
          dev.log('Printed');
        },
        onShared: (context) {},
      ),
    );
  }
}

Future<void> generateAndSavePdfWeb(
  LayoutCallback build,
  PdfPageFormat pageFormat,
  String fileName,
) async {
  final bytes = await build(pageFormat);
  List<int> fileInts = List.from(bytes);
  final base64String = base64.encode(fileInts);

  web.HTMLAnchorElement()
    ..href = 'data:application/pdf;base64,$base64String'
    ..download = '$fileName.pdf'
    ..click();
}

Future<void> generateAndSavePdfMobile(
  LayoutCallback build,
  PdfPageFormat pageFormat,
  String fileName,
) async {
  final bytes = await build(pageFormat);

  final file = File('$fileName.pdf');
  await file.writeAsBytes(bytes);
}

Future<void> _saveAsFile(
  LayoutCallback build,
  PdfPageFormat pageFormat,
) async {
  final bytes = await build(pageFormat);

  final appDocDir = await getApplicationDocumentsDirectory();
  final appDocPath = appDocDir.path;
  final file = File('$appDocPath/document.pdf');

  dev.log('Save as file ${file.path} ...');

  await file.writeAsBytes(bytes);
  await OpenFile.open(file.path);
}
