import 'dart:math';
import 'dart:typed_data';
import 'package:buff_helper/pagrid_helper/ems_helper/tenant/mdl_ems_type_usage_r2.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/tenant/pag_ems_type_usage_calc_rl.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/up_helper/helper/tenant_def.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:developer' as dev;

const int boltIcon = 0xea0b;
const int waterIcon = 0xf084;
const int hvacIcon = 0xf10e;
const int gasIcon = 0xec19;
const int waterDropIcon = 0xe798;

const int usageDecimals = 3;
const int rateDecimals = 4;

const tableHeaders = ['Category', 'Budget', 'Expense', 'Result'];

Future<Uint8List> generatePagInvoice(
  PdfPageFormat pageFormat,
  Map<String, dynamic> billInfo,
) async {
  final invoice = PagBill(
    billingRecName: billInfo['billingRecName'],
    billLabel: billInfo['billLabel'],
    customerLabel: billInfo['customerLabel'],
    customerName: billInfo['customerName'],
    tenantAccountNumber: billInfo['customerAccountId'] ?? '',
    depositAmountStr: billInfo['depositAmountStr'] ?? '',
    paymentMethod: billInfo['paymentMethod'] ?? '',
    tenantBillingAddressLine1: billInfo['tenantBillingAddressLine1'] ?? '',
    tenantBillingAddressLine2: billInfo['tenantBillingAddressLine2'] ?? '',
    tenantBillingAddressLine3: billInfo['tenantBillingAddressLine3'] ?? '',
    customerType: billInfo['customerType'] ?? '',
    gst: billInfo['gst'],
    paymentInfo: billInfo['paymentInfo'] ?? '',
    billTimeRangeStr: billInfo['billTimeRangeStr'],
    billFromStr: billInfo['billFrom'],
    billToStr: billInfo['billTo'],
    billDateStr: billInfo['billDate'],
    totalUsageCost: billInfo['totalUsageCost'],
    subTotalAmount: billInfo['subTotalAmount'],
    gstAmount: billInfo['gstAmount'],
    totalAmount: billInfo['totalAmount'],
    interestInfo: billInfo['interestInfo'],
    payableAmount: billInfo['payableAmount'],
    miniSoaInfo: billInfo['miniSoaInfo'],
    dueDate: billInfo['dueDate'],
    typeRateE: billInfo['typeRateE'],
    typeRateW: billInfo['typeRateW'],
    typeRateB: billInfo['typeRateB'],
    typeRateN: billInfo['typeRateN'],
    typeRateG: billInfo['typeRateG'],
    typeUsageE: billInfo['typeUsageE'],
    typeUsageW: billInfo['typeUsageW'],
    typeUsageB: billInfo['typeUsageB'],
    typeUsageN: billInfo['typeUsageN'],
    typeUsageG: billInfo['typeUsageG'],
    typeCostE: billInfo['typeCostE'],
    typeCostW: billInfo['typeCostW'],
    typeCostB: billInfo['typeCostB'],
    typeCostN: billInfo['typeCostN'],
    typeCostG: billInfo['typeCostG'],
    trendingE: billInfo['trendingE'],
    trendingW: billInfo['trendingW'],
    trendingB: billInfo['trendingB'],
    trendingN: billInfo['trendingN'],
    trendingG: billInfo['trendingG'],
    lineItemLabel1: billInfo['lineItemLabel1'],
    lineItemValue1: billInfo['lineItemValue1'],
    lineItemLabel2: billInfo['lineItemLabel2'],
    lineItemValue2: billInfo['lineItemValue2'],
    assetFolder: billInfo['assetFolder'],
    tenantSingularUsageInfoList: billInfo['tenantSingularUsageInfoList'],
    billedAmgrCompanyTradingName: billInfo['billedAmgrCompanyTradingName'],
    billedAmgrCompanyRegNumber: billInfo['billedAmgrCompanyRegNumber'],
    billedAmgrGstRegNumber: billInfo['billedAmgrGstRegNumber'],
    amgrAddressLine1: billInfo['amgrAddressLine1'],
    amgrAddressLine2: billInfo['amgrAddressLine2'],
    amgrAddressLine3: billInfo['amgrAddressLine3'],
    billedTptNote: billInfo['billedTptNote'],
    tax: .15,
    baseColor: PdfColors.teal,
    accentColor: PdfColors.blueGrey900,
  );

  return await invoice.buildPdf(pageFormat);
}

