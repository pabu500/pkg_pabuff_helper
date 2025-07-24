import 'package:flutter/material.dart';

class WgtTimeSlotPicker extends StatefulWidget {
  const WgtTimeSlotPicker({
    super.key,
    // required this.onSearch,
    required this.onSelected,
    this.slotMinutes,
    this.hintText,
    this.defaultTime,
    this.rangeFrom,
    this.rangeTo,
    // this.setPairingRangeFrom,
  });

  final int? slotMinutes;
  final String? hintText;
  final TimeOfDay? defaultTime;
  final TimeOfDay? rangeFrom;
  final TimeOfDay? rangeTo;
  // final void Function(TimeOfDay? startTime, TimeOfDay? endTime) onSearch;
  final void Function(TimeOfDay? selectedTime) onSelected;

  @override
  State<WgtTimeSlotPicker> createState() => _WgtTimeSlotPickerState();
}

//boilerplate code only
class _WgtTimeSlotPickerState extends State<WgtTimeSlotPicker> {
  TimeOfDay? _selectedTime;
  // TimeOfDay? _selectedEndTime;
  late int _slotMinutes;

  @override
  void initState() {
    super.initState();
    _slotMinutes = widget.slotMinutes ?? 15;
  }

  @override
  Widget build(BuildContext context) {
    //widget dropdown button for time at slotMinutes interval
    return Row(
      children: [
        DropdownButton<TimeOfDay>(
          value: _selectedTime ?? widget.defaultTime,
          hint: Text(widget.hintText ?? 'Timeslot'),
          onChanged: (TimeOfDay? newValue) {
            setState(() {
              _selectedTime = newValue;
            });
            widget.onSelected(_selectedTime);
            // widget.onSearch(_selectedStartTime, _selectedEndTime);
          },
          items: _getDropDownItems(),
        ),
      ],
    );
  }

  List<DropdownMenuItem<TimeOfDay>> _getDropDownItems() {
    List<DropdownMenuItem<TimeOfDay>> items = [];
    for (var i = 0; i < 24 * 60; i += _slotMinutes) {
      final time = TimeOfDay(hour: i ~/ 60, minute: i % 60);
      if (widget.rangeFrom != null &&
          time.hour * 60 + time.minute <=
              widget.rangeFrom!.hour * 60 + widget.rangeFrom!.minute) {
        continue;
      }
      if (widget.rangeTo != null &&
          time.hour * 60 + time.minute >=
              widget.rangeTo!.hour * 60 + widget.rangeTo!.minute) {
        continue;
      }
      items.add(DropdownMenuItem(
        value: time,
        child:
            // Text(time.format(context)),
            //in 24 hour format
            Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
      ));
    }
    return items;
  }
}
