import 'package:buff_helper/pag_helper/comm/comm_pref.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

class WgtPagListColumnCustomize2 extends StatefulWidget {
  const WgtPagListColumnCustomize2({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.projectId,
    required this.prefKey,
    required this.listController,
    required this.defaultColumnVisibility,
    required this.revision,
    required this.onSet,
    this.listHeight = 160,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final int projectId;
  final String prefKey;
  final MdlPagListController listController;
  final Map<String, bool> defaultColumnVisibility;
  final int revision;
  final ValueChanged<int> onSet;
  final double listHeight;

  @override
  State<WgtPagListColumnCustomize2> createState() =>
      _WgtPagListColumnCustomize2State();
}

class _WgtPagListColumnCustomize2State
    extends State<WgtPagListColumnCustomize2> {
  final Map<String, bool> _draft = {};
  bool _saving = false;
  String? _error;
  late int _revision;

  @override
  void initState() {
    super.initState();
    _revision = widget.revision;
    for (final column in widget.listController.listColControllerList) {
      _draft[column.colKey] = column.showColumn;
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final visibility = <String, bool>{};
      for (final column in widget.listController.listColControllerList) {
        if (!column.hidden && column.colTitle.isNotEmpty) {
          visibility[column.colKey] =
              _draft[column.colKey] ?? column.showColumn;
        }
      }
      final saved = await setListColumnPreference(
        appConfig: widget.appConfig,
        user: widget.loggedInUser,
        projectId: widget.projectId,
        prefKey: widget.prefKey,
        columnVisibility: visibility,
        expectedRevision: _revision,
      );
      if (!mounted) return;
      _applyVisibility(visibility);
      widget.onSet(saved.revision);
      Navigator.of(context).pop();
    } catch (error) {
      await _handleSaveError(error);
    }
  }

  Future<void> _reset() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await resetListColumnPreference(
        appConfig: widget.appConfig,
        user: widget.loggedInUser,
        projectId: widget.projectId,
        prefKey: widget.prefKey,
        expectedRevision: _revision,
      );
      if (!mounted) return;
      _applyVisibility(widget.defaultColumnVisibility);
      widget.onSet(0);
      Navigator.of(context).pop();
    } catch (error) {
      await _handleSaveError(error);
    }
  }

  Future<void> _handleSaveError(Object error) async {
    var message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('Preference revision conflict')) {
      try {
        final latest = await getListColumnPreference(
          appConfig: widget.appConfig,
          user: widget.loggedInUser,
          projectId: widget.projectId,
          prefKey: widget.prefKey,
        );
        _revision = latest.revision;
        message = 'Columns changed elsewhere. Review and press Set again.';
      } catch (_) {
        // Retain the original conflict if the refresh also fails.
      }
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = message;
    });
  }

  void _applyVisibility(Map<String, bool> visibility) {
    for (final column in widget.listController.listColControllerList) {
      if (!column.hidden && visibility.containsKey(column.colKey)) {
        column.showColumn = visibility[column.colKey]!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.listController.listColControllerList
        .where((column) => !column.hidden && column.colTitle.isNotEmpty)
        .toList();
    return SizedBox(
      height: widget.listHeight + 55,
      child: Column(
        children: [
          verticalSpaceSmall,
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: columns.map(_columnOption).toList(),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _error!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _saving ? null : _reset,
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Set'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _columnOption(MdlListColController column) {
    return Row(
      children: [
        Transform.scale(
          scale: 0.8,
          child: Checkbox(
            value: _draft[column.colKey] ?? column.showColumn,
            onChanged: _saving
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _draft[column.colKey] = value);
                  },
          ),
        ),
        Expanded(
          child: Text(
            column.colTitle,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
      ],
    );
  }
}
