import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/datetime/wgt_timeslot_picker.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_popup_button.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../show_model_bottom_sheet.dart';

class WgtDateRangePicker2 extends StatefulWidget {
  const WgtDateRangePicker2({
    super.key,
    required this.timezone,
    required this.onSet,
    required this.scopeProfile,
    required this.populateDefaultRange,
    this.startDateTime,
    this.endDateTime,
    this.lastDate,
    this.history = true,
    this.useEdgeTime = true,
    this.showHHmm = false,
    this.singleDate = false,
    this.width = 362,
    this.updateRangeByParent = false,
    this.maxDuration = const Duration(days: 180),
    this.maxSelectionDuration = const Duration(days: 180),
    this.onMaxDurationExceeded,
    // this.allowSameDay = false,
    this.setTime = false,
  });

  final int timezone;
  final ScopeProfile scopeProfile;
  final bool populateDefaultRange;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final DateTime? lastDate;
  final bool history;
  final bool useEdgeTime;
  final bool showHHmm;
  final void Function(
    DateTime? startDate,
    DateTime? endDate,
  ) onSet;
  final bool singleDate;
  final double width;
  final bool updateRangeByParent;
  final Duration maxDuration;
  final Duration maxSelectionDuration;
  final void Function()? onMaxDurationExceeded;
  // final bool allowSameDay;
  final bool setTime;

  @override
  State<WgtDateRangePicker2> createState() => _WgtDateRangePicker2State();
}

//boilerplate code only
class _WgtDateRangePicker2State extends State<WgtDateRangePicker2> {
  // late ScopeProfile _scopeProfile;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime? _defaultEndDate;
  DateTime? _defaultStartDate;

  late List<DateTime?> _rangeDatePickerValueWithDefaultValue;
  // bool _maxDurationExceeded = false;

  String _getValueText(
    CalendarDatePicker2Type datePickerType,
    List<DateTime?> values,
  ) {
    values =
        values.map((e) => e != null ? DateUtils.dateOnly(e) : null).toList();
    var valueText = (values.isNotEmpty ? values[0] : null)
        .toString()
        .replaceAll('00:00:00.000', '');

    if (datePickerType == CalendarDatePicker2Type.multi) {
      valueText = values.isNotEmpty
          ? values
              .map((v) => v.toString().replaceAll('00:00:00.000', ''))
              .join(', ')
          : 'null';
    } else if (datePickerType == CalendarDatePicker2Type.range) {
      if (values.isNotEmpty) {
        final startDate = values[0].toString().replaceAll('00:00:00.000', '');
        final endDate = values.length > 1
            ? values[1].toString().replaceAll('00:00:00.000', '')
            : 'null';
        valueText = '$startDate to $endDate';
      } else {
        return 'null';
      }
    }

    return valueText;
  }

  void updateRange() {
    setState(() {
      _selectedStartDate = _rangeDatePickerValueWithDefaultValue[0];
      _selectedEndDate = _rangeDatePickerValueWithDefaultValue[1];
    });
  }

