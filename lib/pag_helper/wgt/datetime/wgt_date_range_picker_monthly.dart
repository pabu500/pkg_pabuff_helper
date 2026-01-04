import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'dart:developer' as dev;

import '../../../util/date_time_util.dart';
import 'wgt_date_range_picker2.dart';

class WgtPagDateRangePickerMonthly extends StatefulWidget {
  const WgtPagDateRangePickerMonthly({
    super.key,
    // required this.context,
    required this.onRangeSet,
    // required this.scopeProfile,
    required this.populateDefaultRange,
    this.onMonthPicked,
    this.timeZone = 8,
    this.iniStartDateTime,
    this.iniEndDateTime,
    this.lastDate,
    // this.selectedStartDate,
    // this.selectedEndDate,
    this.customRangeSelected = false,
    this.showMonthly = true,
    this.monthPicked,
  });

  // final BuildContext context;
  // final ScopeProfile scopeProfile;
  final Function? onMonthPicked;
  final bool populateDefaultRange;
  final Function onRangeSet;
  final int timeZone;
  final DateTime? iniStartDateTime;
  final DateTime? iniEndDateTime;
  final DateTime? lastDate;
  final DateTime? monthPicked;
  // final DateTime? selectedStartDate;
  // final DateTime? selectedEndDate;
  final bool customRangeSelected;
  final bool showMonthly;

  @override
  State<WgtPagDateRangePickerMonthly> createState() =>
      _WgtPagDateRangePickerMonthlyState();
}

class _WgtPagDateRangePickerMonthlyState
    extends State<WgtPagDateRangePickerMonthly> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _isMTD = false;
  bool _isCustomRange = false;
  DateTime? _monthPicked;

  Future<void> _onMonthlyPressed() async {
    String? locale = 'en';
    // final localeObj = locale != null ? Locale(locale) : null;
    final selected = await showMonthPicker(
      context: context,
      initialDate: _monthPicked ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      // locale: localeObj,
    );

    if (selected != null) {
      if (selected.isAfter(DateTime.now())) {
        dev.log('Selected month is in the future. Ignoring.');
        return;
      }
      if (selected == _monthPicked) {
        dev.log('Selected month is the same as current. Ignoring.');
        return;
      }
      setState(() {
        _monthPicked = selected;

        _selectedStartDate = DateTime(selected.year, selected.month, 1);
        _selectedEndDate = DateTime(selected.year, selected.month + 1, 0);
        _isCustomRange = false;
        _isMTD = false;
        DateTime localNow = getTargetLocalDatetimeNow(widget.timeZone);
        if (localNow.year == selected.year &&
            localNow.month == selected.month) {
          _isMTD = true;
        }
      });
      widget.onMonthPicked?.call(selected);
    }
  }

  @override
  void initState() {
    super.initState();
    _monthPicked = widget.monthPicked;
    _selectedStartDate = widget.iniStartDateTime;
    _selectedEndDate = widget.iniEndDateTime;
    _isCustomRange = widget.customRangeSelected;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showMonthly)
          TextButton(
            onPressed: () {
              _onMonthlyPressed();
            },
            style: TextButton.styleFrom(
              backgroundColor: _monthPicked == null
                  ? Theme.of(context).colorScheme.primary.withAlpha(210)
                  : Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
            child: Text(
              _monthPicked == null
                  ? 'Monthly'
                  : _isMTD
                      ? 'MTD'
                      : _monthPicked.toString().substring(0, 7),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        horizontalSpaceSmall,
        Container(
          height: 45,
          decoration: BoxDecoration(
            border: _isCustomRange
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : Border.all(
                    color: Theme.of(context).hintColor.withAlpha(50),
                    width: 1,
                  ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: WgtDateRangePicker2(
            timezone: widget.timeZone,
            populateDefaultRange: widget.populateDefaultRange,
            width: 290,
            updateRangeByParent: true,
            startDateTime: _selectedStartDate,
            endDateTime: _selectedEndDate,
            lastDate: widget.lastDate,
            onSet: (DateTime? start, DateTime? end) {
              setState(() {
                _selectedStartDate = start;
                _selectedEndDate = end;
                _isCustomRange = true;
                _isMTD = false;
                _monthPicked = null;
              });
              widget.onRangeSet.call(start, end);
            },
            maxDuration: const Duration(days: 180),
            onMaxDurationExceeded: () {},
          ),
        ),
      ],
    );
  }
}
