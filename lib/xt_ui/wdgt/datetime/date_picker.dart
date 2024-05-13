import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class xtDatePicker extends StatefulWidget {
  xtDatePicker(
      {Key? key,
      this.prefix,
      this.suffix,
      this.boarderColor,
      this.initialDate,
      this.displayInitialDate,
      this.minDays,
      this.maxDays,
      this.onDateChanged,
      this.onDateCleared})
      : super(key: key);

  final Icon? prefix;
  final Icon? suffix;
  final Color? boarderColor;
  final DateTime? initialDate;
  final bool? displayInitialDate;
  final int? minDays;
  final int? maxDays;
  final Function(DateTime)? onDateChanged;
  final Function()? onDateCleared;

  @override
  _xtDatePickerState createState() => _xtDatePickerState();
}

class _xtDatePickerState extends State<xtDatePicker> {
  // final sDateFormate = "dd/MM/yyyy";
  // DateTime selectedDate = DateTime.now();
  // String date = DateFormat("dd/MM/yyyy").format(DateTime.now());

  String _selectedDateText = 'Select date';
  DateTime? _selectedDateTime;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? d = await showDatePicker(
      context: context,
      locale: const Locale('en', 'GB'),
      initialDate: widget.initialDate ?? DateTime.now(),
      // fieldHintText: sDateFormate,
      firstDate: widget.minDays == null
          ? DateTime(2023)
          : DateTime.now().add(Duration(days: widget.minDays!)),
      lastDate: DateTime.now().add(Duration(days: widget.maxDays ?? 60)),
    );
    if (d != null) {
      setState(() {
        // _selectedDate = DateFormat(sDateFormate).format(d);
        _selectedDateText = DateFormat.yMMMd().format(d);
        _selectedDateTime = d;
      });
      if (widget.onDateChanged != null) {
        widget.onDateChanged!(d);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.displayInitialDate != null && widget.displayInitialDate!) {
      _selectedDateText = DateFormat.yMMMd().format(widget.initialDate!);
      _selectedDateTime = widget.initialDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color boarderColor = widget.boarderColor ?? Theme.of(context).hintColor;
    return SizedBox(
      // width: 80,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: boarderColor),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              widget.prefix ?? Container(),
              InkWell(
                child: Text(_selectedDateText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: _selectedDateTime == null
                          ? Theme.of(context).hintColor
                          : null,
                    )),
                onTap: () {
                  _selectDate(context);
                },
              ),
              _selectedDateTime == null
                  ? Container()
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Tap to clear date',
                      onPressed: () {
                        if (widget.onDateCleared != null) {
                          widget.onDateCleared!();
                        }
                        setState(() {
                          _selectedDateText = 'Select date';
                          _selectedDateTime = null;
                        });
                      },
                    ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                tooltip: 'Tap to open date picker',
                onPressed: () {
                  _selectDate(context);
                },
              ),
              widget.suffix ?? Container(),
            ],
          ),
        ),
      ),
    );
  }
}
