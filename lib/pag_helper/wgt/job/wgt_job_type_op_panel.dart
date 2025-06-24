import 'dart:async';

import 'package:buff_helper/pag_helper/comm/comm_pag_job.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/pag_helper/wgt/datetime/wgt_date_range_picker_monthly.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/mdl_pag_app_config.dart';

class WgtJobTypeOpPanel extends StatefulWidget {
  const WgtJobTypeOpPanel({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.itemDisplayName,
    required this.jobTypeName,
    required this.jobTaskType,
    this.jobScopeLabel,
    this.jobTypeScope,
    this.listController,
    this.onClose,
    this.onUpdate,
    this.onScopeTreeUpdate,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final String itemDisplayName;
  final String jobTypeName;
  final String jobTaskType;
  final String? jobScopeLabel;
  final MdlPagScope? jobTypeScope;
  final MdlPagListController? listController;

  final Function? onClose;
  final Function? onUpdate;
  final Function? onScopeTreeUpdate;

  @override
  State<WgtJobTypeOpPanel> createState() => _WgtJobTypeOpPanelState();
}

class _WgtJobTypeOpPanelState extends State<WgtJobTypeOpPanel> {
  late MdlPagUser? _loggedInUser;

  final double _width = 500;

  String? _itemDisplayName;
  final List<Widget> fields = [];

  UniqueKey? _timePickerKey;
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  bool _customDateRangeSelected = false;
  bool _isMTD = false;
  DateTime? _monthPicked;

  bool _isPosting = false;
  bool _postDone = false;
  String _postResultErrorText = '';

  bool _mainMeterSelected = true;
  bool _subMeterSelected = true;

  Future<dynamic> _triggerJob() async {
    if (_isPosting) return;

    setState(() {
      _isPosting = true;
      _postDone = false;
      _postResultErrorText = '';
    });

    // align to_timestamp to end of day
    _selectedToDate = DateTime(_selectedToDate!.year, _selectedToDate!.month,
        _selectedToDate!.day, 23, 59, 59);

    try {
      Map<String, dynamic> jobScope = widget.jobTypeScope?.toScopeMap() ??
          widget.loggedInUser.selectedScope.toScopeMap();
      Map<String, dynamic> queryMap = {
        'scope': jobScope,
        'job_request': {
          'job_type': widget.jobTypeName,
          'job_task_type': widget.jobTaskType,
          'scope_prefix': widget.jobScopeLabel ?? '',
          'from_timestamp': _selectedFromDate!.toIso8601String(),
          'to_timestamp': _selectedToDate!.toIso8601String(),
          // 'main_meter_only': 'true',
          'is_monthly': _monthPicked != null ? 'true' : 'false',
          'main_sub_str': _mainMeterSelected && _subMeterSelected
              ? 'main,sub'
              : _mainMeterSelected
                  ? 'main'
                  : 'sub',
        },
        'op_list': [],
      };

      var result = await doPagPostJob(
        widget.appConfig,
        _loggedInUser,
        queryMap,
        MdlPagSvcClaim(
          username: _loggedInUser!.username,
          userId: _loggedInUser!.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      return result;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      _postResultErrorText = 'Error posting task';
      if (e is TooManyRequestsException) {
        String remainingMillisStr = e.message;
        int remainingMillis = int.tryParse(remainingMillisStr) ?? -1;
        _postResultErrorText = 'Too many requests';
        if (remainingMillis > 0) {
          _postResultErrorText =
              'This task is in cooldown with ${(remainingMillis / 1000).toStringAsFixed(0)} seconds remaining';
        }
      }
    } finally {
      setState(() {
        _postDone = true;
        _isPosting = false;
      });
    }
  }

  void _reset({bool resetDateRange = false}) {
    setState(() {
      if (resetDateRange) {
        _selectedToDate = null;
        _selectedFromDate = null;
        _timePickerKey = UniqueKey();
        _customDateRangeSelected = false;
        _monthPicked = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;
    _itemDisplayName = widget.itemDisplayName;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _itemDisplayName ?? '',
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    horizontalSpaceMedium,
                  ],
                ),
              ],
            ),
            // verticalSpaceSmall,
            const Divider(height: 1),
            verticalSpaceSmall,
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).hintColor.withAlpha(50)),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              width: _width,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Time Range',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 16,
                        ),
                      ),
                      horizontalSpaceSmall,
                      WgtPagDateRangePickerMonthly(
                        // key: _timePickerKey,
                        iniEndDateTime: _selectedToDate,
                        iniStartDateTime: _selectedFromDate,
                        customRangeSelected: _customDateRangeSelected,
                        monthPicked: _monthPicked,
                        populateDefaultRange: false,
                        onRangeSet: (startDate, endDate) async {
                          if (startDate == null || endDate == null) return;
                          _reset(resetDateRange: true);
                          setState(() {
                            _selectedFromDate = startDate;
                            _selectedToDate = endDate;

                            _customDateRangeSelected = true;
                            _isMTD = false;
                            _monthPicked = null;

                            // _timePickerKey = UniqueKey();
                          });
                        },
                        onMonthPicked: (selected) {
                          _reset(resetDateRange: true);
                          setState(() {
                            // _timePickerKey = UniqueKey();
                            _monthPicked = selected;
                            _selectedFromDate =
                                DateTime(selected.year, selected.month, 1);
                            _selectedToDate =
                                DateTime(selected.year, selected.month + 1, 0);
                            // _customRange = false;
                            DateTime localNow = getTargetLocalDatetimeNow(widget
                                .loggedInUser.selectedScope
                                .getProjectTimezone());
                            _isMTD = false;
                            if (localNow.year == selected.year &&
                                localNow.month == selected.month) {
                              _isMTD = true;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            verticalSpaceSmall,
            getMainMeterSwitcher(),
            verticalSpaceSmall,
            getTirggerButton(),
            verticalSpaceSmall,
            getresultText(),
            verticalSpaceRegular,
          ],
        ),
      ),
    );
  }

