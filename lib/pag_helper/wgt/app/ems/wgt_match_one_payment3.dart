import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_bill.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:developer' as dev;

import '../../../../pagrid_helper/ems_helper/billing_helper/wgt_pag_composite_bill_view.dart';
import '../../../../xt_ui/wdgt/wgt_pag_wait.dart';
import '../../../comm/comm_fin_ops.dart';
import '../../../def_helper/dh_pag_finance.dart';
import 'wgt_payment_lc_status_op.dart';

class WgtMatchOnePayment3 extends StatefulWidget {
  const WgtMatchOnePayment3({
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
  State<WgtMatchOnePayment3> createState() => _WgtMatchOnePayment3State();
}

class _WgtMatchOnePayment3State extends State<WgtMatchOnePayment3> {
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

  final String defaultErrorText = 'Error committing payment apply';

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

  double? _initialPaymentAmountToApply;
  double? _availablePaymentAmountToApply;

  final Color balColor = Colors.green.shade900.withAlpha(210);
  final Color paymentColor = Colors.green.shade600.withAlpha(210);

  bool _isPopulated = false;

  bool _inManualOverride = false;

  bool _isCommitting = false;
  bool _isCommitted = false;
  String _commitErrorText = '';

  bool _showExistingApplies = false;

  final Map<String, dynamic> _initialBalancePaymentInfo = {};

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
      final paymentInfo = result['payment_info'];
      if (paymentInfo == null) {
        throw Exception("No payment info found in the response");
      }

      final billList = result['bill_list'] ?? [];
      final paymentApplyInfoList = result['payment_apply_info_list'] ?? [];
      _initialBalancePaymentInfo.clear();
      _initialBalancePaymentInfo
          .addAll(result['initial_balance_payment_info'] ?? {});

      _billList.clear();
      for (var item in billList) {
        Map<String, dynamic> billItem = item;
        _billList.add(billItem);
      }

      _initialPaymentAmountToApply = _paymentAmount;
      _availablePaymentAmountToApply = _paymentAmount;

      for (var paymentApplyInfo in paymentApplyInfoList) {
        _paymentApplyInfoListExisting.add(paymentApplyInfo);

        final appliedAmountUsageFromPayment = double.tryParse(
                paymentApplyInfo['usage_amount_from_payment'] ?? '0.0') ??
            0.0;
        final appliedAmountInterestFromPayment = double.tryParse(
                paymentApplyInfo['interest_amount_from_payment'] ?? '0.0') ??
            0.0;
        double totalAppliedFromPayment =
            appliedAmountUsageFromPayment + appliedAmountInterestFromPayment;

        _availablePaymentAmountToApply =
            _availablePaymentAmountToApply! - totalAppliedFromPayment;
      }
    } catch (e) {
      dev.log('Error fetching match op info: $e');
      _errorText = 'Failed to fetch match op info';
      if (e.toString().toLowerCase().contains('soa not initialized')) {
        _errorText = 'SoA not initialized for this tenant';
      }
    } finally {
      setState(() {
        _isFetchingBillList = false;
        _billListFetchTried = true;
      });
    }
  }

  Future<dynamic> _commitApply() async {
    final totalAppliedFromPayment = (_initialPaymentAmountToApply != null &&
            _availablePaymentAmountToApply != null)
        ? (_initialPaymentAmountToApply! - _availablePaymentAmountToApply!)
        : 0.0;

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'tenant_id': widget.tenantInfo['tenant_id'] ?? '',
      'payment_id': _paymentInfo['id'] ?? '',
      'apply_list': _paymentApplyInfoListNew,
    };

    _isCommitting = true;
    _isCommitted = false;
    _commitErrorText = '';
    _isPopulated = false;