class PagBill {
  PagBill({
    required this.customerName,
    required this.tenantAccountNumber,
    required this.customerLabel,
    required this.tenantBillingAddressLine1,
    required this.tenantBillingAddressLine2,
    required this.tenantBillingAddressLine3,
    required this.customerType,
    required this.depositAmountStr,
    required this.paymentMethod,
    required this.gst,
    required this.billingRecName,
    required this.billLabel,
    required this.billFromStr,
    required this.billToStr,
    required this.billDateStr,
    required this.billTimeRangeStr,
    required this.subTotalAmount,
    required this.gstAmount,
    required this.totalAmount,
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
    required this.payableAmount,
    required this.dueDate,
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
    required this.billedTptNote,
  });

  final String customerLabel;
  final String customerName;
  final String tenantAccountNumber;
  final String tenantBillingAddressLine1;
  final String tenantBillingAddressLine2;
  final String tenantBillingAddressLine3;
  final String customerType;
  final String depositAmountStr;
  final String paymentMethod;
  final double? gst;
  final String billingRecName;
  final String billLabel;
  final String billFromStr;
  final String billToStr;
  final String billDateStr;
  final String dueDate;
  final String billTimeRangeStr;
  final double? totalUsageCost;
  final double? subTotalAmount;
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
  final String? billedTptNote;
  static const _darkColor = PdfColors.blueGrey800;
  static const _lightColor = PdfColors.white;

  PdfColor get _baseTextColor => baseColor.isLight ? _lightColor : _darkColor;

  PdfColor get _accentTextColor => baseColor.isLight ? _lightColor : _darkColor;

  late final _logo;

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