  @override
  initState() {
    super.initState();

    // _scopeProfile = Provider.of<AppModel>(context, listen: false).portalScopeProfile!;
    // final activeProjectTimezone = _scopeProfile.timezone;
    final activeProjectTimezone = widget.timezone;
    if (widget.populateDefaultRange) {
      _defaultEndDate = (widget.history
          ? getTargetLocalDatetimeNow(activeProjectTimezone)
          : getTargetLocalDatetimeNow(activeProjectTimezone)
              .add(const Duration(hours: 48)));

      _defaultStartDate = /*widget.startDateTime ??*/
          (widget.history
              ? _defaultEndDate!.subtract(const Duration(hours: 48))
              : getTargetLocalDatetimeNow(activeProjectTimezone));

      // if (widget.useEdgeTime) {
      //   _defaultEndDate = getTargetLocalDatetime(
      //       activeProjectTimezone, 23, 59, 59, 999,
      //       refLocalDatetime: _defaultEndDate); //get the end of the day

      //   _defaultStartDate = getTargetLocalDatetime(
      //       activeProjectTimezone, 0, 0, 0, 0,
      //       refLocalDatetime: _defaultStartDate); //get the start of the day
      // }
      if (widget.useEdgeTime) {
        _defaultEndDate = getTargetLocalDatetime(
            activeProjectTimezone, 23, 59, 59, 999,
            refLocalDatetime: _defaultEndDate); //get the end of the day
        _defaultStartDate = getTargetLocalDatetime(
            activeProjectTimezone, 0, 0, 0, 0,
            refLocalDatetime: _defaultStartDate); //get the start of the day
        _selectedStartDate = getTargetLocalDatetime(
            activeProjectTimezone, 0, 0, 0, 0,
            refLocalDatetime: _defaultStartDate); //get the start of the day
        _selectedEndDate = getTargetLocalDatetime(
            activeProjectTimezone, 23, 59, 59, 999,
            refLocalDatetime: _defaultEndDate); //get the end of the day
      }
    }
    // if (kDebugMode) {
    //   print('ini defaultStartDate: $_defaultStartDate');
    //   print('ini defaultEndDate: $_defaultEndDate');
    // }

    _rangeDatePickerValueWithDefaultValue = [
      _defaultStartDate,
      _defaultEndDate,
    ];
    if (widget.singleDate) {
      _rangeDatePickerValueWithDefaultValue = [
        _defaultEndDate,
        // will assert error if start and end date are the same
        _defaultEndDate?.add(const Duration(seconds: 1)),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.updateRangeByParent) {
      DateTime selectedEndDate = widget.endDateTime ??
          (widget.history
              ? getTargetLocalDatetimeNow(widget.scopeProfile.timezone)
              : getTargetLocalDatetimeNow(widget.scopeProfile.timezone)
                  .add(const Duration(hours: 48)));
      DateTime selectedStartDate = widget.startDateTime ??
          (widget.history && _defaultEndDate != null
              ? _defaultEndDate!.subtract(const Duration(hours: 48))
              : getTargetLocalDatetimeNow(widget.scopeProfile.timezone));
      Duration duration = selectedEndDate.difference(selectedStartDate);

      if (duration.inSeconds > widget.maxDuration.inSeconds + 61) {
        if (widget.onMaxDurationExceeded != null) {
          widget.onMaxDurationExceeded!();
        }
      } else {
        _selectedStartDate = selectedStartDate;
        _selectedEndDate = selectedEndDate;
        _rangeDatePickerValueWithDefaultValue = [
          _selectedStartDate,
          // will assert error if start and end date are the same
          _selectedEndDate?.add(const Duration(milliseconds: 300)),
        ];
        // if (kDebugMode) {
        //   print('defaultStartDate: $_defaultStartDate');
        //   print('defaultEndDate: $_defaultEndDate');
        // }
      }
    }

    String fromText = 'Select';
    String toText = 'Select';
    if (_selectedEndDate != _selectedStartDate) {
      if (_selectedStartDate != null) {
        fromText =
            DateFormat(widget.showHHmm ? 'yyyy-MM-dd HH:mm' : 'yyyy-MM-dd')
                .format(_selectedStartDate!);
      }
      if (_selectedEndDate != null) {
        toText = DateFormat(widget.showHHmm ? 'yyyy-MM-dd HH:mm' : 'yyyy-MM-dd')
            .format(_selectedEndDate!);
      }
    }

    return SizedBox(
      width: widget.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          xtKeyValueText(
            keyText: 'From',
            valueText: fromText,
            valueStyle: TextStyle(
                fontSize: 15,
                color: fromText == 'Select'
                    ? Theme.of(context).hintColor.withAlpha(80)
                    : Theme.of(context).colorScheme.primary),
          ),
          horizontalSpaceTiny,
          xtKeyValueText(
            keyText: 'To',
            valueText: toText,
            valueStyle: TextStyle(
                fontSize: 15,
                color: toText == 'Select'
                    ? Theme.of(context).hintColor.withAlpha(80)
                    : Theme.of(context).colorScheme.primary),
          ),
          horizontalSpaceSmall,
          getDateRangePickerPopupButton(),
        ],
      ),
    );
  }

  Widget _buildDefaultRangeDatePickerWithValue() {
    DateTime startDate = _defaultStartDate ?? DateTime.now();
    DateTime endDate = _defaultEndDate ?? DateTime.now();

    final config = CalendarDatePicker2Config(
      // controlsHeight: 45,
      calendarType: CalendarDatePicker2Type.range,
      lastDate: widget.lastDate ??
          (widget.history
              ? endDate.add(const Duration(days: 1))
              : endDate.add(widget.maxDuration)),
      firstDate: widget.history
          ? startDate.subtract(widget.maxDuration)
          : startDate.subtract(const Duration(days: 1)),
      firstDayOfWeek: 1,
      selectedDayHighlightColor: Theme.of(context).colorScheme.primary,
      weekdayLabelTextStyle: const TextStyle(
        // color: Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      controlsTextStyle: const TextStyle(
        // color: Colors.black,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );

    if (kDebugMode) {
      print(
          '_rangeDatePickerValueWithDefaultValue[0]:${_rangeDatePickerValueWithDefaultValue[0]}');
      print(
          '_rangeDatePickerValueWithDefaultValue[1]:${_rangeDatePickerValueWithDefaultValue[1]}');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // const SizedBox(height: 10),
        SizedBox(
          height: 280,
          child: CalendarDatePicker2(
            config: config,
            value: _rangeDatePickerValueWithDefaultValue,
            onValueChanged: (dates) {
              if (widget.singleDate) {
                dates = [dates[1], dates[1]];
              }
              if (dates.length == 1) {
                return;
              }
              if (dates.length == 2) {
                // _maxDurationExceeded = false;
                Duration? duration = dates[1]!.difference(dates[0]!);
                if (duration > widget.maxSelectionDuration) {
                  // setState(() {
                  //   _maxDurationExceeded = true;
                  // });

                  if (widget.onMaxDurationExceeded != null) {
                    widget.onMaxDurationExceeded!();
                  }
                  return;
                }
              }
              // setState(() {
              _rangeDatePickerValueWithDefaultValue = dates;
              _selectedStartDate = dates[0];
              if (widget.useEdgeTime) {
                _selectedStartDate = getTargetLocalDatetime(
                    widget.scopeProfile.timezone, 0, 0, 0, 0,
                    refLocalDatetime: _selectedStartDate!);
              }
              _selectedEndDate = dates.length > 1 ? dates[1] : null;
              if (_selectedEndDate != null && widget.useEdgeTime) {
                _selectedEndDate = getTargetLocalDatetime(
                    widget.scopeProfile.timezone, 23, 59, 59, 999,
                    refLocalDatetime: _selectedEndDate!);
                if (widget.setTime) {
                  _selectedEndDate = getTargetLocalDatetime(
                      widget.scopeProfile.timezone, 23, 45, 0, 0,
                      refLocalDatetime: _selectedEndDate!);
                } // to avoid assert error
              }
              // });
              if (!widget.updateRangeByParent) {
                setState(() {});
              }
              if (_selectedStartDate != null && _selectedEndDate != null) {
                if (!widget.setTime) {
                  widget.onSet(_selectedStartDate, _selectedEndDate);
                }
              }

              if (kDebugMode) {
                print('onValueChanged: $dates');
              }
            },
          ),
        ),
        if (widget.setTime)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WgtTimeSlotPicker(
                label: 'From',
                hintText: 'From',
                defaultTime: widget.showHHmm
                    ? TimeOfDay.fromDateTime(_selectedStartDate ?? // midnight
                        DateTime(DateTime.now().year, DateTime.now().month,
                            DateTime.now().day, 0, 0))
                    : null,
                rangeTo: _selectedEndDate != null
                    ? TimeOfDay.fromDateTime(DateTime(_selectedEndDate!.year,
                        _selectedEndDate!.month, _selectedEndDate!.day, 23, 45))
                    : null,
                onSelected: (selectedTime) {
                  if (_selectedStartDate != null && selectedTime != null) {
                    DateTime startTime = DateTime(
                      _selectedStartDate!.year,
                      _selectedStartDate!.month,
                      _selectedStartDate!.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    setState(() {
                      _selectedStartDate = startTime;
                    });
                    if (_selectedEndDate != null) {
                      widget.onSet(_selectedStartDate, _selectedEndDate);
                    }
                  } else {
                    widget.onSet(null, _selectedEndDate);
                  }
                },
              ),
              horizontalSpaceSmall,
              WgtTimeSlotPicker(
                label: 'To',
                hintText: 'To',
                defaultTime: _selectedEndDate == null
                    ? null
                    : TimeOfDay(
                        hour: _selectedEndDate!.hour,
                        minute: _selectedEndDate!.minute),
                rangeTo: _selectedEndDate != null
                    ? TimeOfDay.fromDateTime(DateTime(_selectedEndDate!.year,
                        _selectedEndDate!.month, _selectedEndDate!.day, 23, 45))
                    : null,
                onSelected: (selectedTime) {
                  if (_selectedEndDate != null && selectedTime != null) {
                    DateTime endTime = DateTime(
                      _selectedEndDate!.year,
                      _selectedEndDate!.month,
                      _selectedEndDate!.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    setState(() {
                      _selectedEndDate = endTime;
                    });
                    if (_selectedStartDate != null) {
                      widget.onSet(_selectedStartDate, _selectedEndDate);
                    }
                  } else {
                    widget.onSet(_selectedStartDate, null);
                  }
                },
              ),
            ],
          ),
        verticalSpaceSmall,
        // if (_maxDurationExceeded)
        Transform.translate(
          offset: const Offset(0, -10),
          child: Text(
            '* max history: ${getReadableDuration(widget.maxDuration)} \n* max selection range: ${getReadableDuration(widget.maxSelectionDuration)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 16,
              // fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // const SizedBox(height: 10),
        // Row(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     const Text('Selection(s):  '),
        //     const SizedBox(width: 10),
        //     Text(
        //       _getValueText(
        //         config.calendarType,
        //         _rangeDatePickerValueWithDefaultValue,
        //       ),
        //     ),
        //   ],
        // ),
        // const SizedBox(height: 25),
      ],
    );
  }

  Widget getDateRangePickerPopupButton() {
    return Tooltip(
      message: 'Select Date Range',
      child: MediaQuery.of(context).size.width < 500
          ? InkWell(
              onTap: () {
                xtShowModelBottomSheet(
                  context,
                  _buildDefaultRangeDatePickerWithValue(),
                );
              },
              child: Icon(
                Icons.date_range,
                size: 35,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : WgtPopupButton(
              direction: 'left',
              // buttonKey: buttonKey,
              width: 35,
              height: 35,
              popupWidth: 350,
              popupHeight: widget.setTime ? 385 : 350,
              popupChild: _buildDefaultRangeDatePickerWithValue(),
              // disabled: disabled,
              child: Icon(
                Icons.date_range,
                size: 35,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
    );
  }
}