    try {
      final result = await commitPaymentApply(
          widget.appConfig,
          queryMap,
          MdlPagSvcClaim(
            userId: widget.loggedInUser.id,
            username: widget.loggedInUser.username,
            scope: '',
            target: '',
            operation: '',
          ));
      dev.log('Commit payment match apply result: $result');
      // refresh the payment info
      widget.onUpdate?.call();
    } catch (e) {
      dev.log('Error committing payment match apply: $e');
      _commitErrorText = getErrorText(e, defaultErrorText: defaultErrorText);

      // rethrow;
    } finally {
      if (mounted) {
        _isCommitting = false;
        _isCommitted = true;
        setState(() {});
        if (_commitErrorText.isNotEmpty) {
          showInfoDialog(context, 'Error', _commitErrorText);
        }
      }
    }
  }

  // rule 1: payment flows to fill neg initial payment first
  // rule 2: payment flows the bill with exact amount first
  // rule 3: payment flows to the oldest bill first
  // rule 4: payment flows to usage bucket first, for all bills from oldest to newest
  // rule 5: payment flows to interest bucket, for all bills from oldest to newest
  void _populateApply2() {
    if (_billList.isEmpty) {
      return;
    }

    double outBucketThisPayment = _initialPaymentAmountToApply!;
    if (_availablePaymentAmountToApply != null) {
      outBucketThisPayment = _availablePaymentAmountToApply!;
    }
    // convert to 2 decimal places
    outBucketThisPayment =
        double.parse(outBucketThisPayment.toStringAsFixed(2));

    final billList = [];
    billList.addAll(_billList);

    // rule 1: payment flows to fill neg initial payment first
    // if (_initialBalancePaymentInfo.isNotEmpty) {
    //   final initialBalPaymentAmount =
    //       double.tryParse(_initialBalancePaymentInfo['amount'] ?? '0.0') ?? 0.0;
    //   if (initialBalPaymentAmount < 0.0) {
    //     final amountToFill = -initialBalPaymentAmount;
    //     if (outBucketThisPayment > amountToFill - 0.00001) {
    //       // fill full
    //       _paymentApplyInfoListNew.add({
    //         'billing_rec_id': 'neg_initial_balance_payment',
    //         // _initialBalancePaymentInfo['billing_rec_id'] ?? '',
    //         'usage_amount_from_payment': amountToFill,
    //         'interest_amount_from_payment': 0.0,
    //         'is_exact_match': true,
    //       });
    //       outBucketThisPayment -= amountToFill;
    //     } else {
    //       // partial fill
    //       _paymentApplyInfoListNew.add({
    //         'billing_rec_id':
    //             _initialBalancePaymentInfo['billing_rec_id'] ?? '',
    //         'usage_amount_from_payment': outBucketThisPayment,
    //         'interest_amount_from_payment': 0.0,
    //         'is_exact_match': false,
    //       });
    //       outBucketThisPayment = 0.0;
    //     }
    //   }
    // }

    // rule 2: payment flows from outBucketThisPayment to the bill with exact amount first
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
          double.tryParse(bill['billed_total_amount'] ?? '0.0') ?? 0.0;
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
              item['interest_amount_from_payment'] = billedInterestAmount;
            }
            if (item['is_custom_apply_usage'] != true) {
              item['usage_amount_from_payment'] = billedUsageAmount;
            }
            found = true;
            break;
          }
        }
        if (!found) {
          _paymentApplyInfoListNew.add({
            'billing_rec_id': billingRecId,
            'billing_rec_gen_type': bill['gen_type'] ?? '',
            'interest_amount_from_payment': billedInterestAmount,
            'usage_amount_from_payment': billedUsageAmount,
            'is_exact_match': true,
          });
          bill['is_fully_paid_by_current_payment'] = true;

          outBucketThisPayment -= billedTotalCost;
        }
      }
    }

    //for rule 3: sort bills by from_timestamp ascending so that oldest bills are processed first
    billList.sort((a, b) {
      final aTimestamp = a['from_timestamp'] ?? '';
      final bTimestamp = b['from_timestamp'] ?? '';
      return aTimestamp.compareTo(bTimestamp);
    });

    // // rule 4: flow to usage bucket first
    // for (var bill in billList) {
    //   // skip if bill is not released
    //   if (bill['lc_status'] != 'released') {
    //     continue;
    //   }
    //   // skip if bill is already fully paid
    //   if (bill['is_fully_paid_by_current_payment'] == true) {
    //     continue;
    //   }

    //   final billingRecId = bill['id'] ?? '';
    //   final billedTotalCost =
    //       double.tryParse(bill['billed_total_amount'] ?? '0.0') ?? 0.0;
    //   if (billedTotalCost < 0.00001) {
    //     continue;
    //   }
    //   final billedInterestAmount =
    //       double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
    //   final billedUsageCostWithGstAmount =
    //       billedTotalCost - billedInterestAmount;

    //   if (billedUsageCostWithGstAmount > 0.00001) {
    //     double appliedUsage = 0.0;

    //     if (appliedUsage > 0.0) {
    //       bool found = false;
    //       for (var item in _paymentApplyInfoListNew) {
    //         if (item['billing_rec_id'] == billingRecId) {
    //           if (item['is_custom_apply_usage'] != true) {
    //             item['usage_amount_from_bal'] = appliedUsage;
    //           }
    //           found = true;
    //           break;
    //         }
    //       }
    //       if (!found) {
    //         _paymentApplyInfoListNew.add({
    //           'billing_rec_id': billingRecId,
    //           'usage_amount_from_bal': appliedUsage,
    //         });
    //       }
    //       _checkFullyPaid();
    //     }
    //   }
    // }

    // // rule 5: flow to interest bucket next
    // for (var bill in billList) {
    //   // skip if bill is not released
    //   if (bill['lc_status'] != 'released') {
    //     continue;
    //   }
    //   // skip if bill is already fully paid
    //   if (bill['is_fully_paid_by_current_payment'] == true) {
    //     continue;
    //   }

    //   //flow to interest bucket next
    //   final billingRecId = bill['id'] ?? '';
    //   final billedTotalCost =
    //       double.tryParse(bill['billed_total_amount'] ?? '0.0') ?? 0.0;
    //   if (billedTotalCost <= 0.0) {
    //     continue;
    //   }
    //   final billedInterestAmount =
    //       double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
    //   if (billedInterestAmount > 0.0) {
    //     double appliedInterest = 0.0;

    //     if (appliedInterest > 0.0) {
    //       bool found = false;
    //       for (var item in _paymentApplyInfoListNew) {
    //         if (item['billing_rec_id'] == billingRecId) {
    //           if (item['is_custom_apply_interest'] != true) {
    //             item['interest_amount_from_bal'] = appliedInterest;
    //           }
    //           found = true;
    //           break;
    //         }
    //       }
    //       if (!found) {
    //         _paymentApplyInfoListNew.add({
    //           'billing_rec_id': billingRecId,
    //           'interest_amount_from_bal': appliedInterest,
    //         });
    //       }
    //       _checkFullyPaid();
    //     }
    //   }
    // }

    // rule 4: flow out from outBucketThisPayment next
    // rule 4.1: flow to usage bucket first
    for (var billInfo in billList) {
      if (outBucketThisPayment <= 0.0) {
        break;
      }

      // skip if bill is not released
      if (billInfo['lc_status'] != 'released') {
        continue;
      }
      // skip if bill is already fully paid
      if (billInfo['is_fully_paid_by_current_payment'] == true) {
        continue;
      }

      //flow to usage bucket first
      final billingRecId = billInfo['id'] ?? '';
      final billedTotalAmount =
          double.tryParse(billInfo['billed_total_amount'] ?? '0.0') ?? 0.0;
      if (billedTotalAmount <= 0.0) {
        continue;
      }
      final billedInterestAmount =
          double.tryParse(billInfo['billed_interest_amount'] ?? '0.0') ?? 0.0;
      final billedUsageWithGstAmt = billedTotalAmount - billedInterestAmount;
      if (billedUsageWithGstAmt > 0.0) {
        double appliedUsage = _paymentApplyInfoListNew.firstWhere(
              (element) => element['billing_rec_id'] == billingRecId,
              orElse: () => {'usage_amount_from_payment': 0.0},
            )['usage_amount_from_payment'] ??
            0.0;
        double remainingUsageToBePaid = _getBillBalanceToBePaid(billInfo);
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
                item['usage_amount_from_payment'] = appliedUsage;
              }
              found = true;
              break;
            }
          }
          if (!found) {
            _paymentApplyInfoListNew.add({
              'billing_rec_id': billingRecId,
              'billing_rec_gen_type': billInfo['gen_type'] ?? '',
              'usage_amount_from_payment': appliedUsage,
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

      // flow to interest bucket next
      final billingRecId = bill['id'] ?? '';
      final billedTotalAmount =
          double.tryParse(bill['billed_total_amount'] ?? '0.0') ?? 0.0;
      if (billedTotalAmount <= 0.0) {
        continue;
      }
      final billedInterestAmount =
          double.tryParse(bill['billed_interest_amount'] ?? '0.0') ?? 0.0;
      if (billedInterestAmount > 0.0) {
        double appliedInterest = _paymentApplyInfoListNew.firstWhere(
              (element) => element['billing_rec_id'] == billingRecId,
              orElse: () => {'interest_amount_from_payment': 0.0},
            )['interest_amount_from_payment'] ??
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
                item['interest_amount_from_payment'] = appliedInterest;
              }
              found = true;
              break;
            }
          }
          if (!found) {
            _paymentApplyInfoListNew.add({
              'billing_rec_id': billingRecId,
              'billing_rec_gen_type': bill['gen_type'] ?? '',
              'interest_amount_from_payment': appliedInterest,
            });
          }
          _checkFullyPaid();
        }
      }
    }

    // finally, add 0 if not exist
    for (var apply in _paymentApplyInfoListNew) {
      if (!apply.containsKey('usage_amount_from_payment')) {
        apply['usage_amount_from_payment'] = 0.0;
      }
      if (!apply.containsKey('interest_amount_from_payment')) {
        apply['interest_amount_from_payment'] = 0.0;
      }
    }

    setState(() {
      _availablePaymentAmountToApply = outBucketThisPayment;
      _isPopulated = true;
    });
  }

  void _checkFullyPaid() {
    for (var bill in _billList) {
      final billingRecId = bill['id'] ?? '';
      final billedTotalCost =
          double.tryParse(bill['billed_total_amount'] ?? '0.0') ?? 0.0;
      if (billedTotalCost <= 0.0) {
        continue;
      }
      double totalApplied = 0.0;
      for (var item in _paymentApplyInfoListNew) {
        if (item['billing_rec_id'] == billingRecId) {
          final appliedAmountUsage = item['usage_amount_from_payment'] ?? 0.0;
          final appliedAmountInterest =
              item['interest_amount_from_payment'] ?? 0.0;
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

  void _updateCustomApply(int index, String fieldKey, String value) {
    if (index < 0 || index >= _billList.length) {
      return;
    }
    final billInfo = _billList[index];
    final billingRecId = billInfo['id'] ?? '';
    final inBucket = fieldKey.contains('usage_amount') ? 'usage' : 'interest';
    final outBucket = fieldKey.contains('from_bal') ? 'bal' : 'payment';
    bool found = false;
    double diff = 0.0;

    for (var item in _paymentApplyInfoListNew) {
      if (item['billing_rec_id'] == billingRecId) {
        final oldValue =
            double.tryParse(item[fieldKey]?.toString() ?? '0.0') ?? 0.0;
        final newValue = double.tryParse(value) ?? 0.0;
        item[fieldKey] = newValue;
        item['is_custom_apply_$inBucket'] = true;
        diff = newValue - oldValue;
        found = true;
        break;
      }
    }

    if (!found) {
      final newValue = double.tryParse(value) ?? 0.0;
      diff = newValue;
      _paymentApplyInfoListNew.add({
        'billing_rec_id': billingRecId,
        'billing_rec_gen_type': billInfo['gen_type'] ?? '',
        fieldKey: newValue,
        'is_custom_apply_$inBucket': true,
      });
    }

    if (inBucket == 'usage') {
      _availablePaymentAmountToApply =
          (_availablePaymentAmountToApply ?? 0.0) - diff;
    } else {
      _availablePaymentAmountToApply =
          (_availablePaymentAmountToApply ?? 0.0) - diff;
    }
    _checkFullyPaid();
  }

  double _getBillBalanceToBePaid(Map<String, dynamic> billInfo) {
    final billedTotalAmount =
        double.tryParse(billInfo['billed_total_amount'] ?? '0.0') ?? 0.0;

    double appliedUsageTotal = 0.0;
    double appliedInterestTotal = 0.0;
    final existingPaymentApplyInfoList =
        billInfo['existing_payment_apply_info_list'] ?? [];
    for (var applyInfo in existingPaymentApplyInfoList) {
      final appliedUsage = applyInfo['usage_amount_from_payment'] is String
          ? double.tryParse(applyInfo['usage_amount_from_payment'] ?? '0.0') ??
              0.0
          : applyInfo['usage_amount_from_payment'] ?? 0.0;
      final appliedInterest =
          applyInfo['interest_amount_from_payment'] is String
              ? double.tryParse(
                      applyInfo['interest_amount_from_payment'] ?? '0.0') ??
                  0.0
              : applyInfo['interest_amount_from_payment'] ?? 0.0;
      appliedUsageTotal += appliedUsage;
      appliedInterestTotal += appliedInterest;
    }
    double remainingBalanceToBePaid =
        billedTotalAmount - (appliedUsageTotal + appliedInterestTotal);

    return remainingBalanceToBePaid;
  }

  @override
  void initState() {
    super.initState();
    _lcStatusDisplay =
        PagPaymentLcStatus.byValue(widget.defaultPaymentLcStatusStr);
  }

  @override
  Widget build(BuildContext context) {
    bool fetchingMatchingOpInfo = _billList.isEmpty && !_billListFetchTried;

    final tenantLabel = widget.tenantInfo['tenant_label'] ?? '';

    bool showPaymentLcStatusOp = true;
    final lcStatusStr = widget.paymentMatchingInfo?['lc_status'] ?? '';
    PagPaymentLcStatus lcStatus = PagPaymentLcStatus.byValue(lcStatusStr);

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              widget.paymentMatchingInfo?['value_timestamp'] ??
                                  '',
                              style: billKeyStyle),
                        ],
                      ),
                    ],
                  ),
                  horizontalSpaceRegular,
                  getBucketPopulateApply(),
                  const Spacer(),
                  if (showPaymentLcStatusOp)
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
        getPaymentApplyListOfThisPayment(),
        getIniBalPaymentInfo(),
        fetchingMatchingOpInfo
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
      String billingRecId,
      bool isMatchedBill,
      int index,
      double? appliedAmountUsageFromPmt,
      double? appliedAmountInterestFromPmt,
      String? appliedByOpUsername,
      String? appliedTimestampStr) {
    bool isEnabled = false;
    if (_inManualOverride) {
      isEnabled = true;
    }
    // if (!isMatchedBill) {
    // if (availableAmountToApply == null || availableAmountToApply <= 0.0) {
    //   isEnabled = false;
    // }
    // }
    if (_lcStatusDisplay == PagPaymentLcStatus.matched) {
      isEnabled = false;
    }

    final initialValueUsageFromPmt =
        isMatchedBill ? appliedAmountUsageFromPmt?.toString() : null;
    final initialValueInterestFromPmt =
        isMatchedBill ? appliedAmountInterestFromPmt?.toString() : null;
    final valWidth = 105.0;

    Color? valueColor;
    if (_inManualOverride) {
      valueColor = commitColor;
      if (_isCommitted && _commitErrorText.isEmpty) {
        valueColor = Theme.of(context).colorScheme.primary;
      }
    } else {
      if (_isPopulated) {
        valueColor = commitColor;
      }
    }

    for (var item in _paymentApplyInfoListNew) {
      if (item['billing_rec_id'] == billingRecId) {
        // populate initial values from the new apply list
        item['usage_amount_from_payment'] ??= initialValueUsageFromPmt;
        item['interest_amount_from_payment'] ??= initialValueInterestFromPmt;
        break;
      }
    }

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
                  initialValue: initialValueUsageFromPmt,
                  textStyle: TextStyle(color: valueColor),
                  onChanged: (value) {
                    _updateCustomApply(
                        index, 'usage_amount_from_payment', value);
                  },
                  onEditingComplete: () {
                    setState(() {});
                  },
                  onClear: () {
                    _updateCustomApply(index, 'usage_amount_from_payment', '');
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
                  initialValue: initialValueInterestFromPmt,
                  textStyle: TextStyle(color: valueColor),
                  onChanged: (value) {
                    _updateCustomApply(
                        index, 'interest_amount_from_payment', value);
                  },
                  onEditingComplete: () {
                    setState(() {});
                  },
                  onClear: () {
                    _updateCustomApply(
                        index, 'interest_amount_from_payment', '');
                  },
                ),
              ),
            ],
          ),
          verticalSpaceTiny,
          if (appliedTimestampStr != null && appliedByOpUsername != null) ...[
            const SizedBox(height: 5),
            Text('Applied by $appliedByOpUsername at $appliedTimestampStr',
                style: TextStyle(
                    fontSize: 13.5, color: Theme.of(context).hintColor)),
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
    final billedTotalCost = billInfo['billed_total_amount'] ?? '';
    final billingLcStatusStr = billInfo['lc_status'] ?? '';
    final billedTotalCostAmount =
        double.tryParse(billInfo['billed_total_amount'] ?? '0.0') ?? 0.0;
    final usageAmount =
        double.tryParse(billInfo['billed_usage_cost_amount'] ?? '0.0') ?? 0.0;
    final interestAmount =
        double.tryParse(billInfo['billed_interest_amount'] ?? '0.0') ?? 0.0;
    final billedUsageAmountWithGst = billedTotalCostAmount - interestAmount;
    // final totalAmount = usageAmount + interestAmount;

    final existingPaymentApplyInfoList =
        billInfo['existing_payment_apply_info_list'] ?? [];
    // double appliedUsageTotal = 0.0;
    // double appliedInterestTotal = 0.0;
    // for (var applyInfo in existingPaymentApplyInfoList) {
    //   final appliedUsage = applyInfo['usage_amount_from_payment'] is String
    //       ? double.tryParse(applyInfo['usage_amount_from_payment'] ?? '0.0') ??
    //           0.0
    //       : applyInfo['usage_amount_from_payment'] ?? 0.0;
    //   final appliedInterest =
    //       applyInfo['interest_amount_from_payment'] is String
    //           ? double.tryParse(
    //                   applyInfo['interest_amount_from_payment'] ?? '0.0') ??
    //               0.0
    //           : applyInfo['interest_amount_from_payment'] ?? 0.0;
    //   appliedUsageTotal += appliedUsage;
    //   appliedInterestTotal += appliedInterest;
    // }

    PagBillingLcStatus billLcStatus =
        PagBillingLcStatus.values.byName(billingLcStatusStr);

    bool isMatchedBill = false;
    if (widget.paymentMatchingInfo != null) {
      isMatchedBill = widget.paymentMatchingInfo!['matched_payment_info']
              ?['billing_rec_id'] ==
          billingRecId;
    }

    // double? availableAmountToApply;
    double? appliedAmountUsageFromBal;
    double? appliedAmountInterestFromBal;
    double? appliedAmountUsageFromPmt;
    double? appliedAmountInterestFromPmt;
    String? appliedByOpUsername;
    String? appliedTimestampStr;

    final applyInfoList = [];
    applyInfoList.addAll(_paymentApplyInfoListNew);
    if (applyInfoList.isEmpty) {
      applyInfoList.addAll(_paymentApplyInfoListExisting);
    }

    // double balanceAmount = totalAmount - appliedUsageTotal - appliedInterestTotal;
    double balanceAmount = _getBillBalanceToBePaid(billInfo);

    for (var applyInfo in applyInfoList) {
      if (applyInfo['billing_rec_id'] == billingRecId) {
        appliedAmountUsageFromPmt =
            applyInfo['usage_amount_from_payment'] is String
                ? double.tryParse(
                        applyInfo['usage_amount_from_payment'] ?? '0.0') ??
                    0.0
                : applyInfo['usage_amount_from_payment'] ?? 0.0;
        appliedAmountInterestFromPmt =
            applyInfo['interest_amount_from_payment'] is String
                ? double.tryParse(
                        applyInfo['interest_amount_from_payment'] ?? '0.0') ??
                    0.0
                : applyInfo['interest_amount_from_payment'] ?? 0.0;

        // final appliedAmountUsage = (appliedAmountUsageFromBal ?? 0.0) + (appliedAmountUsageFromPmt ?? 0.0);
        // final appliedAmountInterest = (appliedAmountInterestFromBal ?? 0.0) + (appliedAmountInterestFromPmt ?? 0.0);

        appliedByOpUsername = applyInfo['applied_by_op_username'];
        appliedTimestampStr = applyInfo['applied_timestamp'];
        isMatchedBill = true;
        // balanceAmount = balanceAmount - appliedAmountUsage - appliedAmountInterest;
        break;
      }
    }

    return Column(
      children: [
        Container(
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
                                  // usageAmount.toStringAsFixed(2),
                                  billedUsageAmountWithGst.toStringAsFixed(2),
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
                  getApplyOp(
                      billingRecId,
                      isMatchedBill,
                      index,
                      appliedAmountUsageFromPmt,
                      appliedAmountInterestFromPmt,
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
        ),
        getPaymentApplyListOfThisBill(existingPaymentApplyInfoList, billInfo),
      ],
    );
  }

  Widget getBucketPopulateApply() {
    // if Matched, do not show
    if (_lcStatusDisplay == PagPaymentLcStatus.matched) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            getTag('Pmt', 'From Payment', color: paymentColor, width: 39),
            horizontalSpaceTiny,
            Icon(Icons.chevron_right, color: Theme.of(context).hintColor),
          ],
        ),
        horizontalSpaceTiny,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                getTag('ini', 'Initial Value', color: paymentColor, width: 60),
                Text(
                    ' ${_initialPaymentAmountToApply?.toStringAsFixed(2) ?? '0.00'}  ',
                    style: billValStyle),
              ],
            ),
            Row(
              children: [
                getTag('applied', 'Applied Value',
                    color: paymentColor, width: 60),
                Text(
                    ' ${_initialPaymentAmountToApply != null && _initialPaymentAmountToApply! > 0.0 ? (_initialPaymentAmountToApply! - (_availablePaymentAmountToApply ?? 0.0)).toStringAsFixed(2) : '0.0'}  ',
                    style: billValStyle.copyWith(
                        color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            Row(
              children: [
                getTag('avail', 'Available Value',
                    color: paymentColor, width: 60),
                Text(
                  ' ${_availablePaymentAmountToApply?.toStringAsFixed(2) ?? '0.00'} ',
                  style: (_availablePaymentAmountToApply ?? 0.0) >= 0.0
                      ? billValStyle
                      : billValStyle.copyWith(
                          color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
          ],
        ),
        horizontalSpaceSmall,
        Column(
          children: [
            getAutoManualApplySwitch(),
            verticalSpaceTiny,
            getPopulateApply(),
          ],
        ),
        horizontalSpaceSmall,
        getCommitApply(),
      ],
    );
  }

  Widget getPopulateApply() {
    if (_lcStatusDisplay == PagPaymentLcStatus.matched) {
      return const SizedBox.shrink();
    }
    if (_inManualOverride) {
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
    if ((_availablePaymentAmountToApply == null)) {
      return Container();
    }
    if ((_availablePaymentAmountToApply! < 0.0)) {
      return Container();
    }

    if (_isCommitted) {
      if (_commitErrorText.isEmpty) {
        return getInfoTextPrompt(
            context: context,
            infoText: 'Apply Committed',
            textColor: Theme.of(context).colorScheme.primary,
            bgColor: Theme.of(context).colorScheme.primary.withAlpha(80));
      } else {
        return getErrorTextPrompt(
            context: context, errorText: defaultErrorText);
      }
    }

    bool okToCommit = true;

    // payment must be in released status
    String hintMsg = '';
    if (widget.paymentMatchingInfo == null ||
        widget.paymentMatchingInfo!['lc_status'] != 'released') {
      okToCommit = false;
      hintMsg = 'Payment must be in released status to commit';
    }
    // available amount to apply must be at least 0
    else if (_availablePaymentAmountToApply != null &&
        _availablePaymentAmountToApply! < -0.00001) {
      okToCommit = false;
      hintMsg = 'Available amount to apply must not be negative';
    }

    return Padding(
      padding: const EdgeInsets.only(left: 21),
      child: Row(
        children: [
          _isCommitting
              ? const WgtPagWait()
              : Tooltip(
                  message: okToCommit ? 'Commit apply info' : hintMsg,
                  waitDuration: const Duration(milliseconds: 500),
                  child: IconButton(
                    onPressed: okToCommit
                        ? () {
                            _commitApply();
                          }
                        : null,
                    icon: Icon(Icons.cloud_upload,
                        color: okToCommit ? commitColor : null),
                  ),
                ),
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

  Widget getAutoManualApplySwitch() {
    if (_lcStatusDisplay == PagPaymentLcStatus.matched) {
      return const SizedBox.shrink();
    }
    bool isEnabled = true;
    return Row(
      children: [
        Text('Auto ', style: billKeyStyle),
        Switch(
          value: _inManualOverride,
          onChanged: isEnabled
              ? (value) {
                  setState(() {
                    _inManualOverride = value;
                    if (_inManualOverride) {
                      _isPopulated = false;
                      _paymentApplyInfoListNew.clear();
                      _availablePaymentAmountToApply =
                          _initialPaymentAmountToApply;
                    } else {
                      _isPopulated = false;
                      _paymentApplyInfoListNew.clear();
                      _availablePaymentAmountToApply =
                          _initialPaymentAmountToApply;
                    }
                  });
                }
              : null,
        ),
        Text(' Manual', style: billKeyStyle),
      ],
    );
  }

  Widget getPaymentApplyListOfThisPayment() {
    if (_paymentApplyInfoListExisting.isEmpty) {
      return Container();
    }
    List<Widget> appliesWidgets = [];
    appliesWidgets.add(Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () {
            setState(() {
              _showExistingApplies = !_showExistingApplies;
            });
          },
          child: Text(
            'Payment Applies of This Payment (${_paymentApplyInfoListExisting.length})',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).hintColor),
          ),
        ),
      ),
    ));
    for (Map<String, dynamic> applyInfo in _paymentApplyInfoListExisting) {
      if (!_showExistingApplies) {
        break;
      }
      String tenantLabel = applyInfo['tenant_label'] ?? '-';
      String billLabel = applyInfo['bill_label'] ?? '-';
      String billedTotalCost = applyInfo['billed_total_amount'] ?? '-';
      String appliedTimestamp = applyInfo['applied_timestamp'] ?? '-';
      String appliedByOpName = applyInfo['applied_by_op_username'] ?? '-';

      String appliedUsageAmountFromPmtStr =
          applyInfo['usage_amount_from_payment'] ?? '-';
      String appliedInterestAmountFromPmtStr =
          applyInfo['interest_amount_from_payment'] ?? '-';
      double keyWidth1 = 180.0;
      double keyWidth2 = 85.0;
      final keyStyle =
          TextStyle(fontSize: 13.5, color: Theme.of(context).hintColor);

      appliesWidgets.add(Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).hintColor.withAlpha(130)),
          borderRadius: BorderRadius.circular(5),
        ),
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Bill: ', style: keyStyle),
                    Text(
                      billLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('Billed Total ', style: keyStyle),
                    Text(billedTotalCost,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Text('Applied by: $appliedByOpName at $appliedTimestamp',
                    style: keyStyle),
              ],
            ),
            horizontalSpaceRegular,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: keyWidth1,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child:
                            Text('Usage Amt. from Payment: ', style: keyStyle),
                      ),
                    ),
                    Text(appliedUsageAmountFromPmtStr,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: keyWidth1,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('Interest Amt. from Payment: ',
                            style: keyStyle),
                      ),
                    ),
                    Text(appliedInterestAmountFromPmtStr,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(children: appliesWidgets),
    );
  }

  Widget getPaymentApplyListOfThisBill(
      dynamic existingPaymentApplyInfoList, Map<String, dynamic> billInfo) {
    List existingPaymentApplyInfoListTyped = [];
    if (existingPaymentApplyInfoList is List) {
      existingPaymentApplyInfoListTyped = existingPaymentApplyInfoList;
    }
    if (existingPaymentApplyInfoListTyped.isEmpty) {
      return Container();
    }

    String billLabel = billInfo['label'] ?? '-';
    String billedTotalCost = billInfo['billed_total_amount'] ?? '-';

    List<Widget> appliesWidgets = [];
    appliesWidgets.add(Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () {
            setState(() {
              _showExistingApplies = !_showExistingApplies;
            });
          },
          child: Text(
            'Payment Applies (${existingPaymentApplyInfoListTyped.length}) for This Bill - $billLabel',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).hintColor),
          ),
        ),
      ),
    ));
    for (Map<String, dynamic> applyInfo in existingPaymentApplyInfoListTyped) {
      if (!_showExistingApplies) {
        break;
      }
      // String tenantLabel = applyInfo['tenant_label'] ?? '-';

      String appliedTimestamp = applyInfo['applied_timestamp'] ?? '-';
      String appliedByOpName = applyInfo['op_username'] ?? '-';
      String appliedUsageAmountFromPmtStr =
          applyInfo['usage_amount_from_payment'] ?? '-';
      String appliedInterestAmountFromPmtStr =
          applyInfo['interest_amount_from_payment'] ?? '-';

      double keyWidth1 = 180.0;
      double keyWidth2 = 85.0;
      final keyStyle =
          TextStyle(fontSize: 13.5, color: Theme.of(context).hintColor);

      appliesWidgets.add(Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).hintColor.withAlpha(130)),
          borderRadius: BorderRadius.circular(5),
        ),
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row(
                //   children: [
                //     Text('Bill: ', style: keyStyle),
                //     Text(
                //       billLabel,
                //       style: const TextStyle(fontWeight: FontWeight.bold),
                //     ),
                //   ],
                // ),
                // Row(
                //   children: [
                //     Text('Billed Total ', style: keyStyle),
                //     Text(billedTotalCost,
                //         style: const TextStyle(fontWeight: FontWeight.bold)),
                //   ],
                // ),
                Text('Applied by: $appliedByOpName at $appliedTimestamp',
                    style: keyStyle),
              ],
            ),
            horizontalSpaceRegular,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: keyWidth1,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child:
                            Text('Usage Amt. from Payment: ', style: keyStyle),
                      ),
                    ),
                    Text(appliedUsageAmountFromPmtStr,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: keyWidth1,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('Interest Amt. from Payment: ',
                            style: keyStyle),
                      ),
                    ),
                    Text(appliedInterestAmountFromPmtStr,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(children: appliesWidgets),
    );
  }

  Widget getIniBalPaymentInfo() {
    if (_initialBalancePaymentInfo.isEmpty) {
      return Container();
    }

    final iniBalAmount = double.tryParse(
            _initialBalancePaymentInfo['amount']?.toString() ?? '0.0') ??
        0.0;
    final paymentApplyList =
        _initialBalancePaymentInfo['payment_apply_info_list'] ?? [];
    double iniBalAppliedAmount = 0.0;
    for (var applyInfo in paymentApplyList) {
      final usageAmountFromPayment = double.tryParse(
              applyInfo['used_amount_from_payment']?.toString() ?? '0.0') ??
          0.0;
      final interestAmountFromPayment = double.tryParse(
              applyInfo['interest_amount_from_payment']?.toString() ?? '0.0') ??
          0.0;
      iniBalAppliedAmount += usageAmountFromPayment + interestAmountFromPayment;
    }
    final iniBalAvailableAmount = iniBalAmount - iniBalAppliedAmount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          getTag('Ini Bal', 'Initial Balance Payment Info',
              color: PaymentSoaType.initialBalance.color, width: 70),
          horizontalSpaceTiny,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Amount: ', style: billKeyStyle),
                  Text(iniBalAmount.toStringAsFixed(2), style: billValStyle),
                ],
              ),
              Row(
                children: [
                  Text('Applied Amount: ', style: billKeyStyle),
                  Text(iniBalAppliedAmount.toStringAsFixed(2),
                      style: billValStyle.copyWith(
                          color: Theme.of(context).colorScheme.primary)),
                ],
              ),
              Row(
                children: [
                  Text('Balance: ', style: billKeyStyle),
                  Text(iniBalAvailableAmount.toStringAsFixed(2),
                      style: billValStyle),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
