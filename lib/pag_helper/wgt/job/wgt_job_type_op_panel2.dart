import 'dart:async';
import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_pag_job.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/pag_helper/wgt/datetime/wgt_date_range_picker_monthly.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/datetime/wgt_date_picker.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/mdl_pag_app_config.dart';

class WgtJobTypeOpPanel2 extends StatefulWidget {
  const WgtJobTypeOpPanel2({
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
  State<WgtJobTypeOpPanel2> createState() => _WgtJobTypeOpPanel2State();
}

class _WgtJobTypeOpPanel2State extends State<WgtJobTypeOpPanel2> {
  late MdlPagUser? _loggedInUser;

  final double width = 550;

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

  DateTime? _selectedDate1;
  DateTime? _selectedDate2;
  UniqueKey? _date1PickerKey;
  UniqueKey? _date2PickerKey;

  DateTime? _collectionStartDate;
  bool _useCustomCollectionStartDate = false;
  UniqueKey? _timePickerKeyCollectionStartDate;

  String? _selectedLcStatusStr;

  bool _isOption1 = false;

  Future<dynamic> _triggerJob() async {
    if (_isPosting) return;

    setState(() {
      _isPosting = true;
      _postDone = false;
      _postResultErrorText = '';
    });

    // align to the midnight of the next day
    if (_selectedToDate != null) {
      _selectedToDate = DateTime(_selectedToDate!.year, _selectedToDate!.month,
          _selectedToDate!.day + 1, 0, 0, 0);
    }

    try {
      Map<String, dynamic> jobScope = widget.jobTypeScope?.toScopeMap() ??
          widget.loggedInUser.selectedScope.toScopeMap();

      Map<String, String> jobRequest = {
        'job_type': widget.jobTypeName,
        'job_task_type': widget.jobTaskType,
        'scope_prefix': widget.jobScopeLabel ?? '',
      };
      if (_selectedDate1 != null) {
        jobRequest['selected_timestamp'] = _selectedDate1!.toIso8601String();
      }
      if (_selectedDate2 != null) {
        jobRequest['selected_timestamp_2'] = _selectedDate2!.toIso8601String();
      }
      if (_collectionStartDate != null) {
        jobRequest['collection_start_date_timestamp'] =
            _collectionStartDate!.toIso8601String();
      }
      if ((_selectedFromDate) != null && (_selectedToDate) != null) {
        jobRequest['from_timestamp'] = _selectedFromDate!.toIso8601String();
        jobRequest['to_timestamp'] = _selectedToDate!.toIso8601String();
      }
      jobRequest['main_sub_str'] = _mainMeterSelected && _subMeterSelected
          ? 'main,sub'
          : _mainMeterSelected
              ? 'main'
              : 'sub';
      if (_selectedLcStatusStr != null) {
        jobRequest['target_lc_status'] = _selectedLcStatusStr!;
      }

      jobRequest['is_option_1'] = _isOption1.toString();

      Map<String, dynamic> queryMap = {
        'scope': jobScope,
        'job_request': jobRequest,
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
      dev.log(e.toString());

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

  void _resetDate({bool resetDateRange = false}) {
    setState(() {
      if (resetDateRange) {
        _selectedToDate = null;
        _selectedFromDate = null;
        _timePickerKey = UniqueKey();
        _customDateRangeSelected = false;
        _monthPicked = null;
        _isMTD = false;
        _selectedDate1 = null;
      }
    });
  }

  bool _checkEnableSubmit() {
    switch (widget.jobTaskType) {
      case 'usage-report' || 'meter-reading-report-consolidated':
      case 'tenant-usage-report':
        return _selectedFromDate != null && _selectedToDate != null;
      case 'billing-task':
        bool ok = _selectedFromDate != null &&
            _selectedToDate != null &&
            _selectedDate1 != null &&
            _selectedDate2 != null;
        if (_useCustomCollectionStartDate) {
          if (_collectionStartDate == null) {
            ok = false;
          }
        }
        return ok;
      case 'giro-file':
        return _selectedFromDate != null && _selectedToDate != null;

      case 'bill-lc-status-update':
        if (_isOption1) {
          return _selectedLcStatusStr != null;
        } else {
          return _selectedFromDate != null &&
              _selectedToDate != null &&
              _selectedLcStatusStr != null;
        }
      case 'payment-lc-status-update':
        return _selectedFromDate != null &&
            _selectedToDate != null &&
            _selectedLcStatusStr != null;
      case 'gen-payment-matching-form':
        return true;
      default:
        return false;
    }
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
      width: width,
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
            const Divider(height: 1),
            verticalSpaceSmall,
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).hintColor.withAlpha(50)),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              width: width,
              child: getOptions(),
            ),
            verticalSpaceSmall,
            getTriggerButton(),
            verticalSpaceSmall,
            getResultText(),
            verticalSpaceRegular,
          ],
        ),
      ),
    );
  }

  Widget getOptions() {
    switch (widget.jobTaskType) {
      case 'usage-report' || 'meter-reading-report-consolidated':
        return getUsageReportOptions();
      case 'tenant-usage-report':
        return getTenantUsageReportOptions();
      case 'billing-task':
        return getBillingTaskOptions();
      case 'giro-file':
        return getGiroFileOptions();
      case 'billing-report':
        return getBillingReportOptions();
      case 'bill-lc-status-update':
        return getBillLcStatusUpdateOptions();
      case 'payment-lc-status-update':
        return getPaymentLcStatusUpdateOptions();
      case 'gen-payment-matching-form':
        return genPaymentMatchingFormOptions();
      default:
        return const SizedBox();
    }
  }

  Widget getBillingTaskOptions() {
    DateTime? leftMostDate;
    DateTime? rightMostDate;
    DateTime? initDate;
    if ((_selectedFromDate == null || _selectedToDate == null)) {
    } else {
      leftMostDate = _selectedToDate!.add(const Duration(days: 1));
      rightMostDate = leftMostDate.add(const Duration(days: 30));
      initDate = leftMostDate;
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Billing Month',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
              ),
            ),
            horizontalSpaceSmall,
            getTimeRangePicker(),
          ],
        ),
        verticalSpaceSmall,
        (_selectedFromDate == null || _selectedToDate == null)
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
                    key: _date1PickerKey,
                    labelFontSize: 15,
                    defaultFirstDate: leftMostDate,
                    defaultLastDate: rightMostDate,
                    initialDate: _selectedDate1,
                    timeZone:
                        widget.loggedInUser.selectedScope.getProjectTimezone(),
                    label: 'Set Bill Date',
                    onDateChanged: (DateTime selectedDate) {
                      setState(() {
                        _selectedDate1 = selectedDate;
                      });
                    },
                  ),
                ],
              ),
        verticalSpaceSmall,
        getCollectionStartDate(),
        verticalSpaceSmall,
        (_selectedFromDate == null || _selectedToDate == null)
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
                    key: _date2PickerKey,
                    labelFontSize: 15,
                    enabled: true,
                    defaultFirstDate: leftMostDate,
                    defaultLastDate: rightMostDate,
                    initialDate: _selectedDate2,
                    timeZone:
                        widget.loggedInUser.selectedScope.getProjectTimezone(),
                    label: 'Set Collection End Date',
                    onDateChanged: (DateTime selectedDate) {
                      setState(() {
                        _selectedDate2 = selectedDate;
                        _collectionStartDate = DateTime(_selectedDate2!.year,
                            _selectedDate2!.month - 1, _selectedDate2!.day + 1);
                        _useCustomCollectionStartDate = false;
                        _timePickerKeyCollectionStartDate = UniqueKey();
                      });
                    },
                  ),
                ],
              ),
      ],
    );
  }

  Widget getUsageReportOptions() {
    return Column(
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
            getTimeRangePicker(),
          ],
        ),
        verticalSpaceSmall,
        getMainMeterSwitcher(),
      ],
    );
  }

  Widget getCollectionStartDate() {
    if (_selectedDate2 == null) {
      return Container();
    }
    DateTime? leftMostDate = _selectedDate2?.subtract(const Duration(days: 55));

    return Column(
      children: [
        // check box to enable custom collection start date
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
                  _selectedDate2!.subtract(const Duration(days: 1)),
              initialDate: _collectionStartDate,
              timeZone: widget.loggedInUser.selectedScope.getProjectTimezone(),
              label: 'Set Collection Start Date',
              onDateChanged: (DateTime selectedDate) {
                setState(() {
                  _collectionStartDate = selectedDate;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget getTenantUsageReportOptions() {
    return Column(
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
            getTimeRangePicker(),
          ],
        ),
      ],
    );
  }

  Widget getGiroFileOptions() {
    if ((_selectedFromDate == null || _selectedToDate == null)) {}
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Duration',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
              ),
            ),
            horizontalSpaceSmall,
            getTimeRangePicker(),
          ],
        ),
      ],
    );
  }

  Widget getBillingReportOptions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Billing Month',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
              ),
            ),
            horizontalSpaceSmall,
            getTimeRangePicker(forceMonthly: true),
          ],
        ),
      ],
    );
  }

  Widget getBillLcStatusUpdateOptions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Billing Month',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
              ),
            ),
            horizontalSpaceSmall,
            getTimeRangePicker(forceMonthly: true, enabled: !_isOption1),
            VerticalDivider(
              color: Theme.of(context).hintColor,
              width: 20,
            ),
            Row(
              children: [
                Checkbox(
                  value: _isOption1,
                  onChanged: (value) {
                    setState(() {
                      _isOption1 = value ?? false;
                      if (_isOption1) {
                      } else {
                        _resetDate(resetDateRange: true);
                      }
                    });
                  },
                ),
                Text(
                  'Initial Bill',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        verticalSpaceSmall,
        getTargetBillLcStatusSelector(),
      ],
    );
  }

  Widget getTargetBillLcStatusSelector() {
    List<String> targetBilllcStatusOptions = ['pv', 'released', 'mfd'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Target Bill LC Status',
          style: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 16,
          ),
        ),
        horizontalSpaceSmall,
        DropdownButton<String>(
          value: _selectedLcStatusStr,
          items: targetBilllcStatusOptions
              .map((status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  ))
              .toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedLcStatusStr = newValue;
            });
          },
        ),
      ],
    );
  }

  Widget getPaymentLcStatusUpdateOptions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Payment Date Range',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
              ),
            ),
            horizontalSpaceSmall,
            getTimeRangePicker(),
          ],
        ),
        verticalSpaceSmall,
        getTargetPaymentLcStatusSelector(),
      ],
    );
  }

  Widget getTargetPaymentLcStatusSelector() {
    List<String> targetPaymentLcStatusOptions = ['released', 'mfd'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Target Payment LC Status',
          style: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 16,
          ),
        ),
        horizontalSpaceSmall,
        DropdownButton<String>(
          value: _selectedLcStatusStr,
          items: targetPaymentLcStatusOptions
              .map((status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  ))
              .toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedLcStatusStr = newValue;
            });
          },
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
        });
      },
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

  Widget getResultText() {
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

  Widget getTriggerButton() {
    bool enableSubmit = _checkEnableSubmit();
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

  Widget genPaymentMatchingFormOptions() {
    return Container();
  }
}
