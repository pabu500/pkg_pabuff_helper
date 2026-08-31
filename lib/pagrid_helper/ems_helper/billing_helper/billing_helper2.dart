import '../../../util/date_time_util.dart';
import '../tenant/pag_ems_type_usage_calc_rl2.dart';

double? _billValueToDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return value == null ? null : double.tryParse(value.toString());
}

String getBillInvoiceNumber2(Map<String, dynamic> billInfo) {
  if (billInfo['lc_status']?.toString().toLowerCase() != 'released') {
    return '';
  }
  return billInfo['audit_label']?.toString() ??
      billInfo['bill_label']?.toString() ??
      '';
}

Map<String, dynamic> prepCalcedBillInfoRl2(Map<String, dynamic> billInfo) {
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

  final strBilledGst = billInfo['billed_gst'] ?? '';
  double? billedGst = double.tryParse(strBilledGst);
  final strBilledUsageCostAmount = billInfo['billed_usage_cost_amount'] ?? '';
  double? billedUsageCostAmount =
      double.tryParse(strBilledUsageCostAmount) ?? 0.0;

  final strBilledPrincipalAmount = billInfo['billed_principal_amount'] ?? '';
  double? billedPrincipalAmount =
      double.tryParse(strBilledPrincipalAmount) ?? 0.0;

  final strBilledCycleTotalAmount = billInfo['billed_cycle_total_amount'] ?? '';
  double? billedCycleTotalAmount =
      double.tryParse(strBilledCycleTotalAmount) ?? 0.0;

  final strBilledPayableAmount = billInfo['billed_payable_amount'] ?? '';
  double? billedPayableAmount = double.tryParse(strBilledPayableAmount) ?? 0.0;

  final strBilledGstAmount = billInfo['billed_gst_amount'] ?? '';
  double billedGstAmount = 0.0;
  if (strBilledGstAmount is String) {
    billedGstAmount = double.tryParse(strBilledGstAmount) ?? 0.0;
  } else if (strBilledGstAmount is num) {
    billedGstAmount = strBilledGstAmount.toDouble();
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

  final billedBciInfo = billInfo['billed_bci_info'];
  String strBilledTotalBciAmount = billInfo['billed_total_bci_amount'] ?? '';
  double? billedTotalBciAmount =
      double.tryParse(strBilledTotalBciAmount) ?? 0.0;

  final interestInfo = billInfo['interest_info'] ?? {};
  final miniSoaInfo = billInfo['mini_soa_info'] ?? {};
  final strCollectionStartDateTimestamp =
      miniSoaInfo['collection_start_date_timestamp'] ?? '';
  final strCollectionEndDateTimestamp =
      miniSoaInfo['collection_end_date_timestamp'] ?? '';

  String billBarFromMonth = billInfo['bill_bar_from_timestamp'] ?? '';
  List<PagEmsTypeUsageCalcRl2> singularUsageCalcList = [];

  String billedAmgrCompanyTradingName =
      billInfo['billed_amgr_company_trading_name'] ?? '';
  String billedAmgrCompanyRegNumber =
      billInfo['billed_amgr_company_reg_number'] ?? '';
  String billedAmgrGstRegNumber = billInfo['billed_amgr_gst_reg_number'] ?? '';
  String amgrAddressLine1 = billInfo['amgr_address_line_1'] ?? '';
  String amgrAddressLine2 = billInfo['amgr_address_line_2'] ?? '';
  String amgrAddressLine3 = billInfo['amgr_address_line_3'] ?? '';

  String amgrBankAccountName = billInfo['amgr_bank_account_name'] ?? '';
  String amgrBankAccountNumber = billInfo['amgr_bank_account_number'] ?? '';
  String amgrBankLabel = billInfo['amgr_bank_label'] ?? '';
  String amgrBankCode = billInfo['amgr_bank_code'] ?? '';
  String amgrBankBranchCode = billInfo['amgr_bank_branch_code'] ?? '';
  String amgrBankSwiftCode = billInfo['amgr_bank_swift_code'] ?? '';
  String amgrBankPayNow = billInfo['amgr_bank_paynow'] ?? '';

  List<Map<String, dynamic>> singularUsageList = [];

  if (billInfo['singular_billing_rec_list'] != null) {
    for (var singularUsage in billInfo['singular_billing_rec_list']) {
      singularUsageList.add(singularUsage);
    }
  }

  for (Map<String, dynamic> singularUsage in singularUsageList) {
    final meterType =
        singularUsage['meter_type']?.toString().trim().toLowerCase() ?? '';
    if (meterType.isEmpty) {
      continue;
    }

    final billedAutoUsage =
        _billValueToDouble(singularUsage['billed_auto_usage']);
    final billedRate = _billValueToDouble(singularUsage['billed_rate']);
    final billedManualUsage = _billValueToDouble(singularUsage['manual_usage']);

    double? billedGstRate;
    if (singularUsage['billed_gst'] != null) {
      billedGstRate = _billValueToDouble(singularUsage['billed_gst']);
    }

    PagEmsTypeUsageCalcRl2 emsTypeUsageCalcRl = PagEmsTypeUsageCalcRl2(
      costDecimals: 2,
      meterType: meterType,
      billedAutoUsage: billedAutoUsage,
      billedManualUsage: billedManualUsage,
      billedRate: billedRate,
      billedGst: billedGstRate,
      billedGstAmount: billedGstAmount,
      billedUsageCostAmount: billedUsageCostAmount,
      billedPrincipalAmount: billedPrincipalAmount,
      billedCycleTotalAmount: billedCycleTotalAmount,
      lineItemList: lineItemList,
      billBarFromMonth: billBarFromMonth,
    );
    emsTypeUsageCalcRl.doSingularCalc();
    singularUsageCalcList.add(emsTypeUsageCalcRl);

    singularUsage['usage_calc_rl2'] = emsTypeUsageCalcRl;
  }

  PagEmsTypeUsageCalcRl2 compositeUsageCalcRl = PagEmsTypeUsageCalcRl2(
    costDecimals: 2,
    lineItemList: lineItemList,
    billBarFromMonth: billBarFromMonth,
    singularUsageCalcList: singularUsageCalcList,
    miniSoaInfo: miniSoaInfo,
    interestInfo: interestInfo,
    billedGst: billedGst,
    billedGstAmount: billedGstAmount,
    billedUsageCostAmount: billedUsageCostAmount,
    billedPrincipalAmount: billedPrincipalAmount,
    billedCycleTotalAmount: billedCycleTotalAmount,
    billedPayableAmount: billedPayableAmount,
    billedBciInfo: billedBciInfo,
    billedTotalBciAmount: billedTotalBciAmount,
  );
  compositeUsageCalcRl.doCompositeCalc();

  final lineItemLabel1 = compositeUsageCalcRl.getLineItemLabel(true, true);
  final lineItemAmount1 = compositeUsageCalcRl.getLineItemAmount(true, true);
  final lineItemLabel2 = compositeUsageCalcRl.getLineItemLabel(false, true);
  final lineItemAmount2 = compositeUsageCalcRl.getLineItemAmount(false, true);
  final lineItemLabel3 = compositeUsageCalcRl.getLineItemLabel(false, false);
  final lineItemAmount3 = compositeUsageCalcRl.getLineItemAmount(false, false);

  final Map<String, dynamic> calcedBillInfo = {
    'billingRecName': billInfo['name'] ?? '',
    'billLabel': billInfo['bill_label'] ?? '',
    'invoiceNumber': getBillInvoiceNumber2(billInfo),
    'customerName': billInfo['tenant_name'] ?? '',
    'customerLabel': billInfo['tenant_label'] ?? '',
    'customerCompanyTradingName':
        billInfo['customer_company_trading_name'] ?? '',
    'tenantAccountNumber': billInfo['tenant_account_number'] ?? '',
    'strDepositAmount': billInfo['deposit_amount'] ?? '',
    'paymentMethod': billInfo['payment_method'] ?? '',
    'tenantBillingAddressLine1':
        billInfo['tenant_billing_address_line_1'] ?? '',
    'tenantBillingAddressLine2':
        billInfo['tenant_billing_address_line_2'] ?? '',
    'tenantBillingAddressLine3':
        billInfo['tenant_billing_address_line_3'] ?? '',
    'customerType': billInfo['customer_type'] ?? '',
    'gst': compositeUsageCalcRl.billedGst, //billInfo['gst'],
    'paymentInfo': billInfo['payment_info'] ?? '',
    'strBillTimeRange': billTimeRangeStr,
    'strDueDate': billInfo['billed_due_date_timestamp'] ?? '',
    'strFrom': strFromTimestamp,
    'strTo': strToTimestamp,
    'strEffectiveTo': billInfo['effective_to_timestamp'] ?? '',
    'strBillDate': billInfo['bill_date_timestamp'],
    'totalUsageCost': compositeUsageCalcRl.totalUsageCost,
    'subTotalAmount': compositeUsageCalcRl.subTotalCost,
    'gstAmount': compositeUsageCalcRl.billedGstAmount,
    'totalAmount': compositeUsageCalcRl.totalCost,
    'interestInfo': interestInfo,
    'cycleTotalAmount': compositeUsageCalcRl.cycleTotalAmount,
    'payableAmount': compositeUsageCalcRl.payableAmount,
    'typeRateE': compositeUsageCalcRl.getTypeUsage('E')?.rate,
    'typeRateW': compositeUsageCalcRl.getTypeUsage('W')?.rate,
    'typeRateB': compositeUsageCalcRl.getTypeUsage('B')?.rate,
    'typeRateN': compositeUsageCalcRl.getTypeUsage('N')?.rate,
    'typeRateG': compositeUsageCalcRl.getTypeUsage('G')?.rate,
    'typeRateSE1': compositeUsageCalcRl.getTypeUsage('SE1')?.rate,
    'typeUsageE': compositeUsageCalcRl.getTypeUsage('E')?.usage,
    'typeUsageW': compositeUsageCalcRl.getTypeUsage('W')?.usage,
    'typeUsageB': compositeUsageCalcRl.getTypeUsage('B')?.usage,
    'typeUsageN': compositeUsageCalcRl.getTypeUsage('N')?.usage,
    'typeUsageG': compositeUsageCalcRl.getTypeUsage('G')?.usage,
    'typeUsageSE1': compositeUsageCalcRl.getTypeUsage('SE1')?.usage,
    'typeCostE': compositeUsageCalcRl.getTypeUsage('E')?.cost,
    'typeCostW': compositeUsageCalcRl.getTypeUsage('W')?.cost,
    'typeCostB': compositeUsageCalcRl.getTypeUsage('B')?.cost,
    'typeCostN': compositeUsageCalcRl.getTypeUsage('N')?.cost,
    'typeCostG': compositeUsageCalcRl.getTypeUsage('G')?.cost,
    'typeCostSE1': compositeUsageCalcRl.getTypeUsage('SE1')?.cost,
    // Trending snapshots are not part of the Gen3 singular billing record.
    'trendingE': const <Map<String, dynamic>>[],
    'trendingW': const <Map<String, dynamic>>[],
    'trendingB': const <Map<String, dynamic>>[],
    'trendingN': const <Map<String, dynamic>>[],
    'trendingG': const <Map<String, dynamic>>[],
    'trendingSE1': const <Map<String, dynamic>>[],
    'lineItemList': compositeUsageCalcRl.lineItemList,
    'lineItemLabel1': lineItemLabel1,
    'lineItemValue1': lineItemAmount1,
    'lineItemLabel2': lineItemLabel2,
    'lineItemValue2': lineItemAmount2,
    'lineItemLabel3': lineItemLabel3,
    'lineItemValue3': lineItemAmount3,
    'billedBciInfoList': compositeUsageCalcRl.billedEffBciInfoList,
    'billedTotalBciAmount': compositeUsageCalcRl.billedTotalBciAmount,
    'miniSoaInfo': miniSoaInfo,
    'tenantSingularUsageInfoList': singularUsageList,
    'billedAmgrCompanyTradingName': billedAmgrCompanyTradingName,
    'billedAmgrCompanyRegNumber': billedAmgrCompanyRegNumber,
    'billedAmgrGstRegNumber': billedAmgrGstRegNumber,
    'amgrAddressLine1': amgrAddressLine1,
    'amgrAddressLine2': amgrAddressLine2,
    'amgrAddressLine3': amgrAddressLine3,
    'amgrBankAccountName': amgrBankAccountName,
    'amgrBankAccountNumber': amgrBankAccountNumber,
    'amgrBankLabel': amgrBankLabel,
    'amgrBankCode': amgrBankCode,
    'amgrBankBranchCode': amgrBankBranchCode,
    'amgrBankSwiftCode': amgrBankSwiftCode,
    'amgrBankPayNow': amgrBankPayNow,
    'strCollectionStartDate': strCollectionStartDateTimestamp,
    'strCollectionEndDate': strCollectionEndDateTimestamp,
    'singularUsageList': singularUsageList,
    'compositeUsageCalc': compositeUsageCalcRl,
  };

  return calcedBillInfo;
}
