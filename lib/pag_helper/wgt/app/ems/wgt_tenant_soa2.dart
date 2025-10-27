import 'package:buff_helper/pag_helper/def_helper/list_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../comm/comm_tenant.dart';
import '../../../def_helper/dh_pag_finance.dart';
import '../../../def_helper/pag_item_helper.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../../model/mdl_pag_app_context.dart';
import '../../../model/mdl_pag_user.dart';
import '../../datetime/wgt_date_range_picker_monthly.dart';
import '../../ls/wgt_ls_item_flexi.dart';

class WgtTenantSoA2 extends StatefulWidget {
  const WgtTenantSoA2({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.pagAppContext,
    required this.teneantInfo,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final MdlPagAppContext pagAppContext;
  final Map<String, dynamic> teneantInfo;

  @override
  State<WgtTenantSoA2> createState() => _WgtTenantSoA2State();
}

class _WgtTenantSoA2State extends State<WgtTenantSoA2> {
  late final tenantName;
  late final tenantLabel;

  late bool _enableSearch;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _customDateRangeSelected = false;
  bool _isMTD = false;
  DateTime? _pickedMonth;

  bool _fetching = false;
  bool _fetched = false;
  String _errorText = '';

  final List<Map<String, dynamic>> _soaData = [];

  Future<dynamic> _doFetchSoaData() async {
    if (_fetching) {
      return;
    }
    if (_fromDate == null || _toDate == null) {
      _errorText = 'Please select both From and To dates.';
      setState(() {});
      return;
    }
    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'tenant_id': widget.teneantInfo['id'],
      'from_timestamp': _fromDate?.toIso8601String() ?? '',
      'to_timestamp': _toDate?.toIso8601String() ?? '',
    };

    _errorText = '';
    _fetched = false;
    _fetching = true;

    try {
      final result = await doGetTenantSoa(
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      // List<Map<String, dynamic>> debitList = [];
      // List<Map<String, dynamic>> creditList = [];
      // if (result['debit_list'] != null) {
      //   debitList = List<Map<String, dynamic>>.from(result['debit_list']);
      // }
      // if (result['credit_list'] != null) {
      //   creditList = List<Map<String, dynamic>>.from(result['credit_list']);
      // }
      // _updateSoAData(debitList, creditList);
      final soaData = result;
      _soaData.clear();
      if (soaData is List && soaData.isNotEmpty) {
        _soaData.addAll(List<Map<String, dynamic>>.from(soaData));
      }
    } catch (e) {
      if (kDebugMode) {
        print('error: $e');
      }

      _errorText = 'Error fetching SoA data';

      return;
    } finally {
      setState(() {
        _fetched = true;
        _fetching = false;
        _enableSearch = _enableSearchButton();
      });
    }
  }

  void _updateSoAData(List<Map<String, dynamic>> debitList,
      List<Map<String, dynamic>> creditList) {
    _soaData.clear();

    if (debitList.isNotEmpty) {
      for (var item in debitList) {
        _soaData.add({
          'entry_type': 'debit',
          'date': item['date'],
          'amount': item['amount'],
          'description': item['description'] ?? '',
        });
      }
    }
    if (creditList.isNotEmpty) {
      for (var item in creditList) {
        _soaData.add({
          'entry_type': 'credit',
          'date': item['date'],
          'description': item['description'],
          'amount': item['amount'],
        });
      }
    }
    _soaData.sort((a, b) => a['date'].compareTo(b['date']));
    // insert header
    if (_soaData.isNotEmpty) {
      _soaData.insert(0, {
        'entry_type': 'header',
        'date': 'Date',
        'amount': 'Amount',
        'description': 'Description',
      });
    }
  }

  bool _enableSearchButton() {
    if (_fetching) {
      return false;
    }
    if (_fetched) {
      return false;
    }

    if (_fromDate == null || _toDate == null) {
      return false;
    }

    return true;
  }

  void _resetTimeRangPicker({bool resetDateRange = false}) {
    // setState(() {
    if (resetDateRange) {
      _toDate = null;
      _fromDate = null;
      // _timePickerKey = UniqueKey();
      _customDateRangeSelected = false;
      _pickedMonth = null;
      _isMTD = false;
    }
    // widget.onModified?.call();
    // });
  }

  @override
  void initState() {
    super.initState();
    tenantName = widget.teneantInfo['name'] ?? '';
    tenantLabel = widget.teneantInfo['label'] ?? '';
    _enableSearch = _enableSearchButton();
  }

  @override
  Widget build(BuildContext context) {
    if (tenantName.isEmpty || tenantLabel.isEmpty) {
      return getErrorTextPrompt(
          context: context, errorText: 'Error: Misising tenant name or label');
    }

    // bool pullData = _soaData.isEmpty && !_fetching && !_fetched;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Statement of Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).hintColor,
          ),
        ),
        verticalSpaceSmall,
        Text(
          'Tenant: $tenantName ($tenantLabel)',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        verticalSpaceSmall,
        getSoAContainer(),
        verticalSpaceSmall,
      ],
    );
  }

  Widget getSoAContainer() {
    return getSoA2();
  }

  Widget getSoA2() {
    return WgtListSearchItemFlexi(
      appConfig: widget.appConfig,
      pagAppContext: widget.pagAppContext,
      itemKind: PagItemKind.finance,
      // itemType: PagFinanceType.soa,
      itemTypeListStr: PagFinanceType.tenantSoa.value,
      prefKey: widget.pagAppContext.route,
      listContextType: PagListContextType.soa,
      showTimeRangePicker: true,
      timeRangePickerWidget: getTimeRangePicker(),
      initialFilterMap: {
        'tenant_id': widget.teneantInfo['id'],
        'tenant_name': tenantName,
        'tenant_label': tenantLabel,
      },
    );
  }

  Widget getTimeRangePicker() {
    return WgtPagDateRangePickerMonthly(
      // key: _timePickerKey,
      iniEndDateTime: _toDate,
      iniStartDateTime: _fromDate,
      customRangeSelected: _customDateRangeSelected,
      monthPicked: _pickedMonth,
      populateDefaultRange: false,
      onRangeSet: (startDate, endDate) async {
        if (startDate == null || endDate == null) return;
        _resetTimeRangPicker(resetDateRange: true);
        setState(() {
          _fromDate = startDate;
          _toDate = endDate;

          _customDateRangeSelected = true;
          _isMTD = false;
          _pickedMonth = null;

          // _timePickerKey = UniqueKey();
          _enableSearch = _enableSearchButton();
        });
        // widget.onModified?.call();
      },
      onMonthPicked: (selected) {
        _resetTimeRangPicker(resetDateRange: true);
        setState(() {
          // _timePickerKey = UniqueKey();
          _pickedMonth = selected;
          _fromDate = DateTime(selected.year, selected.month, 1);
          _toDate = DateTime(selected.year, selected.month + 1, 1);
          // _customRange = false;
          DateTime localNow = getTargetLocalDatetimeNow(
              widget.loggedInUser.selectedScope.getProjectTimezone());
          _isMTD = false;
          if (localNow.year == selected.year &&
              localNow.month == selected.month) {
            _isMTD = true;
          }
          _enableSearch = _enableSearchButton();
        });
        // widget.onModified?.call();
      },
    );
  }
}