  Widget getMainMeterSwitcher() {
    bool enableMainMeterSelect = true;
    if (!_subMeterSelected && _mainMeterSelected) {
      enableMainMeterSelect = false;
    }
    bool enableSubMeterSelect = true;
    if (!_mainMeterSelected && _subMeterSelected) {
      enableSubMeterSelect = false;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(180),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            spreadRadius: 3,
            blurRadius: 5,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _mainMeterSelected,
                onChanged: !enableMainMeterSelect
                    ? null
                    : (value) {
                        setState(() {
                          _mainMeterSelected = value!;
                        });
                        // widget.onUpdateMainSubMeterSel?.call({
                        //   'main': value!,
                        //   'sub': _subMeterSelected,
                        // });
                      },
              ),
              Text('Main',
                  style: TextStyle(
                      color: enableMainMeterSelect
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withAlpha(130))),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _subMeterSelected,
                onChanged: !enableSubMeterSelect
                    ? null
                    : (value) {
                        setState(() {
                          _subMeterSelected = value!;
                        });
                        // widget.onUpdateMainSubMeterSel?.call({
                        //   'main': _mainMeterSelected,
                        //   'sub': value!,
                        // });
                      },
              ),
              Text('Sub',
                  style: TextStyle(
                      color: enableSubMeterSelect
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withAlpha(130))),
            ],
          ),
        ],
      ),
    );
  }

  Widget getresultText() {
    if (_postDone) {
      if (_postResultErrorText.isNotEmpty) {
        return getErrorTextPrompt(
            context: context, errorText: _postResultErrorText);
      } else {
        return Text(
          'Task submitted successfully',
          style: TextStyle(color: Theme.of(context).hintColor),
        );
      }
    } else {
      return const SizedBox();
    }
  }

  Widget getTirggerButton() {
    bool enableSubmit = _selectedFromDate != null && _selectedToDate != null;
    if (_isPosting || _postDone || _postResultErrorText.isNotEmpty) {
      enableSubmit = false;
    }

    return Container(
      decoration: BoxDecoration(
        color: !enableSubmit
            ? Theme.of(context).colorScheme.secondary.withAlpha(55)
            : Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: !enableSubmit
                ? null
                : () async {
                    await _triggerJob();
                    // Timer.periodic(const Duration(milliseconds: 300), (timer) {
                    //   Navigator.of(context).pop();
                    // });
                  },
            child: Text('Submit Task',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary)),
          ),
          if (_isPosting)
            const Padding(
              padding: EdgeInsets.only(left: 5),
              child: WgtPagWait(size: 21),
            ),
        ],
      ),
    );
  }
}
