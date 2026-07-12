import 'dart:math';

import 'package:buff_helper/pagrid_helper/ems_helper/tenant/mdl_ems_type_usage_r2.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/tenant/pag_ems_type_usage_calc_rl.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:developer' as dev;

import '../../../pag_helper/def_helper/dh_device.dart';
import '../../../pag_helper/def_helper/dh_pag_tenant.dart';
import '../../../util/string_util.dart';
import '../../../util/util.dart';

const int boltIcon = 0xea0b;
const int waterIcon = 0xf084;
const int hvacIcon = 0xf10e;
const int gasIcon = 0xec19;
const int waterDropIcon = 0xe798;

const int usageDecimals = 3;
const int rateDecimals = 4;

const tableHeaders = ['Category', 'Budget', 'Expense', 'Result'];

class PagPdfBillCwP2 {
  PagPdfBillCwP2({
    required this.customerName,
    required this.tenantAccountNumber,
    required this.customerLabel,
    required this.tenantBillingAddressLine1,
    required this.tenantBillingAddressLine2,
    required this.tenantBillingAddressLine3,
    required this.customerType,
    required this.strDepositAmount,
    required this.paymentMethod,
    required this.gst,
    required this.billingRecName,
    required this.billLabel,
    required this.strFrom,
    required this.strTo,
    required this.strEffectiveTo,
    required this.strBillDate,
    required this.strBillTimeRange,
    required this.subTotalAmount,
    required this.gstAmount,
    required this.totalAmount,
    required this.cycleTotalAmount,
    required this.totalUsageCost,
    required this.typeRateE,
    required this.typeRateW,
    required this.typeRateB,
    required this.typeRateN,
    required this.typeRateG,
    required this.typeUsageE,
    required this.typeUsageW,
    required this.typeUsageB,
    required this.typeUsageN,
    required this.typeUsageG,
    required this.typeCostE,
    required this.typeCostW,
    required this.typeCostB,
    required this.typeCostN,
    required this.typeCostG,
    required this.trendingE,
    required this.trendingW,
    required this.trendingB,
    required this.trendingN,
    required this.trendingG,
    required this.tax,
    required this.paymentInfo,
    required this.interestInfo,
    required this.lineItemLabel1,
    required this.lineItemValue1,
    required this.lineItemLabel2,
    required this.lineItemValue2,
    required this.lineItemLabel3,
    required this.lineItemValue3,
    required this.billedBciInfoList,
    required this.payableAmount,
    required this.strDueDate,
    required this.baseColor,
    required this.accentColor,
    required this.assetFolder,
    required this.tenantSingularUsageInfoList,
    required this.miniSoaInfo,
    required this.billedAmgrCompanyTradingName,
    required this.billedAmgrCompanyRegNumber,
    required this.billedAmgrGstRegNumber,
    required this.amgrAddressLine1,
    required this.amgrAddressLine2,
    required this.amgrAddressLine3,
    required this.amgrBankAccountName,
    required this.amgrBankAccountNumber,
    required this.amgrBankName,
    required this.amgrBankBranchCode,
    required this.amgrBankSwiftCode,
    required this.amgrBankPayNow,
    required this.strCollectionStartDate,
    required this.strCollectionEndDate,
  });

  final String customerLabel;
  final String customerName;
  final String tenantAccountNumber;
  final String tenantBillingAddressLine1;
  final String tenantBillingAddressLine2;
  final String tenantBillingAddressLine3;
  final String customerType;
  final String strDepositAmount;
  final String paymentMethod;
  final double? gst;
  final String billingRecName;
  final String billLabel;
  final String strFrom;
  final String strTo;
  final String strEffectiveTo;
  final String strBillDate;
  final String strDueDate;
  final String strBillTimeRange;
  final double? totalUsageCost;
  final double? subTotalAmount;
  final double? cycleTotalAmount;
  final double? gstAmount;
  final double? totalAmount;
  final Map<String, dynamic>? interestInfo;
  final double? payableAmount;
  final double? typeRateE;
  final double? typeRateW;
  final double? typeRateB;
  final double? typeRateN;
  final double? typeRateG;
  final double? typeUsageE;
  final double? typeUsageW;
  final double? typeUsageB;
  final double? typeUsageN;
  final double? typeUsageG;
  final double? typeCostE;
  final double? typeCostW;
  final double? typeCostB;
  final double? typeCostN;
  final double? typeCostG;
  final String? lineItemLabel1;
  final double? lineItemValue1;
  final String? lineItemLabel2;
  final double? lineItemValue2;
  final String? lineItemLabel3;
  final double? lineItemValue3;
  final List<Map<String, dynamic>>? billedBciInfoList;
  final List<Map<String, dynamic>>? trendingE;
  final List<Map<String, dynamic>>? trendingW;
  final List<Map<String, dynamic>>? trendingB;
  final List<Map<String, dynamic>>? trendingN;
  final List<Map<String, dynamic>>? trendingG;
  final double tax;
  final String paymentInfo;
  final PdfColor baseColor;
  final PdfColor accentColor;
  final String? assetFolder;
  final List<Map<String, dynamic>> tenantSingularUsageInfoList;
  final Map<String, dynamic>? miniSoaInfo;
  final String? billedAmgrCompanyTradingName;
  final String? billedAmgrCompanyRegNumber;
  final String? billedAmgrGstRegNumber;
  final String? amgrAddressLine1;
  final String? amgrAddressLine2;
  final String? amgrAddressLine3;
  final String? amgrBankAccountName;
  final String? amgrBankAccountNumber;
  final String? amgrBankName;
  final String? amgrBankBranchCode;
  final String? amgrBankSwiftCode;
  final String? amgrBankPayNow;
  final String strCollectionStartDate;
  final String strCollectionEndDate;
  // final String? billedTptNote;
  static const _darkColor = PdfColors.blueGrey800;

  dynamic _logo;

  final double size1 = 8.5;
  final double size2 = 9.5;
  final double size3 = 10;
  final double size4 = 11;
  final double size5 = 12;
  final double size6 = 13;

  late final pw.TextStyle styleSmall = pw.TextStyle(
    fontSize: size1,
    color: _darkColor,
  );
  late final pw.TextStyle styleNormal = pw.TextStyle(
    fontSize: size2,
    color: _darkColor,
  );
  late final pw.TextStyle styleLarge = pw.TextStyle(
    fontSize: size3,
    color: _darkColor,
  );

