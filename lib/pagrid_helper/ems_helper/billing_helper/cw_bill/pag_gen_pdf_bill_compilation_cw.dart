import 'dart:typed_data';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../pag_helper/model/mdl_pag_project_profile.dart';
import '../../../../util/date_time_util.dart';
import '../../tenant/pag_ems_type_usage_calc_rl.dart';
import 'pag_gen_pdf_bill_cw.dart';

Future<Uint8List> generatePagInvoiceCompilation(
  MdlPagUser loggedInUser,
  PdfPageFormat pageFormat,
  Map<String, dynamic> billInfo,
) async {
  MdlPagProjectProfile selectedProjectProfile =
      loggedInUser.selectedScope.projectProfile!;
  final String assetFolder = selectedProjectProfile.assetFolder!;

  final billInfoList = billInfo['bill_info_list'] as List<Map<String, dynamic>>;

  List<PagBill> invoiceList = [];
  for (var billInfo in billInfoList) {
    String genType = billInfo['gen_type'] ?? '';
    if (genType == 'initial_balance') {
      continue;
    }

    String strFromTimestamp = billInfo['from_timestamp'];
    DateTime? fromDatetime = getTargetDatetimeFromTargetStr(strFromTimestamp);
    String strToTimestamp = billInfo['to_timestamp'];
    DateTime? toDatetime = getTargetDatetimeFromTargetStr(strToTimestamp);
    String billTimeRangeStr = getTimeRangeStr(
      fromDatetime!,
      toDatetime!,
      targetInterval: 'monthly',
      useMiddle: true,
    );

    final billedGstStr = billInfo['billed_gst'] ?? '';
    double? billedGst = double.tryParse(billedGstStr);
    final billedUsageCostAmountStr = billInfo['billed_usage_cost_amount'] ?? '';
    double? billedUsageCostAmount =
        double.tryParse(billedUsageCostAmountStr) ?? 0.0;

    final billedInterestAmountStr = billInfo['billed_interest_amount'] ?? '';
    double? billedInterestAmount =
        double.tryParse(billedInterestAmountStr) ?? 0.0;

    final billedPrincipalAmountStr = billInfo['billed_principal_amount'] ?? '';
    double? billedPrincipalAmount =
        double.tryParse(billedPrincipalAmountStr) ?? 0.0;

    final billedCycleTotalAmountStr =
        billInfo['billed_cycle_total_amount'] ?? '';
    double? billedCycleTotalAmount =
        double.tryParse(billedCycleTotalAmountStr) ?? 0.0;

    final billedPayableAmountStr = billInfo['billed_payable_amount'] ?? '';
    double? billedPayableAmount =
        double.tryParse(billedPayableAmountStr) ?? 0.0;

    final billedGstAmount = billInfo['billed_gst_amount'] ?? '';
    double billedGstAmountDouble = 0.0;
    if (billedGstAmount is String) {
      billedGstAmountDouble = double.tryParse(billedGstAmount) ?? 0.0;
    } else if (billedGstAmount is num) {
      billedGstAmountDouble = billedGstAmount.toDouble();
    }

    List<Map<String, dynamic>> lineItemList = [];
    final lineItemInfo = billInfo['line_item_info'] ?? {};
    if (lineItemInfo['line_item_label_1'] != null &&
        lineItemInfo['line_item_amount_1'] != null) {
      lineItemList.add({
        'label': lineItemInfo['line_item_label_1'],
        'amount': lineItemInfo['line_item_amount_1'],
        'subjectToTax': true,
        'subjectToInterest': true,
      });
    }
    if (lineItemInfo['line_item_label_2'] != null &&
        lineItemInfo['line_item_amount_2'] != null) {
      lineItemList.add({
        'label': lineItemInfo['line_item_label_2'],
        'amount': lineItemInfo['line_item_amount_2'],
        'subjectToTax': false,
        'subjectToInterest': true,
      });
    }
    if (lineItemInfo['line_item_label_3'] != null &&
        lineItemInfo['line_item_amount_3'] != null) {
      lineItemList.add({
        'label': lineItemInfo['line_item_label_3'],
        'amount': lineItemInfo['line_item_amount_3'],
        'subjectToTax': false,
        'subjectToInterest': false,
      });
    }

    final interestInfo = billInfo['interest_info'] ?? {};
    final miniSoaInfo = billInfo['mini_soa_info'] ?? {};
    final strCollectionStartDateTimestamp =
        miniSoaInfo['collection_start_date_timestamp'] ?? '';
    final strCollectionEndDateTimestamp =
        miniSoaInfo['collection_end_date_timestamp'] ?? '';

    String billBarFromMonth = billInfo['bill_bar_from_timestamp'] ?? '';
    List<PagEmsTypeUsageCalcRl> singularUsageCalcList = [];

    String billedAmgrCompanyTradingName =
        billInfo['billed_amgr_company_trading_name'] ?? '';
    String billedAmgrCompanyRegNumber =
        billInfo['billed_amgr_company_reg_number'] ?? '';
    String billedAmgrGstRegNumber =
        billInfo['billed_amgr_gst_reg_number'] ?? '';
    String amgrAddressLine1 = billInfo['amgr_address_line_1'] ?? '';
    String amgrAddressLine2 = billInfo['amgr_address_line_2'] ?? '';
    String amgrAddressLine3 = billInfo['amgr_address_line_3'] ?? '';

    String amgrBankAccountName = billInfo['amgr_bank_account_name'] ?? '';
    String amgrBankAccountNumber = billInfo['amgr_bank_account_number'] ?? '';
    String amgrBankName = billInfo['amgr_bank_name'] ?? '';
    String amgrBankBranchCode = billInfo['amgr_bank_branch_code'] ?? '';
    String amgrBankSwiftCode = billInfo['amgr_bank_swift_code'] ?? '';
    String amgrBankPayNow = billInfo['amgr_bank_paynow'] ?? '';

    List<String> usageTypeTags = ['E', 'W', 'B', 'N', 'G'];

    Map<String, dynamic> billedUsageFactorInfo = {};
    if (billInfo['usage_factor_list'] != null) {
      for (var item in billInfo['usage_factor_list']) {
        String meterType = item['meter_type'];
        meterType = meterType.toLowerCase();
        String valueStr = item['usage_factor'];
        double? value = double.tryParse(valueStr);
        billedUsageFactorInfo['billed_usage_factor_$meterType'] = value;
      }
    }

    List<Map<String, dynamic>> singularUsageList = [];

    if (billInfo['singular_billing_rec_list'] != null) {
      for (var singularUsage in billInfo['singular_billing_rec_list']) {
        singularUsageList.add(singularUsage);
      }
    }

    for (Map<String, dynamic> singularUsage in singularUsageList) {
      Map<String, dynamic> billedAutoUsageInfo = {};
      for (String typeTag in usageTypeTags) {
        typeTag = typeTag.toLowerCase();
        String typebilledAutoUsageStr =
            singularUsage['billed_auto_usage_$typeTag'] ?? '';
        double? usage = double.tryParse(typebilledAutoUsageStr);
        if (usage != null) {
          billedAutoUsageInfo['billed_auto_usage_$typeTag'] = usage;
        }
      }

      Map<String, dynamic> billedRateInfo = {};
      for (String typeTag in usageTypeTags) {
        typeTag = typeTag.toLowerCase();
        String typebilledRateStr = singularUsage['billed_rate_$typeTag'] ?? '';
        double? rate = double.tryParse(typebilledRateStr);
        if (rate != null) {
          billedRateInfo['billed_rate_$typeTag'] = rate;
        }
      }

      Map<String, dynamic> billedSubTenantUsages = {};
      Map<String, dynamic> billedManualUsages = {};
      List<Map<String, dynamic>> billedTrendingSnapShot = [];

      double? billedGst;
      if (singularUsage['billed_gst'] != null) {
        billedGst = double.tryParse(singularUsage['billed_gst']);
      }
      // double? billedGstAmount;
      // if (singularUsage['billed_gst_amount'] != null) {
      //   billedGstAmount = double.tryParse(singularUsage['billed_gst_amount']);
      // }

      PagEmsTypeUsageCalcRl emsTypeUsageCalcRl = PagEmsTypeUsageCalcRl(
        costDecimals: 2,
        billedAutoUsageE: billedAutoUsageInfo['billed_auto_usage_e'],
        billedAutoUsageW: billedAutoUsageInfo['billed_auto_usage_w'],
        billedAutoUsageB: billedAutoUsageInfo['billed_auto_usage_b'],
        billedAutoUsageN: billedAutoUsageInfo['billed_auto_usage_n'],
        billedAutoUsageG: billedAutoUsageInfo['billed_auto_usage_g'],
        billedSubTenantUsageE:
            billedSubTenantUsages['billed_sub_tenant_usage_e'],
        billedSubTenantUsageW:
            billedSubTenantUsages['billed_sub_tenant_usage_w'],
        billedSubTenantUsageB:
            billedSubTenantUsages['billed_sub_tenant_usage_b'],
        billedSubTenantUsageN:
            billedSubTenantUsages['billed_sub_tenant_usage_n'],
        billedSubTenantUsageG:
            billedSubTenantUsages['billed_sub_tenant_usage_g'],
        billedManualUsageE: billedManualUsages['manual_usage_e'],
        billedManualUsageW: billedManualUsages['manual_usage_w'],
        billedManualUsageB: billedManualUsages['manual_usage_b'],
        billedManualUsageN: billedManualUsages['manual_usage_n'],
        billedManualUsageG: billedManualUsages['manual_usage_g'],
        billedUsageFactorE: billedUsageFactorInfo['billed_usage_factor_e'],
        billedUsageFactorW: billedUsageFactorInfo['billed_usage_factor_w'],
        billedUsageFactorB: billedUsageFactorInfo['billed_usage_factor_b'],
        billedUsageFactorN: billedUsageFactorInfo['billed_usage_factor_n'],
        billedUsageFactorG: billedUsageFactorInfo['billed_usage_factor_g'],
        billedRateE: billedRateInfo['billed_rate_e'],
        billedRateW: billedRateInfo['billed_rate_w'],
        billedRateB: billedRateInfo['billed_rate_b'],
        billedRateN: billedRateInfo['billed_rate_n'],
        billedRateG: billedRateInfo['billed_rate_g'],
        billedGst: billedGst,
        billedGstAmount: billedGstAmountDouble,
        billedUsageCostAmount: billedUsageCostAmount,
        billedPrincipalAmount: billedPrincipalAmount,
        billedInterestAmount: billedInterestAmount,
        billedCycleTotalAmount: billedCycleTotalAmount,
        lineItemList: [], //lineItemList,
        billedTrendingSnapShot: billedTrendingSnapShot,
        billBarFromMonth: billBarFromMonth,
      );
      emsTypeUsageCalcRl.doSingularCalc();
      singularUsageCalcList.add(emsTypeUsageCalcRl);

      singularUsage['usage_calc'] = emsTypeUsageCalcRl;
    }

    PagEmsTypeUsageCalcRl compositeUsageCalcRl = PagEmsTypeUsageCalcRl(
      costDecimals: 2,
      billedRateE: billInfo['billed_rate_e'],
      billedRateW: billInfo['billed_rate_w'],
      billedRateB: billInfo['billed_rate_b'],
      billedRateN: billInfo['billed_rate_n'],
      billedRateG: billInfo['billed_rate_g'],
      billedAutoUsageE: billInfo['billed_auto_usage_e'],
      billedAutoUsageW: billInfo['billed_auto_usage_w'],
      billedAutoUsageB: billInfo['billed_auto_usage_b'],
      billedAutoUsageN: billInfo['billed_auto_usage_n'],
      billedAutoUsageG: billInfo['billed_auto_usage_g'],
      billedSubTenantUsageE: billInfo['billed_sub_tenant_usage_e'],
      billedSubTenantUsageW: billInfo['billed_sub_tenant_usage_w'],
      billedSubTenantUsageB: billInfo['billed_sub_tenant_usage_b'],
      billedSubTenantUsageN: billInfo['billed_sub_tenant_usage_n'],
      billedSubTenantUsageG: billInfo['billed_sub_tenant_usage_g'],
      billedManualUsageE: billInfo['manual_usage_e'],
      billedManualUsageW: billInfo['manual_usage_w'],
      billedManualUsageB: billInfo['manual_usage_b'],
      billedManualUsageN: billInfo['manual_usage_n'],
      billedManualUsageG: billInfo['manual_usage_g'],
      billedUsageFactorE: billInfo['billed_usage_factor_e'],
      billedUsageFactorW: billInfo['billed_usage_factor_w'],
      billedUsageFactorB: billInfo['billed_usage_factor_b'],
      billedUsageFactorN: billInfo['billed_usage_factor_n'],
      billedUsageFactorG: billInfo['billed_usage_factor_g'],
      billedTrendingSnapShot: billInfo['billed_trending_snapshot'] ?? [],
      lineItemList: lineItemList,
      billBarFromMonth: billBarFromMonth,
      singularUsageCalcList: singularUsageCalcList,
      miniSoaInfo: miniSoaInfo,
      interestInfo: interestInfo,
      billedGst: billedGst,
      billedGstAmount: billedGstAmountDouble,
      billedUsageCostAmount: billedUsageCostAmount,
      billedPrincipalAmount: billedPrincipalAmount,
      billedInterestAmount: billedInterestAmount,
      billedCycleTotalAmount: billedCycleTotalAmount,
      billedPayableAmount: billedPayableAmount,
    );
    compositeUsageCalcRl.doCompositeCalc();

    final invoice = PagBill(
      billingRecName: billInfo['name'] ?? '',
      billLabel: billInfo['label'] ?? '',
      customerName: billInfo['tenant_name'] ?? '',
      customerLabel: billInfo['tenant_label'] ?? '',
      tenantAccountNumber: billInfo['tenant_account_number'] ?? '',
      depositAmountStr: billInfo['deposit_amount'] ?? '',
      paymentMethod: billInfo['payment_method'] ?? '',
      tenantBillingAddressLine1: billInfo['tenant_billing_address_line1'] ?? '',
      tenantBillingAddressLine2: billInfo['tenant_billing_address_line2'] ?? '',
      tenantBillingAddressLine3: billInfo['tenant_billing_address_line3'] ?? '',
      customerType: billInfo['customer_type'] ?? '',
      gst: billInfo['gst'],
      paymentInfo: billInfo['payment_info'] ?? '',
      billTimeRangeStr: billTimeRangeStr,
      dueDate: billInfo['billed_due_date_timestamp'] ?? '',
      billFromStr: strFromTimestamp,
      billToStr: strToTimestamp,
      billDateStr: billInfo['bill_date_timestamp'],
      totalUsageCost: compositeUsageCalcRl.totalUsageCost,
      subTotalAmount: compositeUsageCalcRl.subTotalCost,
      gstAmount: compositeUsageCalcRl.billedGstAmount,
      totalAmount: compositeUsageCalcRl.totalCost,
      interestInfo: interestInfo,
      cycleTotalAmount: compositeUsageCalcRl.cycleTotalAmount,
      payableAmount: compositeUsageCalcRl.payableAmount,
      typeRateE: compositeUsageCalcRl.typeUsageE?.rate,
      typeRateW: compositeUsageCalcRl.typeUsageW?.rate,
      typeRateB: compositeUsageCalcRl.typeUsageB?.rate,
      typeRateN: compositeUsageCalcRl.typeUsageN?.rate,
      typeRateG: compositeUsageCalcRl.typeUsageG?.rate,
      typeUsageE: compositeUsageCalcRl.typeUsageE?.usage,
      typeUsageW: compositeUsageCalcRl.typeUsageW?.usage,
      typeUsageB: compositeUsageCalcRl.typeUsageB?.usage,
      typeUsageN: compositeUsageCalcRl.typeUsageN?.usage,
      typeUsageG: compositeUsageCalcRl.typeUsageG?.usage,
      typeCostE: compositeUsageCalcRl.typeUsageE?.cost,
      typeCostW: compositeUsageCalcRl.typeUsageW?.cost,
      typeCostB: compositeUsageCalcRl.typeUsageB?.cost,
      typeCostN: compositeUsageCalcRl.typeUsageN?.cost,
      typeCostG: compositeUsageCalcRl.typeUsageG?.cost,
      trendingE: compositeUsageCalcRl.trendingE,
      trendingW: compositeUsageCalcRl.trendingW,
      trendingB: compositeUsageCalcRl.trendingB,
      trendingN: compositeUsageCalcRl.trendingN,
      trendingG: compositeUsageCalcRl.trendingG,
      lineItemLabel1: compositeUsageCalcRl.getLineItem(0)?['label'],
      lineItemValue1: compositeUsageCalcRl.getLineItem(0)?['amount'],
      lineItemLabel2: compositeUsageCalcRl.getLineItem(1)?['label'],
      lineItemValue2: compositeUsageCalcRl.getLineItem(1)?['amount'],
      miniSoaInfo: miniSoaInfo,
      assetFolder: assetFolder,
      tenantSingularUsageInfoList: singularUsageList,
      billedAmgrCompanyTradingName:
          billInfo['billed_amgr_company_trading_name'],
      billedAmgrCompanyRegNumber: billInfo['billed_amgr_company_reg_number'],
      billedAmgrGstRegNumber: billInfo['billed_amgr_gst_reg_number'],
      amgrAddressLine1: billInfo['amgr_address_line_1'],
      amgrAddressLine2: billInfo['amgr_address_line_2'],
      amgrAddressLine3: billInfo['amgr_address_line_3'],
      amgrBankAccountName: billInfo['amgr_bank_account_name'],
      amgrBankAccountNumber: billInfo['amgr_bank_account_number'],
      amgrBankName: billInfo['amgr_bank_name'],
      amgrBankBranchCode: billInfo['amgr_bank_branch_code'],
      amgrBankSwiftCode: billInfo['amgr_bank_swift_code'],
      amgrBankPayNow: billInfo['amgr_bank_pay_now'],
      collectionStartDateStr: strCollectionStartDateTimestamp,
      collectionEndDateStr: strCollectionEndDateTimestamp,
      tax: .15,
      baseColor: PdfColors.teal,
      accentColor: PdfColors.blueGrey900,
    );
    invoiceList.add(invoice);
  }

  return await buildPdf(pageFormat, assetFolder, invoiceList);
}

Future<Uint8List> buildPdf(PdfPageFormat pageFormat, String assetFolder,
    List<PagBill> invoiceList) async {
  final pdf = pw.Document();
  final logo = pw.MemoryImage(
    (await rootBundle.load('$assetFolder/transparent_32x32.png'))
        .buffer
        .asUint8List(),
  );

  for (var invoice in invoiceList) {
    pdf.addPage(await invoice.getPage1(logo: logo));
  }
  return await pdf.save();
}
