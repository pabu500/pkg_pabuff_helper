import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';

class WgtMonthPicker extends StatefulWidget {
  const WgtMonthPicker({
    super.key,
    required this.onSet,
    this.initialDate,
    this.readOnly = false,
    this.useDefault = true,
  });

  final Function(DateTime?, DateTime?) onSet;
  final DateTime? initialDate;
  final bool readOnly;
  final bool useDefault;

  @override
  State<WgtMonthPicker> createState() => _WgtMonthPickerState();
}

class _WgtMonthPickerState extends State<WgtMonthPicker> {
  late ScopeProfile _scopeProfile;
  late Evs2User? _loggedInUser;

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  String get _selectedMonth {
    return _selectedStartDate != null
        ? '${_selectedStartDate!.year}-${_selectedStartDate!.month}'
        : '-';
  }

  Future<void> _onMonthlyPressed(
      {required BuildContext context,
      String? locale,
      DateTime? initialDate}) async {
    // final localeObj = locale != null ? Locale(locale) : null;
    final selected = await showMonthPicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      // locale: localeObj,
    );

    if (selected != null) {
      setState(() {
        _selectedStartDate = DateTime(selected.year, selected.month, 1);
        _selectedEndDate = DateTime(selected.year, selected.month + 1, 0);
      });
    }
    widget.onSet!(_selectedStartDate, _selectedEndDate);
  }

  @override
  void initState() {
    super.initState();
    _scopeProfile =
        Provider.of<AppModel>(context, listen: false).portalScopeProfile;
    _loggedInUser =
        Provider.of<UserProvider>(context, listen: false).currentUser;

    _selectedStartDate =
        widget.initialDate ?? (widget.useDefault ? DateTime.now() : null);
    _selectedEndDate =
        widget.initialDate ?? (widget.useDefault ? DateTime.now() : null);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: widget.readOnly
              ? null
              : () {
                  _onMonthlyPressed(
                      context: context,
                      locale: 'en',
                      initialDate: _selectedStartDate);
                },
          child: Text(_selectedMonth),
        ),
      ],
    );
  }
}
