import 'package:buff_helper/pag_helper/model/acl/mdl_pag_role.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_error_text_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:buff_helper/pag_helper/comm/comm_user_service.dart';

import '../../model/mdl_pag_app_config.dart';

class WgtUesrRoleSetter extends StatefulWidget {
  const WgtUesrRoleSetter({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.userIndexStr,
    this.width = 395,
    this.height,
    this.targetPortalTypeStr,
    this.onUserRoleListLoaded,
    this.onUserRoleListSet,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final String userIndexStr;
  final double width;

  /// Minimum height; assigned roles can expand the editor beyond it.
  final double? height;
  final String? targetPortalTypeStr;
  final Function(List<Map<String, dynamic>>)? onUserRoleListLoaded;
  final Function(List<Map<String, dynamic>>)? onUserRoleListSet;

  @override
  State<WgtUesrRoleSetter> createState() => _WgtUesrRoleSetterState();
}

class _WgtUesrRoleSetterState extends State<WgtUesrRoleSetter> {
  final List<Map<String, dynamic>> _userRoleListOriginal = [];
  final List<Map<String, dynamic>> _userRoleList = [];
  String _errorTextRoleList = '';

  bool _isEditing = false;
  bool _isCommitting = false;
  bool _isModified = false;
  bool _showCommitted = true;
  String _committedMessage = '';
  String _committErrorText = '';
  late Future<void> _roleListFuture;
  final TextEditingController _searchController = TextEditingController();

  Future<void> _commit() async {
    setState(() {
      _committErrorText = '';
      _isCommitting = true;
    });
    try {
      final result = await commitUserRoleList(
        widget.appConfig,
        widget.loggedInUser,
        {
          'scope': widget.loggedInUser.selectedScope.toScopeMap(),
          'user_id': widget.userIndexStr,
          'user_role_list': _userRoleList,
        },
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: 'update',
        ),
      );
      if (!mounted) return;
      if (result['error'] != null) throw Exception(result['error']);
      setState(() {
        _updateOriginal();
        _isEditing = false;
        _isModified = false;
        _showCommitted = true;
        _committedMessage = result['message'] ?? 'Changes saved';
        _searchController.clear();
      });
      widget.onUserRoleListSet?.call(
        _userRoleList.map((role) => Map<String, dynamic>.from(role)).toList(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _committErrorText = 'Error saving roles. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isCommitting = false);
    }
  }

  Future<void> _getUserRoleList() async {
    try {
      final result = await doGetUserRoleList(
        widget.loggedInUser,
        widget.appConfig,
        {
          'scope': widget.loggedInUser.selectedScope.toScopeMap(),
          'user_id': widget.userIndexStr,
        },
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );
      if (!mounted) return;
      _userRoleList.clear();
      for (MdlPagRole role in result['user_role_list']) {
        _userRoleList.add(role.toJson());
      }
      _updateOriginal();
      widget.onUserRoleListLoaded?.call(
        _userRoleList.map((role) => Map<String, dynamic>.from(role)).toList(),
      );
    } catch (e) {
      _errorTextRoleList = 'Error getting role list';
      rethrow;
    }
  }

  String _roleKey(Map<String, dynamic> role) => role['name'] as String;

  void _updateOriginal() {
    _userRoleListOriginal
      ..clear()
      ..addAll(_userRoleList.map((role) => Map<String, dynamic>.from(role)));
  }

  void _restoreOriginal() {
    setState(() {
      _isModified = false;
      _isEditing = false;
      _committErrorText = '';
      _searchController.clear();
      _userRoleList
        ..clear()
        ..addAll(
          _userRoleListOriginal.map((role) => Map<String, dynamic>.from(role)),
        );
    });
  }

  // Use the target user's saved profile, so removing a role during an edit
  // does not change which roles can be added in the same edit.
  bool _matchesProfile(Map<String, dynamic> role) {
    // Admins can assign a first role from another portal profile.
    if (widget.loggedInUser.selectedRole?.isAdmin() ?? false) return true;

    final profileTypes = widget.targetPortalTypeStr
        ?.split(',')
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toSet();
    final types = profileTypes == null || profileTypes.isEmpty
        ? _userRoleListOriginal.map((role) => role['portal_type']).toSet()
        : profileTypes;
    final hasTenant = types.contains(PagPortalType.pagEmsTp.value);
    final opsTypes = {
      PagPortalType.pagConsole.value,
      PagPortalType.pagConsoleApp.value,
      PagPortalType.pagCmApp.value,
    };
    final hasOps = types.any(opsTypes.contains);
    if (hasTenant && hasOps) return true;
    if (hasTenant) return role['portal_type'] == PagPortalType.pagEmsTp.value;
    if (hasOps) return opsTypes.contains(role['portal_type']);
    // A user with no profile yet needs a first role to establish one.
    return types.isEmpty || types.contains(role['portal_type']);
  }

  void _setRole(Map<String, dynamic> role, bool selected) {
    setState(() {
      if (selected) {
        if (!_userRoleList.any((item) => _roleKey(item) == _roleKey(role))) {
          _userRoleList.add(Map<String, dynamic>.from(role));
        }
      } else {
        _userRoleList.removeWhere((item) => _roleKey(item) == _roleKey(role));
      }
      _isModified = !setEquals(
        _userRoleList.map(_roleKey).toSet(),
        _userRoleListOriginal.map(_roleKey).toSet(),
      );
      _committErrorText = '';
    });
  }

  @override
  void initState() {
    super.initState();
    _roleListFuture = _getUserRoleList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      constraints: BoxConstraints(minHeight: widget.height ?? 0),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: FutureBuilder<void>(
        future: _roleListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: WgtPagWait(size: 21));
          }
          if (snapshot.hasError) {
            return getErrorTextPrompt(
              context: context,
              errorText: _errorTextRoleList,
            );
          }
          return getCompletedUserRoleList();
        },
      ),
    );
  }

  Widget _roleRow(Map<String, dynamic> role, bool assigned) {
    return CheckboxListTile(
      key: ValueKey('role-${_roleKey(role)}'),
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      visualDensity: VisualDensity.compact,
      title: Text(role['label'] ?? role['name']),
      value: assigned,
      onChanged: _isEditing && !_isCommitting
          ? (selected) => _setRole(role, selected ?? false)
          : null,
    );
  }

  Widget getCompletedUserRoleList() {
    final assignedNames = _userRoleList.map(_roleKey).toSet();
    final query = _searchController.text.trim().toLowerCase();
    final seenNames = <String>{};
    final availableRoles = <Map<String, dynamic>>[];
    for (final role
        in widget.loggedInUser.selectedScope.projectProfile!.visibleRoleList) {
      final info = role.toJson();
      if (!seenNames.add(role.name) ||
          assignedNames.contains(role.name) ||
          !_matchesProfile(info)) {
        continue;
      }
      if (query.isNotEmpty &&
          !'${role.label ?? ''} ${role.name}'.toLowerCase().contains(query)) {
        continue;
      }
      availableRoles.add(info);
    }
    final availableList = availableRoles.isEmpty
        ? Center(
            child: Text(
              query.isEmpty
                  ? 'No unassigned roles available'
                  : 'No matching roles',
            ),
          )
        : ListView.builder(
            itemCount: availableRoles.length,
            itemBuilder: (context, index) =>
                _roleRow(availableRoles[index], false),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Assigned roles (${_userRoleList.length})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (_userRoleList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 3),
            child: Text('No roles assigned'),
          )
        else
          for (final role in _userRoleList) _roleRow(role, true),
        verticalSpaceTiny,
        const Text('Add roles', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: _searchController,
          enabled: _isEditing && !_isCommitting,
          decoration: InputDecoration(
            hintText: 'Search unassigned roles',
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(_searchController.clear),
                  ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        SizedBox(height: 180, child: availableList),
        if (_committErrorText.isNotEmpty)
          Text(
            _committErrorText,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        getControl(),
      ],
    );
  }

  Widget getControl({String errorText = ''}) {
    bool enableCommit = false;
    bool showClear = false;

    if (_isModified || _isEditing) {
      enableCommit = true;
      showClear = true;
    }

    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 8),
          SizedBox(
            width: 35,
            child: showClear
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel changes',
                    onPressed: _isCommitting ? null : _restoreOriginal,
                  )
                : Container(),
          ),
          Expanded(child: Container()),
          if (_showCommitted)
            Row(
              children: [
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    _committedMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          Expanded(child: Container()),
          _isEditing
              ? IconButton(
                  icon: Icon(
                    Icons.check,
                    color: enableCommit
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  tooltip: 'Save roles',
                  onPressed: !enableCommit || _isCommitting
                      ? null
                      : () async {
                          if (!_isModified) {
                            setState(() {
                              _isEditing = false;
                            });
                            return;
                          }

                          await _commit();
                        },
                )
              : IconButton(
                  icon: Icon(Icons.edit, color: Theme.of(context).hintColor),
                  tooltip: 'Edit roles',
                  onPressed: () {
                    setState(() {
                      _committErrorText = '';
                      _isEditing = true;
                      _showCommitted = false;
                    });
                  },
                ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
