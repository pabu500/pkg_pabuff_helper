import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pagrid_helper/ems_helper/billing_helper/pag_bill_def.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:developer' as dev;

import '../../../../pagrid_helper/ems_helper/billing_helper/wgt_pag_composite_bill_view.dart';
import '../../../../xt_ui/wdgt/info/get_error_text_prompt.dart';
import '../../../../xt_ui/wdgt/wgt_pag_wait.dart';
import '../../../comm/comm_fin_ops.dart';
import '../../../def_helper/dh_pag_finance_type.dart';
import 'wgt_payment_lc_status_op.dart';

class WgtMatchOnePayment2 extends StatefulWidget {
  const WgtMatchOnePayment2({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.tenantInfo,
    required this.defaultPaymentLcStatusStr,
    this.paymentMatchingInfo,
    this.onUpdate,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Map<String, dynamic> tenantInfo;
  final Map<String, dynamic>? paymentMatchingInfo;
  final String defaultPaymentLcStatusStr;
  final Function? onUpdate;

  @override
  State<WgtMatchOnePayment2> createState() => _WgtMatchOnePayment2State();
}

class _WgtMatchOnePayment2State extends State<WgtMatchOnePayment2> {
  late final TextStyle mainLabelStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Theme.of(context).hintColor,
  );
  late final TextStyle mainTextStyle = const TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
  );

