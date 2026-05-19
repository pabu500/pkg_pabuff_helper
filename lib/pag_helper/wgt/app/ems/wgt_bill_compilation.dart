import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/def_helper/list_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../pagrid_helper/ems_helper/billing_helper/cw_bill/pag_gen_pdf_bill_compilation_cw.dart';
import '../../../../pagrid_helper/ems_helper/billing_helper/wgt_pag_render_pdf.dart';
import '../../../../up_helper/exceptions.dart';
import '../../../../util/date_time_util.dart';
import '../../../../xt_ui/xt_helpers.dart';
import '../../../comm/comm_pag_billing.dart';
import '../../../comm/comm_pag_item.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_context.dart';
import '../../../model/mdl_pag_user.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../../model/scope/mdl_pag_scope.dart';
import '../../datetime/wgt_date_range_picker_monthly.dart';

class WgtBillCompilation extends StatefulWidget {
  const WgtBillCompilation({
    super.key,
    required this.appConfig,
    required this.pagAppContext,
    required this.loggedInUser,
    required this.scopeType,
    required this.scopeInfo,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagAppContext pagAppContext;
  final MdlPagUser loggedInUser;
  final PagScopeType scopeType;
  final Map<String, dynamic> scopeInfo;

  @override
  State<WgtBillCompilation> createState() => _WgtBillCompilationState();
}

class _WgtBillCompilationState extends State<WgtBillCompilation> {
  String _errorText = '';
  bool _gettingBillList = false;
  bool _fetchedBillList = false;
  final List<Map<String, dynamic>> _billList = [];
  int _pullFails = 0;
  bool _showCompilation = false;
  bool _compilationGenerated = false;
  final String defaultErrorText = 'Error getting bill compilation';

  final int maxPerPage = 1000;
  late final BoxDecoration boxDecoration = BoxDecoration(
    border: Border.all(color: Theme.of(context).hintColor, width: 1.5),
    borderRadius: BorderRadius.circular(5),
  );

  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  bool _customDateRangeSelected = false;
  bool _isMTD = false;
  DateTime? _monthPicked;
  DateTime? _selectedDate1;
  DateTime? _selectedDate2;
  UniqueKey? _date1PickerKey;
  UniqueKey? _date2PickerKey;

  Future<dynamic> _getScopeBillList() async {
    if (_gettingBillList) {
      return;
    }
    if (_fetchedBillList) {
      return;
    }

    setState(() {
      _errorText = '';
      _gettingBillList = true;
      _billList.clear();
    });

    Map<String, dynamic> itemScopeMap = {};
    itemScopeMap.addAll(widget.loggedInUser.selectedScope.toScopeMap());
    if (widget.scopeType == PagScopeType.location) {
      itemScopeMap['location_id'] = widget.scopeInfo['id'];
      itemScopeMap['location_name'] = widget.scopeInfo['name'];
    } else if (widget.scopeType == PagScopeType.locationGroup) {
      itemScopeMap['location_group_id'] = widget.scopeInfo['id'];
      itemScopeMap['location_group_name'] = widget.scopeInfo['name'];
    } else if (widget.scopeType == PagScopeType.building) {
      itemScopeMap['building_id'] = widget.scopeInfo['id'];
      itemScopeMap['building_name'] = widget.scopeInfo['name'];
    } else if (widget.scopeType == PagScopeType.site) {
      itemScopeMap['site_id'] = widget.scopeInfo['id'];
      itemScopeMap['site_name'] = widget.scopeInfo['name'];
    } else if (widget.scopeType == PagScopeType.siteGroup) {
      itemScopeMap['site_group_id'] = widget.scopeInfo['id'];
      itemScopeMap['site_group_name'] = widget.scopeInfo['name'];
    } else if (widget.scopeType == PagScopeType.project) {
    } else {
      setState(() {
        _gettingBillList = false;
        _errorText = 'Unsupported scope type: ${widget.scopeType}';
      });
      return;
    }

    String cycleStr = '';
    if (_selectedFromDate != null && _selectedToDate != null) {
      // get mid date and make 'YYYY-MM' format
      DateTime midDate = _selectedFromDate!
          .add(_selectedToDate!.difference(_selectedFromDate!) ~/ 2);
      cycleStr = '${midDate.year}-${midDate.month.toString().padLeft(2, '0')}';
    }
    if (cycleStr.isEmpty) {
      throw Exception('Cycle month is not selected');
    }

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'item_scope': itemScopeMap,
      'item_kind': PagItemKind.bill.name,
      // 'item_type': itemTypeStr,
      'max_rows_per_page': '$maxPerPage',
      'lc_status': 'released',
      'additional_constraint':
          'gen_type != \'initial_balance\' AND cycle_str = \'$cycleStr\'',
      // 'current_page': '$_currentPage',
      'sort_by': 'account_number',
      'sort_order': 'asc',
      // 'get_count_only': widget.getCountOnly ? 'true' : 'false',
      'list_context_type': PagListContextType.billCompilation.name,
      // 'allow_flexi_label': widget.allowFlexiLabel ? 'true' : 'false',
    };

    try {
      final billResult = await fetchItemList(
        widget.loggedInUser,
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          target: '',
          scope: '',
          operation: 'get_bill_list',
        ),
      );
      final itemList = billResult['item_list'];
      for (var item in itemList) {
        String itemId = item['id'];
        // _billList.add(item);
        Map<String, dynamic> queryMap = {
          'scope': widget.loggedInUser.selectedScope.toScopeMap(),
          'billing_rec_index': itemId,
          'is_released_mode': 'true',
        };
        try {
          final billResult = await getPagCompositeBill(
            widget.appConfig,
            queryMap,
            MdlPagSvcClaim(
              userId: widget.loggedInUser.id,
              username: widget.loggedInUser.username,
              target: '',
              scope: '',
              operation: '',
            ),
          );
          _billList.add(billResult);
        } catch (err) {
          _pullFails++;
          dev.log('Error generating bill: $err');

          _errorText = getErrorText(err, defaultErrorText: defaultErrorText);
        } finally {
          setState(() {
            _gettingBillList = false;
            if (_errorText.isNotEmpty) {
              showInfoDialog(context, 'Error', _errorText);
            }
          });
        }
      }
    } catch (err) {
      _pullFails++;

      dev.log('Error generating bill: $err');

      _errorText =
          getErrorText(err, defaultErrorText: 'Error getting scope bill list');
    } finally {
      setState(() {
        _gettingBillList = false;
        _fetchedBillList = true;
        if (_errorText.isNotEmpty) {
          // showInfoDialog(context, 'Error', _errorText);
        }
      });
    }
  }

