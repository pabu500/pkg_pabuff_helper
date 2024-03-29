import 'package:flutter/material.dart';

class WgtListSortIcon extends StatefulWidget {
  WgtListSortIcon({
    Key? key,
    this.labelWidget,
    this.sortOrder,
    required this.onSort,
    this.parentRefreshKey,
  });

  final Widget? labelWidget;
  final String? sortOrder;
  final void Function(String) onSort;
  final UniqueKey? parentRefreshKey;

  @override
  _WgtListSortIconState createState() => _WgtListSortIconState();
}

class _WgtListSortIconState extends State<WgtListSortIcon> {
  late String _sortOrder;
  UniqueKey? _parentRefreshKey;
  @override
  void initState() {
    super.initState();
    _sortOrder = widget.sortOrder ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.parentRefreshKey != null &&
        _parentRefreshKey != widget.parentRefreshKey) {
      _parentRefreshKey = widget.parentRefreshKey;
      _sortOrder = widget.sortOrder ?? '';
    }
    return Tooltip(
      message: _sortOrder == 'asc'
          ? 'Sort descending'
          : _sortOrder == 'desc'
              ? 'Sort ascending'
              : 'No sort',
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        child: Row(
          children: [
            widget.labelWidget ?? Container(),
            Icon(
              _sortOrder == 'asc'
                  ? Icons.arrow_drop_up
                  : _sortOrder == 'desc'
                      ? Icons.arrow_drop_down
                      // : Icons.unfold_less,
                      // : Icons.import_export,
                      : Icons.arrow_left_outlined,
              size: 21,
              color: Theme.of(context).hintColor,
            ),
          ],
        ),
        onTap: () {
          setState(() {
            //rotate between asc, desc, and no sort
            // _sortOrder = _sortOrder == 'asc'
            //     ? 'desc'
            //     : _sortOrder == 'desc'
            //         ? ''
            //         : 'asc';

            //rotate between asc, desc
            _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
          });
          widget.onSort(_sortOrder);
        },
      ),
    );
  }
}
