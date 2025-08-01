import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WgtDatePicker extends StatefulWidget {
  const WgtDatePicker({
    super.key,
    required this.timeZone,
    this.prefix = const Icon(Icons.arrow_right),
    this.suffix = const Icon(Icons.arrow_drop_down),
    this.defaultFirstDate,
    this.defaultLastDate,
    this.onDateChanged,
    this.onDateCleared,
    this.label,
    this.initialDate,
  });

  final int timeZone;
  final Icon? prefix;
  final Icon suffix;
  final DateTime? defaultFirstDate;
  final DateTime? defaultLastDate;
  final Function(DateTime)? onDateChanged;
  final Function()? onDateCleared;
  final String? label;
  final DateTime? initialDate;

  @override
  State<WgtDatePicker> createState() => _WgtDatePickerState();
}

class _WgtDatePickerState extends State<WgtDatePicker> {
  // final sDateFormate = "dd/MM/yyyy";
  // DateTime selectedDate = DateTime.now();
  // String date = DateFormat("dd/MM/yyyy").format(DateTime.now());

  String _selectedDateText = 'Select date';
  DateTime? _selectedDateTime;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? d = await showDatePicker(
      context: context,
      locale: const Locale('en', 'GB'),
      initialDate:
          widget.initialDate ?? getTargetLocalDatetimeNow(widget.timeZone),
      // fieldHintText: sDateFormate,
      firstDate: widget.defaultFirstDate ?? DateTime(2020),
      lastDate: widget.defaultLastDate ??
          DateTime.now().add(const Duration(days: 60)),
    );
    if (d != null) {
      setState(() {
        // _selectedDate = DateFormat(sDateFormate).format(d);
        _selectedDateText = DateFormat.yMMMd().format(d);
        _selectedDateTime = d;
      });
      widget.onDateChanged?.call(d);
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDateText = widget.label ?? 'Select date';
    if (widget.initialDate != null) {
      _selectedDateText = DateFormat.yMMMd().format(widget.initialDate!);
      _selectedDateTime = widget.initialDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color boarderColor = Theme.of(context).hintColor;
    return SizedBox(
      // width: 80,
      child: Container(
        decoration: panelBoxDecor(boarderColor),
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
                icon: Icon(Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary),
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
