import 'dart:typed_data';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/pag_pdf_bill.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:pdf/pdf.dart';

import '../../../../pag_helper/model/mdl_pag_project_profile.dart';

Future<Uint8List> generatePagInvoice(
  MdlPagUser loggedInUser,
  PdfPageFormat pageFormat,
  Map<String, dynamic> calcedBillInfoRl,
) async {
  MdlPagProjectProfile selectedProjectProfile =
      loggedInUser.selectedScope.projectProfile!;
  final String assetFolder = selectedProjectProfile.assetFolder!;

  final invoice = PagPdfBill(
    billingRecName: calcedBillInfoRl['billingRecName'] ?? '',
    billLabel: calcedBillInfoRl['billLabel'] ?? '',
    customerName: calcedBillInfoRl['customerName'] ?? '',
    customerLabel: calcedBillInfoRl['customerLabel'] ?? '',
    tenantAccountNumber: calcedBillInfoRl['tenantAccountNumber'] ?? '',
    strDepositAmount: calcedBillInfoRl['strDepositAmount'] ?? '',
    paymentMethod: calcedBillInfoRl['paymentMethod'] ?? '',
    tenantBillingAddressLine1:
        calcedBillInfoRl['tenantBillingAddressLine1'] ?? '',
    tenantBillingAddressLine2:
        calcedBillInfoRl['tenantBillingAddressLine2'] ?? '',
    tenantBillingAddressLine3:
        calcedBillInfoRl['tenantBillingAddressLine3'] ?? '',
    customerType: calcedBillInfoRl['customerType'] ?? '',
    gst: calcedBillInfoRl['gst'],
    paymentInfo: calcedBillInfoRl['paymentInfo'] ?? '',
    strBillTimeRange: calcedBillInfoRl['strBillTimeRange'],
    strDueDate: calcedBillInfoRl['strDueDate'] ?? '',
    strFrom: calcedBillInfoRl['strFrom'] ?? '',
    strTo: calcedBillInfoRl['strTo'] ?? '',
    strEffectiveTo: calcedBillInfoRl['strEffectiveTo'] ?? '',
    strBillDate: calcedBillInfoRl['strBillDate'] ?? '',
    totalUsageCost: calcedBillInfoRl['totalUsageCost'] ?? 0.0,
    subTotalAmount: calcedBillInfoRl['subTotalAmount'] ?? 0.0,
    gstAmount: calcedBillInfoRl['gstAmount'] ?? 0.0,
    totalAmount: calcedBillInfoRl['totalAmount'] ?? 0.0,
    interestInfo: calcedBillInfoRl['interestInfo'] ?? {},
    cycleTotalAmount: calcedBillInfoRl['cycleTotalAmount'] ?? 0.0,
    payableAmount: calcedBillInfoRl['payableAmount'] ?? 0.0,
    typeRateE: calcedBillInfoRl['typeRateE'],
    typeRateW: calcedBillInfoRl['typeRateW'],
    typeRateB: calcedBillInfoRl['typeRateB'],
    typeRateN: calcedBillInfoRl['typeRateN'],
    typeRateG: calcedBillInfoRl['typeRateG'],
    typeUsageE: calcedBillInfoRl['typeUsageE'],
    typeUsageW: calcedBillInfoRl['typeUsageW'],
    typeUsageB: calcedBillInfoRl['typeUsageB'],
    typeUsageN: calcedBillInfoRl['typeUsageN'],
    typeUsageG: calcedBillInfoRl['typeUsageG'],
    typeCostE: calcedBillInfoRl['typeCostE'],
    typeCostW: calcedBillInfoRl['typeCostW'],
    typeCostB: calcedBillInfoRl['typeCostB'],
    typeCostN: calcedBillInfoRl['typeCostN'],
    typeCostG: calcedBillInfoRl['typeCostG'],
    trendingE: calcedBillInfoRl['trendingE'],
    trendingW: calcedBillInfoRl['trendingW'],
    trendingB: calcedBillInfoRl['trendingB'],
    trendingN: calcedBillInfoRl['trendingN'],
    trendingG: calcedBillInfoRl['trendingG'],
    lineItemLabel1: calcedBillInfoRl['lineItemLabel1'],
    lineItemValue1: calcedBillInfoRl['lineItemValue1'],
    lineItemLabel2: calcedBillInfoRl['lineItemLabel2'],
    lineItemValue2: calcedBillInfoRl['lineItemValue2'],
    lineItemLabel3: calcedBillInfoRl['lineItemLabel3'],
    lineItemValue3: calcedBillInfoRl['lineItemValue3'],
    billedBciInfoList: calcedBillInfoRl['billedBciInfoList'] ?? [],
    miniSoaInfo: calcedBillInfoRl['miniSoaInfo'] ?? {},
    assetFolder: assetFolder,
    tenantSingularUsageInfoList:
        calcedBillInfoRl['tenantSingularUsageInfoList'] ?? [],
    billedAmgrCompanyTradingName:
        calcedBillInfoRl['billedAmgrCompanyTradingName'] ?? '',
    billedAmgrCompanyRegNumber:
        calcedBillInfoRl['billedAmgrCompanyRegNumber'] ?? '',
    billedAmgrGstRegNumber: calcedBillInfoRl['billedAmgrGstRegNumber'] ?? '',
    amgrAddressLine1: calcedBillInfoRl['amgrAddressLine1'] ?? '',
    amgrAddressLine2: calcedBillInfoRl['amgrAddressLine2'] ?? '',
    amgrAddressLine3: calcedBillInfoRl['amgrAddressLine3'] ?? '',
    amgrBankAccountName: calcedBillInfoRl['amgrBankAccountName'] ?? '',
    amgrBankAccountNumber: calcedBillInfoRl['amgrBankAccountNumber'] ?? '',
    amgrBankName: calcedBillInfoRl['amgrBankName'] ?? '',
    amgrBankBranchCode: calcedBillInfoRl['amgrBankBranchCode'] ?? '',
    amgrBankSwiftCode: calcedBillInfoRl['amgrBankSwiftCode'] ?? '',
    amgrBankPayNow: calcedBillInfoRl['amgrBankPayNow'] ?? '',
    strCollectionStartDate: calcedBillInfoRl['strCollectionStartDate'] ?? '',
    strCollectionEndDate: calcedBillInfoRl['strCollectionEndDate'] ?? '',
    tax: .15,
    baseColor: PdfColors.teal,
    accentColor: PdfColors.blueGrey900,
  );

  return await invoice.buildPdf(pageFormat);
}
