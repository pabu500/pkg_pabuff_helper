import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/list_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/ems/comm_ems.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/wgt/datetime/wgt_date_range_picker_monthly.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_ls_item_flexi.dart';
import 'package:buff_helper/up_helper/enum/enum_acl.dart';
import 'package:buff_helper/up_helper/enum/enum_item.dart';
import 'package:buff_helper/up_helper/exceptions.dart';
import 'package:buff_helper/up_helper/helper/acl_helper.dart';
import 'package:buff_helper/util/date_time_util.dart';
import 'package:buff_helper/util/string_util.dart';
import 'package:buff_helper/xt_ui/wdgt/info/empty_result.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_error_text_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/input/wgt_text_field2.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_popup_button.dart';
import 'package:buff_helper/xt_ui/wdgt/xtInfoBox.dart';
import 'package:buff_helper/xt_ui/wdgt/xtWait.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;

import '../../../comm/comm_tenant_usage.dart';

class WgtCreatePagSingularBill extends StatefulWidget {
  const WgtCreatePagSingularBill({
    super.key,
    required this.appConfig,
    required this.appContext,
    required this.loggedInUser,
    required this.tenantInfo,
    required this.fromDateTime,
    required this.toDateTime,
    required this.singularBillKey,
    this.width,
    this.sidePadding = const EdgeInsets.only(left: 0, right: 60),
    this.onChanged,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagAppContext appContext;
  final MdlPagUser? loggedInUser;
  final Map<String, dynamic> tenantInfo;
  final DateTime? fromDateTime;
  final DateTime? toDateTime;
  final UniqueKey singularBillKey;
  final double? width;
  final EdgeInsets sidePadding;
  final Function(UniqueKey, Map<String, dynamic>)? onChanged;

  @override
  State<WgtCreatePagSingularBill> createState() =>
      _WgtCreatePagSingularBillState();
}

class _WgtCreatePagSingularBillState extends State<WgtCreatePagSingularBill> {
  String _errorText = '';
  String? _inputErrorText;
  // final EdgeInsets sidePadding = const EdgeInsets.only(left: 0, right: 60);

  // final List<Map<String, dynamic>> _tariffPackageList = [];
  final Map<String, dynamic> _tariffPackageE = {};
  final Map<String, dynamic> _tariffPackageW = {};
  final Map<String, dynamic> _tariffPackageB = {};
  final Map<String, dynamic> _tariffPackageN = {};
  final Map<String, dynamic> _tariffPackageG = {};

  double? _manualUsageE;
  double? _manualUsageW;
  double? _manualUsageB;
  double? _manualUsageN;
  double? _manualUsageG;
  // double? _manualRateE;
  // double? _manualRateW;
  // double? _manualRateB;
  // double? _manualRateN;
  // double? _manualRateG;
  String? _manualUsageErrorTextE;
  String? _manualUsageErrorTextW;
  String? _manualUsageErrorTextB;
  String? _manualUsageErrorTextN;
  String? _manualUsageErrorTextG;
  // String? _manualRateErrorTextE;
  // String? _manualRateErrorTextW;
  // String? _manualRateErrorTextB;
  // String? _manualRateErrorTextN;
  // String? _manualRateErrorTextG;

  bool _gettingAutoUsage = false;
  String? _autoUsageHintE;
  String? _autoUsageHintW;
  String? _autoUsageHintB;
  String? _autoUsageHintN;
  String? _autoUsageHintG;
  String _errorTextUsageHint = '';

  DateTime? _selectedFromDateTime;
  DateTime? _selectedToDateTime;

  bool _queryTariffPackageComplete = false;

  int _totalTarriffPackageCount = 0;
  String _errorTextTp = '';

  bool _showEmptyResultTariffPackage = false;

  bool _useAutoUsage = true;
  bool _useAssignedTps = true;

  bool _durationOK = false;
  UniqueKey? _timePickerKey;
  bool _customDateRangeSelected = false;
  bool _isMTD = false;
  DateTime? _monthPicked;

  late bool _tariffPackageOK = _durationOK && _useAssignedTps;
  late bool _usageOK = _durationOK && _useAutoUsage;
  late bool _usageCostOK = _durationOK && _useAssignedTps && _useAutoUsage;

  bool _isSearchingTariffPackage = false;

  final Map<String, dynamic> singularBillinfo = {};

  bool _showTpSelector = true;

  void _genAlignedFromTo(DateTime? from, DateTime? to) {
    if (from == null || to == null) return;

    _selectedFromDateTime = DateTime(from.year, from.month, from.day);
    _selectedToDateTime = DateTime(to.year, to.month, to.day, 0, 0, 0).add(
      const Duration(days: 1),
    );
  }

  Future<dynamic> _getAutoUsage() async {
    setState(() {
      _gettingAutoUsage = true;
    });

    _genAlignedFromTo(widget.fromDateTime, widget.toDateTime);

    try {
      Map<String, dynamic> queryMap = {
        'scope': widget.loggedInUser!.selectedScope.toScopeMap(),
        'item_type': PagDeviceCat.meter.name,
        'from_timestamp': _selectedFromDateTime.toString(),
        'to_timestamp': _selectedToDateTime.toString(),
        'item_id_type': ItemIdType.name.name,
        'tenant_list': [widget.tenantInfo],
      };

      // Duration duration =
      //     _selectedToDateTime!.difference(_selectedFromDateTime!);
      // queryMap['duration'] = duration;

      var result = await queryPagTenantUsageSummary(
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser!.username,
          userId: widget.loggedInUser!.id,
          scope: AclScope.global.name,
          target: getAclTargetStr(AclTarget.tenant_p_usage),
          operation: AclOperation.read.name,
        ),
      );
      final tenantInfoList = result;
      final usageSummary = tenantInfoList.first['tenant_usage_summary'];
      final meterGroupUsageList = usageSummary['meter_group_usage_list'];

      double? totalAutoUsageE;
      double? totalAutoUsageW;
      double? totalAutoUsageB;
      double? totalAutoUsageN;
      double? totalAutoUsageG;

      for (var meterGroupUsageInfo in meterGroupUsageList) {
        String meterTypeTag = meterGroupUsageInfo['meter_type'];

        final meterGroupUsageSummary =
            meterGroupUsageInfo['meter_group_usage_summary'];
        if (meterGroupUsageSummary == null) {
          continue;
        }
        final meterUsageList = meterGroupUsageSummary['meter_usage_list'];
        if (meterUsageList == null) {
          continue;
        }

        for (Map<String, dynamic> meterUsageInfo in meterUsageList) {
          final meterUsageSummary = meterUsageInfo['meter_usage_summary'];
          String usageStr = meterUsageSummary['usage'];
          double? usage = double.tryParse(usageStr);
          if (usage == null) {
            dev.log('non-double usageStr $usageStr of $meterTypeTag');
            continue;
          }
          String percentageStr = meterUsageSummary['percentage'];
          double? percentage = double.tryParse(percentageStr);
          if (percentage == null) {
            dev.log('non-double percentageStr $percentageStr of $meterTypeTag');
            continue;
          }
          switch (meterTypeTag) {
            case 'E':
              totalAutoUsageE ??= 0;
              totalAutoUsageE += usage * percentage / 100;
              break;
            case 'W':
              totalAutoUsageW ??= 0;
              totalAutoUsageW += usage * percentage / 100;
              break;
            case 'B':
              totalAutoUsageB ??= 0;
              totalAutoUsageB += usage * percentage / 100;
              break;
            case 'N':
              totalAutoUsageN ??= 0;
              totalAutoUsageN += usage * percentage / 100;
              break;
            case 'G':
              totalAutoUsageG ??= 0;
              totalAutoUsageG += usage * percentage / 100;
              break;
          }
        }
      }

      _autoUsageHintE =
          totalAutoUsageE == null ? '-- ' : totalAutoUsageE.toStringAsFixed(3);

      _autoUsageHintW =
          totalAutoUsageW == null ? '-- ' : totalAutoUsageW.toStringAsFixed(3);

      _autoUsageHintB =
          totalAutoUsageB == null ? '-- ' : totalAutoUsageB.toStringAsFixed(3);

      _autoUsageHintN =
          totalAutoUsageN == null ? '-- ' : totalAutoUsageN.toStringAsFixed(3);

      _autoUsageHintG =
          totalAutoUsageG == null ? '-- ' : totalAutoUsageG.toStringAsFixed(3);

      setState(() {});
    } catch (err) {
      // setState(() {
      //   _errorText = 'Error generating bill';
      // });
      String errMsg = err.toString().toLowerCase();
      if (errMsg.contains('meter type rate') ||
          errMsg.contains('tariff supplied') ||
          errMsg.contains('incomplete usage data')) {
        _errorTextUsageHint = err.toString().replaceFirst('Exception: ', '');
      } else {
        _errorTextUsageHint = 'Error getting auto usage hint';
      }

      dev.log(err.toString());
    } finally {
      setState(() {
        _gettingAutoUsage = false;
      });
    }
  }

  Future<dynamic> _checkTpInfo(String typeStr, String tpId) async {
    if (_selectedFromDateTime == null || _selectedToDateTime == null) {
      dev.log('Please select date range');
      return;
    }

    _errorTextTp = '';
    // if (_queryTariffPackageComplete) {
    //   return;
    // }
    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser!.selectedScope.toScopeMap(),
      'tariff_package_id': tpId,
      'from_timestamp': _selectedFromDateTime!.toString(),
      'to_timestamp': _selectedToDateTime!.toString(),
      'is_time_slot': 'true',
      'meter_type': typeStr,
    };
    try {
      final tpInfo = await getTariffPackageTariffRateInfo(
        widget.appConfig,
        widget.loggedInUser!,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser!.username,
          userId: widget.loggedInUser!.id,
          target: '',
          scope: '',
          operation: '',
        ),
      );
      final tpRateList = tpInfo['tariff_package_tariff_rate_list'];
      if (tpRateList == null || tpRateList.isEmpty) {
        throw ItemNotFoundException(
            'no tariff package rate found for the selected date range');
      }
      if (tpRateList.length > 1) {
        dev.log(
            'more than 1 tariff package rate found for the selected date range');
        throw Exception(
            'more than 1 tariff package rate found for the selected date range');
      }
      final tpRateInfo = tpRateList.first;
      // Map<String, dynamic> tpRate = tpInfo;
      if (typeStr == 'E') {
        // _tariffPackageRateE.clear();
        _tariffPackageE['rate_info'] = tpRateInfo;
      } else if (typeStr == 'W') {
        // _tariffPackageW.clear();
        // _tariffPackageW.addAll(tpRate);
        _tariffPackageW['rate_info'] = tpRateInfo;
      } else if (typeStr == 'B') {
        // _tariffPackageB.clear();
        // _tariffPackageB.addAll(tpRate);
        _tariffPackageB['rate_info'] = tpRateInfo;
      } else if (typeStr == 'N') {
        // _tariffPackageN.clear();
        // _tariffPackageN.addAll(tpRate);
        _tariffPackageN['rate_info'] = tpRateInfo;
      } else if (typeStr == 'G') {
        // _tariffPackageN.clear();
        // _tariffPackageN.addAll(tpRate);
        _tariffPackageG['rate_info'] = tpRateInfo;
      }
    } catch (err) {
      if (err is ItemNotFoundException) {
        String errMsg =
            'no tariff package rate found for the selected date range';
        _errorTextTp = errMsg;
        if (typeStr == 'E') {
          // _tariffPackageE.clear();
          _tariffPackageE['error'] = errMsg;
        } else if (typeStr == 'W') {
          // _tariffPackageW.clear();
          _tariffPackageW['error'] = errMsg;
        } else if (typeStr == 'B') {
          // _tariffPackageB.clear();
          _tariffPackageB['error'] = errMsg;
        } else if (typeStr == 'N') {
          // _tariffPackageN.clear();
          _tariffPackageN['error'] = errMsg;
        } else if (typeStr == 'G') {
          // _tariffPackageN.clear();
          _tariffPackageG['error'] = errMsg;
        }
      } else {
        dev.log(err.toString());
        _errorTextTp = getErrorText(err,
            defaultErrorText: 'error checking tariff package rate info');
      }
    } finally {
      // setState(() {
      //   _queryTariffPackageComplete = true;
      // });
    }
  }

  void _resetTariffPackage() {
    setState(() {
      _queryTariffPackageComplete = false;
      // _tariffPackageList.clear();
      _totalTarriffPackageCount = 0;
      _showEmptyResultTariffPackage = false;
      _tariffPackageE.clear();
      _tariffPackageW.clear();
      _tariffPackageB.clear();
      _tariffPackageN.clear();
      _tariffPackageG.clear();
      _errorText = '';
      _errorTextTp = '';
      // _billResult.clear();
      _errorTextUsageHint = '';
      _tariffPackageOK = _durationOK && _useAssignedTps;
    });
  }

  void _resetManualUsage() {
    setState(() {
      _manualUsageE = null;
      _manualUsageW = null;
      _manualUsageB = null;
      _manualUsageN = null;
      _manualUsageG = null;
      // _manualRateE = null;
      // _manualRateW = null;
      // _manualRateB = null;
      // _manualRateN = null;
      // _manualRateG = null;
      _manualUsageErrorTextE = null;
      _manualUsageErrorTextW = null;
      _manualUsageErrorTextB = null;
      _manualUsageErrorTextN = null;
      _manualUsageErrorTextG = null;
      _usageOK = _durationOK && _useAutoUsage;
    });
  }

  void _updateTpRows() {
    if (_useAssignedTps) {
      //disable tp rows
      _tariffPackageE.clear();
      _tariffPackageW.clear();
      _tariffPackageB.clear();
      _tariffPackageN.clear();
      _tariffPackageG.clear();
      _tariffPackageOK = false;
    }
  }

  void _checkUsageOK() {
    if (_useAutoUsage) {
      _usageOK = true;
      _checkUsageCostOK();
      return;
    }

    bool ok = true;
    if (_tariffPackageE.isNotEmpty) {
      if (_manualUsageE == null) {
        ok = false;
      }
    }
    if (_tariffPackageW.isNotEmpty) {
      if (_manualUsageW == null) {
        ok = false;
      }
    }
    if (_tariffPackageB.isNotEmpty) {
      if (_manualUsageB == null) {
        ok = false;
      }
    }
    if (_tariffPackageN.isNotEmpty) {
      if (_manualUsageN == null) {
        ok = false;
      }
    }
    if (_tariffPackageG.isNotEmpty) {
      if (_manualUsageG == null) {
        ok = false;
      }
    }
    _usageOK = ok;
    _checkUsageCostOK();
  }

  void _checkUsageCostOK() {
    bool ok = false;
    if (_useAssignedTps) {
      if (_useAutoUsage) {
        ok = true;
      } else {
        if ((_manualUsageE != null && _manualUsageErrorTextE == null) ||
            (_manualUsageW != null && _manualUsageErrorTextW == null) ||
            (_manualUsageB != null && _manualUsageErrorTextB == null) ||
            (_manualUsageN != null && _manualUsageErrorTextN == null) ||
            (_manualUsageG != null && _manualUsageErrorTextG == null)) {
          ok = true;
        }
      }
    } else {
      if (_useAutoUsage) {
        bool ok2 = true;
        if (double.tryParse(_autoUsageHintE ?? '') == null &&
            double.tryParse(_autoUsageHintW ?? '') == null &&
            double.tryParse(_autoUsageHintB ?? '') == null &&
            double.tryParse(_autoUsageHintN ?? '') == null &&
            double.tryParse(_autoUsageHintG ?? '') == null) {
          ok2 = false;
        } else {
          if (_autoUsageHintE != null && _tariffPackageE.isEmpty) {
            ok2 = false;
          }
          if (_autoUsageHintW != null && _tariffPackageW.isEmpty) {
            ok2 = false;
          }
          if (_autoUsageHintB != null && _tariffPackageB.isEmpty) {
            ok2 = false;
          }
          if (_autoUsageHintN != null && _tariffPackageN.isEmpty) {
            ok2 = false;
          }
          if (_autoUsageHintG != null && _tariffPackageG.isEmpty) {
            ok2 = false;
          }
          ok = ok2;
        }
      } else {
        // if ((_tariffPackageE.isNotEmpty && _manualUsageE != null) ||
        //     (_tariffPackageW.isNotEmpty && _manualUsageW != null) ||
        //     (_tariffPackageB.isNotEmpty && _manualUsageB != null) ||
        //     (_tariffPackageN.isNotEmpty && _manualUsageN != null) ||
        //     (_tariffPackageG.isNotEmpty && _manualUsageG != null)) {
        //   ok = true;
        // }

        if ((_manualUsageE != null && _manualUsageErrorTextE == null) ||
            (_manualUsageW != null && _manualUsageErrorTextW == null) ||
            (_manualUsageB != null && _manualUsageErrorTextB == null) ||
            (_manualUsageN != null && _manualUsageErrorTextN == null) ||
            (_manualUsageG != null && _manualUsageErrorTextG == null)) {
          ok = true;
        }
      }
    }

    _usageCostOK = ok;
  }

  void _resetDuration({bool resetDateRange = false}) {
    setState(() {
      if (resetDateRange) {
        _selectedToDateTime = null;
        _selectedFromDateTime = null;
        _timePickerKey = UniqueKey();
        _customDateRangeSelected = false;
        _monthPicked = null;
        _isMTD = false;
      }
    });
  }

  void _resetAll() {
    _resetDuration(resetDateRange: true);
    _resetTariffPackage();
    _resetManualUsage();
  }

  void _checkSingularBillReady() {
    bool isReady = _durationOK && _tariffPackageOK && _usageOK;
    if (isReady) {
      singularBillinfo['from_timestamp'] = _selectedFromDateTime.toString();
      singularBillinfo['to_timestamp'] = _selectedToDateTime.toString();
      singularBillinfo['use_assigned_tps'] = _useAssignedTps.toString();
      singularBillinfo['use_auto_usage'] = _useAutoUsage.toString();

      if (_useAssignedTps) {
      } else {
        singularBillinfo['tariff_package_e'] = _tariffPackageE;
        singularBillinfo['tariff_package_w'] = _tariffPackageW;
        singularBillinfo['tariff_package_b'] = _tariffPackageB;
        singularBillinfo['tariff_package_n'] = _tariffPackageN;
        singularBillinfo['tariff_package_g'] = _tariffPackageG;
      }

      if (_useAutoUsage) {
      } else {
        singularBillinfo['manual_usage_e'] = _manualUsageE;
        singularBillinfo['manual_usage_w'] = _manualUsageW;
        singularBillinfo['manual_usage_b'] = _manualUsageB;
        singularBillinfo['manual_usage_n'] = _manualUsageN;
        singularBillinfo['manual_usage_g'] = _manualUsageG;
        // singularBillinfo['manual_rate_e'] = _manualRateE;
        // singularBillinfo['manual_rate_w'] = _manualRateW;
        // singularBillinfo['manual_rate_b'] = _manualRateB;
        // singularBillinfo['manual_rate_n'] = _manualRateN;
        // singularBillinfo['manual_rate_g'] = _manualRateG;
      }
    }

    if (widget.onChanged != null) {
      singularBillinfo['is_ready'] = isReady;
      widget.onChanged!(widget.singularBillKey, singularBillinfo);
    }
  }

  @override
  void initState() {
    super.initState();

    _selectedFromDateTime = widget.fromDateTime;
    _selectedToDateTime = widget.toDateTime;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.sidePadding,
      child: getSingluarBill(),
    );
  }

  Widget getSingluarBill() {
    return Container(
      width: widget.width ?? MediaQuery.of(context).size.width - 130,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor, width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 13),
      child: Column(
        children: [
          getTimeRangePicker(),
          getDurationBox(),
          const Divider(thickness: 0.5),
          getTpLsBox(),
          verticalSpaceTiny,
          getTpInfoBox(),
          verticalSpaceSmall,
          getUsageOptionBox(),
          verticalSpaceSmall,
          getManualUsageBox(),
          verticalSpaceTiny,
          getCheckers(),
        ],
      ),
    );
  }

  Widget getTimeRangePicker() {
    return WgtPagDateRangePickerMonthly(
      // key: _timePickerKey,
      iniStartDateTime: _selectedFromDateTime,
      iniEndDateTime: _selectedToDateTime,
      maxDurationDays: 500,
      maxSelectionDurationDays: 31,
      customRangeSelected: _customDateRangeSelected,
      monthPicked: _monthPicked,
      populateDefaultRange: false,
      onRangeSet: (startDate, endDate) async {
        if (startDate == null || endDate == null) return;
        _resetDuration(resetDateRange: true);

        endDate = DateTime(endDate.year, endDate.month, endDate.day, 0, 0, 0, 0)
            .add(const Duration(days: 1));
        dev.log(
            'selected date range: ${startDate.toString()} to ${endDate.toString()}');

        // align to mid night
        startDate = DateTime(
            startDate.year, startDate.month, startDate.day, 0, 0, 0, 0);
        setState(() {
          _selectedFromDateTime = startDate;
          _selectedToDateTime = endDate;

          _customDateRangeSelected = true;
          _isMTD = false;
          _monthPicked = null;

          _durationOK = true;

          _checkUsageCostOK();

          _resetTariffPackage();
          _resetManualUsage();
          _checkSingularBillReady();
        });
      },
      onMonthPicked: (selected) {
        _resetDuration(resetDateRange: true);
        setState(() {
          // _timePickerKey = UniqueKey();
          _monthPicked = selected;
          _selectedFromDateTime = DateTime(selected.year, selected.month, 1);
          final month = selected.month < 12 ? selected.month + 1 : 1;
          final year = selected.month < 12 ? selected.year : selected.year + 1;
          _selectedToDateTime = DateTime(year, month, 1);
          // _customRange = false;
          DateTime localNow = getTargetLocalDatetimeNow(
              widget.loggedInUser!.selectedScope.getProjectTimezone());
          _isMTD = false;
          if (localNow.year == selected.year &&
              localNow.month == selected.month) {
            _isMTD = true;
          }

          _durationOK = true;

          _checkUsageCostOK();

          _resetTariffPackage();
          _resetManualUsage();
          _checkSingularBillReady();
        });
      },
    );
  }

  Widget getDurationBox() {
    if (_selectedFromDateTime == null || _selectedToDateTime == null) {
      return Container();
    }
    String fromDateTimeStr = _selectedFromDateTime.toString().substring(0, 10);
    String toDateTimeStr = _selectedToDateTime.toString().substring(0, 10);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).hintColor.withAlpha(55),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          getTypeTag('Duration'),
          horizontalSpaceSmall,
          Text('From: $fromDateTimeStr To: $toDateTimeStr'),
        ],
      ),
    );
  }

  Widget getTpLsBox() {
    if (_useAssignedTps || !_useAutoUsage) {
      return Container();
    }
    List<String> meterTypeTagList = widget
        .loggedInUser!.selectedScope.projectProfile!
        .getPortalMeterTypeTagList();
    // remove 'SE1' from the list
    meterTypeTagList.remove('SE1');

    List<Widget> tpLsWidgets = [];
    for (var meterTypeTag in meterTypeTagList) {
      tpLsWidgets.add(Row(
        children: [
          SizedBox(width: 45, child: getTypeTag(meterTypeTag)),
          horizontalSpaceTiny,
          WgtListSearchItemFlexi(
            appConfig: widget.appConfig,
            widthOffset: -135,
            // initialFilterMap: {
            //   'meter_type': meterTypeTag,
            // },
            initialFilterGroupType: PagFilterGroupType.spec,
            pagAppContext: widget.appContext,
            // itemKind: PagItemKind.tariffPackage,
            itemKind: PagItemKind.tariff,
            listContextType: PagListContextType.info,
            isSingleItemMode: true,
            showList: false,
            prefKey: '${widget.appContext.route}_tp',
            hint: 'Select Tariff Package',
            onResult: (Map<String, dynamic> itemFindResult) async {
              Map<String, dynamic> result = itemFindResult;
              if (result.isEmpty) {
                setState(() {
                  _isSearchingTariffPackage = false;
                });
              } else {
                // _tariffPackageList.clear();
                List<Map<String, dynamic>> itemList = result['item_list'];
                // for (var item in itemList) {
                //   _tariffPackageList.add(item);
                // }
                if (itemList.length == 1) {
                  String type = itemList.first['meter_type'];
                  if (type == 'E') {
                    _tariffPackageE.clear();
                    _tariffPackageE.addAll(itemList.first);
                    await _checkTpInfo(type, _tariffPackageE['id']);
                  } else if (type == 'W') {
                    _tariffPackageW.clear();
                    _tariffPackageW.addAll(itemList.first);
                    await _checkTpInfo(type, _tariffPackageW['id']);
                  } else if (type == 'B') {
                    _tariffPackageB.clear();
                    _tariffPackageB.addAll(itemList.first);
                    await _checkTpInfo(type, _tariffPackageB['id']);
                  } else if (type == 'N') {
                    _tariffPackageN.clear();
                    _tariffPackageN.addAll(itemList.first);
                    await _checkTpInfo(type, _tariffPackageN['id']);
                  } else if (type == 'G') {
                    _tariffPackageG.clear();
                    _tariffPackageG.addAll(itemList.first);
                    await _checkTpInfo(type, _tariffPackageG['id']);
                  }
                }

                setState(() {
                  _totalTarriffPackageCount = itemList.length;
                  // _itemSelectQuery = result['id_select_query'];
                  // _queryMap = result['query_map'];

                  _showEmptyResultTariffPackage = false;
                  if (_totalTarriffPackageCount == 0) {
                    _showEmptyResultTariffPackage = true;
                  }
                  _isSearchingTariffPackage = false;
                  _queryTariffPackageComplete = true;

                  _tariffPackageOK = true;
                  _checkSingularBillReady();
                });
              }
            },
          ),
        ],
      ));
      // tpLsWidgets.add(verticalSpaceSmall);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _showTpSelector = !_showTpSelector;
                });
              },
              child: Icon(
                _showTpSelector ? Icons.arrow_drop_down : Icons.arrow_right,
                size: 30,
              ),
            ),
            horizontalSpaceSmall,
            getTypeTag('Tariff Package'),
            horizontalSpaceTiny,
            const Text('Select tariff package(s) for the selected duration'),
          ],
        ),
        verticalSpaceSmall,
        if (_showTpSelector)
          Column(
            children: [
              ...tpLsWidgets,
            ],
          ),
      ],
    );
  }

  Widget getTpInfoBox() {
    if (!_durationOK) {
      return Container();
    }
    if (_errorTextTp.isNotEmpty) {
      return getErrorTextPrompt(context: context, errorText: _errorTextTp);
    }
    EdgeInsets padding = const EdgeInsets.all(0);
    return !_queryTariffPackageComplete
        ? Container()
        : _totalTarriffPackageCount == 0
            ? const EmptyResult(
                width: 250, height: 50, message: 'No tariff package found')
            : _totalTarriffPackageCount > 1
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
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
                            'More than 1 tariff package found, please refine your search.',
                        textStyle: TextStyle(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_tariffPackageE.isNotEmpty)
                        Padding(
                          padding: padding,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).hintColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              // mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                getTypeTag('E'),
                                horizontalSpaceSmall,
                                Text(
                                    '${_tariffPackageE['name']}${_tariffPackageE['label'] == null ? '' : ' - ${_tariffPackageE['label']}'} (${_tariffPackageE['tpt_label']}, ${_tariffPackageE['tpt_cat']})'),
                                horizontalSpaceSmall,
                                getCheckTpRateInfo('E'),
                              ],
                            ),
                          ),
                        ),
                      if (_tariffPackageW.isNotEmpty)
                        Padding(
                          padding: padding,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).hintColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              // mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                getTypeTag('W'),
                                horizontalSpaceSmall,
                                Text(
                                    '${_tariffPackageW['name']}${_tariffPackageW['label'] == null ? '' : ' - ${_tariffPackageW['label']}'}'),
                                horizontalSpaceSmall,
                                getCheckTpRateInfo('W'),
                              ],
                            ),
                          ),
                        ),
                      if (_tariffPackageB.isNotEmpty)
                        Padding(
                          padding: padding,
                          child: Container(
                            padding: const EdgeInsets.all(8),
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
                                getTypeTag('B'),
                                horizontalSpaceSmall,
                                Text(
                                    '${_tariffPackageB['name']}${_tariffPackageB['label'] == null ? '' : ' - ${_tariffPackageB['label']}'}'),
                                horizontalSpaceSmall,
                                getCheckTpRateInfo('B'),
                              ],
                            ),
                          ),
                        ),
                      if (_tariffPackageN.isNotEmpty)
                        Padding(
                          padding: padding,
                          child: Container(
                            padding: const EdgeInsets.all(8),
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
                                getTypeTag('N'),
                                horizontalSpaceSmall,
                                Text(
                                    '${_tariffPackageN['name']}${_tariffPackageN['label'] == null ? '' : ' - ${_tariffPackageN['label']}'}'),
                                horizontalSpaceSmall,
                                getCheckTpRateInfo('N'),
                              ],
                            ),
                          ),
                        ),
                      if (_tariffPackageG.isNotEmpty)
                        Padding(
                          padding: padding,
                          child: Container(
                            padding: const EdgeInsets.all(8),
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
                                getTypeTag('G'),
                                horizontalSpaceSmall,
                                Text(
                                    '${_tariffPackageG['name']}${_tariffPackageG['label'] == null ? '' : ' - ${_tariffPackageG['label']}'}'),
                                horizontalSpaceSmall,
                                getCheckTpRateInfo('G'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
  }

  Widget getCheckTpRateInfo(String type) {
    Map<String, dynamic> tariffPackage = {};
    switch (type) {
      case 'E':
        tariffPackage = _tariffPackageE;
      case 'W':
        tariffPackage = _tariffPackageW;
      case 'B':
        tariffPackage = _tariffPackageB;
      case 'N':
        tariffPackage = _tariffPackageN;
      case 'G':
        tariffPackage = _tariffPackageG;
      default:
        // return Container();
        tariffPackage = {};
    }

    if (tariffPackage.isEmpty) {
      return Text(
        'No tariff package selected',
        style: TextStyle(
          color: Theme.of(context).hintColor,
        ),
      );
    }
    if (tariffPackage['error'] != null) {
      return Text(
        tariffPackage['error'],
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }
    if (tariffPackage['rate_info'] == null) {
      return Text(
        'No rate info found',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }
    String rate = tariffPackage['rate_info']['rate'];
    String gstStr = tariffPackage['rate_info']['gst'];
    double gst = double.parse(gstStr);
    String fromTimestamp = tariffPackage['rate_info']['from_timestamp'];
    String toTimestamp = tariffPackage['rate_info']['to_timestamp'];
    return Text(
      'Rate: $rate, GST: ${gst.toStringAsFixed(0)}% From: ${fromTimestamp.substring(0, 10)} To: ${toTimestamp.substring(0, 10)}',
      style: TextStyle(
        color: Theme.of(context).hintColor,
      ),
    );
  }

  Widget getUsageOptionBox() {
    if (!_durationOK) {
      return Container();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        getAutoUageHintButton(),
        //checkbox
        Row(
          children: [
            Checkbox(
              value: _useAssignedTps,
              onChanged: (value) {
                setState(() {
                  _useAssignedTps = value!;
                  _updateTpRows();
                  _tariffPackageOK = true;
                  _checkSingularBillReady();
                });
              },
            ),
            const Text('Use Assigned TPs'),
            horizontalSpaceSmall,
            Checkbox(
              value: _useAutoUsage,
              onChanged: (value) {
                setState(() {
                  _useAutoUsage = value!;
                  _resetManualUsage();
                  _checkSingularBillReady();
                });
              },
            ),
            const Text('Use auto usage'),
          ],
        ),
      ],
    );
  }

  Widget getManualUsageBox() {
    if (_useAutoUsage) {
      return Container();
    }
    if (!_durationOK) {
      return Container();
    }
    return Container(
      // width: 350,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).hintColor.withAlpha(55),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text('* Please put value AFTER usage factor applied',
                  style: TextStyle(color: Theme.of(context).hintColor)),
              verticalSpaceSmall,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  getUsageHint(_autoUsageHintE ?? ''),
                  getTypeTag('E'),
                  horizontalSpaceSmall,
                  SizedBox(
                    width: 185,
                    child: WgtTextField(
                      appConfig: widget.appConfig,
                      initialValue:
                          _manualUsageE == null ? '' : _manualUsageE.toString(),
                      labelText: 'Manual E Usage (kWh)',
                      hintText: 'Enter E usage (kWh)',
                      validateOnChange: false,
                      onChanged: (value) {
                        setState(() {
                          _manualUsageE = double.tryParse(value);
                          // _checkUsageOK();
                          // _checkSingularBillReady();
                        });
                      },
                      onEditingComplete: () {
                        _checkUsageOK();
                        _checkSingularBillReady();
                      },
                      onClear: () {
                        setState(() {
                          _manualUsageE = null;
                          _manualUsageErrorTextE = null;
                        });
                      },
                      validator: usageValidator,
                      onValidate: (result) {
                        setState(() {
                          _inputErrorText = result;
                          _manualUsageErrorTextE = result;
                        });

                        _checkUsageOK();
                        _checkSingularBillReady();

                        if (result == null) {
                          return;
                        }
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  getUsageHint(_autoUsageHintW),
                  getTypeTag('W'),
                  horizontalSpaceSmall,
                  SizedBox(
                    width: 185,
                    child: WgtTextField(
                      appConfig: widget.appConfig,
                      labelText: 'Manual W Usage (Cu M)',
                      hintText: 'Enter W usage (Cu M)',
                      validateOnChange: false,
                      onChanged: (value) {
                        setState(() {
                          _manualUsageW = double.tryParse(value);
                          // _checkUsageOK();
                        });
                      },
                      onEditingComplete: () {
                        _checkUsageOK();
                        _checkSingularBillReady();
                      },
                      onClear: () {
                        setState(() {
                          _manualUsageW = null;
                          _manualUsageErrorTextW = null;
                        });
                      },
                      validator: usageValidator,
                      onValidate: (result) {
                        setState(() {
                          _inputErrorText = result;
                          _manualUsageErrorTextW = result;
                        });

                        _checkUsageOK();
                        _checkSingularBillReady();

                        if (result == null) {
                          return;
                        }
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  getUsageHint(_autoUsageHintB),
                  getTypeTag('B'),
                  horizontalSpaceSmall,
                  SizedBox(
                    width: 185,
                    child: WgtTextField(
                      appConfig: widget.appConfig,
                      initialValue:
                          _manualUsageB == null ? '' : _manualUsageB.toString(),
                      labelText: 'Manual B Usage (kWh)',
                      hintText: 'Enter B usage (kWh)',
                      validateOnChange: false,
                      onChanged: (value) {
                        setState(() {
                          _manualUsageB = double.tryParse(value);
                          // _checkUsageOK();
                          // _checkSingularBillReady();
                        });
                      },
                      onEditingComplete: () {
                        _checkUsageOK();
                        _checkSingularBillReady();
                      },
                      onClear: () {
                        setState(() {
                          _manualUsageB = null;
                          _manualUsageErrorTextB = null;
                        });
                      },
                      validator: usageValidator,
                      onValidate: (result) {
                        setState(() {
                          _inputErrorText = result;
                          _manualUsageErrorTextB = result;
                        });

                        _checkUsageOK();
                        _checkSingularBillReady();

                        if (result == null) {
                          return;
                        }
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  getUsageHint(_autoUsageHintN),
                  getTypeTag('N'),
                  horizontalSpaceSmall,
                  SizedBox(
                    width: 185,
                    child: WgtTextField(
                      appConfig: widget.appConfig,
                      initialValue:
                          _manualUsageN == null ? '' : _manualUsageN.toString(),
                      labelText: 'Manual N Usage (Cu M)',
                      hintText: 'Enter N usage (Cu M)',
                      validateOnChange: false,
                      onChanged: (value) {
                        setState(() {
                          _manualUsageN = double.tryParse(value);
                          // _checkUsageOK();
                          // _checkSingularBillReady();
                        });
                      },
                      onEditingComplete: () {
                        _checkUsageOK();
                        _checkSingularBillReady();
                      },
                      onClear: () {
                        setState(() {
                          _manualUsageN = null;
                          _manualUsageErrorTextN = null;
                        });
                      },
                      validator: usageValidator,
                      onValidate: (result) {
                        setState(() {
                          _inputErrorText = result;
                          _manualUsageErrorTextN = result;
                        });

                        _checkUsageOK();
                        _checkSingularBillReady();

                        if (result == null) {
                          return;
                        }
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  getUsageHint(_autoUsageHintG),
                  getTypeTag('G'),
                  horizontalSpaceSmall,
                  SizedBox(
                    width: 185,
                    child: WgtTextField(
                      appConfig: widget.appConfig,
                      initialValue:
                          _manualUsageG == null ? '' : _manualUsageG.toString(),
                      labelText: 'Manual G Usage (kWh)',
                      hintText: 'Enter G usage (kWh)',
                      validateOnChange: false,
                      onChanged: (value) {
                        setState(() {
                          _manualUsageG = double.tryParse(value);
                          // _checkUsageOK();
                          // _checkSingularBillReady();
                        });
                      },
                      onEditingComplete: () {
                        _checkUsageOK();
                        _checkSingularBillReady();
                      },
                      onClear: () {
                        setState(() {
                          _manualUsageG = null;
                          _manualUsageErrorTextG = null;
                        });
                      },
                      validator: usageValidator,
                      onValidate: (result) {
                        setState(() {
                          _inputErrorText = result;
                          _manualUsageErrorTextG = result;
                        });

                        _checkUsageOK();
                        _checkSingularBillReady();

                        if (result == null) {
                          return;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  double maxUsage = 10000000;
  String? usageValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    //positive number
    if (double.parse(value) < 0) {
      return 'Please enter a positive number';
    }
    // check max usage
    if (double.parse(value) > maxUsage) {
      return 'Please enter a value less than $maxUsage';
    }
    return null;
  }

  String? rateValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    //positive number
    if (double.parse(value) < 0) {
      return 'Please enter a positive number';
    }
    return null;
  }

  Widget getAutoUageHintButton() {
    if (_useAutoUsage) {
      return Container();
    }
    if (_errorTextUsageHint.isNotEmpty) {
      return getErrorTextPrompt(
          context: context, errorText: _errorTextUsageHint, margin: 13);
    }
    bool tenantOK = true;
    bool durationOK =
        _selectedFromDateTime != null && _selectedToDateTime != null;
    return //button
        InkWell(
      onTap:
          !durationOK || !tenantOK || _gettingAutoUsage ? null : _getAutoUsage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(192),
          borderRadius: BorderRadius.circular(5),
        ),
        child: _gettingAutoUsage
            ? xtWait(
                color: Theme.of(context).colorScheme.onSurface,
              )
            : Text('Get Auto Usage Hint',
                style: TextStyle(
                  color: !durationOK || !tenantOK
                      ? Theme.of(context).hintColor
                      : Theme.of(context).colorScheme.onSurface,
                )),
      ),
    );
  }

  Widget getUsageHint(String? usageStr) {
    String displayStr = usageStr ?? '';
    double stringDisplaySize = 1.116 *
        getStringDisplaySize(displayStr, const TextStyle(fontSize: 15)).width;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 120,
        child: Align(
          alignment: Alignment.centerRight,
          child: WgtPopupButton(
            width: stringDisplaySize,
            height: 20,
            direction: 'right',
            popupWidth: 90,
            popupHeight: 30,
            // backgroundColor: Theme.of(context).colorScheme.primary,
            //  Colors.green.shade700,
            popupChild: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withAlpha(21),
                border: Border.all(
                  color: Theme.of(context).hintColor.withAlpha(75),
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).hintColor.withAlpha(21),
                    spreadRadius: 0,
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Align(
                alignment: Alignment.center,
                child: Text('Copied'),
              ),
            ),
            child: Text(
              displayStr,
              style: TextStyle(
                color: Theme.of(context).hintColor,
              ),
            ),
            onTap: () {
              Clipboard.setData(ClipboardData(text: displayStr));
            },
          ),
        ),
      ),
    );
  }

  Widget getTypeTag(String type) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(128),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(type),
    );
  }

  Widget getCheckers() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      xtInfoBox(
          iconTextSpace: 3,
          icon: _durationOK
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  Icons.pending,
                  color: Theme.of(context).hintColor,
                ),
          text: 'Duration'),
      xtInfoBox(
        iconTextSpace: 3,
        icon: _tariffPackageOK
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : Icon(
                Icons.pending,
                color: Theme.of(context).hintColor,
              ),
        text: 'Tariff Package',
      ),
      xtInfoBox(
          iconTextSpace: 3,
          icon: _usageOK
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  Icons.pending,
                  color: Theme.of(context).hintColor,
                ),
          text: 'Usage'),
      xtInfoBox(
          iconTextSpace: 3,
          icon: _usageCostOK
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  Icons.pending,
                  color: Theme.of(context).hintColor,
                ),
          text: 'Usage Cost'),
    ]);
  }
}
