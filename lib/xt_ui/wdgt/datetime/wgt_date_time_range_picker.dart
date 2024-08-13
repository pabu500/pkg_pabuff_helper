import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

import 'wgt_date_picker.dart';
import 'wgt_timeslot_picker.dart';

class WgtSameDayTimeRangePicker extends StatefulWidget {
  const WgtSameDayTimeRangePicker({
    super.key,
    required this.timeZone,
    required this.onSet,
    this.defaultDate,
    this.defaultStartTime,
    this.defaultEndTime,
    this.isDaily = false,
    this.singleDateTime = false,
  });

  final int timeZone;
  final DateTime? defaultDate;
  final TimeOfDay? defaultStartTime;
  final TimeOfDay? defaultEndTime;
  final void Function(
    DateTime? startDateTime,
    DateTime? endDateTime,
  ) onSet;
  final bool isDaily;
  final bool singleDateTime;

  @override
  State<WgtSameDayTimeRangePicker> createState() =>
      _WgtSameDayTimeRangePickerState();
}

//boilerplate code only
class _WgtSameDayTimeRangePickerState extends State<WgtSameDayTimeRangePicker> {
  DateTime? _selectedStartDateTime;
  DateTime? _selectedEndDateTime;
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  @override
  void initState() {
    super.initState();
    // not setting default date here
    // set by the user
    // _selectedDate = widget.defaultDate;
    _selectedStartTime = widget.defaultStartTime;
    _selectedEndTime = widget.defaultEndTime;
    if (widget.isDaily) {
      _selectedDate = widget.defaultDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!widget.isDaily)
          WgtDatePicker(
            timeZone: widget.timeZone,
            defaultFirstDate: widget.defaultDate,
            defaultLastDate: widget.defaultDate?.add(const Duration(days: 180)),
            onDateChanged: (DateTime selectedDate) {
              setState(() {
                _selectedDate = selectedDate;
                if (_selectedStartTime != null && _selectedEndTime != null) {
                  DateTime startTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    _selectedStartTime!.hour,
                    _selectedStartTime!.minute,
                  );
                  DateTime endTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    _selectedEndTime!.hour,
                    _selectedEndTime!.minute,
                  );
                  _selectedStartDateTime = startTime;
                  _selectedEndDateTime = endTime;
                  widget.onSet(_selectedStartDateTime, _selectedEndDateTime);
                }
              });
            },
            onDateCleared: () {
              setState(() {
                _selectedDate = null;
                _selectedStartDateTime = null;
                _selectedEndDateTime = null;
              });
              widget.onSet(_selectedStartDateTime, _selectedEndDateTime);
            },
            prefix: Icon(Icons.arrow_right,
                color: Theme.of(context).colorScheme.primary),
            suffix: const Icon(Icons.arrow_drop_down),
          ),
        horizontalSpaceSmall,
        WgtTimeSlotPicker(
          hintText: widget.singleDateTime ? 'Time' : 'From',
          defaultTime: widget.defaultStartTime,
          rangeTo: _selectedEndTime ?? widget.defaultEndTime,
          onSelected: (selectedTime) {
            setState(() {
              _selectedStartTime = selectedTime;
            });
            if (_selectedDate != null && _selectedEndTime != null) {
              DateTime startTime = DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                selectedTime!.hour,
                selectedTime.minute,
              );
              DateTime endTime = DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                _selectedEndTime!.hour,
                _selectedEndTime!.minute,
              );
              setState(() {
                _selectedStartDateTime = startTime;
                _selectedEndDateTime = endTime;
              });
              widget.onSet(_selectedStartDateTime, _selectedEndDateTime);
            }
          },
          // onSearch: (startTime, endTime) {
          //   widget.onSet(
          //     _selectedStartDateTime?.add(Duration(
          //       hours: startTime?.hour ?? 0,
          //       minutes: startTime?.minute ?? 0,
          //     )),
          //     _selectedStartDateTime?.add(Duration(
          //       hours: endTime?.hour ?? 0,
          //       minutes: endTime?.minute ?? 0,
          //     )),
          //   );
          // },
        ),
        horizontalSpaceTiny,
        if (!widget.singleDateTime)
          WgtTimeSlotPicker(
            hintText: 'To',
            defaultTime: widget.defaultEndTime,
            rangeFrom: _selectedStartTime ?? widget.defaultStartTime,
            onSelected: (selectedTime) {
              setState(() {
                _selectedEndTime = selectedTime;
              });
              if (_selectedDate != null && _selectedStartTime != null) {
                DateTime startTime = DateTime(
                  _selectedDate!.year,
                  _selectedDate!.month,
                  _selectedDate!.day,
                  _selectedStartTime!.hour,
                  _selectedStartTime!.minute,
                );
                DateTime endTime = DateTime(
                  _selectedDate!.year,
                  _selectedDate!.month,
                  _selectedDate!.day,
                  selectedTime!.hour,
                  selectedTime.minute,
                );
                setState(() {
                  _selectedStartDateTime = startTime;
                  _selectedEndDateTime = endTime;
                });
                widget.onSet(_selectedStartDateTime, _selectedEndDateTime);
              }
            },
            // onSearch: (startTime, endTime) {
            //   widget.onSet(
            //     _selectedEndDateTime?.add(Duration(
            //       hours: startTime?.hour ?? 0,
            //       minutes: startTime?.minute ?? 0,
            //     )),
            //     _selectedEndDateTime?.add(Duration(
            //       hours: endTime?.hour ?? 0,
            //       minutes: endTime?.minute ?? 0,
            //     )),
            //   );
            // },
          ),
      ],
    );
  }
}
