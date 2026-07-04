import '../../../util/date_time_util.dart';
import '../tenant/pag_ems_type_usage_calc_rl.dart';

Map<String, dynamic> prepCalcedBillInfoRl(Map<String, dynamic> billInfo) {
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

  final strBilledInterestAmount = billInfo['billed_interest_amount'] ?? '';
  double? billedInterestAmount =
      double.tryParse(strBilledInterestAmount) ?? 0.0;

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
  List<PagEmsTypeUsageCalcRl> singularUsageCalcList = [];

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
  String amgrBankName = billInfo['amgr_bank_label'] ?? '';
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

    double? billedGstRate;
    if (singularUsage['billed_gst'] != null) {
      billedGstRate = double.tryParse(singularUsage['billed_gst']);
    }

    PagEmsTypeUsageCalcRl emsTypeUsageCalcRl = PagEmsTypeUsageCalcRl(
      costDecimals: 2,
      billedAutoUsageE: billedAutoUsageInfo['billed_auto_usage_e'],
      billedAutoUsageW: billedAutoUsageInfo['billed_auto_usage_w'],
      billedAutoUsageB: billedAutoUsageInfo['billed_auto_usage_b'],
      billedAutoUsageN: billedAutoUsageInfo['billed_auto_usage_n'],
      billedAutoUsageG: billedAutoUsageInfo['billed_auto_usage_g'],
      billedManualUsageE: billedManualUsages['manual_usage_e'],
      billedManualUsageW: billedManualUsages['manual_usage_w'],
      billedManualUsageB: billedManualUsages['manual_usage_b'],
      billedManualUsageN: billedManualUsages['manual_usage_n'],
      billedManualUsageG: billedManualUsages['manual_usage_g'],
      billedRateE: billedRateInfo['billed_rate_e'],
      billedRateW: billedRateInfo['billed_rate_w'],
      billedRateB: billedRateInfo['billed_rate_b'],
      billedRateN: billedRateInfo['billed_rate_n'],
      billedRateG: billedRateInfo['billed_rate_g'],
      billedUsageFactorE: billedUsageFactorInfo['billed_usage_factor_e'],
      billedUsageFactorW: billedUsageFactorInfo['billed_usage_factor_w'],
      billedUsageFactorB: billedUsageFactorInfo['billed_usage_factor_b'],
      billedUsageFactorN: billedUsageFactorInfo['billed_usage_factor_n'],
      billedUsageFactorG: billedUsageFactorInfo['billed_usage_factor_g'],
      billedSubTenantUsageE: billedSubTenantUsages['billed_sub_tenant_usage_e'],
      billedSubTenantUsageW: billedSubTenantUsages['billed_sub_tenant_usage_w'],
      billedSubTenantUsageB: billedSubTenantUsages['billed_sub_tenant_usage_b'],
      billedSubTenantUsageN: billedSubTenantUsages['billed_sub_tenant_usage_n'],
      billedSubTenantUsageG: billedSubTenantUsages['billed_sub_tenant_usage_g'],
      billedGst: billedGstRate,
      billedGstAmount: billedGstAmount,
      billedUsageCostAmount: billedUsageCostAmount,
      billedPrincipalAmount: billedPrincipalAmount,
      billedInterestAmount: billedInterestAmount,
      billedCycleTotalAmount: billedCycleTotalAmount,
      lineItemList: lineItemList,
      billedTrendingSnapShot: billedTrendingSnapShot,
      billBarFromMonth: billBarFromMonth,
    );
    emsTypeUsageCalcRl.doSingularCalc();
    singularUsageCalcList.add(emsTypeUsageCalcRl);

    singularUsage['usage_calc'] = emsTypeUsageCalcRl;
  }

  PagEmsTypeUsageCalcRl compositeUsageCalcRl = PagEmsTypeUsageCalcRl(
    costDecimals: 2,
    billedTrendingSnapShot: billInfo['billed_trending_snapshot'] ?? [],
    lineItemList: lineItemList,
    billBarFromMonth: billBarFromMonth,
    singularUsageCalcList: singularUsageCalcList,
    miniSoaInfo: miniSoaInfo,
    interestInfo: interestInfo,
    billedGst: billedGst,
    billedGstAmount: billedGstAmount,
    billedUsageCostAmount: billedUsageCostAmount,
    billedPrincipalAmount: billedPrincipalAmount,
    billedInterestAmount: billedInterestAmount,
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
    'customerName': billInfo['tenant_name'] ?? '',
    'customerLabel': billInfo['tenant_label'] ?? '',
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
    'typeRateE': compositeUsageCalcRl.typeUsageE?.rate,
    'typeRateW': compositeUsageCalcRl.typeUsageW?.rate,
    'typeRateB': compositeUsageCalcRl.typeUsageB?.rate,
    'typeRateN': compositeUsageCalcRl.typeUsageN?.rate,
    'typeRateG': compositeUsageCalcRl.typeUsageG?.rate,
    'typeUsageE': compositeUsageCalcRl.typeUsageE?.usage,
    'typeUsageW': compositeUsageCalcRl.typeUsageW?.usage,
    'typeUsageB': compositeUsageCalcRl.typeUsageB?.usage,
    'typeUsageN': compositeUsageCalcRl.typeUsageN?.usage,
    'typeUsageG': compositeUsageCalcRl.typeUsageG?.usage,
    'typeCostE': compositeUsageCalcRl.typeUsageE?.cost,
    'typeCostW': compositeUsageCalcRl.typeUsageW?.cost,
    'typeCostB': compositeUsageCalcRl.typeUsageB?.cost,
    'typeCostN': compositeUsageCalcRl.typeUsageN?.cost,
    'typeCostG': compositeUsageCalcRl.typeUsageG?.cost,
    'trendingE': compositeUsageCalcRl.trendingE,
    'trendingW': compositeUsageCalcRl.trendingW,
    'trendingB': compositeUsageCalcRl.trendingB,
    'trendingN': compositeUsageCalcRl.trendingN,
    'trendingG': compositeUsageCalcRl.trendingG,
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
    'amgrBankName': amgrBankName,
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