  void _resetDate({bool resetDateRange = false}) {
    setState(() {
      if (resetDateRange) {
        _selectedToDate = null;
        _selectedFromDate = null;
        // _timePickerKey = UniqueKey();
        _customDateRangeSelected = false;
        _monthPicked = null;
        _isMTD = false;
        _selectedDate1 = null;
        _selectedDate2 = null;
        _date1PickerKey = null;
        _date2PickerKey = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 500,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Symbols.assignment_ind, color: Colors.transparent),
              getScopeInfo(),
              IconButton(
                icon: const Icon(Symbols.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const Divider(thickness: 0.5),
          verticalSpaceTiny,
          getOpRow(),
          verticalSpaceSmall,
          if (_showCompilation && _billList.isNotEmpty)
            WgtPagRenderPdf(
              loggedInUser: widget.loggedInUser,
              itemInfo: {'bill_info_list': _billList},
              builder: generatePagInvoiceCompilation,
            ),
          verticalSpaceSmall,
        ],
      ),
    );
  }

  Widget getScopeInfo() {
    MdlPagScope itemScope = MdlPagScope.fromScopeTypeInfo(
        widget.scopeInfo,
        widget.scopeType,
        widget.loggedInUser.selectedScope.projectProfile!.id.toString(),
        widget.loggedInUser.selectedScope.projectProfile!.name);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bill Compilation ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).hintColor,
              ),
            ),
            getScopeLabel(context, itemScope),
          ],
        ),
      ],
    );
  }

  Widget getOpRow() {
    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
      borderRadius: BorderRadius.circular(5),
      color: Theme.of(context).colorScheme.primary,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Cycle Month',
          style: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 16,
          ),
        ),
        horizontalSpaceSmall,
        getTimeRangePicker(forceMonthly: true),
        horizontalSpaceSmall,
        if (_selectedFromDate != null && _selectedToDate != null)
          WgtCommButton(
            enabled: !_gettingBillList && !_fetchedBillList,
            label: 'Get Bill List',
            onPressed: _gettingBillList ? null : _getScopeBillList,
          ),
        if (_fetchedBillList)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text('Got ${_billList.length} bills for this scope'),
          ),
        if (_pullFails > 0) Text('Failed attempts: $_pullFails'),
        if (_billList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: WgtCommButton(
                label: 'Gen Compilation',
                enabled: !_compilationGenerated,
                onPressed: () {
                  setState(() {
                    _showCompilation = true;
                    _compilationGenerated = true;
                  });
                }),
          ),
      ],
    );
  }

  Widget getTimeRangePicker({bool forceMonthly = false, bool enabled = true}) {
    return WgtPagDateRangePickerMonthly(
      // key: _timePickerKey,
      enabled: enabled,
      iniEndDateTime: _selectedToDate,
      iniStartDateTime: _selectedFromDate,
      customRangeSelected: _customDateRangeSelected,
      monthPicked: _monthPicked,
      populateDefaultRange: false,
      allowCustomRange: !forceMonthly,
      onRangeSet: (startDate, endDate) async {
        if (startDate == null || endDate == null) return;
        _resetDate(resetDateRange: true);
        setState(() {
          _selectedFromDate = startDate;
          _selectedToDate = endDate;

          _customDateRangeSelected = true;
          _isMTD = false;
          _monthPicked = null;

          // _timePickerKey = UniqueKey();
          _selectedDate1 = null;
          _selectedDate2 = null;
          _date1PickerKey = UniqueKey();
          _date2PickerKey = UniqueKey();

          _billList.clear();
          _showCompilation = false;
          _compilationGenerated = false;
          _errorText = '';
          _fetchedBillList = false;
          _gettingBillList = false;
          _pullFails = 0;
        });
      },
      onMonthPicked: (selected) {
        _resetDate(resetDateRange: true);
        setState(() {
          // _timePickerKey = UniqueKey();
          _monthPicked = selected;
          _selectedFromDate = DateTime(selected.year, selected.month, 1);
          _selectedToDate = DateTime(selected.year, selected.month + 1, 0);
          // _customRange = false;
          DateTime localNow = getTargetLocalDatetimeNow(
              widget.loggedInUser.selectedScope.getProjectTimezone());
          _isMTD = false;
          if (localNow.year == selected.year &&
              localNow.month == selected.month) {
            _isMTD = true;
          }

          _selectedDate1 = null;
          _selectedDate2 = null;
          _date1PickerKey = UniqueKey();
          _date2PickerKey = UniqueKey();

          _billList.clear();
          _showCompilation = false;
          _compilationGenerated = false;
          _errorText = '';
          _fetchedBillList = false;
          _gettingBillList = false;
          _pullFails = 0;
        });
      },
    );
  }
}