    // Return the PDF file content
    return doc.save();
  }

  Future<pw.MultiPage> getPage1() async {
    double pageWidth = PdfPageFormat.a4.width;
    dev.log('Page width: $pageWidth');

    return pw.MultiPage(
      pageTheme: pw.PageTheme(
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.openSansRegular(),
          bold: await PdfGoogleFonts.openSansBold(),
          icons: await PdfGoogleFonts.materialSymbolsOutlinedRegular(),
        ),
      ),
      header: _buildHeader,
      footer: _buildFooter,
      build: (context) => [
        _contentHeader(context),
        pw.SizedBox(height: 5),
        _getBillTime(),
        _getSingularList(),
        pw.SizedBox(height: 5),
        _getTotal(),
        // _getContentFooter(context),
        // pw.SizedBox(height: 10),
        // _termsAndConditions(context),
      ],
    );
  }

  pw.Widget _buildHeader(pw.Context context) {
    // int codePoint = mt.Icons.abc.codePoint;
    //hex
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 210,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisSize: pw.MainAxisSize.min,
                children: [_getLogo(), _getBillerInfo()],
              ),
            ),
            pw.Expanded(child: pw.Container()),
            pw.SizedBox(width: 250, child: _getPaymentInfo()),
          ],
        ),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(width: 250, child: _getPayerInfo()),
          ],
        ),
        if (context.pageNumber > 1) pw.SizedBox(height: 20)
      ],
    );
  }

  pw.Widget _getLogo() {
    return pw.Container(
      alignment: pw.Alignment.topLeft,
      // padding: const pw.EdgeInsets.only(bottom: 8, left: 30),
      height: 50,
      child: _logo != null ? pw.Image(_logo!) : pw.PdfLogo(),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.start,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(),
        // pw.Container(
        //   height: 20,
        //   width: 100,
        //   child: pw.BarcodeWidget(
        //     barcode: pw.Barcode.pdf417(),
        //     data: 'Invoice# $billingRecName',
        //     drawText: false,
        //   ),
        // ),
        // pw.Text(
        //   'Page ${context.pageNumber}/${context.pagesCount}',
        //   style: const pw.TextStyle(
        //     fontSize: 12,
        //     color: PdfColors.white,
        //   ),
        // ),
        pw.Text(
          'Bill Number: $billingRecName',
          style: const pw.TextStyle(color: _darkColor, fontSize: 9),
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
    return pw.SizedBox(height: 5);
  }

  pw.Widget _getPayerInfo() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(customerLabel,
            style: pw.TextStyle(
                color: _darkColor,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Row(children: [
          pw.Text(tenantBillingAddressLine1,
              style: const pw.TextStyle(color: _darkColor, fontSize: 10)),
        ]),
        pw.Row(children: [
          pw.Text(tenantBillingAddressLine2,
              style: const pw.TextStyle(color: _darkColor, fontSize: 10)),
        ]),
        pw.Row(children: [
          pw.Text(tenantBillingAddressLine3,
              style: const pw.TextStyle(color: _darkColor, fontSize: 10)),
        ]),
      ],
    );
  }

  pw.Widget _getPaymentInfo() {
    pw.TextStyle textStyle = const pw.TextStyle(
      color: _darkColor,
      fontSize: 9,
    );
    pw.TextStyle textStyleLarge = pw.TextStyle(
      color: _darkColor,
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
    );
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      // mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        pw.SizedBox(
          height: 160,
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 20),
                pw.Text('TAX INVOICE',
                    style: pw.TextStyle(
                        color: _darkColor,
                        fontSize: 13.5,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
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
                        pw.Text(' Account Number:', style: textStyle),
                        pw.Text(' $tenantAccountNumber', style: textStyle)
                      ]),
                      pw.TableRow(children: [
                        pw.Text(' Invoice Number:', style: textStyle),
                        pw.Text(' $billLabel', style: textStyle),
                      ]),
                      pw.TableRow(children: [
                        pw.Text(' Date of Invoice:', style: textStyle),
                        pw.Text(' ${billDateStr.substring(0, 10)}',
                            style: textStyle),
                      ]),
                      pw.TableRow(children: [
                        pw.Text(' Deposit Amount:', style: textStyle),
                        pw.Text(' $depositAmountStr', style: textStyle),
                      ]),
                      pw.TableRow(children: [
                        pw.Text(' Mode of Payment:', style: textStyle),
                        pw.Text(' $paymentMethod', style: textStyle),
                      ]),
                    ]),
                pw.SizedBox(height: 15),
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
                        pw.Text(' Total Amount Payable:', style: textStyle),
                        pw.Text(' $payableAmount', style: textStyleLarge),
                      ]),
                      pw.TableRow(children: [
                        pw.Text(' Due Date:', style: textStyle),
                        pw.Text(' ${dueDate.substring(0, 10)}',
                            style: textStyleLarge),
                      ]),
                    ]),
              ]),
        ),
      ],
    );
  }

  String _getBillingPeriodStr() {
    DateTime billFrom = DateTime.parse(billFromStr);
    DateTime billTo = DateTime.parse(billToStr);
    String formattedFrom = DateFormat('dd MMM yyyy').format(billFrom);
    String formattedTo = DateFormat('dd MMM yyyy').format(billTo);
    return '$formattedFrom - $formattedTo';
  }

  String _getBillDate() {
    DateTime billDate = DateTime.parse(billDateStr);
    String formattedDate = DateFormat('dd MMM yyyy').format(billDate);
    return formattedDate;
  }

  pw.Widget _getBillTime() {
    return pw.SizedBox(
      height: 20,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Text('Billing Period: ',
                style: pw.TextStyle(
                    color: _darkColor, fontWeight: pw.FontWeight.bold)),
            pw.Text(_getBillingPeriodStr(),
                style: const pw.TextStyle(color: _darkColor, fontSize: 11)),
          ]),
          pw.SizedBox(width: 50),
          pw.Row(children: [
            pw.Text('Bill Date: ',
                style: pw.TextStyle(
                    color: _darkColor, fontWeight: pw.FontWeight.bold)),
            pw.Text(_getBillDate(),
                style: const pw.TextStyle(color: _darkColor, fontSize: 11)),
          ]),
        ],
      ),
    );
  }

  pw.Widget _getBillerInfo() {
    pw.TextStyle textStyle = const pw.TextStyle(
      color: _darkColor,
      fontSize: 10,
    );
    return pw.SizedBox(
        height: 90,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(billedAmgrCompanyTradingName ?? '',
                style: pw.TextStyle(
                    color: _darkColor, fontWeight: pw.FontWeight.bold)),
            pw.Text('Company Reg No: ${billedAmgrCompanyRegNumber ?? ''}',
                style: textStyle),
            pw.Text('GST Reg No: ${billedAmgrGstRegNumber ?? ''}',
                style: textStyle),
            pw.Text(amgrAddressLine1 ?? '', style: textStyle),
            pw.Text(amgrAddressLine2 ?? '', style: textStyle),
            pw.Text(amgrAddressLine3 ?? '', style: textStyle),
          ],
        ));
  }

  pw.Widget _getContentFooter(pw.Context context) {
    double width = 130;

    // double? subTotalAmt = totalAmount;
    // if (subTotalAmt != null) {
    //   // subTotalAmt = getRoundUp(subTotalAmt, 2);
    //   // subTotalAmt = getRound(subTotalAmt, 2);
    // }
    // double? totalAmt = subTotalAmt;
    bool applyGst = false;
    // double? gstAmt;
    if (TenantType.cw_nus_internal != getTenantType(customerType)) {
      applyGst = true;
      //   if (subTotalAmt != null && gst != null) {
      //     subTotalAmt = getRound(subTotalAmt, 2);
      //     gstAmt = subTotalAmt * gst! / 100;
      //     gstAmt = getRoundUp(gstAmt, 2);
      //     // total = subTotal + subTotal * (gst / 100);
      //     totalAmt = subTotalAmt + gstAmt;
      // }
    } else {
      applyGst = false;
      //   if (subTotalAmt != null) {
      //     totalAmt = getRoundUp(subTotalAmt, 2);
      //   }
    }
    return applyGst
        ? pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Container()),
                pw.Container(
                  width: width,
                  child: pw.Column(
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            'Sub Total:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Expanded(child: pw.Container()),
                          pw.Text(
                            _formatCurrency(subTotalAmount),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'GST ($gst%)',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Expanded(child: pw.Container()),
                          pw.Text(
                            // _formatCurrency(subTotalAmt * (gst / 100)),
                            _formatCurrency(gstAmount),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Total:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Expanded(child: pw.Container()),
                          pw.Text(
                            _formatCurrency(totalAmount),
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Container()),
                pw.Container(
                  width: width,
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'Total:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(child: pw.Container()),
                      pw.Text(
                        _formatCurrency(subTotalAmount, isRoundUp: false),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
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
    for (Map<String, dynamic> singularUsageInfo
        in tenantSingularUsageInfoList) {
      List<pw.Widget> typeStatList = [];
      String slotFromTimestampStr = singularUsageInfo['from_timestamp'] ?? '';
      String slotToTimestampStr = singularUsageInfo['to_timestamp'] ?? '';
      String slotStr =
          '  ${slotFromTimestampStr.substring(0, 10)} - ${slotToTimestampStr.substring(0, 10)}';
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
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Text(slotStr,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                        fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 5),
            ...typeStatList,
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
    PagEmsTypeUsageCalcRl usageCalc = singularUsageInfo['usage_calc'];

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

    pw.TextStyle textStyle = const pw.TextStyle(
      color: _darkColor,
      fontSize: 10,
    );

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
            pw.Text('  Item', style: textStyle),
            pw.Text('  Usage', style: textStyle),
            pw.Text('  Rate', style: textStyle),
            pw.Text('  Sub-total', style: textStyle),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Row(
              children: [
                pw.Icon(
                  pw.IconData(codePoint),
                  color: PdfColors.grey,
                  size: 16,
                ),
                pw.Text(
                  typeStr,
                  style: const pw.TextStyle(color: _darkColor),
                ),
              ],
            ),
            pw.Row(
              children: [
                pw.SizedBox(width: 5),
                pw.Text(
                  '${usage.toStringAsFixed(usageDecimals)} ($typeUnit)',
                  style: textStyle,
                ),
              ],
            ),
            pw.Row(
              children: [
                pw.SizedBox(width: 5),
                pw.Text(
                  '\$${rate.toStringAsFixed(rateDecimals)}',
                  style: textStyle,
                ),
              ],
            ),
            pw.Row(
              children: [
                pw.SizedBox(width: 5),
                pw.Text(
                  _formatCurrency(cost),
                  style: textStyle,
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
    double interestAmount = 0;
    if (interestAmountObj != null) {
      if (interestAmountObj is double) {
        interestAmount = interestAmountObj;
      } else if (interestAmountObj is String) {
        interestAmount = double.tryParse(interestAmountObj) ?? 0;
      }
    }

    final closingBal =
        miniSoaInfo != null ? miniSoaInfo!['closing_balance'] : null;
    double closingBalAmount = 0;
    if (closingBal != null) {
      if (closingBal is double) {
        closingBalAmount = closingBal;
      } else if (closingBal is String) {
        closingBalAmount = double.tryParse(closingBal) ?? 0;
      }
    }
    closingBalAmount = -1 * closingBalAmount;

    return pw.Container(
        width: 500,
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey600, width: 1),
          borderRadius: pw.BorderRadius.circular(5.0),
        ),
        child: pw.Column(
          children: [
            //cf
            if (closingBal != null)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Closing Balance from Previous Bill',
                    style: pw.TextStyle(
                      color: _darkColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _formatCurrency(closingBalAmount),
                    style: pw.TextStyle(
                      color: _darkColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (lineItemLabel1 != null && lineItemValue1 != null)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    lineItemLabel1!,
                    style: pw.TextStyle(
                      color: _darkColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _formatCurrency(lineItemValue1!),
                    style: pw.TextStyle(
                      color: _darkColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Usage Total',
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _formatCurrency(totalUsageCost ?? 0),
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Sub Total',
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _formatCurrency(subTotalAmount),
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'GST (${gst ?? 0}%)',
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _formatCurrency(gstAmount),
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Total Amount',
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _formatCurrency(totalAmount),
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.grey600, thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Interest Amount',
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _formatCurrency(interestAmount),
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.grey600, thickness: 0.5),
            // line item 2
            if (lineItemLabel2 != null && lineItemValue2 != null)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    lineItemLabel2!,
                    style: pw.TextStyle(
                      color: _darkColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _formatCurrency(lineItemValue2!),
                    style: pw.TextStyle(
                      color: _darkColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Payable Amount',
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _formatCurrency(payableAmount),
                  style: pw.TextStyle(
                    color: _darkColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  pw.Widget _getLineItemRow(String label, double value) {
    return pw.Container(
      height: 50,
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey500,
          width: 0.5,
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: _darkColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            _formatCurrency(value),
            style: const pw.TextStyle(color: _darkColor),
          ),
        ],
      ),
    );
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
                  // bottom: pw.Container(
                  //   alignment: pw.Alignment.bottomCenter,
                  //   margin: const pw.EdgeInsets.only(top: 5),
                  //   child: pw.Text('xxx'),
                  // ),
                  // overlay: pw.ChartLegend(
                  //   position: const pw.Alignment(-.7, 1),
                  //   decoration: pw.BoxDecoration(
                  //     color: PdfColors.white,
                  //     border: pw.Border.all(
                  //       color: PdfColors.black,
                  //       width: .5,
                  //     ),
                  //   ),
                  // ),
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
