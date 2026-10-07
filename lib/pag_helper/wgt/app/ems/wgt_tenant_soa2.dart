import 'dart:developer' as dev;
import 'wgt_soa_correction.dart';

import 'package:buff_helper/pag_helper/def_helper/dh_list.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

import '../../../comm/comm_ex.dart';
import '../../../comm/pag_be_api_base.dart';
import '../../../def_helper/dh_pag_finance.dart';
import '../../../def_helper/dh_pag_item.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../../model/mdl_pag_app_context.dart';
import '../../datetime/wgt_date_range_picker_monthly.dart';
import '../../ls/wgt_ls_item_flexi.dart';
import '../../wgt_comm_button.dart';

class WgtTenantSoA2 extends StatefulWidget {
  const WgtTenantSoA2({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.pagAppContext,
    required this.tenantInfo,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final MdlPagAppContext pagAppContext;
  final Map<String, dynamic> tenantInfo;

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
  bool _isFetchingSoa = false;
  int _correctionRefresh = 0;
  bool _correctionHeld = false;
  final _correctionKey = GlobalKey<WgtSoaCorrectionState>();
  Map<String, Map<String, dynamic>> _reverseActions = {};

  bool _isUpdatingSoa = false;
  bool _updated = false;
  String _errorText = '';

  String _updateSoaErrorText = '';

  Future<void> _populateMissingSoaEntry() async {
    if (_isUpdatingSoa) return;

    // await Future.delayed(const Duration(milliseconds: 5000));

    _isUpdatingSoa = true;
    _updateSoaErrorText = '';

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'tenant_id': widget.tenantInfo['id'],
    };

    try {
      final result = await ex(
        endpoint: PagUrlBase.eptUpdateMissingSoaBuckets,
        crudType: 'update',
        opStr: 'populate missing SoA entry',
        appConfig: widget.appConfig,
        queryMap: queryMap,
        svcClaim: MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          roleId: widget.loggedInUser.selectedRole?.id,
          roleName: widget.loggedInUser.selectedRole?.name,
          roleLabel: widget.loggedInUser.selectedRole?.label,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: 'update',
        ),
      );
    } catch (e) {
      dev.log(e.toString());
      _updateSoaErrorText = getErrorText(
        e,
        defaultErrorText: 'Error populating missing SoA entry',
      );
      rethrow;
    } finally {
      setState(() {
        _isUpdatingSoa = false;
        _updated = true;
        _enableSearch = _enableSearchButton();
      });
    }
  }

  bool _enableSearchButton() {
    if (_isUpdatingSoa) {
      return false;
    }

    if (_fromDate == null || _toDate == null) {
      // return false;
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
    tenantName = widget.tenantInfo['name'] ?? '';
    tenantLabel = widget.tenantInfo['label'] ?? '';
    _enableSearch = _enableSearchButton();
  }

  @override
  Widget build(BuildContext context) {
    if (tenantName.isEmpty || tenantLabel.isEmpty) {
      return getErrorTextPrompt(
        context: context,
        errorText: 'Error: Misising tenant name or label',
      );
    }

    final accountNumber =
        widget.tenantInfo['account_number']?.toString().trim() ?? '';

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
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            getPopulateMissingSoaEntryButton(),
            WgtSoaCorrection(
              key: _correctionKey,
              appConfig: widget.appConfig,
              user: widget.loggedInUser,
              tenantId: widget.tenantInfo['id'].toString(),
              onActionsChanged: (actions) {
                if (mounted) setState(() => _reverseActions = actions);
              },
              onChanged: () {
                if (mounted) setState(() => _correctionRefresh++);
              },
              onHoldChanged: (held) {
                if (mounted) setState(() => _correctionHeld = held);
              },
            ),
            Text(
              accountNumber.isEmpty
                  ? 'Tenant: $tenantName ($tenantLabel)'
                  : 'Tenant: $accountNumber ($tenantName, $tenantLabel)',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        if (_updateSoaErrorText.isNotEmpty)
          getErrorTextPrompt(context: context, errorText: _updateSoaErrorText),
        verticalSpaceSmall,
        Flexible(child: getSoAContainer()),
        verticalSpaceSmall,
      ],
    );
  }

  Widget getPopulateMissingSoaEntryButton() {
    return WgtCommButton(
      label: 'Check SoA Entry',
      enabled:
          !_correctionHeld &&
          !_isFetchingSoa &&
          !_isUpdatingSoa &&
          !_updated &&
          _updateSoaErrorText.isEmpty,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSecondary,
        fontSize: 13.5,
      ),
      // width: barWidth + margin,
      onPressed: () async {
        setState(() {
          _enableSearch = false;
          // _finderFreshKey = UniqueKey();
        });
        await _populateMissingSoaEntry();
      },
    );
  }

  Widget getSoAContainer() {
    return getSoA2();
  }

  Widget getSoA2() {
    return WgtListSearchItemFlexi(
      refreshCurrentSearchKey: ValueKey(_correctionRefresh),
      rowLeadingBuilder: (row) {
        final action = _reverseActions[row['id']?.toString()];
        if (action == null) return const SizedBox.shrink();
        return IconButton(
          key: ValueKey('reverse-soa-${row['id']}'),
          tooltip: 'Reverse this entry',
          icon: const Icon(Icons.undo),
          color: Theme.of(context).colorScheme.primary,
          onPressed: () => _correctionKey.currentState?.openEntry(action, row),
        );
      },
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
        'tenant_id': widget.tenantInfo['id'],
        'tenant_name': tenantName,
        'tenant_label': tenantLabel,
      },
      enableSearch: _enableSearch,
      onSearching: () {
        _correctionKey.currentState?.invalidateList();
        setState(() {
          _isFetchingSoa = true;
          _enableSearch = _enableSearchButton();
        });
      },
      onResult: (result) {
        setState(() {
          _isFetchingSoa = false;
        });
        _correctionKey.currentState?.updateList(result);
      },
      sortBy: 'entry_timestamp',
      sortOrder: 'desc',
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
        _correctionKey.currentState?.invalidateList();
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
        _correctionKey.currentState?.invalidateList();
        _resetTimeRangPicker(resetDateRange: true);
        setState(() {
          // _timePickerKey = UniqueKey();
          _pickedMonth = selected;
          _fromDate = DateTime(selected.year, selected.month, 1);
          _toDate = DateTime(selected.year, selected.month + 1, 1);
          // _customRange = false;
          DateTime localNow = getTargetLocalDatetimeNow(
            widget.loggedInUser.selectedScope.getProjectTimezone(),
          );
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
