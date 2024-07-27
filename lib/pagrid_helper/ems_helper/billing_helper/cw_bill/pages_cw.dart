import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/up_helper/helper/tenant_def.dart';
import 'package:flutter/material.dart' as mt;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const int boltIcon = 0xea0b;
const int waterIcon = 0xf084;
const int hvacIcon = 0xf10e;
const int gasIcon = 0xec19;
const int waterDropIcon = 0xe798;

const int usageDecimals = 3;
const int rateDecimals = 4;

const tableHeaders = ['Category', 'Budget', 'Expense', 'Result'];

Future<Uint8List> generateInvoice(
  PdfPageFormat pageFormat,
  Map<String, dynamic> billInfo,
) async {
  final invoice = Bill(
    billingRecName: billInfo['billingRecName'],
    customerLabel: billInfo['customerLabel'],
    customerName: billInfo['customerName'],
    customerAccountId: billInfo['customerAccountId'] ?? '',
    customerAddress: billInfo['customerAddress'] ?? '',
    customerType: billInfo['customerType'],
    gst: billInfo['gst'],
    paymentInfo: billInfo['paymentInfo'] ?? '',
    billTimeRangeStr: billInfo['billTimeRangeStr'],
    billFromStr: billInfo['billFrom'],
    billToStr: billInfo['billTo'],
    billDateStr: billInfo['billDate'],
    subTotalAmount: billInfo['subTotalAmount'],
    gstAmount: billInfo['gstAmount'],
    totalAmount: billInfo['totalAmount'],
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
    tax: .15,
    baseColor: PdfColors.teal,
    accentColor: PdfColors.blueGrey900,
  );

  return await invoice.buildPdf(pageFormat);
}

class Bill {
  Bill({
    required this.customerName,
    required this.customerAccountId,
    required this.customerLabel,
    required this.customerAddress,
    required this.customerType,
    required this.gst,
    required this.billingRecName,
    required this.billFromStr,
    required this.billToStr,
    required this.billDateStr,
    required this.billTimeRangeStr,
    required this.subTotalAmount,
    required this.gstAmount,
    required this.totalAmount,
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
    required this.lineItemLabel1,
    required this.lineItemValue1,
    required this.baseColor,
    required this.accentColor,
  });

  final String customerLabel;
  final String customerName;
  final String customerAccountId;
  final String customerAddress;
  final String customerType;
  final double? gst;
  final String billingRecName;
  final String billFromStr;
  final String billToStr;
  final String billDateStr;
  final String billTimeRangeStr;
  final double? subTotalAmount;
  final double? gstAmount;
  final double? totalAmount;
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
  final List<Map<String, dynamic>>? trendingE;
  final List<Map<String, dynamic>>? trendingW;
  final List<Map<String, dynamic>>? trendingB;
  final List<Map<String, dynamic>>? trendingN;
  final List<Map<String, dynamic>>? trendingG;
  final double tax;
  final String paymentInfo;
  final PdfColor baseColor;
  final PdfColor accentColor;

  static const _darkColor = PdfColors.blueGrey800;
  static const _lightColor = PdfColors.white;

  PdfColor get _baseTextColor => baseColor.isLight ? _lightColor : _darkColor;

  PdfColor get _accentTextColor => baseColor.isLight ? _lightColor : _darkColor;

  late final _logo;

  String? _bgShape;

  Future<Uint8List> buildPdf(PdfPageFormat pageFormat) async {
    // Create a PDF document.
    final doc = pw.Document();

    // mt.AssetImage logoImage = const mt.AssetImage("assets/images/cw_logo_r_s.png");
    _logo = //await rootBundle.loadString('assets/images/C&W_Services_Logo_Color.png');
        pw.MemoryImage(
      (await rootBundle.load('assets/images/cw_logo_r_s.png'))
          .buffer
          .asUint8List(),
    );
    _bgShape = await rootBundle.loadString('assets/images/invoice.svg');

    // Add page to the PDF
    doc.addPage(
      pw.MultiPage(
        // theme: pw.ThemeData.withFont(icons: icons),
        // theme: pw.ThemeData.withFont(
        //   base: await PdfGoogleFonts.openSansRegular(),
        //   bold: await PdfGoogleFonts.openSansBold(),
        //   icons: await PdfGoogleFonts.materialIcons(), // this line
        // ),
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData.withFont(
            base: await PdfGoogleFonts.openSansRegular(),
            bold: await PdfGoogleFonts.openSansBold(),
            icons: await PdfGoogleFonts.materialSymbolsOutlinedRegular(),
          ),
        ),
        // _buildTheme(
        //   pageFormat,
        //   await PdfGoogleFonts.robotoRegular(),
        //   await PdfGoogleFonts.robotoBold(),
        //   await PdfGoogleFonts.robotoItalic(),
        // ),
        header: _buildHeader,
        footer: _buildFooter,
        build: (context) => [
          _contentHeader(context),
          _getBillTime(),
          _getContent(context),
          pw.SizedBox(height: 10),
          // _contentFooter(context),
          _getContentFooter(context),
          pw.SizedBox(height: 10),
          _termsAndConditions(context),
        ],
      ),
    );

