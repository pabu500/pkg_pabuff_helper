import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../xt_ui/wdgt/wgt_pag_wait.dart';
import '../../../comm/comm_tenant.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../../model/mdl_pag_user.dart';
import '../../datetime/wgt_date_range_picker_monthly.dart';

class WgtTenantSoA2 extends StatefulWidget {
  const WgtTenantSoA2({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.teneantInfo,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
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
        const SizedBox(height: 16),
        Text(
          'Tenant: $tenantName ($tenantLabel)',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        verticalSpaceSmall,
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WgtPagDateRangePickerMonthly(
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
            ),
            horizontalSpaceSmall,
            WgtCommButton(
                label: 'Fetch SoA',
                onPressed: !_enableSearch
                    ? null
                    : () async {
                        await _doFetchSoaData();
                      }),
          ],
        ),
        verticalSpaceSmall,
        getSoAContainer(),
        verticalSpaceSmall,
      ],
    );
  }

  Widget getSoAContainer() {
    Widget wgt = const SizedBox.shrink();
    if (!_fetched) {
      return wgt;
    } else if (_errorText.isNotEmpty) {
      wgt = getErrorTextPrompt(context: context, errorText: _errorText);
    } else if (_fetched && _soaData.isEmpty) {
      wgt = const Text('No SoA data available for this tenant.');
    } else {
      wgt = SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [getSoA()],
      ));
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: Theme.of(context).hintColor, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      child: wgt,
    );
  }

  Widget getSoA() {
    return Container(
      padding: const EdgeInsets.all(3.0),
      // build list
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _soaData.length + (_soaData.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          // if header
          if (index == 0) {
            return getSoaHeader();
          }
          final item = _soaData[index - 1];
          return getSoaRow(item);
        },
      ),
    );
  }

  Widget getSoaRow(Map<String, dynamic> item) {
    String date = item['entry_timestamp'] ?? '';
    // only show date if it is not empty
    if (date.isNotEmpty) {
      date = DateTime.parse(date).toLocal().toIso8601String().split('T')[0];
    }

    TextStyle rowStyle =
        TextStyle(color: Theme.of(context).colorScheme.onSurface);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SizedBox(width: 100, child: Text(date, style: rowStyle)),
        SizedBox(
          width: 100,
          child: Text(
            item['entry_type'] == 'debit'
                ? item['debit_amount'].toString()
                : '',
            style: rowStyle.copyWith(color: Colors.red),
          ),
        ),
        SizedBox(
          width: 100,
          child: Text(
            item['entry_type'] == 'credit'
                ? item['credit_amount'].toString()
                : '',
            style: rowStyle.copyWith(color: Colors.green),
          ),
        ),
        SizedBox(
          width: 100,
          child: Text(item['balance'] ?? '', style: rowStyle),
        ),
        SizedBox(
          width: 200,
          child: Text(item['description'] ?? '', style: rowStyle),
        ),
      ],
    );
  }

  Widget getSoaHeader() {
    TextStyle headerStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).hintColor,
    );
    return Container(
      // underline
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).hintColor,
            width: 1.0,
          ),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
            width: 90,
            child: Text('Date', style: headerStyle),
          ),
          SizedBox(
            width: 90,
            child: Text('Debit', style: headerStyle),
          ),
          SizedBox(
            width: 90,
            child: Text('Credit', style: headerStyle),
          ),
          SizedBox(
            width: 90,
            child: Text('Balance', style: headerStyle),
          ),
          SizedBox(
            width: 200,
            child: Text('Description', style: headerStyle),
          ),
        ],
      ),
    );
  }
}