  String? _bgShape = '';

  Future<Uint8List> buildPdf(PdfPageFormat pageFormat) async {
    // Create a PDF document.
    final doc = pw.Document();

    // mt.AssetImage logoImage = const mt.AssetImage("assets/images/cw_logo_r_s.png");
    _logo = //await rootBundle.loadString('assets/images/C&W_Services_Logo_Color.png');
        pw.MemoryImage(
      // (await rootBundle.load('$assetFolder/cw_logo_r_s.png'))
      (await rootBundle.load('$assetFolder/transparent_32x32.png'))
          .buffer
          .asUint8List(),
    );
    // _bgShape = await rootBundle.loadString('$assetFolder/invoice.svg');

    // Add page to the PDF
    doc.addPage(await getPage1());
    doc.addPage(await getPage2());

    // Return the PDF file content
    return doc.save();
  }

  Future<pw.MultiPage> getPage1({dynamic logo}) async {
    double pageWidth = PdfPageFormat.a4.width;
    dev.log('Page width: $pageWidth');

    if (logo != null) {
      _logo = logo;
    }

    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.openSansRegular(),
          bold: await PdfGoogleFonts.openSansBold(),
          icons: await PdfGoogleFonts.materialSymbolsOutlinedRegular(),
        ),
      ),
      header: _buildHeaderP1,
      footer: _buildFooter,
      build: (context) => [
        _contentHeader(context),
        pw.SizedBox(height: 3),
        _getBillTime(),
        _getNote1(),
        _getSingularList(),
        pw.SizedBox(height: 3),
        _getTotal(),
        _getContentFooter(context),
        // pw.SizedBox(height: 10),
        // _termsAndConditions(context),
      ],
    );
  }

  Future<pw.MultiPage> getPage2({dynamic logo}) async {
    double pageWidth = PdfPageFormat.a4.width;
    dev.log('Page width: $pageWidth');

    if (logo != null) {
      _logo = logo;
    }

    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.openSansRegular(),
          bold: await PdfGoogleFonts.openSansBold(),
          icons: await PdfGoogleFonts.materialSymbolsOutlinedRegular(),
        ),
      ),
      header: _buildHeaderP2,
      // footer: _buildFooter,
      build: (context) => [
        _getMeterTypeMeterListUsage(),
      ],
    );
  }

  pw.Widget _buildHeaderP1(pw.Context context) {
    // int codePoint = mt.Icons.abc.codePoint;
    //hex
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 270,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisSize: pw.MainAxisSize.min,
                children: [_getLogo(), _getBillerInfo()],
              ),
            ),
            pw.Expanded(child: pw.Container()),
            pw.SizedBox(width: 230, child: _getPaymentInfo()),
          ],
        ),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(width: 230, child: _getPayerInfo()),
            pw.Expanded(child: pw.Container()),
            if (paymentMethod == 'giro')
              pw.SizedBox(width: 210, child: _getGrioNote()),
          ],
        ),
        // if (context.pageNumber > 1) pw.SizedBox(height: 20)
      ],
    );
  }

  pw.Widget _buildHeaderP2(pw.Context context) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 250,
              child: pw.Text(
                'Meter Usage Details for $billLabel',
                style: styleLarge.copyWith(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _getLogo({dynamic logo}) {
    dynamic displayLogo = logo ?? _logo;
    return pw.Container(
      alignment: pw.Alignment.topLeft,
      // padding: const pw.EdgeInsets.only(bottom: 8, left: 30),
      height: 39,
      child: displayLogo != null ? pw.Image(displayLogo) : pw.PdfLogo(),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 300,
          // height: 200,
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey600, width: 1),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Text('Payment by Telegraphic Transfer (T/T) or PayNow',
                      style: styleSmall),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text(
                      'Please quote Account Number & Invoice Number(s) & remit to:',
                      style: styleSmall),
                ],
              ),
              pw.Table(
                columnWidths: {
                  0: const pw.FixedColumnWidth(60),
                  1: const pw.FixedColumnWidth(180),
                },
                children: [
                  pw.TableRow(children: [
                    pw.Text('Account Name:', style: styleSmall),
                    pw.Text(amgrBankAccountName ?? '-', style: styleSmall),
                  ]),
                  pw.TableRow(children: [
                    pw.Text('Account Number:', style: styleSmall),
                    pw.Text(amgrBankAccountNumber ?? '-', style: styleSmall),
                  ]),
                  pw.TableRow(children: [
                    pw.Text('Bank Name:', style: styleSmall),
                    pw.Text(amgrBankName ?? '-', style: styleSmall),
                  ]),
                  pw.TableRow(children: [
                    pw.Text('Branch Code:', style: styleSmall),
                    pw.Text(amgrBankBranchCode ?? '-', style: styleSmall),
                  ]),
                  pw.TableRow(children: [
                    pw.Text('Swift Code:', style: styleSmall),
                    pw.Text(amgrBankSwiftCode ?? '-', style: styleSmall),
                  ]),
                  pw.TableRow(children: [
                    pw.Text('PayNow:', style: styleSmall),
                    pw.Text(amgrBankPayNow ?? '-', style: styleSmall),
                  ]),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text('(No receipt will be issued)', style: styleSmall),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Table(
          columnWidths: {
            0: const pw.FixedColumnWidth(70),
            1: const pw.FixedColumnWidth(105),
          },
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
          children: [
            pw.TableRow(children: [
              pw.Text(' Account No',
                  style: styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.Text(' $tenantAccountNumber',
                  style: styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
            ]),
            pw.TableRow(children: [
              pw.Text(' Invoice No',
                  style: styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.Text(' $billLabel',
                  style: styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
            ]),
            pw.TableRow(children: [
              pw.Text(' Total Amount',
                  style: styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  payableAmount != null
                      // ? ' \$${payableAmount.toString()}'
                      ? ' \$${getCommaNumberStr(payableAmount!, decimal: 2)}'
                      : '-',
                  style: styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
            ]),
          ],
        ),
      ],
    );
  }

  pw.PageTheme _buildTheme(
      PdfPageFormat pageFormat, pw.Font base, pw.Font bold, pw.Font italic) {
    return pw.PageTheme(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(
        base: base,
        bold: bold,
        italic: italic,
      ),
      buildBackground: (context) => pw.FullPage(
        ignoreMargins: true,
        child: pw.SvgImage(svg: _bgShape!),
      ),
    );
  }

  pw.Widget _contentHeader(pw.Context context) {
    return pw.SizedBox(height: 3);
  }

  pw.Widget _getPayerInfo() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(customerLabel,
            style: styleLarge.copyWith(fontWeight: pw.FontWeight.bold)),
        // pw.SizedBox(height: 2),
        pw.Row(children: [
          pw.Text(tenantBillingAddressLine1, style: styleNormal),
        ]),
        pw.Row(children: [
          pw.Text(tenantBillingAddressLine2, style: styleNormal),
        ]),
        pw.Row(children: [
          pw.Text(tenantBillingAddressLine3, style: styleNormal),
        ]),
      ],
    );
  }

  pw.Widget _getPaymentInfo() {
    double depositAmount =
        double.tryParse(strDepositAmount.replaceAll(',', '')) ?? 0;

    PagPaymentMethod paymentMethodEnum =
        PagPaymentMethod.byValue(paymentMethod);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      // mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        pw.SizedBox(
          height: 125,
          width: 210,
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // pw.SizedBox(height: 20),
                pw.Text('TAX INVOICE',
                    style: styleLarge.copyWith(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Table(
                    border: pw.TableBorder.all(
                        color: PdfColors.grey600, width: 0.5),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(30),
                      1: const pw.FixedColumnWidth(30),
                    },
                    defaultVerticalAlignment:
                        pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.TableRow(children: [
                        pw.Text(' Account Number:', style: styleNormal),
                        pw.Text(' $tenantAccountNumber', style: styleNormal)
                      ]),
                      pw.TableRow(children: [
                        pw.Text(' Invoice Number:', style: styleNormal),
                        pw.Text(' $billLabel', style: styleNormal),
                      ]),
                      pw.TableRow(children: [
                        pw.Text(' Date of Invoice:', style: styleNormal),
                        pw.Text(' ${_getDateStr(strBillDate)}',
                            style: styleNormal),
                      ]),
                      pw.TableRow(children: [
                        pw.Text(' Deposit Amount:', style: styleNormal),
                        pw.Text(' \$${getCommaNumberStr(depositAmount)}',
                            style: styleNormal),
                      ]),
                      pw.TableRow(children: [
                        pw.Text(' Mode of Payment:', style: styleNormal),
                        pw.Text(' ${paymentMethodEnum.label}',
                            style: styleNormal),
                      ]),
                    ]),
                pw.SizedBox(height: 10),
                pw.Table(
                    border: pw.TableBorder.all(
                        color: PdfColors.grey600, width: 0.5),
                    columnWidths: {
                      0: const pw.FixedColumnWidth(35),
                      1: const pw.FixedColumnWidth(35),
                    },
                    defaultVerticalAlignment:
                        pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.TableRow(children: [
                        pw.Text(' Total Amount Payable', style: styleNormal),
                        pw.Text(
                            ' \$${getCommaNumberStr(payableAmount!, decimal: 2)}',
                            style: styleNormal.copyWith(
                                fontWeight: pw.FontWeight.bold)),
                      ]),
                      pw.TableRow(children: [
                        pw.Text(' Due Date', style: styleNormal),
                        pw.Text(' ${_getDateStr(strDueDate)}',
                            style: styleNormal.copyWith(
                                fontWeight: pw.FontWeight.bold)),
                      ]),
                    ]),
              ]),
        ),
      ],
    );
  }

  pw.Widget _getGrioNote() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Note for GIRO tenants:',
            style: styleSmall.copyWith(fontWeight: pw.FontWeight.bold)),
        pw.Text(
          'If invoice due date falls on a non-business day, GIRO deduction (if applicable) will be processed on the next business day. If deduction is unsuccessful, late payment interest will accrue daily from the due date until the invoice is fully settled.',
          style: styleSmall,
        ),
      ],
    );
  }

  String _getBillingPeriodStr(String fromStr, String toStr) {
    DateTime billFrom = DateTime.parse(fromStr);
    // subtract 1 second from billTo to avoid showing next day if billTo is at 00:00:00
    DateTime billTo =
        DateTime.parse(toStr).subtract(const Duration(seconds: 1));
    String formattedFrom = DateFormat('dd MMM yyyy').format(billFrom);
    String formattedTo = DateFormat('dd MMM yyyy').format(billTo);
    return '$formattedFrom - $formattedTo';
  }

  String _getDateStr(String dateTimeStr) {
    DateTime dateTime = DateTime.parse(dateTimeStr);
    String formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
    return formattedDate;
  }

  // String _getBillDate() {
  //   DateTime billDate = DateTime.parse(billDateStr);
  //   String formattedDate = DateFormat('dd MMM yyyy').format(billDate);
  //   return formattedDate;
  // }

  pw.Widget _getBillTime() {
    return pw.SizedBox(
      // height: 10,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Text('Billing Period: ',
                style: styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
            pw.Text(
                _getBillingPeriodStr(
                    strFrom, strEffectiveTo.isEmpty ? strTo : strEffectiveTo),
                style: styleNormal),
          ]),
          pw.SizedBox(width: 50),
          pw.Row(children: [
            pw.Text('Bill Date: ',
                style: styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
            pw.Text(_getDateStr(strBillDate), style: styleNormal),
          ]),
        ],
      ),
    );
  }

  pw.Widget _getNote1() {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Text(
                'For premise address(es) relating to this invoice, refer to page 2',
                style: styleSmall),
          ]),
        ],
      ),
    );
  }

  pw.Widget _getBillerInfo() {
    return pw.SizedBox(
        height: 95,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Issued on behalf of', style: styleSmall),
            pw.Text(billedAmgrCompanyTradingName ?? '',
                maxLines: 2,
                style: styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
            pw.Text('Company Reg No: ${billedAmgrCompanyRegNumber ?? ''}',
                style: styleNormal),
            pw.Text('GST Reg No: ${billedAmgrGstRegNumber ?? ''}',
                style: styleNormal),
            pw.Text(amgrAddressLine1 ?? '', style: styleNormal),
            pw.Text(amgrAddressLine2 ?? '', style: styleNormal),
            pw.Text(amgrAddressLine3 ?? '', style: styleNormal),
          ],
        ));
  }

  pw.Widget _getContentFooter(pw.Context context) {
    double width = 130;
    return pw.SizedBox();
  }

  pw.Widget _termsAndConditions(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // pw.Container(
              //   decoration: pw.BoxDecoration(
              //     border: pw.Border(top: pw.BorderSide(color: accentColor)),
              //   ),
              //   padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
              //   child:
              //   pw.Text(
              //     'Terms & Conditions',
              //     style: pw.TextStyle(
              //       fontSize: 12,
              //       color: baseColor,
              //       fontWeight: pw.FontWeight.bold,
              //     ),
              //   ),
              // ),
              pw.Text(
                'The amount will be posted against your department\'s WBS by 4th week of each month. Please ensure available budget for successful deduction.',
                // pw.LoremText().paragraph(40),
                textAlign: pw.TextAlign.justify,
                style: const pw.TextStyle(
                  fontSize: 8,
                  lineSpacing: 2,
                  color: _darkColor,
                ),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.SizedBox(),
        ),
      ],
    );
  }

  pw.Widget _getSingularList() {
    List<pw.Widget> singularStatList = [];
    double footnoteWidth = 470;

    for (Map<String, dynamic> singularUsageInfo
        in tenantSingularUsageInfoList) {
      List<pw.Widget> typeStatList = [];
      String billedTpNote = singularUsageInfo['billed_tp_note'] ?? '';
      String billedTpNote2 = singularUsageInfo['billed_tp_note2'] ?? '';
      String billedTptRateNote =
          singularUsageInfo['billed_tpt_rate_note'] ?? '';
      String billedTptCycleNote =
          singularUsageInfo['billed_tpt_cycle_note'] ?? '';

      if (billedTptCycleNote == billedTptRateNote) {
        billedTptCycleNote = '';
      }
      String slotFromTimestampStr = singularUsageInfo['from_timestamp'] ?? '';
      String slotToTimestampStr = singularUsageInfo['to_timestamp'] ?? '';
      String slotStr =
          // '  ${slotFromTimestampStr.substring(0, 10)} - ${slotToTimestampStr.substring(0, 10)}';
          '  ${_getBillingPeriodStr(slotFromTimestampStr, slotToTimestampStr)}';
      typeStatList.add(
          _getTypeRow2(boltIcon, 'Electricity', 'kWh', singularUsageInfo, 'E'));
      typeStatList
          .add(_getTypeRow2(hvacIcon, 'BTU', 'kWh', singularUsageInfo, 'B'));
      typeStatList
          .add(_getTypeRow2(waterIcon, 'Water', 'CuM', singularUsageInfo, 'W'));
      typeStatList.add(_getTypeRow2(
          waterDropIcon, 'NeWater', 'CuM', singularUsageInfo, 'N'));
      typeStatList
          .add(_getTypeRow2(gasIcon, 'Gas', 'kWh', singularUsageInfo, 'G'));
      singularStatList.add(pw.Container(
        width: 500,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey600, width: 1),
          borderRadius: pw.BorderRadius.circular(5.0),
        ),
        margin: const pw.EdgeInsets.only(top: 5),
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            // pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text(slotStr,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                        fontSize: size2)),
              ],
            ),
            pw.SizedBox(height: 2),
            ...typeStatList,
            pw.SizedBox(height: 2),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (billedTpNote.isNotEmpty)
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('    *: ', style: styleSmall),
                        pw.SizedBox(
                            width: footnoteWidth,
                            child: pw.Text(billedTpNote,
                                maxLines: 2,
                                style: styleSmall.copyWith(
                                    fontStyle: pw.FontStyle.italic))),
                      ]),
                if (billedTpNote2.isNotEmpty)
                  pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('    *: ', style: styleSmall),
                        pw.SizedBox(
                            width: footnoteWidth,
                            child: pw.Text(billedTpNote2,
                                maxLines: 2,
                                style: styleSmall.copyWith(
                                    fontStyle: pw.FontStyle.italic))),
                      ]),
                if (billedTptRateNote.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('  **: ', style: styleSmall),
                          pw.SizedBox(
                              width: footnoteWidth,
                              child: pw.Text(billedTptRateNote,
                                  maxLines: 2,
                                  style: styleSmall.copyWith(
                                      fontStyle: pw.FontStyle.italic))),
                        ]),
                  ),
                if (billedTptCycleNote.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('***: ', style: styleSmall),
                          pw.SizedBox(
                              width: footnoteWidth,
                              child: pw.Text(billedTptCycleNote,
                                  maxLines: 2,
                                  style: styleSmall.copyWith(
                                      fontStyle: pw.FontStyle.italic))),
                        ]),
                  ),
              ],
            ),
          ],
        ),
      ));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: singularStatList,
    );
  }

  pw.Widget _getTypeRow2(int codePoint, String typeStr, String typeUnit,
      Map<String, dynamic> singularUsageInfo, String typeKeyPrefix) {
    PagEmsTypeUsageCalcRl usageCalc = singularUsageInfo['usage_calc_rl'];

    EmsTypeUsageR2? typeUsage;
    if (typeStr == 'Electricity') {
      typeUsage = usageCalc.getTypeUsage('E');
    } else if (typeStr == 'BTU') {
      typeUsage = usageCalc.getTypeUsage('B');
    } else if (typeStr == 'Water') {
      typeUsage = usageCalc.getTypeUsage('W');
    } else if (typeStr == 'NeWater') {
      typeUsage = usageCalc.getTypeUsage('N');
    } else if (typeStr == 'Gas') {
      typeUsage = usageCalc.getTypeUsage('G');
    }

    if (typeUsage == null) {
      dev.log('Usage is null for type $typeStr');
      return pw.Container();
    }
    if (typeUsage.usage == null) {
      return pw.Container();
    }

    // pw.TextStyle textStyle = pw.TextStyle(
    //   color: _darkColor,
    //   fontSize: size2,
    // );

    double usage = typeUsage.usage!;
    double rate = typeUsage.rate!;
    double cost = typeUsage.cost!;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(90),
        1: const pw.FixedColumnWidth(55),
        2: const pw.FixedColumnWidth(20),
        3: const pw.FixedColumnWidth(35),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          children: [
            pw.Text('  Item',
                style: styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
            pw.Text('  Usage',
                style: styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
            pw.Text('  Rate',
                style: styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
            pw.Text('  Amount',
                style: styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Row(
              children: [
                pw.Icon(
                  pw.IconData(codePoint),
                  color: PdfColors.grey,
                  size: 13,
                ),
                pw.Text(typeStr, style: styleNormal),
              ],
            ),
            pw.Row(
              children: [
                pw.SizedBox(width: 5),
                pw.Text(
                  // '${usage.toStringAsFixed(usageDecimals)} ($typeUnit)',
                  '${getCommaNumberStr(usage, decimal: usageDecimals)} ($typeUnit)',
                  style: styleNormal,
                ),
              ],
            ),
            pw.Row(
              children: [
                pw.SizedBox(width: 5),
                pw.Text(
                  '\$${getCommaNumberStr(rate, decimal: rateDecimals)}',
                  style: styleNormal,
                ),
              ],
            ),
            pw.Row(
              children: [
                pw.SizedBox(width: 5),
                pw.Text(
                  _formatCurrency(cost),
                  style: styleNormal,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _getTotal() {
    final interestAmountObj =
        interestInfo != null ? interestInfo!['total_interest_amount'] : null;
    double billedInterestAmount = 0;
    if (interestAmountObj != null) {
      if (interestAmountObj is double) {
        billedInterestAmount = interestAmountObj;
      } else if (interestAmountObj is String) {
        billedInterestAmount = double.tryParse(interestAmountObj) ?? 0;
      }
    }

    final openingBal =
        miniSoaInfo != null ? miniSoaInfo!['opening_balance'] : null;
    final closingBal =
        miniSoaInfo != null ? miniSoaInfo!['closing_balance'] : null;
    final paymentList =
        miniSoaInfo != null ? miniSoaInfo!['payment_list'] : null;
    double openingBalAmount = 0;
    if (openingBal != null) {
      if (openingBal is double) {
        openingBalAmount = openingBal;
      } else if (openingBal is String) {
        openingBalAmount = (double.tryParse(openingBal) ?? 0);
      }
      openingBalAmount = -1 * openingBalAmount;
    }

    double closingBalAmount = 0;
    if (closingBal != null) {
      if (closingBal is double) {
        closingBalAmount = closingBal;
      } else if (closingBal is String) {
        closingBalAmount = double.tryParse(closingBal) ?? 0;
      }
    }
    closingBalAmount = -1 * closingBalAmount;

// “Non-Taxable Panel” Consists of:
// Late Payment Interest
// [Line Item 2] - Line adjustable that is not GST liable AND interest generating
// [Line Item 3] - Line adjustment that is not GST liable AND NOT interest generating

// Sub-Total (Non-Taxable)
// Late Payment Interest:
// - is the interest generated based on the previous outstanding amounts that were not paid any day during the collection period of this current invoice.
// - system generated
// Line Item 2
// - Definition as per background above
// - keyed-in by C&W
// Line Item 3
// - Definition as per background aboved
// - keyed-in by C&W
// Sub-Total (Non-Taxable) = (1) + (2) + (3)

    double latePaymentInterestAmount =
        billedInterestAmount - (lineItemValue3 ?? 0.0);

    double subTotalNonTaxable = latePaymentInterestAmount +
        (lineItemValue2 ?? 0.0) +
        (lineItemValue3 ?? 0.0);

    return pw.Container(
      width: 500,
      child: pw.Column(
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600, width: 1),
              borderRadius: pw.BorderRadius.circular(3.0),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: pw.Column(
              children: [
                if (lineItemLabel1 != null && lineItemValue1 != null)
                  if (lineItemValue1!.abs() > 0.0001)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(lineItemLabel1!, style: styleNormal),
                        pw.Text(_formatCurrency(lineItemValue1!),
                            style: styleNormal),
                      ],
                    ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Usage Total', style: styleNormal),
                    pw.Text(_formatCurrency(totalUsageCost ?? 0),
                        style: styleNormal),
                  ],
                ),
                // bci
                getBci(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Sub-Total (Taxable)',
                      style:
                          styleNormal.copyWith(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      _formatCurrency(subTotalAmount),
                      style:
                          styleNormal.copyWith(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Divider(color: PdfColors.grey600, thickness: 0.5, height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'GST (${gst ?? 0}%)',
                      style:
                          styleNormal.copyWith(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      _formatCurrency(gstAmount),
                      style:
                          styleNormal.copyWith(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Divider(color: PdfColors.grey600, thickness: 0.5, height: 5),
                if (latePaymentInterestAmount.abs() > 0.0001)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Late Payment Interest',
                        style: styleNormal,
                      ),
                      pw.Text(
                        _formatCurrency(latePaymentInterestAmount),
                        style: styleNormal,
                      ),
                    ],
                  ),
                // line item 2
                if (lineItemLabel2 != null && lineItemValue2 != null)
                  if (lineItemValue2!.abs() > 0.0001)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          lineItemLabel2!,
                          style: styleNormal,
                        ),
                        pw.Text(
                          _formatCurrency(lineItemValue2!),
                          style: styleNormal,
                        ),
                      ],
                    ),
                // line item 3
                if (lineItemLabel3 != null && lineItemValue3 != null)
                  if (lineItemValue3!.abs() > 0.0001)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          lineItemLabel3!,
                          style: styleNormal,
                        ),
                        pw.Text(
                          _formatCurrency(lineItemValue3!),
                          style: styleNormal,
                        ),
                      ],
                    ),
                // sub total (non-taxable)
                if (subTotalNonTaxable.abs() > 0.0001)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Sub-Total (Non-Taxable)',
                        style: styleNormal.copyWith(
                            fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        _formatCurrency(subTotalNonTaxable),
                        style: styleNormal.copyWith(
                            fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                pw.Divider(color: PdfColors.grey600, thickness: 0.5, height: 5),
                pw.Container(
                    color: PdfColors.grey300,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 3, horizontal: 1),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Total Current Charge',
                            style: styleNormal.copyWith(
                                fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            _formatCurrency(cycleTotalAmount),
                            style: styleNormal.copyWith(
                                fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          if (openingBal != null)
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600, width: 0.5),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Balance B/F from previous invoice',
                        style: styleNormal,
                      ),
                      pw.Text(_formatCurrency(openingBalAmount),
                          style: styleNormal),
                    ],
                  ),
                  if (paymentList != null)
                    ...paymentList.map<pw.Widget>((payment) {
                      final paymentAmountObj = payment['credit_amount'];
                      final paymentDateStr = payment['entry_timestamp'] ?? '';
                      double paymentAmount = 0;
                      if (paymentAmountObj != null) {
                        if (paymentAmountObj is double) {
                          paymentAmount = -1 * paymentAmountObj;
                        } else if (paymentAmountObj is String) {
                          paymentAmount =
                              double.tryParse(paymentAmountObj) ?? 0;
                        }
                      }
                      paymentAmount = -1 * paymentAmount;
                      return pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Payment received as at ${_getDateStr(paymentDateStr)}',
                            style: styleNormal,
                          ),
                          pw.Text(
                            _formatCurrency(paymentAmount),
                            style: styleNormal,
                          ),
                        ],
                      );
                    }).toList(),
                  pw.Container(
                    color: PdfColors.grey300,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 3, horizontal: 1),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'Balance C/F as at* ${_getDateStr(strCollectionEndDate)}',
                            style: styleNormal.copyWith(
                                fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            _formatCurrency(closingBalAmount),
                            style: styleNormal.copyWith(
                                fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 3),
          pw.Row(children: [
            pw.Text(
              '* payments made close to this collection end date may not be reflected',
              style: styleSmall.copyWith(fontStyle: pw.FontStyle.italic),
            ),
          ]),
          pw.SizedBox(height: 3),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600, width: 2),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            child: pw.Container(
              color: PdfColors.grey300,
              child: pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 1),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      // 'Balance Due (Due Date: ${_getDateStr(dueDate)})',
                      'Balance Due',
                      style:
                          styleLarge.copyWith(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      _formatCurrency(payableAmount),
                      style:
                          styleLarge.copyWith(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget getBci() {
    if ((billedBciInfoList ?? []).isEmpty) {
      return pw.SizedBox();
    }
    return pw.Column(
      children: billedBciInfoList!.map<pw.Widget>((bciInfo) {
        String bciLabel = bciInfo['billing_cost_item_label'] ?? '';
        double bciAmt = 0;
        final bciAmtObj = bciInfo['billing_cost_item_amount'];
        if (bciAmtObj != null) {
          if (bciAmtObj is double) {
            bciAmt = bciAmtObj;
          } else if (bciAmtObj is String) {
            bciAmt = double.tryParse(bciAmtObj) ?? 0;
          }
        }
        if (bciAmt.abs() < 0.0001) {
          return pw.SizedBox();
        }
        return pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(bciLabel, style: styleNormal),
            pw.Text(_formatCurrency(bciAmt), style: styleNormal),
          ],
        );
      }).toList(),
    );
  }

  pw.Widget _getMeterTypeMeterListUsage() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // pw.Text('Meter Type & Usage', style: styleNormal),
        // pw.SizedBox(height: 5),
        _getSingluarStat(),
      ],
    );
  }

  pw.Widget _getSingluarStat() {
    List<pw.Widget> singularStatList = [];
    for (Map<String, dynamic> singularUsageInfo
        in tenantSingularUsageInfoList) {
      List<pw.Widget> typeStatList = [];
      String slotFromTimestampStr = singularUsageInfo['from_timestamp'] ?? '';
      String slotToTimestampStr = singularUsageInfo['to_timestamp'] ?? '';
      if (strEffectiveTo.isNotEmpty) {
        slotToTimestampStr = strEffectiveTo;
      }
      String slotStr =
          '  ${slotFromTimestampStr.substring(0, 10)} - ${slotToTimestampStr.substring(0, 10)}';
      typeStatList.add(_getTypeStat(singularUsageInfo, 'E'));
      typeStatList.add(_getTypeStat(singularUsageInfo, 'B'));
      typeStatList.add(_getTypeStat(singularUsageInfo, 'W'));
      typeStatList.add(_getTypeStat(singularUsageInfo, 'N'));
      typeStatList.add(_getTypeStat(singularUsageInfo, 'G'));
      singularStatList.add(pw.Container(
        width: 550,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _darkColor, width: 1),
          borderRadius: pw.BorderRadius.circular(5.0),
        ),
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text(slotStr,
                    style:
                        styleNormal.copyWith(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 5),
            ...typeStatList,
          ],
        ),
      ));
    }

    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        // verticalSpaceSmall,
        ...singularStatList,
      ],
    );
  }

  pw.Widget _getTypeStat(
      Map<String, dynamic> singularUsageInfo, String targetMeterTypeTag) {
    PagMeterType? meterType = PagMeterType.byTag(targetMeterTypeTag);
    assert(meterType != PagMeterType.unknown, 'meterType cannot be unknown');

    String slotFromTimestampStr = singularUsageInfo['from_timestamp'] ?? '';
    String slotToTimestampStr = singularUsageInfo['to_timestamp'] ?? '';
    assert(
      slotFromTimestampStr.isNotEmpty && slotToTimestampStr.isNotEmpty,
      'from_timestamp and to_timestamp cannot be empty',
    );
    // String slotStr = '  ${slotFromTimestampStr.substring(0, 10)} - ${slotToTimestampStr.substring(0, 10)}';
    String genType = singularUsageInfo['gen_type'] ?? '';
    String excludeAutoUsageStr = singularUsageInfo['exclude_auto_usage'] ?? '';
    List<pw.TableRow> typeGroupList = [];
    if ('true' == excludeAutoUsageStr) {
      return _getManualUsage(singularUsageInfo, targetMeterTypeTag);
    } else {
      final tenantUsageSummary = singularUsageInfo['tenant_usage_summary'];
      assert(tenantUsageSummary != null, 'tenantUsageSummary cannot be null');

      final meterGroupUsageList =
          tenantUsageSummary['meter_group_usage_list'] ?? [];
      final typeGroupInfoList = meterGroupUsageList
          .where((element) => element['meter_type'] == targetMeterTypeTag)
          .toList();
      // List<pw.TableRow> typeGroupList = [];
      for (var groupInfo in typeGroupInfoList) {
        String meterTypeTag = groupInfo['meter_type'] ?? '';
        // MeterType? meterType = getMeterType(meterTypeTag);
        PagMeterType? meterType = PagMeterType.byTag(meterTypeTag);
        assert(
            meterType != PagMeterType.unknown, 'meterType cannot be unknown');

        Map<String, dynamic>? meterTypeRateInfo =
            singularUsageInfo['meter_type_rate_info'];
        assert(meterTypeRateInfo != null, 'meterTypeRateInfo cannot be null');
        PagEmsTypeUsageCalcRl? usageCalc = singularUsageInfo['usage_calc_rl'];
        assert(usageCalc != null, 'usageCalc cannot be null');

        double? typeUsageFactor = usageCalc!.getTypeUsageFactor(meterTypeTag);

        final meterGroupUsageSummary =
            groupInfo['meter_group_usage_summary'] ?? [];
        final meterUsageList = meterGroupUsageSummary['meter_usage_list'] ?? [];
        for (Map<String, dynamic> meterUsageInfo in meterUsageList) {
          final meterUsageSummary = meterUsageInfo['meter_usage_summary'];
          String meterSn = meterUsageSummary['meter_sn'] ?? '';
          String locatinLabel = meterUsageSummary['location_label'] ?? '';
          String buildingLabel = meterUsageSummary['building_label'] ?? '';
          String strFirstReading =
              meterUsageSummary['first_reading_value'] ?? '';
          String strLastReading = meterUsageSummary['last_reading_value'] ?? '';
          String strUsage = meterUsageSummary['usage'] ?? '';

          typeGroupList.add(pw.TableRow(
            children: [
              pw.Text('  $buildingLabel', style: styleSmall),
              pw.Text('  $meterSn', style: styleSmall),
              pw.Text('  $locatinLabel', style: styleSmall),
              pw.Text('  $strFirstReading', style: styleSmall),
              pw.Text('  $strLastReading', style: styleSmall),
              pw.Text('  x${typeUsageFactor?.toStringAsFixed(0) ?? ''}',
                  style: styleSmall),
              pw.Text('  $strUsage', style: styleSmall),
              pw.Text('  ${meterType.unit}', style: styleSmall),
            ],
          ));
        }
      }
      if (typeGroupList.isEmpty) {
        return pw.Container();
      }
      // meterUsageInfoList.add(pw.Column(
      //   children: [...typeGroupList],
      // ));
    }

    return pw.Column(children: [
      pw.Row(
        children: [
          pw.Icon(pw.IconData(meterType.iconData.codePoint),
              color: PdfColors.grey, size: 13),
          pw.Text(' ${meterType.label}', style: styleNormal),
        ],
      ),
      pw.SizedBox(height: 2),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
        columnWidths: {
          0: const pw.FixedColumnWidth(120),
          1: const pw.FixedColumnWidth(55),
          2: const pw.FixedColumnWidth(65),
          3: const pw.FixedColumnWidth(65),
          4: const pw.FixedColumnWidth(65),
          5: const pw.FixedColumnWidth(20),
          6: const pw.FixedColumnWidth(60),
          7: const pw.FixedColumnWidth(30),
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        children: [
          pw.TableRow(
            children: [
              pw.Text('  Building',
                  style: styleSmall.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.Text('  Meter S/N',
                  style: styleSmall.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.Text('  Unit Number',
                  style: styleSmall.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.Text('  First Reading',
                  style: styleSmall.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.Text('  Last Reading',
                  style: styleSmall.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.Text('  M',
                  style: styleSmall.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.Text('  Usage',
                  style: styleSmall.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.Text('  Unit',
                  style: styleSmall.copyWith(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          // ...meterUsageInfoList,
          ...typeGroupList,
        ],
      )
    ]);
  }

  pw.Widget _getManualUsage(
      Map<String, dynamic> singularUsageInfo, String typeStr) {
    final manualUsageList = singularUsageInfo['manual_usage_list'] ?? [];
    if (manualUsageList.isEmpty) {
      return pw.Container();
    }
    List<pw.Widget> manualUsageWidgets = [];
    for (var manualUsage in manualUsageList) {
      String usageType = manualUsage['usage_type'] ?? '';
      if (usageType != typeStr) {
        continue;
      }
      double usage = double.tryParse(manualUsage['usage'] ?? '0') ?? 0;
      String unit = manualUsage['unit'] ?? '';
      manualUsageWidgets.add(
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Manual Usage', style: styleNormal),
            pw.Text('${getCommaNumberStr(usage)} ($unit)', style: styleNormal),
          ],
        ),
      );
    }
    return pw.Column(children: [...manualUsageWidgets]);
  }

  pw.Widget _getTrending(List<Map<String, dynamic>>? trending) {
    if (trending == null) {
      return pw.SizedBox();
    }
    if (trending.isEmpty) {
      return pw.SizedBox();
    }
    if ((trending).isNotEmpty) {
      //reverse the list
      trending = trending.reversed.toList();
    }

    int lookBackMonthCap = 6;
    int lookBackMonth = trending.length;
    if (lookBackMonth > lookBackMonthCap) {
      lookBackMonth = lookBackMonthCap;
    }

    List<Map<String, dynamic>> trendingLastMonthSuper = [];
    for (int i = 0; i < lookBackMonth; i++) {
      trending[i]['label'] = trending[i]['label'] + '';
      String valueStr = getBarNumberStr(trending[i]['value'] as double);
      trending[i]['valueStr'] = valueStr;

      var item = trending[i];
      if (i == lookBackMonth - 1) {
        trendingLastMonthSuper.add({
          'label': item['label'],
          'value': item['value'],
          'valueStr': '',
        });
      } else {
        trendingLastMonthSuper.add({
          'label': item['label'],
          'value': 0,
          'valueStr': '',
        });
      }
    }

    //if length less then lookBackMonth, add empty data
    if (trending.length < lookBackMonth) {
      for (int i = 0; i < lookBackMonth - trending.length; i++) {
        trending.insert(0, {
          'label': '',
          'value': 0,
          'valueStr': '',
        });
        trendingLastMonthSuper.insert(0, {
          'label': '',
          'value': 0,
          'valueStr': '',
        });
      }
    }

    pw.TextStyle labelStyle = const pw.TextStyle(
      color: _darkColor,
      fontSize: 9,
    );
    return pw.Container(
      height: 100,
      width: 350,
      child: trending.isEmpty
          ? pw.SizedBox()
          : pw.Stack(
              children: [
                pw.Chart(
                  left: pw.Container(
                    alignment: pw.Alignment.topCenter,
                    margin: const pw.EdgeInsets.only(right: 5, top: 10),
                    child: pw.Transform.rotateBox(
                      angle: pi / 2,
                      child: pw.Text(''),
                    ),
                  ),
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis.fromStrings(
                      color: PdfColors.white,
                      List<String>.generate(
                        lookBackMonth, // trending.length,
                        (index) =>
                            // '${trending?[index]['label']}\n ${trending?[index]['value']}',
                            // '${trending?[index]['label']}',
                            '',
                      ),
                      marginStart: 30,
                      marginEnd: 30,
                      ticks: false,
                      textStyle: const pw.TextStyle(
                        color: PdfColors.grey,
                        fontSize: 9,
                      ),
                      buildLabel: (num i) {
                        int index = i.toInt();
                        return pw.Transform.translate(
                          offset: const PdfPoint(-10, 0),
                          child: pw.Column(
                            children: [
                              pw.Text('_',
                                  style: labelStyle.copyWith(
                                      color: PdfColors.white)),
                              pw.Text('_',
                                  style: labelStyle.copyWith(
                                      color: PdfColors.white)),
                            ],
                          ),
                        );
                      },
                    ),
                    yAxis: _getTrendingAxis(trending),
                  ),
                  datasets: [
                    pw.BarDataSet(
                      color: PdfColors.white,
                      legend: tableHeaders[2],
                      width: 15,
                      offset: -10,
                      borderColor: PdfColors.grey,
                      data: List<pw.PointChartValue>.generate(
                        lookBackMonth, // trending.length,
                        (i) {
                          final v = trending?[i]['value'] as num;
                          return pw.PointChartValue(i.toDouble(), v.toDouble());
                        },
                      ),
                    ),
                  ],
                ),
                pw.Chart(
                  left: pw.Container(
                    alignment: pw.Alignment.topCenter,
                    margin: const pw.EdgeInsets.only(right: 5, top: 10),
                    child: pw.Transform.rotateBox(
                      angle: pi / 2,
                      child: pw.Text(''),
                    ),
                  ),
                  grid: pw.CartesianGrid(
                    xAxis: pw.FixedAxis.fromStrings(
                      color: PdfColors.grey300,
                      List<String>.generate(
                        lookBackMonth, //trending.length,
                        (index) =>
                            // trending?[index]['label'] as String,
                            '',
                      ),
                      marginStart: 30,
                      marginEnd: 30,
                      ticks: false,
                      textStyle: const pw.TextStyle(
                        color: PdfColors.grey,
                        fontSize: 9,
                      ),
                      buildLabel: (num i) {
                        int index = i.toInt();
                        String monthLabel =
                            _getMonthLable(trending?[index]['label'] as String);
                        return pw.Transform.translate(
                          offset: const PdfPoint(-10, 0),
                          child: pw.Column(
                            children: [
                              pw.Text(monthLabel, style: labelStyle),
                              pw.Text((trending?[index]['valueStr'] ?? ''),
                                  style: labelStyle),
                            ],
                          ),
                        );
                      },
                    ),
                    yAxis: _getTrendingAxis(trending),
                  ),
                  datasets: [
                    pw.BarDataSet(
                      color: PdfColors.grey,
                      legend: tableHeaders[2],
                      width: 15,
                      offset: -10,
                      borderColor: PdfColors.grey,
                      data: List<pw.PointChartValue>.generate(
                        lookBackMonth, //trending.length,
                        (i) {
                          final v = trendingLastMonthSuper[i]['value'] as num;
                          return pw.PointChartValue(i.toDouble(), v.toDouble());
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  pw.FixedAxis _getTrendingAxis(List<Map<String, dynamic>> trending) {
    double max = 0;
    for (var item in trending) {
      final value = item['value'] as double;
      if (value > max) {
        max = value;
      }
    }
    int numberOfTicks = 2;
    List<double> ticks = [];

    //if max is 0, set to 1 otherwise it will throw error
    if (max == 0) {
      max = 1;
    }
    for (var i = 0; i < numberOfTicks; i++) {
      ticks.add((max / (numberOfTicks - 1)) * i);
    }
    return pw.FixedAxis(
      color: PdfColors.grey300,
      divisionsColor: PdfColors.grey300,
      ticks,
      format: (v) => '', //(v) => '$v',
      divisions: true,
    );
  }

  String _formatCurrency(double? amount, {bool isRoundUp = false}) {
    if (amount == null) {
      return '-';
    }
    double value = isRoundUp ? getRoundUp(amount, 2) : getRound(amount, 2);
    String commaText = getCommaNumberStr(value, decimal: 2);
    return '\$$commaText';

    // return '\$${isRoundUp ? getRoundUp(amount, 2) : amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final format = DateFormat.yMMMd('en_US');
    return format.format(date);
  }

  String _getMonthLable(String label) {
    if (label.isEmpty) {
      return '';
    }
    //change 2024-6 to Jun'24
    List<String> monthList = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    List<String> dateList = label.split('-');
    if (dateList.length != 2) {
      return '';
    }
    int month = int.parse(dateList[1]);
    return '${monthList[month - 1]}\'${dateList[0].substring(2)}';
  }

  String getBarNumberStr(double value) {
    bool useG = false;
    bool useM = false;
    bool useK = false;
    if (value >= 10000000000) {
      value = value / 1000000000;
      useG = true;
    } else if (value >= 10000000) {
      value = value / 1000000;
      useM = true;
    } else if (value >= 10000) {
      value = value / 1000;
      useK = true;
    }
    return value.toStringAsFixed(1) +
        (useG
            ? 'G'
            : useM
                ? 'M'
                : useK
                    ? 'K'
                    : '');
  }
}
