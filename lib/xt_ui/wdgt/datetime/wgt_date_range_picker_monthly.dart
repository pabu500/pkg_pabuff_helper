import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class WgtDateRangePickerMonthly extends StatefulWidget {
  const WgtDateRangePickerMonthly({
    super.key,
    // required this.context,
    required this.onRangeSet,
    required this.scopeProfile,
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
    this.maxHistoryDays = 180,
  });

  // final BuildContext context;
  final ScopeProfile scopeProfile;
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
  final int maxHistoryDays;

  @override
  State<WgtDateRangePickerMonthly> createState() =>
      _WgtDateRangePickerMonthlyState();
}

class _WgtDateRangePickerMonthlyState extends State<WgtDateRangePickerMonthly> {
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
        return;
      }
      if (selected == _monthPicked) {
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
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.75)
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
                    color: Theme.of(context).hintColor.withOpacity(0.2),
                    width: 1,
                  ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: WgtDateRangePicker2(
            timezone: widget.timeZone,
            scopeProfile: widget.scopeProfile,
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
            maxDuration: Duration(days: widget.maxHistoryDays),
            onMaxDurationExceeded: () {},
          ),
        ),
      ],
    );
  }
}