  late final TextStyle billLabelStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
    // color: Theme.of(context).colorScheme.primary,
  );
  late final TextStyle billKeyStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Theme.of(context).hintColor,
  );
  late final TextStyle billValStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 21,
    color: Theme.of(context).colorScheme.onSurface,
  );

  late final String tenantName = widget.tenantInfo['tenant_name'];

  bool _isFetchingBillList = false;
  bool _billListFetchTried = false;
  String _errorText = '';

  final List<Map<String, dynamic>> _billList = [];
  late PagPaymentLcStatus _lcStatusDisplay;
  UniqueKey? _lcStatusOpsKey;
  late final Map<String, dynamic> _paymentInfo =
      widget.paymentMatchingInfo ?? {};
  late final double? _paymentAmount =
      double.tryParse(_paymentInfo['amount'] ?? '');

  // info from payment_billing_rec mapping
  final List<Map<String, dynamic>> _paymentApplyInfoListExisting = [];
  final List<Map<String, dynamic>> _paymentApplyInfoListNew = [];

  double? _initialExcessiveBalanceToApply;
  double? _initialPaymentAmountToApply;
  double? _availableExcessiveBalanceToApply;
  double? _availablePaymentAmountToApply;

  final Color balColor = Colors.green.shade900.withAlpha(210);
  final Color paymentColor = Colors.green.shade600.withAlpha(210);

  Future<void> _fetchPaymentMatchOpInfo() async {
    if (_isFetchingBillList || _billListFetchTried) return;

    _isFetchingBillList = true;
    _errorText = '';

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'item_kind': PagItemKind.bill.name,
      't.name': tenantName,
      'payment_id': _paymentInfo['id'] ?? '',
    };

    try {
      final result = await fetchPaymentMatchOpInfo(
          widget.appConfig,
          queryMap,
          MdlPagSvcClaim(
            userId: widget.loggedInUser.id,
            username: widget.loggedInUser.username,
            scope: '',
            target: '',
            operation: '',
          ));
      final itemList = result['bill_list'] ?? [];
      // final itemList = result['item_list'] ?? [];
      _billList.clear();
      // _billList.addAll(itemList);
      for (var item in itemList) {
        Map<String, dynamic> billItem = item;
        _billList.add(billItem);
      }
      final paymentApplyInfoList = result['payment_apply_info_list'] ?? {};

      _initialPaymentAmountToApply = _paymentAmount;
      _availablePaymentAmountToApply = _paymentAmount;

      _initialExcessiveBalanceToApply = 50.0; // hard coded for now
      _availableExcessiveBalanceToApply = _initialExcessiveBalanceToApply;

      for (var item in paymentApplyInfoList) {
        _paymentApplyInfoListExisting.add(item);
        final appliedAmountUsage =
            double.tryParse(item['applied_usage_amount'] ?? '0.0') ?? 0.0;
        final appliedAmountInterest =
            double.tryParse(item['applied_interest_amount'] ?? '0.0') ?? 0.0;
        double totalApplied = appliedAmountUsage + appliedAmountInterest;

        _availablePaymentAmountToApply =
            _availablePaymentAmountToApply! - totalApplied;
      }
    } catch (e) {
      dev.log('Error fetching bill list: $e');
      _errorText = 'Failed to fetch bills';
    } finally {
      setState(() {
        _isFetchingBillList = false;
        _billListFetchTried = true;
      });
    }
  }

  void _populateApply() {
    if (_availablePaymentAmountToApply == null ||
        _availablePaymentAmountToApply! <= 0.0) {
      return;
    }
    if (_billList.isEmpty) {
      return;
    }

    // rule 1: payment flows the bill with exact amount first
    // rule 2: payment from excessive balance first
    // rule 3: pay oldest bill first
    // rule 4: pay usage of the usage bucket first, for all bills from oldest to newest
    // rule 5: pay interest of the interest bucket first, for all bills from oldest to newest

    _paymentApplyInfoListNew.clear();

    double outBucketExcessiveBalance = _initialExcessiveBalanceToApply!;
    double outBucketThisPayment = _initialPaymentAmountToApply!;

    final billList = [];
    billList.addAll(_billList);

    // rule 1: payment flows from outBucketThisPayment to the bill with exact amount first
    for (var bill in billList) {
      if (outBucketThisPayment <= 0.0) {
        break;
      }

      // skip if bill is not released
      if (bill['lc_status'] != 'released') {
        continue;
      }

      final billingRecId = bill['id'] ?? '';
      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }

      if (outBucketThisPayment == billedTotalCost) {
        final billedInterestAmount =
            double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
        final billedUsageAmount = billedTotalCost - billedInterestAmount;

        _paymentApplyInfoListNew.add({
          'billing_rec_id': billingRecId,
          'applied_interest_amount': billedInterestAmount,
          'applied_usage_amount': billedUsageAmount,
        });
        bill['is_fully_paid_by_current_payment'] = true;

        outBucketThisPayment -= billedTotalCost;
      }
    }

    billList.sort((a, b) {
      final aTimestamp = a['from_timestamp'] ?? '';
      final bTimestamp = b['from_timestamp'] ?? '';
      return aTimestamp.compareTo(bTimestamp);
    });

    double inBucketTotalBilledUsageAmount = 0.0;
    double inBucketTotalBilledInterestAmount = 0.0;
    for (var bill in billList) {
      // skip if bill is not released
      if (bill['lc_status'] != 'released') {
        continue;
      }
      // skip if bill is already fully paid
      if (bill['is_fully_paid_by_current_payment'] == true) {
        continue;
      }

      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }

      final billedInterestAmount =
          double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
      final billedUsageAmount = billedTotalCost - billedInterestAmount;
      inBucketTotalBilledUsageAmount += billedUsageAmount;
      inBucketTotalBilledInterestAmount += billedInterestAmount;
    }

    // rule 3: flow out from outBucketExcessiveBalance first
    // rule 3.1: flow to usage bucket first
    for (var bill in billList) {
      if (outBucketExcessiveBalance <= 0.0) {
        break;
      }

      // skip if bill is not released
      if (bill['lc_status'] != 'released') {
        continue;
      }
      // skip if bill is already fully paid
      if (bill['is_fully_paid_by_current_payment'] == true) {
        continue;
      }

      //flow to usage bucket first
      final billingRecId = bill['id'] ?? '';
      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }
      final billedInterestAmount =
          double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
      final billedUsageAmount = billedTotalCost - billedInterestAmount;
      if (billedUsageAmount > 0.0) {
        double appliedUsage = 0.0;
        if (outBucketExcessiveBalance >= billedUsageAmount) {
          appliedUsage = billedUsageAmount;
          outBucketExcessiveBalance -= billedUsageAmount;
        } else {
          appliedUsage = outBucketExcessiveBalance;
          outBucketExcessiveBalance = 0.0;
        }
        if (appliedUsage > 0.0) {
          bool found = false;
          for (var item in _paymentApplyInfoListNew) {
            if (item['billing_rec_id'] == billingRecId) {
              item['applied_usage_amount'] = appliedUsage;
              found = true;
              break;
            }
          }
          if (!found) {
            _paymentApplyInfoListNew.add({
              'billing_rec_id': billingRecId,
              'applied_usage_amount': appliedUsage,
            });
          }
          _checkFullyPaid();
        }
      }
    }
    // rule 3.2: flow to interest bucket next
    for (var bill in billList) {
      if (outBucketExcessiveBalance <= 0.0) {
        break;
      }

      // skip if bill is not released
      if (bill['lc_status'] != 'released') {
        continue;
      }
      // skip if bill is already fully paid
      if (bill['is_fully_paid_by_current_payment'] == true) {
        continue;
      }

      //flow to interest bucket next
      final billingRecId = bill['id'] ?? '';
      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }
      final billedInterestAmount =
          double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
      if (billedInterestAmount > 0.0) {
        double appliedInterest = 0.0;
        if (outBucketExcessiveBalance >= billedInterestAmount) {
          appliedInterest = billedInterestAmount;
          outBucketExcessiveBalance -= billedInterestAmount;
        } else {
          appliedInterest = outBucketExcessiveBalance;
          outBucketExcessiveBalance = 0.0;
        }
        if (appliedInterest > 0.0) {
          bool found = false;
          for (var item in _paymentApplyInfoListNew) {
            if (item['billing_rec_id'] == billingRecId) {
              item['applied_interest_amount'] = appliedInterest;
              found = true;
              break;
            }
          }
          if (!found) {
            _paymentApplyInfoListNew.add({
              'billing_rec_id': billingRecId,
              'applied_interest_amount': appliedInterest,
            });
          }
          _checkFullyPaid();
        }
      }
    }

    // rule 4: flow out from outBucketThisPayment next
    // rule 4.1: flow to usage bucket first
    for (var bill in billList) {
      if (outBucketThisPayment <= 0.0) {
        break;
      }

      // skip if bill is not released
      if (bill['lc_status'] != 'released') {
        continue;
      }
      // skip if bill is already fully paid
      if (bill['is_fully_paid_by_current_payment'] == true) {
        continue;
      }

      //flow to usage bucket first
      final billingRecId = bill['id'] ?? '';
      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }
      final billedInterestAmount =
          double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
      final billedUsageAmount = billedTotalCost - billedInterestAmount;
      if (billedUsageAmount > 0.0) {
        double appliedUsage = _paymentApplyInfoListNew.firstWhere(
              (element) => element['billing_rec_id'] == billingRecId,
              orElse: () => {'applied_usage_amount': 0.0},
            )['applied_usage_amount'] ??
            0.0;
        double remainingUsageToBePaid = billedUsageAmount - appliedUsage;
        if (remainingUsageToBePaid <= 0.0) {
          continue;
        }
        if (outBucketThisPayment >= remainingUsageToBePaid) {
          appliedUsage += remainingUsageToBePaid;
          outBucketThisPayment -= remainingUsageToBePaid;
        } else {
          appliedUsage += outBucketThisPayment;
          outBucketThisPayment = 0.0;
        }
        if (appliedUsage > 0.0) {
          bool found = false;
          for (var item in _paymentApplyInfoListNew) {
            if (item['billing_rec_id'] == billingRecId) {
              item['applied_usage_amount'] = appliedUsage;
              found = true;
              break;
            }
          }
          if (!found) {
            _paymentApplyInfoListNew.add({
              'billing_rec_id': billingRecId,
              'applied_usage_amount': appliedUsage,
            });
          }
          _checkFullyPaid();
        }
      }
    }
    // rule 4.2: flow to interest bucket next
    for (var bill in billList) {
      if (outBucketThisPayment <= 0.0) {
        break;
      }

      // skip if bill is not released
      if (bill['lc_status'] != 'released') {
        continue;
      }
      // skip if bill is already fully paid
      if (bill['is_fully_paid_by_current_payment'] == true) {
        continue;
      }

      //flow to interest bucket next
      final billingRecId = bill['id'] ?? '';
      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }
      final billedInterestAmount =
          double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
      if (billedInterestAmount > 0.0) {
        double appliedInterest = _paymentApplyInfoListNew.firstWhere(
              (element) => element['billing_rec_id'] == billingRecId,
              orElse: () => {'applied_interest_amount': 0.0},
            )['applied_interest_amount'] ??
            0.0;
        double remainingInterestToBePaid =
            billedInterestAmount - appliedInterest;
        if (remainingInterestToBePaid <= 0.0) {
          continue;
        }
        if (outBucketThisPayment >= remainingInterestToBePaid) {
          appliedInterest += remainingInterestToBePaid;
          outBucketThisPayment -= remainingInterestToBePaid;
        } else {
          appliedInterest += outBucketThisPayment;
          outBucketThisPayment = 0.0;
        }
        if (appliedInterest > 0.0) {
          bool found = false;
          for (var item in _paymentApplyInfoListNew) {
            if (item['billing_rec_id'] == billingRecId) {
              item['applied_interest_amount'] = appliedInterest;
              found = true;
              break;
            }
          }
          if (!found) {
            _paymentApplyInfoListNew.add({
              'billing_rec_id': billingRecId,
              'applied_interest_amount': appliedInterest,
            });
          }
          _checkFullyPaid();
        }
      }
    }

    setState(() {
      _availablePaymentAmountToApply = outBucketThisPayment;
      _availableExcessiveBalanceToApply = outBucketExcessiveBalance;
    });
  }

  void _populateApply2() {
    // if (_availablePaymentAmountToApply == null ||
    //     _availablePaymentAmountToApply! <= 0.0) {
    //   return;
    // }
    if (_billList.isEmpty) {
      return;
    }

    // rule 1: payment flows the bill with exact amount first
    // rule 2: payment from excessive balance first
    // rule 3: pay oldest bill first
    // rule 4: pay usage of the usage bucket first, for all bills from oldest to newest
    // rule 5: pay interest of the interest bucket first, for all bills from oldest to newest

    // _paymentApplyInfoListNew.clear();

    double outBucketExcessiveBalance = _initialExcessiveBalanceToApply!;
    double outBucketThisPayment = _initialPaymentAmountToApply!;

    final billList = [];
    billList.addAll(_billList);

    // rule 1: payment flows from outBucketThisPayment to the bill with exact amount first
    for (var bill in billList) {
      if (outBucketThisPayment <= 0.0) {
        break;
      }

      // skip if bill is not released
      if (bill['lc_status'] != 'released') {
        continue;
      }

      final billingRecId = bill['id'] ?? '';
      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }

      if (outBucketThisPayment == billedTotalCost) {
        final billedInterestAmount =
            double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
        final billedUsageAmount = billedTotalCost - billedInterestAmount;

        //check if already in the list
        bool found = false;
        for (var item in _paymentApplyInfoListNew) {
          if (item['billing_rec_id'] == billingRecId) {
            if (item['is_custom_apply_interest'] != true) {
              item['applied_interest_amount'] = billedInterestAmount;
            }
            if (item['is_custom_apply_usage'] != true) {
              item['applied_usage_amount'] = billedUsageAmount;
            }
            found = true;
            break;
          }
        }
        if (!found) {
          _paymentApplyInfoListNew.add({
            'billing_rec_id': billingRecId,
            'applied_interest_amount': billedInterestAmount,
            'applied_usage_amount': billedUsageAmount,
            'is_exact_match': true,
          });
          bill['is_fully_paid_by_current_payment'] = true;

          outBucketThisPayment -= billedTotalCost;
        }
      }
    }

    billList.sort((a, b) {
      final aTimestamp = a['from_timestamp'] ?? '';
      final bTimestamp = b['from_timestamp'] ?? '';
      return aTimestamp.compareTo(bTimestamp);
    });

    double inBucketTotalBilledUsageAmount = 0.0;
    double inBucketTotalBilledInterestAmount = 0.0;
    for (var bill in billList) {
      // skip if bill is not released
      if (bill['lc_status'] != 'released') {
        continue;
      }
      // skip if bill is already fully paid
      if (bill['is_fully_paid_by_current_payment'] == true) {
        continue;
      }

      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }

      final billedInterestAmount =
          double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
      final billedUsageAmount = billedTotalCost - billedInterestAmount;
      inBucketTotalBilledUsageAmount += billedUsageAmount;
      inBucketTotalBilledInterestAmount += billedInterestAmount;
    }

    // rule 3: flow out from outBucketExcessiveBalance first
    // rule 3.1: flow to usage bucket first
    for (var bill in billList) {
      if (outBucketExcessiveBalance <= 0.0) {
        break;
      }

      // skip if bill is not released
      if (bill['lc_status'] != 'released') {
        continue;
      }
      // skip if bill is already fully paid
      if (bill['is_fully_paid_by_current_payment'] == true) {
        continue;
      }

      //flow to usage bucket first
      final billingRecId = bill['id'] ?? '';
      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }
      final billedInterestAmount =
          double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
      final billedUsageAmount = billedTotalCost - billedInterestAmount;
      if (billedUsageAmount > 0.0) {
        double appliedUsage = 0.0;
        if (outBucketExcessiveBalance >= billedUsageAmount) {
          appliedUsage = billedUsageAmount;
          outBucketExcessiveBalance -= billedUsageAmount;
        } else {
          appliedUsage = outBucketExcessiveBalance;
          outBucketExcessiveBalance = 0.0;
        }
        if (appliedUsage > 0.0) {
          bool found = false;
          for (var item in _paymentApplyInfoListNew) {
            if (item['billing_rec_id'] == billingRecId) {
              if (item['is_custom_apply_usage'] != true) {
                item['applied_usage_amount'] = appliedUsage;
              }
              found = true;
              break;
            }
          }
          if (!found) {
            _paymentApplyInfoListNew.add({
              'billing_rec_id': billingRecId,
              'applied_usage_amount': appliedUsage,
            });
          }
          _checkFullyPaid();
        }
      }
    }
    // rule 3.2: flow to interest bucket next
    for (var bill in billList) {
      if (outBucketExcessiveBalance <= 0.0) {
        break;
      }

      // skip if bill is not released
      if (bill['lc_status'] != 'released') {
        continue;
      }
      // skip if bill is already fully paid
      if (bill['is_fully_paid_by_current_payment'] == true) {
        continue;
      }

      //flow to interest bucket next
      final billingRecId = bill['id'] ?? '';
      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }
      final billedInterestAmount =
          double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
      if (billedInterestAmount > 0.0) {
        double appliedInterest = 0.0;
        if (outBucketExcessiveBalance >= billedInterestAmount) {
          appliedInterest = billedInterestAmount;
          outBucketExcessiveBalance -= billedInterestAmount;
        } else {
          appliedInterest = outBucketExcessiveBalance;
          outBucketExcessiveBalance = 0.0;
        }
        if (appliedInterest > 0.0) {
          bool found = false;
          for (var item in _paymentApplyInfoListNew) {
            if (item['billing_rec_id'] == billingRecId) {
              if (item['is_custom_apply_interest'] != true) {
                item['applied_interest_amount'] = appliedInterest;
              }
              found = true;
              break;
            }
          }
          if (!found) {
            _paymentApplyInfoListNew.add({
              'billing_rec_id': billingRecId,
              'applied_interest_amount': appliedInterest,
            });
          }
          _checkFullyPaid();
        }
      }
    }

    // rule 4: flow out from outBucketThisPayment next
    // rule 4.1: flow to usage bucket first
    for (var bill in billList) {
      if (outBucketThisPayment <= 0.0) {
        break;
      }

      // skip if bill is not released
      if (bill['lc_status'] != 'released') {
        continue;
      }
      // skip if bill is already fully paid
      if (bill['is_fully_paid_by_current_payment'] == true) {
        continue;
      }

      //flow to usage bucket first
      final billingRecId = bill['id'] ?? '';
      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }
      final billedInterestAmount =
          double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
      final billedUsageAmount = billedTotalCost - billedInterestAmount;
      if (billedUsageAmount > 0.0) {
        double appliedUsage = _paymentApplyInfoListNew.firstWhere(
              (element) => element['billing_rec_id'] == billingRecId,
              orElse: () => {'applied_usage_amount': 0.0},
            )['applied_usage_amount'] ??
            0.0;
        double remainingUsageToBePaid = billedUsageAmount - appliedUsage;
        if (remainingUsageToBePaid <= 0.0) {
          continue;
        }
        if (outBucketThisPayment >= remainingUsageToBePaid) {
          appliedUsage += remainingUsageToBePaid;
          outBucketThisPayment -= remainingUsageToBePaid;
        } else {
          appliedUsage += outBucketThisPayment;
          outBucketThisPayment = 0.0;
        }
        if (appliedUsage > 0.0) {
          bool found = false;
          for (var item in _paymentApplyInfoListNew) {
            if (item['billing_rec_id'] == billingRecId) {
              if (item['is_custom_apply_usage'] != true) {
                item['applied_usage_amount'] = appliedUsage;
              }
              found = true;
              break;
            }
          }
          if (!found) {
            _paymentApplyInfoListNew.add({
              'billing_rec_id': billingRecId,
              'applied_usage_amount': appliedUsage,
            });
          }
          _checkFullyPaid();
        }
      }
    }
    // rule 4.2: flow to interest bucket next
    for (var bill in billList) {
      if (outBucketThisPayment <= 0.0) {
        break;
      }

      // skip if bill is not released
      if (bill['lc_status'] != 'released') {
        continue;
      }
      // skip if bill is already fully paid
      if (bill['is_fully_paid_by_current_payment'] == true) {
        continue;
      }

      //flow to interest bucket next
      final billingRecId = bill['id'] ?? '';
      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }
      final billedInterestAmount =
          double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
      if (billedInterestAmount > 0.0) {
        double appliedInterest = _paymentApplyInfoListNew.firstWhere(
              (element) => element['billing_rec_id'] == billingRecId,
              orElse: () => {'applied_interest_amount': 0.0},
            )['applied_interest_amount'] ??
            0.0;
        double remainingInterestToBePaid =
            billedInterestAmount - appliedInterest;
        if (remainingInterestToBePaid <= 0.0) {
          continue;
        }
        if (outBucketThisPayment >= remainingInterestToBePaid) {
          appliedInterest += remainingInterestToBePaid;
          outBucketThisPayment -= remainingInterestToBePaid;
        } else {
          appliedInterest += outBucketThisPayment;
          outBucketThisPayment = 0.0;
        }
        if (appliedInterest > 0.0) {
          bool found = false;
          for (var item in _paymentApplyInfoListNew) {
            if (item['billing_rec_id'] == billingRecId) {
              if (item['is_custom_apply_interest'] != true) {
                item['applied_interest_amount'] = appliedInterest;
              }
              found = true;
              break;
            }
          }
          if (!found) {
            _paymentApplyInfoListNew.add({
              'billing_rec_id': billingRecId,
              'applied_interest_amount': appliedInterest,
            });
          }
          _checkFullyPaid();
        }
      }
    }

    setState(() {
      _availablePaymentAmountToApply = outBucketThisPayment;
      _availableExcessiveBalanceToApply = outBucketExcessiveBalance;
    });
  }

  void _checkFullyPaid() {
    for (var bill in _billList) {
      final billingRecId = bill['id'] ?? '';
      final billedTotalCost =
          double.tryParse(bill['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }
      double totalApplied = 0.0;
      for (var item in _paymentApplyInfoListNew) {
        if (item['billing_rec_id'] == billingRecId) {
          final appliedAmountUsage = item['applied_usage_amount'] ?? 0.0;
          final appliedAmountInterest = item['applied_interest_amount'] ?? 0.0;
          totalApplied = appliedAmountUsage + appliedAmountInterest;
          break;
        }
      }
      if (totalApplied >= billedTotalCost) {
        bill['is_fully_paid_by_current_payment'] = true;
      } else {
        bill['is_fully_paid_by_current_payment'] = false;
      }
    }
  }

  void _updateApplyInfo(int index, String fieldKey, String value) {
    if (index < 0 || index >= _billList.length) {
      return;
    }
    final billInfo = _billList[index];
    final billingRecId = billInfo['id'] ?? '';
    final suffix = fieldKey == 'applied_usage_amount' ? 'usage' : 'interest';
    bool found = false;
    final newValue = value.isEmpty ? 0.0 : double.tryParse(value) ?? 0.0;
    for (var item in _paymentApplyInfoListNew) {
      if (item['billing_rec_id'] == billingRecId) {
        item[fieldKey] = newValue;
        item['is_custom_apply_$suffix'] = true;
        found = true;
        break;
      }
    }
    if (!found) {
      // add new entry
      _paymentApplyInfoListNew.add({
        'billing_rec_id': billingRecId,
        fieldKey: newValue,
        'is_custom_apply_$fieldKey': true,
      });
    }

    // recalculate available amount to apply
    double totalApplied = 0.0;
    for (var item in _paymentApplyInfoListNew) {
      final appliedAmountUsage = item['applied_usage_amount'] ?? 0.0;
      final appliedAmountInterest = item['applied_interest_amount'] ?? 0.0;
      totalApplied += (appliedAmountUsage + appliedAmountInterest);
    }

    // if all applied amount is zero, clear the list
    if (totalApplied <= 0.0) {
      _paymentApplyInfoListNew.clear();
    }

    // recalculate available balance to apply
    // and payment amount to apply
    double outBucketExcessiveBalance = _initialExcessiveBalanceToApply!;
    double outBucketThisPayment = _initialPaymentAmountToApply!;

    // for (var item in _paymentApplyInfoListNew) {
    //   final appliedAmountUsage = item['applied_usage_amount'] ?? 0.0;
    //   final appliedAmountInterest = item['applied_interest_amount'] ?? 0.0;
    //   double totalApplied = appliedAmountUsage + appliedAmountInterest;

    //   if (totalApplied <= 0.0) {
    //     continue;
    //   }

    //   // first use excessive balance
    //   if (outBucketExcessiveBalance >= totalApplied) {
    //     outBucketExcessiveBalance -= totalApplied;
    //     totalApplied = 0.0;
    //   } else {
    //     totalApplied -= outBucketExcessiveBalance;
    //     outBucketExcessiveBalance = 0.0;
    //   }

    //   // then use this payment
    //   if (totalApplied > 0.0) {
    //     if (outBucketThisPayment >= totalApplied) {
    //       outBucketThisPayment -= totalApplied;
    //       totalApplied = 0.0;
    //     } else {
    //       // over applied, reset to zero
    //       outBucketThisPayment = 0.0;
    //       totalApplied = 0.0;
    //     }
    //   }
    // }

    // rule1: flow back to this payment first unless this payment is exact match
    // and the flow back amount is equal to the exact match amount
    for (var item in _paymentApplyInfoListNew) {
      final appliedAmountUsage = item['applied_usage_amount'] ?? 0.0;
      final appliedAmountInterest = item['applied_interest_amount'] ?? 0.0;
      double totalApplied = appliedAmountUsage + appliedAmountInterest;
      if (totalApplied <= 0.0) {
        continue;
      }
      final billingRecId = item['billing_rec_id'] ?? '';
      final billInfo = _billList.firstWhere(
        (element) => element['id'] == billingRecId,
        orElse: () => {},
      );
      final billedTotalCost =
          double.tryParse(billInfo['billed_total_cost'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }
      if (totalApplied == billedTotalCost &&
          _initialPaymentAmountToApply == billedTotalCost) {
        // do not flow back to this payment
      } else {
        // flow back to this payment first
        if (outBucketThisPayment >= totalApplied) {
          outBucketThisPayment -= totalApplied;
          totalApplied = 0.0;
        } else {
          totalApplied -= outBucketThisPayment;
          outBucketThisPayment = 0.0;
        }
      }
      // then flow back to excessive balance
      if (totalApplied > 0.0) {
        if (outBucketExcessiveBalance >= totalApplied) {
          outBucketExcessiveBalance -= totalApplied;
          totalApplied = 0.0;
        } else {
          // over applied, reset to zero
          outBucketExcessiveBalance = 0.0;
          totalApplied = 0.0;
        }
      }
    }

    setState(() {
      _availablePaymentAmountToApply = outBucketThisPayment;
      _availableExcessiveBalanceToApply = outBucketExcessiveBalance;
    });

    setState(() {
      // _availableAmountToApply = (_paymentAmount ?? 0.0) - totalApplied;
    });
  }

  void _updateApplyInfo2(int index, String fieldKey, String value) {
    if (index < 0 || index >= _billList.length) {
      return;
    }
    final billInfo = _billList[index];
    final billingRecId = billInfo['id'] ?? '';
    final suffix = fieldKey == 'applied_usage_amount' ? 'usage' : 'interest';
    bool found = false;
    double diff = 0.0;

    final newValue = value.isEmpty ? 0.0 : double.tryParse(value) ?? 0.0;
    for (var item in _paymentApplyInfoListNew) {
      if (item['billing_rec_id'] == billingRecId) {
        double oldValue = item[fieldKey] ?? 0.0;
        item[fieldKey] = newValue;
        diff = newValue - oldValue;
        item['is_custom_apply_$suffix'] = true;
        found = true;
        break;
      }
    }
    if (!found) {
      // add new entry
      _paymentApplyInfoListNew.add({
        'billing_rec_id': billingRecId,
        fieldKey: newValue,
        'is_custom_apply_$fieldKey': true,
      });
    }

    // update _availablePaymentAmountToApply and _availableExcessiveBalanceToApply
    // rule1: if diff > 0, means more applied, so reduce from excessive balance first, then from this payment
    // rule2: if diff < 0, means less applied, so add back to this payment first, then to excessive balance
    // rule3: do not flow back to this payment if this payment is exact match, unless it's the exact match amount
    if (diff > 0) {
      // more applied
      if (_availableExcessiveBalanceToApply != null &&
          _availableExcessiveBalanceToApply! > 0.0) {
        if (_availableExcessiveBalanceToApply! >= diff) {
          _availableExcessiveBalanceToApply =
              _availableExcessiveBalanceToApply! - diff;
          diff = 0.0;
        } else {
          diff = diff - _availableExcessiveBalanceToApply!;
          _availableExcessiveBalanceToApply = 0.0;
        }
      }
      if (diff > 0.0 &&
          _availablePaymentAmountToApply != null &&
          _availablePaymentAmountToApply! > 0.0) {
        if (_availablePaymentAmountToApply! >= diff) {
          _availablePaymentAmountToApply =
              _availablePaymentAmountToApply! - diff;
          diff = 0.0;
        } else {
          // over applied, reset to zero
          diff = diff - _availablePaymentAmountToApply!;
          _availablePaymentAmountToApply = 0.0;
        }
      }
    } else if (diff < 0) {
      // less applied
      diff = -diff; // make it positive

      String exactMatchBillingRecId = '';
      for (var item in _paymentApplyInfoListNew) {
        final bId = item['billing_rec_id'] ?? '';
        final billInfo = _billList.firstWhere(
          (element) => element['id'] == bId,
          orElse: () => {},
        );
        final billedTotalCost =
            double.tryParse(billInfo['billed_total_cost'] ?? '0.0') ?? 0.0;
        if (billedTotalCost <= 0.0) {
          continue;
        }
        if (item['is_exact_match'] == true &&
            _initialPaymentAmountToApply == billedTotalCost) {
          exactMatchBillingRecId = bId;
          break;
        }
      }
      if (_initialPaymentAmountToApply != null &&
          _initialPaymentAmountToApply! > 0.0) {
        // check if this payment is exact match
        if (exactMatchBillingRecId == billingRecId) {
          // this payment is exact match, do not flow back to this payment
        } else {
          if (_availablePaymentAmountToApply != null) {
            _availablePaymentAmountToApply =
                _availablePaymentAmountToApply! + diff;
            if (_availablePaymentAmountToApply! >
                _initialPaymentAmountToApply!) {
              _availablePaymentAmountToApply = _initialPaymentAmountToApply!;
            }
            diff = 0.0;
          }
        }
      }
      if (diff > 0.0 && _availableExcessiveBalanceToApply != null) {
        _availableExcessiveBalanceToApply =
            _availableExcessiveBalanceToApply! + diff;
        if (_availableExcessiveBalanceToApply! >
            _initialExcessiveBalanceToApply!) {
          _availableExcessiveBalanceToApply = _initialExcessiveBalanceToApply!;
        }
        diff = 0.0;
      }
      if (diff > 0.0 &&
          _availablePaymentAmountToApply != null &&
          _availablePaymentAmountToApply! > _initialPaymentAmountToApply!) {
        _availablePaymentAmountToApply = _initialPaymentAmountToApply!;
      }
      if (diff > 0.0 &&
          _availableExcessiveBalanceToApply != null &&
          _availableExcessiveBalanceToApply! >
              _initialExcessiveBalanceToApply!) {
        _availableExcessiveBalanceToApply = _initialExcessiveBalanceToApply!;
      }
    }

    _populateApply2();
  }

  @override
  void initState() {
    super.initState();
    _lcStatusDisplay =
        PagPaymentLcStatus.byValue(widget.defaultPaymentLcStatusStr);
  }

  @override
  Widget build(BuildContext context) {
    bool fetchingBillList = _billList.isEmpty && !_billListFetchTried;

    final tenantLabel = widget.tenantInfo['tenant_label'] ?? '';

    bool showPaymentLcStatusOp = false;
    final lcStatusStr = widget.paymentMatchingInfo?['lc_status'] ?? '';
    PagPaymentLcStatus lcStatus = PagPaymentLcStatus.byValue(lcStatusStr);

    bool hasMatchedBill = false;
    for (var bill in _billList) {
      if (widget.paymentMatchingInfo != null &&
          widget.paymentMatchingInfo!['matched_payment_info'] != null &&
          widget.paymentMatchingInfo!['matched_payment_info']
                  ['billing_rec_id'] ==
              bill['id']) {
        hasMatchedBill = true;
        break;
      }
    }
    if (hasMatchedBill) {
      showPaymentLcStatusOp = true;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(PagItemKind.tenant.iconData),
                          Text(' $tenantLabel', style: billLabelStyle),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Symbols.chevron_forward,
                              color: Theme.of(context).hintColor),
                          Text('Payment: ', style: mainLabelStyle),
                          Text(
                              _paymentAmount != null
                                  ? _paymentAmount.toStringAsFixed(2)
                                  : '-',
                              style: mainTextStyle),
                        ],
                      ),
                    ],
                  ),
                  horizontalSpaceSmall,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          getTag('Bal', 'From Balance',
                              color: balColor, width: 39),
                          horizontalSpaceTiny,
                          Icon(Icons.chevron_right,
                              color: Theme.of(context).hintColor),
                          horizontalSpaceTiny,
                          getTag('ini', 'Initial Value', color: balColor),
                          Text(
                              ' ${_initialExcessiveBalanceToApply?.toStringAsFixed(2) ?? '0.00'}  ',
                              style: billValStyle),
                          getTag('applied', 'Applied Value', color: balColor),
                          Text(
                              ' ${_initialExcessiveBalanceToApply != null && _initialExcessiveBalanceToApply! > 0.0 ? (_initialExcessiveBalanceToApply! - (_availableExcessiveBalanceToApply ?? 0.0)).toStringAsFixed(2) : '0.0'}  ',
                              style: billValStyle),
                          getTag('avail', 'Available Value', color: balColor),
                          Text(
                              ' ${_availableExcessiveBalanceToApply?.toStringAsFixed(2) ?? '0.00'} ',
                              style: billValStyle),
                        ],
                      ),
                      Row(
                        children: [
                          getTag('Pmt', 'From Payment',
                              color: paymentColor, width: 39),
                          horizontalSpaceTiny,
                          Icon(Icons.chevron_right,
                              color: Theme.of(context).hintColor),
                          horizontalSpaceTiny,
                          getTag('ini', 'Initial Value', color: paymentColor),
                          Text(
                              ' ${_initialPaymentAmountToApply?.toStringAsFixed(2) ?? '0.00'}  ',
                              style: billValStyle),
                          getTag('applied', 'Applied Value',
                              color: paymentColor),
                          Text(
                              ' ${_initialPaymentAmountToApply != null && _initialPaymentAmountToApply! > 0.0 ? (_initialPaymentAmountToApply! - (_availablePaymentAmountToApply ?? 0.0)).toStringAsFixed(2) : '0.0'}  ',
                              style: billValStyle),
                          getTag('avail', 'Available Value',
                              color: paymentColor),
                          Text(
                              ' ${_availablePaymentAmountToApply?.toStringAsFixed(2) ?? '0.00'} ',
                              style: billValStyle),
                        ],
                      ),
                    ],
                  ),
                  horizontalSpaceSmall,
                  getPopulateApply(),
                  getCommitApply(),
                  const Spacer(),
                  if (hasMatchedBill)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: WgtPagPaymentLcStatusOp(
                        key: _lcStatusOpsKey,
                        appConfig: widget.appConfig,
                        loggedInUser: widget.loggedInUser,
                        enableEdit: false,
                        // enableEdit: true,
                        paymentInfo: widget.paymentMatchingInfo ?? {},
                        initialStatus: _lcStatusDisplay,
                        onCommitted: (newStatus) {
                          setState(() {
                            _lcStatusOpsKey = UniqueKey();
                            // _bill['lc_status'] = newStatus.value;
                            _paymentInfo['lc_status'] = newStatus.value;

                            // _isDisabledGn = newStatus == PagBillingLcStatus.pv ||
                            //     newStatus == PagBillingLcStatus.released;
                            _lcStatusDisplay = newStatus;
                          });
                          dev.log('on committed: $newStatus');
                          widget.onUpdate?.call();
                        },
                      ),
                    ),
                  const Padding(padding: EdgeInsets.only(right: 60)),
                ]),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Symbols.close))
              ],
            ),
          ],
        ),
        fetchingBillList
            ? FutureBuilder(
                // future: _fetchBillList(),
                future: _fetchPaymentMatchOpInfo(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return const WgtPagWait();
                    default:
                      if (snapshot.hasError) {
                        return getErrorTextPrompt(
                          context: context,
                          errorText: 'Error fetching data',
                        );
                      } else {
                        return completedWidget();
                      }
                  }
                },
              )
            : completedWidget(),
      ],
    );
  }

  Widget completedWidget() {
    return SizedBox(
      height: 500,
      child: ListView.builder(
        itemCount: _billList.length,
        itemBuilder: (context, index) {
          return getListItem(index);
        },
      ),
    );
  }

  Widget getListItem(int index) {
    if (index < 0 || index >= _billList.length) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: getBillItem(index),
    );
  }

  Widget getApplyOp(
      bool isMatchedBill,
      int index,
      double? availableAmountToApply,
      double? appliedAmountUsage,
      double? appliedAmountInterest,
      String? appliedByOpUsername,
      String? appliedTimestampStr) {
    bool isEnabled = true;
    if (!isMatchedBill) {
      if (availableAmountToApply == null || availableAmountToApply <= 0.0) {
        isEnabled = false;
      }
    }

    if (_lcStatusDisplay == PagPaymentLcStatus.released) {
      isEnabled = false;
    }

    final initialValueUsage =
        isMatchedBill ? appliedAmountUsage?.toString() : null;
    final initialValueInterest =
        isMatchedBill ? appliedAmountInterest?.toString() : null;
    final valWidth = 105.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: isEnabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).disabledColor.withAlpha(130)),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              getTag('Bal', 'From Balance', color: balColor, width: 39),
              horizontalSpaceRegular, // usage bucket
              SizedBox(
                width: valWidth,
                child: WgtTextField(
                  key: UniqueKey(),
                  appConfig: widget.appConfig,
                  loggedInUser: widget.loggedInUser,
                  hintText: 'Usage',
                  labelText: 'Usage',
                  enabled: isEnabled,
                  initialValue: initialValueUsage,
                  onChanged: (value) {
                    // setState(() {
                    //   _paymentApply = value;
                    // });
                  },
                  onClear: () {
                    _updateApplyInfo2(index, 'applied_usage_amount', '');
                  },
                ),
              ),
              horizontalSpaceSmall, // interest bucket
              SizedBox(
                width: valWidth,
                child: WgtTextField(
                  key: UniqueKey(),
                  appConfig: widget.appConfig,
                  loggedInUser: widget.loggedInUser,
                  hintText: 'Interest',
                  labelText: 'Interest',
                  enabled: isEnabled,
                  initialValue: initialValueInterest,
                  onChanged: (value) {
                    // setState(() {
                    //   _paymentApply = value;
                    // });
                  },
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              getTag('Pmt', 'From Payment', color: paymentColor, width: 39),
              horizontalSpaceRegular, // usage bucket
              SizedBox(
                width: valWidth,
                child: WgtTextField(
                  key: UniqueKey(),
                  appConfig: widget.appConfig,
                  loggedInUser: widget.loggedInUser,
                  hintText: 'Usage',
                  labelText: 'Usage',
                  enabled: isEnabled,
                  initialValue: initialValueUsage,
                  onChanged: (value) {
                    // setState(() {
                    //   _paymentApply = value;
                    // });
                  },
                  onClear: () {
                    _updateApplyInfo2(index, 'applied_usage_amount', '');
                  },
                ),
              ),
              horizontalSpaceSmall, // interest bucket
              SizedBox(
                width: valWidth,
                child: WgtTextField(
                  key: UniqueKey(),
                  appConfig: widget.appConfig,
                  loggedInUser: widget.loggedInUser,
                  hintText: 'Interest',
                  labelText: 'Interest',
                  enabled: isEnabled,
                  initialValue: initialValueInterest,
                  onChanged: (value) {
                    // setState(() {
                    //   _paymentApply = value;
                    // });
                  },
                ),
              ),
            ],
          ),
          if (appliedTimestampStr != null && appliedByOpUsername != null) ...[
            const SizedBox(height: 5),
            Text('Applied by $appliedByOpUsername at $appliedTimestampStr',
                style: billKeyStyle.copyWith(fontSize: 12)),
          ]
        ],
      ),
    );
  }

  Widget getBillItem(int index) {
    Map<String, dynamic> billInfo = _billList[index];
    final billingRecId = billInfo['id'] ?? '';
    final billLabel = billInfo['label'] ?? '';
    final cycleStr = billInfo['cycle_str'] ?? '';
    final billedTotalCost = billInfo['billed_total_cost'] ?? '';
    final billingLcStatusStr = billInfo['lc_status'] ?? '';
    final usageAmount =
        double.tryParse(billInfo['billed_total_cost'] ?? '0.0') ?? 0.0;
    final interestAmount =
        double.tryParse(billInfo['billed_interest_amount'] ?? '0.0') ?? 0.0;
    final totalAmount = usageAmount + interestAmount;

    PagBillingLcStatus billLcStatus =
        PagBillingLcStatus.values.byName(billingLcStatusStr);

    bool isMatchedBill = false;
    if (widget.paymentMatchingInfo != null) {
      isMatchedBill = widget.paymentMatchingInfo!['matched_payment_info']
              ?['billing_rec_id'] ==
          billingRecId;
    }

    double? availableAmountToApply;
    double? appliedAmountUsage;
    double? appliedAmountInterest;
    String? appliedByOpUsername;
    String? appliedTimestampStr;

    final applyInfoList = [];
    applyInfoList.addAll(_paymentApplyInfoListNew);
    if (applyInfoList.isEmpty) {
      applyInfoList.addAll(_paymentApplyInfoListExisting);
    }

    double balanceAmount = totalAmount;
    for (var item in applyInfoList) {
      if (item['billing_rec_id'] == billingRecId) {
        appliedAmountUsage = item['applied_usage_amount'] ?? 0.0;
        appliedAmountInterest = item['applied_interest_amount'] ?? 0.0;
        appliedByOpUsername = item['applied_by_op_username'];
        appliedTimestampStr = item['applied_timestamp'];
        isMatchedBill = true;
        balanceAmount = balanceAmount -
            (appliedAmountUsage ?? 0.0 + (appliedAmountInterest ?? 0.0));
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: isMatchedBill
            ? Border.all(color: commitColor.withAlpha(130), width: 2)
            : Border.all(color: Theme.of(context).hintColor.withAlpha(130)),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 13),
      child: Column(
        children: [
          Row(
            children: [
              getBillLcStatusTagWidget(context, billLcStatus),
              horizontalSpaceSmall,
              InkWell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$billLabel', style: billLabelStyle),
                    Text('$cycleStr', style: billLabelStyle),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _billList[index]['show_bill'] =
                        !(_billList[index]['show_bill'] ?? false);
                  });
                },
              ),
              horizontalSpaceSmall,
              IntrinsicHeight(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Total: ',
                              style: billKeyStyle,
                            ),
                            Text('$billedTotalCost',
                                style: billValStyle.copyWith(fontSize: 25)),
                          ],
                        ),
                        verticalSpaceTiny,
                        Row(
                          children: [
                            Text('Usage: ', style: billKeyStyle),
                            Text(
                              usageAmount.toStringAsFixed(2),
                              style: billValStyle,
                            ),
                            horizontalSpaceSmall,
                            Text('Interest: ', style: billKeyStyle),
                            Text(
                              interestAmount.toStringAsFixed(2),
                              style: billValStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
                    VerticalDivider(
                      color: Theme.of(context).hintColor,
                      width: 20,
                    ),
                    Text('Balance: ', style: billKeyStyle),
                    Text(
                      balanceAmount.toStringAsFixed(2),
                      style: billValStyle,
                    ),
                    horizontalSpaceSmall,
                  ],
                ),
              ),
              const Spacer(),
              // _isApplied ? getAppliedPayment() : getApplyOp(),
              getApplyOp(
                  isMatchedBill,
                  index,
                  availableAmountToApply,
                  appliedAmountUsage,
                  appliedAmountInterest,
                  appliedByOpUsername,
                  appliedTimestampStr),
              horizontalSpaceSmall,
            ],
          ),
          if (billInfo['show_bill'] ?? false) const Divider(),
          if (billInfo['show_bill'] ?? false)
            WgtPagCompositeBillView(
              costDecimals: 2,
              appConfig: widget.appConfig,
              loggedInUser: widget.loggedInUser,
              displayContextStr: 'match_one_paymment',
              billingRecIndexStr: billingRecId,
              defaultBillLcStatusStr: billingLcStatusStr,
              modes: const ['wgt', 'pdf'],
              genTypes: billLcStatus == PagBillingLcStatus.generated
                  ? ['generated']
                  : ['released'],
            ),
        ],
      ),
    );
  }

  Widget getPopulateApply() {
    if (_lcStatusDisplay == PagPaymentLcStatus.released) {
      return const SizedBox.shrink();
    }
    if (_availablePaymentAmountToApply == null ||
        _availablePaymentAmountToApply! <= 0.0) {
      return const SizedBox.shrink();
    }

    if (_billList.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_paymentApplyInfoListNew.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        _populateApply2();
      },
      child: Container(
        decoration: BoxDecoration(
          // border: Border.all(color: Theme.of(context).colorScheme.primary),
          color: Theme.of(context).colorScheme.secondary.withAlpha(210),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        child: Text('Populate Apply',
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
      ),
    );
  }

  Widget getCommitApply() {
    if (_paymentApplyInfoListNew.isEmpty) {
      return Container();
    }

    // bool isPaymentReleased = widget.paymentMatchingInfo != null &&
    //     widget.paymentMatchingInfo!['lc_status'] == 'released';

    bool okToCommit = true;

    // payment must be in released status
    String hintMsg = '';
    if (widget.paymentMatchingInfo == null ||
        widget.paymentMatchingInfo!['lc_status'] != 'released') {
      okToCommit = false;
      hintMsg = 'Payment must be in released status to commit';
    }

    return Padding(
      padding: const EdgeInsets.only(left: 21),
      child: Row(
        children: [
          Tooltip(
            message: okToCommit ? 'Commit apply info' : hintMsg,
            waitDuration: const Duration(milliseconds: 500),
            child: IconButton(
              onPressed: okToCommit
                  ? () {
                      // commit the apply info
                    }
                  : null,
              icon: Icon(Icons.cloud_upload,
                  color: okToCommit ? commitColor : null),
            ),
          ),
          // if (!okToCommit)
          //   Padding(
          //     padding: const EdgeInsets.only(left: 8),
          //     child: getInfoTextPrompt(
          //         context: context, infoText: 'Release payment to commit'),
          //   ),
        ],
      ),
    );
  }

  Widget getTag(String text, String tooltip, {Color? color, double? width}) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: color ?? Colors.green.shade600.withAlpha(210),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
        child: Center(
          child: Text(text,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontSize: 13.5)),
        ),
      ),
    );
  }
}
