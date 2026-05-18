import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pag_gen_pdf_bill_cw.dart';

Future<Uint8List> generatePagInvoiceCompilation(
  PdfPageFormat pageFormat,
  Map<String, dynamic> billInfo,
) async {
  final billInfoList = billInfo['bill_info_list'] as List<Map<String, dynamic>>;
  List<PagBill> invoiceList = [];
  for (var billInfo in billInfoList) {
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
      dueDate: billInfo['dueDate'],
      billFromStr: billInfo['billFrom'],
      billToStr: billInfo['billTo'],
      billDateStr: billInfo['billDate'],
      totalUsageCost: billInfo['totalUsageCost'],
      subTotalAmount: billInfo['subTotalAmount'],
      gstAmount: billInfo['gstAmount'],
      totalAmount: billInfo['totalAmount'],
      interestInfo: billInfo['interestInfo'],
      cycleTotalAmount: billInfo['cycleTotalAmount'],
      payableAmount: billInfo['payableAmount'],
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
      miniSoaInfo: billInfo['miniSoaInfo'],
      assetFolder: billInfo['assetFolder'],
      tenantSingularUsageInfoList: billInfo['tenantSingularUsageInfoList'],
      billedAmgrCompanyTradingName: billInfo['billedAmgrCompanyTradingName'],
      billedAmgrCompanyRegNumber: billInfo['billedAmgrCompanyRegNumber'],
      billedAmgrGstRegNumber: billInfo['billedAmgrGstRegNumber'],
      amgrAddressLine1: billInfo['amgrAddressLine1'],
      amgrAddressLine2: billInfo['amgrAddressLine2'],
      amgrAddressLine3: billInfo['amgrAddressLine3'],
      amgrBankAccountName: billInfo['amgrBankAccountName'],
      amgrBankAccountNumber: billInfo['amgrBankAccountNumber'],
      amgrBankName: billInfo['amgrBankName'],
      amgrBankBranchCode: billInfo['amgrBankBranchCode'],
      amgrBankSwiftCode: billInfo['amgrBankSwiftCode'],
      amgrBankPayNow: billInfo['amgrBankPayNow'],
      collectionStartDateStr: billInfo['collectionStartDate'],
      collectionEndDateStr: billInfo['collectionEndDate'],
      tax: .15,
      baseColor: PdfColors.teal,
      accentColor: PdfColors.blueGrey900,
    );
    invoiceList.add(invoice);
  }

  Future<Uint8List> buildPdf(PdfPageFormat pageFormat) async {
    final pdf = pw.Document();
    for (var invoice in invoiceList) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) => generatePagInvoice(invoice),
        ),
      );
    }
    return await pdf.save();
  }
}
