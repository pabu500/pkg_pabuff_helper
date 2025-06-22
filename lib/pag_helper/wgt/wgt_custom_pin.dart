import 'package:flutter/material.dart';

class WgtCustomPin extends StatefulWidget {
  const WgtCustomPin({
    super.key,
    required this.name,
    required this.initialPinned,
    required this.onUpdatePinned,
  });

  final String name;
  final bool initialPinned;
  final Function(bool) onUpdatePinned;

  @override
  State<WgtCustomPin> createState() => _WgtCustomPinState();
}

class _WgtCustomPinState extends State<WgtCustomPin> {
  late bool _pinned;

  // void _loadCustomize() {
  //   String key = '${widget.name}_pinned';
  //   bool? pinned = readFromSharedPref(key);

  //   if (pinned != null) {
  //     _pinned = pinned;
  //     widget.onUpdatePinned(_pinned);
  //   }
  // }

  // void _saveCustomize() {
  //   String key = '${widget.name}_pinned';

  //   saveToSharedPref(key, _pinned);
  // }

  @override
  void initState() {
    super.initState();

    _pinned = widget.initialPinned;

    // _loadCustomize();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _pinned = !_pinned;
        });
        widget.onUpdatePinned(_pinned);
        // _saveCustomize();
      },
      child: Icon(
        _pinned ? Icons.push_pin : Icons.push_pin_outlined,
        size: 16,
        color: _pinned
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).hintColor.withAlpha(180),
      ),
    );
  }
}
