import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_list.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_ls_item_flexi.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/datetime/wgt_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:developer' as dev;

import '../../../comm/comm_billing2.dart';
import '../../../model/mdl_pag_app_config.dart';
import 'bill_helper.dart';
import 'wgt_create_pag_singular_bill2.dart';

class WgtCreatePagCompositeBill2 extends StatefulWidget {
  const WgtCreatePagCompositeBill2({
    super.key,
    required this.appConfig,
    required this.pagAppContext,
    required this.loggedInUser,
    this.width,
    this.height = 600,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagAppContext pagAppContext;
  final MdlPagUser loggedInUser;
  final double? width;
  final double height;
  final Function? onCreated;

  @override
  State<WgtCreatePagCompositeBill2> createState() =>
      _WgtCreatePagCompositeBill2State();
}

class _WgtCreatePagCompositeBill2State
    extends State<WgtCreatePagCompositeBill2> {
  // late MdlPagUser? _loggedInUser;

  final defaultErrorText = 'Error generating bill';

  late double? _width = widget.width;
  String _errorText = '';
  String? _inputErrorText;
  bool _isSearchingTenant = false;
  bool _isSearchingTariffPackage = false;
  bool _showEmptyResultTenant = false;

  bool _queryTenantsComplete = false;
  bool _generatingBill = false;
  Map<String, dynamic> _billResult = {};

  final List<Map<String, dynamic>> _tenentInfoList = [];

  String? _lineItemLabel1;
  double? _lineItemAmount1;
  UniqueKey? _lineItemLabelKey1;
  UniqueKey? _lineItemAmountKey1;
  String? _lineItemLabelErrorText1;
  String? _lineItemAmountErrorText1;

  String? _lineItemLabel2;
  double? _lineItemAmount2;
  UniqueKey? _lineItemLabelKey2;
  UniqueKey? _lineItemAmountKey2;
  String? _lineItemLabelErrorText2;
  String? _lineItemAmountErrorText2;

  String? _lineItemLabel3;
  double? _lineItemAmount3;
  UniqueKey? _lineItemLabelKey3;
  UniqueKey? _lineItemAmountKey3;
  String? _lineItemLabelErrorText3;
  String? _lineItemAmountErrorText3;

  bool _lineItemOK = false;

  int _totalTenantCount = 0;

  final EdgeInsets sidePadding = const EdgeInsets.only(left: 0, right: 60);

  late bool _viewOnly;

  bool _tenantOK = false;
  bool _singularBillListOK = false;

  final List<WgtCreatePagSingularBill2> _singularBillWgtList = [];
  final List<Map<String, dynamic>> _singularBillInfoList = [];

  bool _createIniBalBill = false;
  bool _iniBalBillExists = false;
  bool _iniBalBillIsReleased = false;

  UniqueKey? _timePickerKey;
  DateTime? _billDate;
  bool _billDateOk = false;
  DateTime? _collectionEndDate;
  bool _collectionDateOk = false;
  bool _useCustomCollectionStartDate = false;
  DateTime? _collectionStartDate;
  UniqueKey? _timePickerKeyCollectionStartDate;

  final List<Map<String, dynamic>> _assignedTpInfoList = [];

  Future<dynamic> _genBill() async {
    if (_totalTenantCount != 1) {
      dev.log('Please select 1 tenant');

      return;
    }

    setState(() {
      _generatingBill = true;
      _errorText = '';
      _inputErrorText = '';
      _billResult.clear();
    });

    // _genAlignedFromTo(_selectedStartDate, _selectedEndDate);

    try {
      Map<String, dynamic> queryMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'tenant_id': _tenentInfoList.first['id'],
        'tenant_name': _tenentInfoList.first['tenant_name'],
        'tenant_lc_status': _tenentInfoList.first['lc_status'],
        'gen_by': widget.loggedInUser.username,
        'singular_bill_info_list': _singularBillInfoList,
        'create_initial_balance_bill': _createIniBalBill.toString(),
      };
      if (_billDate != null) {
        queryMap['bill_date_timestamp'] = _billDate!.toIso8601String();
      }
      if (_collectionEndDate != null) {
        queryMap['collection_end_date_timestamp'] =
            _collectionEndDate!.toIso8601String();
      }
      if (_useCustomCollectionStartDate && _collectionStartDate != null) {
        queryMap['collection_start_date_timestamp'] =
            _collectionStartDate!.toIso8601String();
      }

      if (_lineItemLabel1 != null) {
        queryMap['line_item_label_1'] = _lineItemLabel1;
      }
      if (_lineItemAmount1 != null) {
        queryMap['line_item_amount_1'] = _lineItemAmount1.toString();
      }

      if (_lineItemLabel2 != null) {
        queryMap['line_item_label_2'] = _lineItemLabel2;
      }
      if (_lineItemAmount2 != null) {
        queryMap['line_item_amount_2'] = _lineItemAmount2.toString();
      }
      if (_lineItemLabel3 != null) {
        queryMap['line_item_label_3'] = _lineItemLabel3;
      }
      if (_lineItemAmount3 != null) {
        queryMap['line_item_amount_3'] = _lineItemAmount3.toString();
      }

      final result = await genPagBill2(
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          target: getAclTargetStr(AclTarget.bill_p_entity),
          scope: '',
          operation: AclOperation.create.name,
        ),
      );
      if (result['error'] != null) {
        dev.log(result['error']);
      } else {
        dev.log('Bill generated');
      }
      setState(() {
        _billResult = result; //result['result'];
      });

      widget.onCreated?.call();
    } catch (err) {
      dev.log('Error generating bill: $err');

      _errorText = getErrorText(err, defaultErrorText: defaultErrorText);
    } finally {
      setState(() {
        _generatingBill = false;
        if (_errorText.isNotEmpty) {
          showInfoDialog(context, 'Error', _errorText);
        }
      });
      _resetSingularBillList();
      _resetLineItem();
      _resetBillDate(resetDateRange: true);
      _resetCollectionDate(resetDateRange: true);
    }
  }