    // Return the PDF file content
    return doc.save();
  }

  pw.Widget _buildHeader(pw.Context context) {
    int codePoint = mt.Icons.abc.codePoint;
    //hex
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 250,
              child: _getPayerInfo(),
            ),
            pw.Expanded(child: pw.Container()),
            pw.SizedBox(
              width: 210,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisSize: pw.MainAxisSize.min,
                children: [_getLogo(), _getBillerInfo()],
              ),
            ),
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
          'Bill Number:$billingRecName',
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
    pw.TextStyle textStyle = const pw.TextStyle(
      color: _darkColor,
      fontSize: 9,
    );
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      // mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        pw.SizedBox(
          height: 150,
          child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Issued on behalf of', style: textStyle),
                pw.Text('National University of Singapore', style: textStyle),
                pw.SizedBox(height: 20),
                pw.Text(
                    customerType == 'cw_nus_internal'
                        ? 'MEMO' //'UTILITES INVOICE'
                        : 'TAX INVOICE',
                    style: pw.TextStyle(
                        color: _darkColor,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text(customerLabel,
                    style: pw.TextStyle(
                        color: _darkColor,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Row(children: [
                  pw.Text('Tenant ID: ',
                      style: pw.TextStyle(
                          fontSize: 10,
                          color: _darkColor,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text(customerName,
                      style:
                          const pw.TextStyle(color: _darkColor, fontSize: 10)),
                ]),
                pw.SizedBox(height: 5),
                pw.Row(children: [
                  pw.Text('Account ID: ',
                      style: pw.TextStyle(
                          fontSize: 10,
                          color: _darkColor,
                          fontWeight: pw.FontWeight.bold)),
                  pw.Text(customerAccountId,
                      style:
                          const pw.TextStyle(color: _darkColor, fontSize: 10)),
                ]),
                pw.Text(customerAddress, style: textStyle),
              ]),
        ),
        // pw.Expanded(child: pw.Container()),
        // pw.SizedBox(height: 40),
        // pw.SizedBox(
        //   height: 40,
        //   child: pw.Column(
        //     crossAxisAlignment: pw.CrossAxisAlignment.start,
        //     children: [
        //       pw.Row(children: [
        //         pw.Text('Billing Period: ',
        //             style: pw.TextStyle(
        //                 color: _darkColor, fontWeight: pw.FontWeight.bold)),
        //         pw.Text(_getBillingPeriodStr(),
        //             style:
        //                 const pw.TextStyle(color: _darkColor, fontSize: 11)),
        //       ]),
        //       pw.SizedBox(height: 5),
        //       pw.Row(children: [
        //         pw.Text('Bill Date: ',
        //             style: pw.TextStyle(
        //                 color: _darkColor, fontWeight: pw.FontWeight.bold)),
        //         pw.Text(_getBillDate(),
        //             style:
        //                 const pw.TextStyle(color: _darkColor, fontSize: 11)),
        //       ]),
        //     ],
        //   ),
        // ),
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
            pw.Text('Authorized Agent', style: textStyle),
            pw.Text(
              'C&W Services (S) Pte Ltd',
              style: pw.TextStyle(
                  color: _darkColor, fontWeight: pw.FontWeight.bold),
            ),
            // pw.Text('Reg. No: 199805375C', style: textStyle),
            // pw.Text('750A Chai Chee Road \n#05-01, ESR BizPark @ Chai Chee\nSingapore 469001',style: textStyle),
            pw.Text('www.cwservices.sg', style: textStyle),
            pw.Text('contactcentre-emrs.sgp@cwservices.com', style: textStyle),
            // pw.SizedBox(height: 5),
            // pw.Container(
            //   decoration: pw.BoxDecoration(
            //     border: pw.Border.all(
            //       color: accentColor,
            //       width: 0.5,
            //     ),
            //   ),
            //   padding:
            //       const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            //   child: pw.Column(
            //     crossAxisAlignment: pw.CrossAxisAlignment.start,
            //     children: [
            //       // pw.Text('For billing enquiries:', style: textStyle),
            //       pw.Text(
            //           'Tel: +65 6354 4919 Fax: +65 6876 6496\ncontactcentre-emrs.sgp@cwservices.com',
            //           style: textStyle),
            //     ],
            //   ),
            // ),
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

  pw.Widget _getContent(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (typeCostE != null)
          _getTypeRow(boltIcon, 'Electricity', 'kWh', typeRateE!, typeUsageE!,
              typeCostE!,
              trending: trendingE),
        if (typeCostB != null)
          _getTypeRow(
              hvacIcon, 'BTU', 'kWh', typeRateB!, typeUsageB!, typeCostB!,
              trending: trendingB),
        if (typeCostW != null)
          _getTypeRow(
              waterIcon, 'Water', 'CuM', typeRateW!, typeUsageW!, typeCostW!,
              trending: trendingW),
        if (typeCostN != null)
          _getTypeRow(waterDropIcon, 'NeWater', 'CuM', typeRateN!, typeUsageN!,
              typeCostN!,
              trending: trendingN),
        if (typeCostG != null)
          _getTypeRow(
              gasIcon, 'Gas', 'kWh', typeRateG!, typeUsageG!, typeCostG!,
              trending: trendingG),
        if (lineItemValue1 != null)
          _getLineItemRow(lineItemLabel1!, lineItemValue1!),
      ],
    );
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

  pw.Widget _getTypeRow(int codePoint, String typeStr, String typeUnit,
      double rate, double usage, double cost,
      {List<Map<String, dynamic>>? trending}) {
    pw.TextStyle textStyle = const pw.TextStyle(
      color: _darkColor,
      fontSize: 10,
    );
    return pw.Container(
        height: 95,
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
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 10),
              child: pw.SizedBox(
                width: 350,
                height: 95,
                child: _getTrending(trending),
              ),
            ),
            pw.SizedBox(
              width: 100,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Row(
                    children: [
                      pw.Icon(
                        pw.IconData(codePoint),
                        color: PdfColors.grey,
                        size: 25,
                      ),
                      pw.Text(
                        typeStr,
                        style: pw.TextStyle(
                          color: _darkColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.SizedBox(width: 3),
                          // pw.Text(
                          //   ' Usage: ',
                          //   style: textStyle,
                          // ),
                          pw.Text(
                            '${usage.toStringAsFixed(usageDecimals)} $typeUnit',
                            style: textStyle,
                          ),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Text(
                            ' Rate: ',
                            style: textStyle,
                          ),
                          pw.Text(
                            '\$${rate.toStringAsFixed(rateDecimals)}',
                            style: textStyle,
                          ),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: [
                          pw.Text(
                            ' Cost: ${_formatCurrency(cost)}',
                            style: textStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                  // pw.SizedBox(
                  //   width: 80,
                  //   child: pw.Align(
                  //     alignment: pw.Alignment.centerRight,
                  //     child: pw.Text(
                  //       _formatCurrency(cost),
                  //       style: const pw.TextStyle(color: _darkColor),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ));
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

    List<Map<String, dynamic>> trendingLastMonthSuper = [];
    for (int i = 0; i < trending.length; i++) {
      trending[i]['label'] = trending[i]['label'] + '';
      String valueStr = getBarNumberStr(trending[i]['value'] as double);
      trending[i]['valueStr'] = valueStr;

      var item = trending[i];
      if (i == trending.length - 1) {
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

    //if length less then 6, add empty data
    if (trending.length < 6) {
      for (int i = 0; i < 6 - trending.length; i++) {
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
                        trending.length,
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
                        trending.length,
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
                        trending.length,
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
                        return pw.Transform.translate(
                          offset: const PdfPoint(-10, 0),
                          child: pw.Column(
                            children: [
                              pw.Text(trending?[index]['label'] as String,
                                  style: labelStyle),
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
                        trending.length,
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