  void _checkTenantOk() {
    _tenantOK = _totalTenantCount == 1 &&
        (_tenentInfoList.first['initial_balance_payment_lc_status'] != null &&
            _tenentInfoList.first['initial_balance_payment_amount'] != null);
  }

  void _checkSingularBillListOk() {
    _singularBillListOK = _singularBillInfoList.isNotEmpty &&
        _singularBillInfoList.every((element) =>
            element['is_ready'] != null && element['is_ready'] == true);
  }

  void _checkLineItemOk() {
    _lineItemOK = _totalTenantCount == 1;
    if (_lineItemAmount1 != null) {
      if (_lineItemLabel1 == null || _lineItemLabel1!.isEmpty) {
        _lineItemOK = false;
      }
    }
    if ((_lineItemLabel1 ?? '').isNotEmpty) {
      if (_lineItemAmount1 == null) {
        _lineItemOK = false;
      }
    }
    if (_lineItemLabelErrorText1 != null &&
        _lineItemLabelErrorText1!.isNotEmpty) {
      _lineItemOK = false;
    }
    if (_lineItemAmountErrorText1 != null &&
        _lineItemAmountErrorText1!.isNotEmpty) {
      _lineItemOK = false;
    }

    if (_lineItemAmount2 != null) {
      if (_lineItemLabel2 == null || _lineItemLabel2!.isEmpty) {
        _lineItemOK = false;
      }
    }
    if ((_lineItemLabel2 ?? '').isNotEmpty) {
      if (_lineItemAmount2 == null) {
        _lineItemOK = false;
      }
    }
    if (_lineItemLabelErrorText2 != null &&
        _lineItemLabelErrorText2!.isNotEmpty) {
      _lineItemOK = false;
    }
    if (_lineItemAmountErrorText2 != null &&
        _lineItemAmountErrorText2!.isNotEmpty) {
      _lineItemOK = false;
    }
    if (_lineItemAmount3 != null) {
      if (_lineItemLabel3 == null || _lineItemLabel3!.isEmpty) {
        _lineItemOK = false;
      }
    }
    if ((_lineItemLabel3 ?? '').isNotEmpty) {
      if (_lineItemAmount3 == null) {
        _lineItemOK = false;
      }
    }
    if (_lineItemLabelErrorText3 != null &&
        _lineItemLabelErrorText3!.isNotEmpty) {
      _lineItemOK = false;
    }
    if (_lineItemAmountErrorText3 != null &&
        _lineItemAmountErrorText3!.isNotEmpty) {
      _lineItemOK = false;
    }
  }

  void _checkBillDateOk() {
    _billDateOk = _billDate != null;
  }

  void _checkCollectionDateOk() {
    _collectionDateOk = _collectionEndDate != null;
    if (_useCustomCollectionStartDate) {
      _collectionDateOk = _collectionDateOk && _collectionStartDate != null;
    }
  }

  void _resetTenant() {
    setState(() {
      _queryTenantsComplete = false;
      _tenentInfoList.clear();
      _totalTenantCount = 0;
      _showEmptyResultTenant = false;
      _errorText = '';
      _billResult.clear();

      _singularBillInfoList.clear();
    });
  }

  void _resetSingularBillList() {
    setState(() {
      _singularBillWgtList.clear();
      _singularBillInfoList.clear();
      _singularBillListOK = false;
    });
  }

  void _resetLineItem() {
    setState(() {
      _lineItemLabel1 = null;
      _lineItemAmount1 = null;
      _lineItemLabelKey1 = UniqueKey();
      _lineItemAmountKey1 = UniqueKey();
      _lineItemLabelErrorText1 = null;
      _lineItemAmountErrorText1 = null;
      _lineItemLabel2 = null;
      _lineItemAmount2 = null;
      _lineItemLabelKey2 = UniqueKey();
      _lineItemAmountKey2 = UniqueKey();
      _lineItemLabelErrorText2 = null;
      _lineItemAmountErrorText2 = null;
      _lineItemLabel3 = null;
      _lineItemAmount3 = null;
      _lineItemLabelKey3 = UniqueKey();
      _lineItemAmountKey3 = UniqueKey();
      _lineItemLabelErrorText3 = null;
      _lineItemAmountErrorText3 = null;
    });
  }

  void _resetAll() {
    _billResult.clear();
    _resetTenant();
    _resetSingularBillList();
    _resetLineItem();
    _resetBillDate(resetDateRange: true);
    _resetCollectionDate(resetDateRange: true);
  }

  void _resetBillDate({bool resetDateRange = false}) {
    setState(() {
      if (resetDateRange) {
        _timePickerKey = UniqueKey();
        _billDate = null;
        _billDateOk = false;
      }
    });
  }

  void _resetCollectionDate({bool resetDateRange = false}) {
    setState(() {
      _useCustomCollectionStartDate = false;
      if (resetDateRange) {
        _timePickerKey = UniqueKey();
        _collectionEndDate = null;
        _collectionStartDate = null;
        _collectionDateOk = false;
      }
    });
  }

  // void _genAlignedFromTo(DateTime? from, DateTime? to) {
  //   if (from == null || to == null) return;

  //   _selectedStartDate = DateTime(from.year, from.month, from.day);
  //   _selectedEndDate = DateTime(to.year, to.month, to.day, 23, 59, 59);
  // }

  void _updateTpInfoList(Map<String, dynamic> tenantInfo) {
    List<String> meterTypeTagList = widget
        .loggedInUser.selectedScope.projectProfile!
        .getPortalMeterTypeTagList();

    _assignedTpInfoList.clear();
    for (String meterTypeTag in meterTypeTagList) {
      meterTypeTag = meterTypeTag.toLowerCase();
      if (tenantInfo['tp_name_$meterTypeTag'] == null) {
        continue;
      }
      _assignedTpInfoList.add({
        'meter_type': meterTypeTag.toUpperCase(),
        'tp_id': tenantInfo['tp_id_$meterTypeTag'],
        'tp_name': tenantInfo['tp_name_$meterTypeTag'],
        'tp_label': tenantInfo['tp_label_$meterTypeTag'],
        'tpt_name': tenantInfo['tpt_name_$meterTypeTag'],
        'tpt_label': tenantInfo['tpt_label_$meterTypeTag'],
        'tpt_cat': tenantInfo['tpt_cat_$meterTypeTag'],
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // _loggedInUser = Provider.of<PagUserProvider>(context, listen: false).currentUser;

    _viewOnly = false;
  }

  @override
  Widget build(BuildContext context) {
    _width ??= MediaQuery.of(context).size.width - 130;

    bool showBillComponent =
        !_generatingBill && !(_iniBalBillExists && !_iniBalBillIsReleased);
    return _viewOnly
        ? const Center(
            child:
                // Text('You do not have permission to create new billing record')
                SizedBox())
        : SingleChildScrollView(
            child: Column(
              children: [
                WgtListSearchItemFlexi(
                  appConfig: widget.appConfig,
                  pagAppContext: widget.pagAppContext,
                  itemKind: PagItemKind.tenant,
                  listContextType: PagListContextType.info,
                  isSingleItemMode: true,
                  showList: false,
                  prefKey: '${widget.pagAppContext.route}_tenant',
                  hint: 'Select tenant for billing',
                  additionalQuery: const {
                    'get_initial_balance_payment_info': 'true',
                  },
                  onResult: (Map<String, dynamic> result) {
                    _resetAll();

                    setState(() {
                      if (result['item_list'] != null) {
                        List<Map<String, dynamic>> resultList =
                            List<Map<String, dynamic>>.from(
                                result['item_list']);
                        _tenentInfoList.addAll(resultList);
                        _totalTenantCount = resultList.length;
                      } else {
                        _totalTenantCount = 0;
                      }
                      _queryTenantsComplete = true;
                      _showEmptyResultTenant =
                          _totalTenantCount == 0 ? true : false;
                      _errorText = '';

                      _tenantOK = _totalTenantCount == 1 ? true : false;

                      _updateTpInfoList(_tenentInfoList.first);

                      if (_tenentInfoList
                                  .first['initial_balance_payment_lc_status'] ==
                              null ||
                          _tenentInfoList
                                  .first['initial_balance_payment_amount'] ==
                              null) {
                        _createIniBalBill = true;
                      }
                      final lcStatusIniBalPayment = _tenentInfoList
                          .first['initial_balance_payment_lc_status'];
                      _iniBalBillExists = _tenentInfoList
                              .first['initial_balance_billing_rec_name'] !=
                          null;
                      _iniBalBillIsReleased = _tenentInfoList
                              .first['initial_balance_billing_rec_lc_status'] ==
                          BillingLcStatus.released.name;
                    });
                  },
                ),
                getTenantInfoBox(),
                if (showBillComponent) const Divider(thickness: 0.5),
                getAddSingluarBillButton(),
                verticalSpaceTiny,
                ...getSingularBillList(),
                if (showBillComponent) const Divider(thickness: 0.5),
                getLineItems(),
                verticalSpaceSmall,
                getBillDate(),
                verticalSpaceSmall,
                getCollectionStartDate(),
                verticalSpaceSmall,
                getCollectionEndDate(),
                verticalSpaceSmall,
                if (_billResult.isEmpty && _errorText.isEmpty)
                  getGenBillButton(),
                verticalSpaceTiny,
                getCheckers(),
                verticalSpaceTiny,
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: getActions(),
                ),
              ],
            ),
          );
  }

  Widget getTenantInfoBox() {
    return Column(
      children: [
        !_queryTenantsComplete
            ? Container()
            : _totalTenantCount == 0
                ? const EmptyResult(message: 'No tenant found')
                : _totalTenantCount > 1
                    ? Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).hintColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: xtInfoBox(
                          icon: Icon(
                            Icons.info,
                            color: Theme.of(context).hintColor,
                          ),
                          text:
                              'More than 1 tenant found, please refine your search.',
                          textStyle: TextStyle(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    Theme.of(context).hintColor.withAlpha(55),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            child: Row(
                              children: [
                                getTypeTag(context, 'Tenant'),
                                horizontalSpaceSmall,
                                Text(
                                    '${_tenentInfoList.first['name']} - ${_tenentInfoList.first['label']}'),
                                horizontalSpaceSmall,
                                PagTenantLcStatus.getTagWidget(
                                    PagTenantLcStatus.byValue(
                                        _tenentInfoList.first['lc_status'] ??
                                            '')),
                              ],
                            ),
                          ),
                          horizontalSpaceSmall,
                          getInitialBalanceBillCheckbox(
                              pagAppContext: widget.pagAppContext,
                              tenantInfo: _tenentInfoList.first),
                        ],
                      ),
        if (_iniBalBillExists && !_iniBalBillIsReleased)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      Symbols.warning,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    horizontalSpaceSmall,
                    Text(
                      'Initial balance bill "${_tenentInfoList.first['initial_balance_billing_rec_label']}" is not released yet, please release it before creating new bill.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        getTpInfoBox(),
      ],
    );
  }

  Widget getTpInfoBox() {
    if (_assignedTpInfoList.isEmpty) {
      return Container();
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).hintColor.withAlpha(55),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Assigned TPs:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          horizontalSpaceTiny,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._assignedTpInfoList.map((tpInfo) {
                return Text(
                    '${tpInfo['meter_type']} - ${tpInfo['tp_id']} - ${tpInfo['tp_label']} (${tpInfo['tpt_label']}, ${tpInfo['tpt_cat']})');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget getInitialBalanceBillCheckbox(
      {required MdlPagAppContext pagAppContext,
      required Map<String, dynamic> tenantInfo}) {
    final lcStatusIniBalPayment =
        tenantInfo['initial_balance_payment_lc_status'];
    final amountIniBalPayment = tenantInfo['initial_balance_payment_amount'];
    final iniBalBillingRecName = tenantInfo['initial_balance_billing_rec_name'];
    final iniBalBillingRecLabel =
        tenantInfo['initial_balance_billing_rec_label'];
    final iniBalBillingRecLcStatus =
        tenantInfo['initial_balance_billing_rec_lc_status'];
    bool iniBalBillExists = iniBalBillingRecName != null;
    // bool iniBalBIllIsReleased = iniBalBillingRecLcStatus == BillingLcStatus.released.name;
    // assert(lcStatusIniBalPayment != null);
    // assert(amountIniBalPayment != null);
    if (lcStatusIniBalPayment == null || amountIniBalPayment == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).hintColor.withAlpha(55),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          children: [
            Icon(
              Icons.warning,
              color: Theme.of(context).colorScheme.error,
            ),
            horizontalSpaceSmall,
            Text(
              'Initial balance payment info not available',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }

    double amount = 0;
    if (amountIniBalPayment is String) {
      amount = double.tryParse(amountIniBalPayment) ?? 0.0;
    } else if (amountIniBalPayment is double) {
      amount = amountIniBalPayment;
    }
    if (lcStatusIniBalPayment == 'matched' || amount > -0.0001) {
      return Container();
    }

    if (lcStatusIniBalPayment != 'matched' && amount < -0.0001) {
      // force check the box
      // _createIniBalBill = true;
      if (iniBalBillExists) {
        _createIniBalBill = false;
      } else {
        _createIniBalBill = true;
      }
    }

    if (_iniBalBillExists && !_iniBalBillIsReleased) {
      // return Container(
      //   decoration: BoxDecoration(
      //     border: Border.all(
      //       color: Theme.of(context).hintColor.withAlpha(55),
      //       width: 1,
      //     ),
      //     borderRadius: BorderRadius.circular(5),
      //   ),
      //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      //   child: Row(
      //     children: [
      //       Icon(
      //         Symbols.warning,
      //         color: Theme.of(context).colorScheme.error,
      //       ),
      //       horizontalSpaceSmall,
      //       Text(
      //         'Initial balance bill "$iniBalBillingRecLabel" is not released yet, please release it before creating new bill.',
      //         style: TextStyle(
      //           color: Theme.of(context).colorScheme.error,
      //         ),
      //       ),
      //     ],
      //   ),
      // );
    }

    return Tooltip(
      message: iniBalBillExists
          ? 'Initial balance bill already exists (Name: $iniBalBillingRecName, Lc Status: $iniBalBillingRecLcStatus)'
          : 'Create bill to settle negative initial balance',
      waitDuration: const Duration(milliseconds: 500),
      child: Row(
        children: [
          Checkbox(
            value: _createIniBalBill,
            // onChanged: (bool? value) {
            //   setState(() {
            //     _createIniBalBill = value ?? false;
            //   });
            // },
            onChanged: null,
          ),
          const Text('Initial Balance Bill'),
          horizontalSpaceSmall,
          Text(
            'Amount: ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget getAddSingluarBillButton() {
    if (_createIniBalBill || (_iniBalBillExists && !_iniBalBillIsReleased)) {
      return Container();
    }
    bool disalbled = !_tenantOK;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: disalbled
            ? null
            : () {
                final singularBillKey = UniqueKey();

                Map<String, dynamic> singularBillInfo = {};
                singularBillInfo['key'] = singularBillKey;
                _singularBillInfoList.add(singularBillInfo);

                setState(() {
                  _singularBillWgtList.add(WgtCreatePagSingularBill2(
                    appConfig: widget.appConfig,
                    appContext: widget.pagAppContext,
                    loggedInUser: widget.loggedInUser,
                    tenantInfo: _tenentInfoList.first,
                    fromDateTime: null,
                    toDateTime: null,
                    singularBillKey: singularBillKey,
                    onChanged: (UniqueKey singularBillKey,
                        Map<String, dynamic> singularBillInfo) {
                      // update the singular bill info list
                      int index = _singularBillInfoList.indexWhere(
                          (element) => element['key'] == singularBillKey);
                      if (index != -1) {
                        _singularBillInfoList[index] = singularBillInfo;
                      }
                      setState(() {
                        _timePickerKey = UniqueKey();

                        _billDate = null;
                        _collectionEndDate = null;
                        _collectionStartDate = null;

                        _singularBillListOK =
                            _singularBillInfoList.isNotEmpty &&
                                _singularBillInfoList.every((element) =>
                                    element['is_ready'] != null &&
                                    element['is_ready'] == true);
                      });
                    },
                  ));
                });
              },
        icon: Icon(Icons.add,
            color: disalbled ? Theme.of(context).disabledColor : null),
        label: Text('Add Singular Bill',
            style: TextStyle(
                color: disalbled ? Theme.of(context).disabledColor : null)),
      ),
    );
  }

  List<Widget> getSingularBillList() {
    if (!_tenantOK) {
      return [];
    }
    if (_iniBalBillExists && !_iniBalBillIsReleased) {
      return [];
    }
    if (_createIniBalBill) {
      return [];
    }
    return _singularBillWgtList;
  }

  Widget getLineItems() {
    if (_totalTenantCount != 1) {
      return Container();
    }
    if (_createIniBalBill) {
      return Container();
    }
    if (_iniBalBillExists && !_iniBalBillIsReleased) {
      return Container();
    }
    return Padding(
      padding: sidePadding,
      child: Container(
        width: _width,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).hintColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).hintColor.withAlpha(55),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 350,
                        child: WgtTextField(
                          key: _lineItemLabelKey1,
                          appConfig: widget.appConfig,
                          labelText: 'Line Item Label (subject to tax)',
                          hintText: 'Enter line item label (subject to tax)',
                          onChanged: (value) {
                            setState(() {
                              _lineItemLabel1 = value;

                              if ((_lineItemLabel1 ?? '').isEmpty) {
                                if (_lineItemAmountErrorText1 != null) {
                                  _lineItemAmountErrorText1 = null;
                                  // to remove the 'required' error
                                  _lineItemAmountKey1 = UniqueKey();
                                }
                              }
                              _checkLineItemOk();
                            });
                          },
                          onClear: () {
                            setState(() {
                              _lineItemLabel1 = null;
                              if (_lineItemAmountErrorText1 != null) {
                                _lineItemAmountErrorText1 = null;
                                // to remove the 'required' error
                                _lineItemAmountKey1 = UniqueKey();
                              }
                            });
                          },
                          validator: (value) {
                            // validaor will prevent _lineItemLabel from being null
                            // for this case need to manually set it to null
                            setState(() {
                              _lineItemLabel1 = value;
                            });

                            if (value == null || value.isEmpty) {
                              if (_lineItemAmount1 != null) {
                                return 'required';
                              }
                            }
                            return null;
                          },
                          onValidate: (result) {
                            setState(() {
                              _lineItemLabelErrorText1 = result;
                            });
                          },
                        ),
                      ),
                      verticalSpaceSmall,
                      SizedBox(
                        width: 350,
                        child: WgtTextField(
                          resetKey: _lineItemAmountKey1,
                          appConfig: widget.appConfig,
                          labelText: 'Line Item amount (subject to tax)',
                          hintText: 'Line Item amount (subject to tax) 1',
                          validator: lineItem1Validator,
                          onValidate: (result) {
                            setState(() {
                              _lineItemAmountErrorText1 = result;
                            });

                            if (result == null) {
                              return;
                            }
                          },
                          onChanged: (value) {
                            setState(() {
                              _lineItemAmount1 = double.tryParse(value);
                              if (_lineItemAmount1 == null) {
                                if (_lineItemLabelErrorText1 != null) {
                                  _lineItemLabelErrorText1 = null;
                                  // to remove the 'required' error
                                  _lineItemLabelKey1 = UniqueKey();
                                }
                              }
                              _checkLineItemOk();
                            });
                          },
                          onClear: () {
                            setState(() {
                              _lineItemAmount1 = null;
                              if (_lineItemLabelErrorText1 != null) {
                                _lineItemLabelErrorText1 = null;
                                // to remove the 'required' error
                                _lineItemLabelKey1 = UniqueKey();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                verticalSpaceSmall,
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).hintColor.withAlpha(55),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 350,
                        child: WgtTextField(
                          key: _lineItemLabelKey2,
                          appConfig: widget.appConfig,
                          labelText: 'Line Item Label (NOT subject to tax)',
                          hintText:
                              'Enter line item label (NOT subject to tax)',
                          onChanged: (value) {
                            setState(() {
                              _lineItemLabel2 = value;

                              if ((_lineItemLabel2 ?? '').isEmpty) {
                                if (_lineItemAmountErrorText2 != null) {
                                  _lineItemAmountErrorText2 = null;
                                  // to remove the 'required' error
                                  _lineItemAmountKey2 = UniqueKey();
                                }
                              }
                              _checkLineItemOk();
                            });
                          },
                          onClear: () {
                            setState(() {
                              _lineItemLabel2 = null;
                              if (_lineItemAmountErrorText2 != null) {
                                _lineItemAmountErrorText2 = null;
                                // to remove the 'required' error
                                _lineItemAmountKey2 = UniqueKey();
                              }
                            });
                          },
                          validator: (value) {
                            // validaor will prevent _lineItemLabel from being null
                            // for this case need to manually set it to null
                            setState(() {
                              _lineItemLabel2 = value;
                            });

                            if (value == null || value.isEmpty) {
                              if (_lineItemAmount2 != null) {
                                return 'required';
                              }
                            }
                            return null;
                          },
                          onValidate: (result) {
                            setState(() {
                              _lineItemLabelErrorText2 = result;
                            });
                          },
                        ),
                      ),
                      verticalSpaceSmall,
                      SizedBox(
                        width: 350,
                        child: WgtTextField(
                          resetKey: _lineItemAmountKey2,
                          appConfig: widget.appConfig,
                          labelText: 'Line Item amount (NOT subject to tax)',
                          hintText: 'Line Item amount (NOT subject to tax)',
                          validator: lineItem2Validator,
                          onValidate: (result) {
                            setState(() {
                              _lineItemAmountErrorText2 = result;
                            });

                            if (result == null) {
                              return;
                            }
                          },
                          onChanged: (value) {
                            setState(() {
                              _lineItemAmount2 = double.tryParse(value);
                              if (_lineItemAmount2 == null) {
                                if (_lineItemLabelErrorText2 != null) {
                                  _lineItemLabelErrorText2 = null;
                                  // to remove the 'required' error
                                  _lineItemLabelKey2 = UniqueKey();
                                }
                              }
                              _checkLineItemOk();
                            });
                          },
                          onClear: () {
                            setState(() {
                              _lineItemAmount2 = null;
                              if (_lineItemLabelErrorText2 != null) {
                                _lineItemLabelErrorText2 = null;
                                // to remove the 'required' error
                                _lineItemLabelKey2 = UniqueKey();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                verticalSpaceSmall,
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).hintColor.withAlpha(55),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 350,
                        child: WgtTextField(
                          key: _lineItemLabelKey3,
                          appConfig: widget.appConfig,
                          labelText: 'Interest Adjustment',
                          hintText: 'Enter interest adjustment',
                          onChanged: (value) {
                            setState(() {
                              _lineItemLabel3 = value;

                              if ((_lineItemLabel3 ?? '').isEmpty) {
                                if (_lineItemAmountErrorText3 != null) {
                                  _lineItemAmountErrorText3 = null;
                                  // to remove the 'required' error
                                  _lineItemAmountKey3 = UniqueKey();
                                }
                              }
                              _checkLineItemOk();
                            });
                          },
                          onClear: () {
                            setState(() {
                              _lineItemLabel3 = null;
                              if (_lineItemAmountErrorText3 != null) {
                                _lineItemAmountErrorText3 = null;
                                // to remove the 'required' error
                                _lineItemAmountKey3 = UniqueKey();
                              }
                            });
                          },
                          validator: (value) {
                            // validaor will prevent _lineItemLabel from being null
                            // for this case need to manually set it to null
                            setState(() {
                              _lineItemLabel3 = value;
                            });

                            if (value == null || value.isEmpty) {
                              if (_lineItemAmount3 != null) {
                                return 'required';
                              }
                            }
                            return null;
                          },
                          onValidate: (result) {
                            setState(() {
                              _lineItemLabelErrorText3 = result;
                            });
                          },
                        ),
                      ),
                      verticalSpaceSmall,
                      SizedBox(
                        width: 350,
                        child: WgtTextField(
                          resetKey: _lineItemAmountKey3,
                          appConfig: widget.appConfig,
                          labelText: 'Interest Adjustment Amount',
                          hintText: 'Enter interest adjustment amount',
                          validator: lineItem3Validator,
                          onValidate: (result) {
                            setState(() {
                              _lineItemAmountErrorText3 = result;
                            });

                            if (result == null) {
                              return;
                            }
                          },
                          onChanged: (value) {
                            setState(() {
                              _lineItemAmount3 = double.tryParse(value);
                              if (_lineItemAmount3 == null) {
                                if (_lineItemLabelErrorText3 != null) {
                                  _lineItemLabelErrorText3 = null;
                                  // to remove the 'required' error
                                  _lineItemLabelKey3 = UniqueKey();
                                }
                              }
                              _checkLineItemOk();
                            });
                          },
                          onClear: () {
                            setState(() {
                              _lineItemAmount3 = null;
                              if (_lineItemLabelErrorText3 != null) {
                                _lineItemLabelErrorText3 = null;
                                // to remove the 'required' error
                                _lineItemLabelKey3 = UniqueKey();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double limitNeg = -1000000;
  double limitPos = 1000000;
  String? lineItem1Validator(String? value) {
    if ((_lineItemLabel1 ?? '').isNotEmpty && (value ?? '').isEmpty) {
      _lineItemAmount1 = null;
      return 'required';
    }

    if (value == null || value.isEmpty) {
      return null;
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    if (double.parse(value) < limitNeg) {
      return 'Please enter a value greater than $limitNeg';
    }
    // check max
    if (double.parse(value) > limitPos) {
      return 'Please enter a value less than $limitPos';
    }

    return null;
  }

  String? lineItem2Validator(String? value) {
    if ((_lineItemLabel2 ?? '').isNotEmpty && (value ?? '').isEmpty) {
      _lineItemAmount2 = null;
      return 'required';
    }

    if (value == null || value.isEmpty) {
      return null;
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    if (double.parse(value) < limitNeg) {
      return 'Please enter a value greater than $limitNeg';
    }
    // check max
    if (double.parse(value) > limitPos) {
      return 'Please enter a value less than $limitPos';
    }

    return null;
  }

  String? lineItem3Validator(String? value) {
    if ((_lineItemLabel3 ?? '').isNotEmpty && (value ?? '').isEmpty) {
      _lineItemAmount3 = null;
      return 'required';
    }

    if (value == null || value.isEmpty) {
      return null;
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    if (double.parse(value) < limitNeg) {
      return 'Please enter a value greater than $limitNeg';
    }
    // check max
    if (double.parse(value) > limitPos) {
      return 'Please enter a value less than $limitPos';
    }

    return null;
  }

  Widget getBillDate() {
    if (!_singularBillListOK) {
      return Container();
    }

    DateTime? leftMostDate;
    DateTime? rightMostDate;
    DateTime? initDate;

    DateTime? overallFromDate;
    DateTime? overallToDate;
    for (Map<String, dynamic> singularBillInfo in _singularBillInfoList) {
      if (singularBillInfo['from_timestamp'] != null) {
        DateTime fromDate = DateTime.parse(singularBillInfo['from_timestamp']);
        if (overallFromDate == null || fromDate.isBefore(overallFromDate)) {
          overallFromDate = fromDate;
        }
      }
      if (singularBillInfo['to_timestamp'] != null) {
        DateTime toDate = DateTime.parse(singularBillInfo['to_timestamp']);
        if (overallToDate == null || toDate.isAfter(overallToDate)) {
          overallToDate = toDate;
        }
      }
    }

    if ((overallFromDate == null || overallToDate == null)) {
    } else {
      leftMostDate = overallToDate.add(const Duration(days: 1));
      rightMostDate = leftMostDate.add(const Duration(days: 30));
      initDate = overallFromDate.add(const Duration(days: 35));
    }
    return Column(
      children: [
        (overallFromDate == null || overallToDate == null)
            ? const SizedBox()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 160,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Bill Date',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  horizontalSpaceSmall,
                  WgtDatePicker(
                    key: _timePickerKey,
                    defaultFirstDate: leftMostDate,
                    defaultLastDate: rightMostDate,
                    initialDate: _billDate, //initDate,
                    labelFontSize: 15,
                    timeZone:
                        widget.loggedInUser.selectedScope.getProjectTimezone(),
                    label: 'Set Bill Date',
                    onDateChanged: (DateTime selectedDate) {
                      setState(() {
                        _billDate = selectedDate;
                        _collectionEndDate = null;
                        _collectionStartDate = null;
                        _useCustomCollectionStartDate = false;

                        _checkBillDateOk();
                      });
                    },
                  ),
                ],
              ),
      ],
    );
  }

  Widget getCollectionEndDate() {
    if (!_singularBillListOK) {
      return Container();
    }

    DateTime? leftMostDate;
    DateTime? rightMostDate;
    DateTime? initDate;

    DateTime? overallFromDate;
    DateTime? overallToDate;
    for (Map<String, dynamic> singularBillInfo in _singularBillInfoList) {
      if (singularBillInfo['from_timestamp'] != null) {
        DateTime fromDate = DateTime.parse(singularBillInfo['from_timestamp']);
        if (overallFromDate == null || fromDate.isBefore(overallFromDate)) {
          overallFromDate = fromDate;
        }
      }
      if (singularBillInfo['to_timestamp'] != null) {
        DateTime toDate = DateTime.parse(singularBillInfo['to_timestamp']);
        if (overallToDate == null || toDate.isAfter(overallToDate)) {
          overallToDate = toDate;
        }
      }
    }

    if ((overallFromDate == null || overallToDate == null)) {
    } else {
      leftMostDate = overallToDate.add(const Duration(days: 1));
      rightMostDate = leftMostDate.add(const Duration(days: 30));
      initDate = overallFromDate.add(const Duration(days: 35));
    }
    return Column(
      children: [
        (overallFromDate == null || overallToDate == null)
            ? const SizedBox()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 160,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Collection End Date',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  horizontalSpaceSmall,
                  WgtDatePicker(
                    key: _timePickerKey,
                    labelFontSize: 15,
                    defaultFirstDate:
                        leftMostDate?.subtract(const Duration(days: 25)),
                    defaultLastDate: rightMostDate,
                    initialDate: _collectionEndDate,
                    timeZone:
                        widget.loggedInUser.selectedScope.getProjectTimezone(),
                    label: 'Set Collection End Date',
                    onDateChanged: (DateTime selectedDate) {
                      setState(() {
                        _collectionEndDate = selectedDate;
                        _collectionStartDate = DateTime(
                            _collectionEndDate!.year,
                            _collectionEndDate!.month - 1,
                            _collectionEndDate!.day + 1
                            // _collectionEndDate!.day
                            );
                        _useCustomCollectionStartDate = false;
                        _timePickerKeyCollectionStartDate = UniqueKey();
                        _checkCollectionDateOk();
                      });
                    },
                  ),
                ],
              ),
      ],
    );
  }

  Widget getCollectionStartDate() {
    if (!_singularBillListOK) {
      return Container();
    }
    if (_collectionEndDate == null) {
      return Container();
    }

    // previous month
    // DateTime defualtCollectionStartDate = DateTime(_collectionEndDate!.year,
    //     _collectionEndDate!.month - 1, _collectionEndDate!.day + 1);
    DateTime? leftMostDate =
        _collectionEndDate?.subtract(const Duration(days: 55));

    return Column(
      children: [
        // check box to enable custom collection start date
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: _useCustomCollectionStartDate,
              onChanged: (bool? value) {
                setState(() {
                  _useCustomCollectionStartDate = value ?? false;
                });
              },
            ),
            const Text('Set Custom Collection Start Date'),
          ],
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Collection Start Date',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            horizontalSpaceSmall,
            WgtDatePicker(
              key: _timePickerKeyCollectionStartDate,
              labelFontSize: 15,
              enabled: _useCustomCollectionStartDate,
              defaultFirstDate: leftMostDate,
              defaultLastDate:
                  _collectionEndDate!.subtract(const Duration(days: 1)),
              initialDate: _collectionStartDate, //defualtCollectionStartDate,
              timeZone: widget.loggedInUser.selectedScope.getProjectTimezone(),
              label: 'Set Collection Start Date',
              onDateChanged: (DateTime selectedDate) {
                setState(() {
                  _collectionStartDate = selectedDate;
                  _checkCollectionDateOk();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget getActions() {
    return _errorText.isEmpty
        ? _billResult.isEmpty
            ? Container()
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: 'Generate another bill',
                    waitDuration: const Duration(milliseconds: 500),
                    child: InkWell(
                      onTap: () {
                        // _resetTenant();
                        // _resetTariffPackage();
                        _resetAll();
                      },
                      child: Icon(
                        Symbols.restart_alt,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  horizontalSpaceSmall,
                  Text(
                    'Bill generated: ',
                    style: TextStyle(
                        color: Theme.of(context).hintColor, fontSize: 21),
                  ),
                  Text(
                    '${_billResult['bill_name']}',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      // color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(
                      width: 40,
                      child: getCopyButton(context, _billResult['bill_name'],
                          direction: 'left'))
                ],
              )
        : getErrorTextPrompt(
            context: context, errorText: defaultErrorText, margin: 13);
  }

  Widget getCheckers() {
    if (_createIniBalBill) {
      return Container();
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      xtInfoBox(
          iconTextSpace: 3,
          icon: _tenantOK
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  Icons.pending,
                  color: Theme.of(context).hintColor,
                ),
          text: 'Tenant'),
      xtInfoBox(
          iconTextSpace: 3,
          icon: _singularBillListOK
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  Icons.pending,
                  color: Theme.of(context).hintColor,
                ),
          text: 'Singular Bills'),
      xtInfoBox(
          iconTextSpace: 3,
          icon: _lineItemOK
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  Icons.pending,
                  color: Theme.of(context).hintColor,
                ),
          text: 'Line Item'),
      xtInfoBox(
          iconTextSpace: 3,
          icon: _billDateOk
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  Icons.pending,
                  color: Theme.of(context).hintColor,
                ),
          text: 'Bill Date'),
      xtInfoBox(
          iconTextSpace: 3,
          icon: _collectionDateOk
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  Icons.pending,
                  color: Theme.of(context).hintColor,
                ),
          text: 'Collection Date'),
    ]);
  }

  Widget getGenBillButton() {
    setState(() {
      // _tenantOK = _totalTenantCount == 1;
      _checkTenantOk();
      _checkLineItemOk();
      _checkSingularBillListOk();
      _checkBillDateOk();
      _checkCollectionDateOk();
    });
    bool enableGenBill = _tenantOK &&
        _singularBillListOK &&
        _lineItemOK &&
        _billDateOk &&
        _collectionDateOk;
    if (_createIniBalBill) {
      enableGenBill = _tenantOK;
    }
    return Padding(
      padding: sidePadding,
      child: SizedBox(
        width: 350,
        child: xtButton(
          text: 'Generate Bill',
          color: Theme.of(context).colorScheme.primary,
          onPressed: enableGenBill
              ? () async {
                  await _genBill();
                }
              : null,
          waiting: _generatingBill,
        ),
      ),
    );
  }
}
