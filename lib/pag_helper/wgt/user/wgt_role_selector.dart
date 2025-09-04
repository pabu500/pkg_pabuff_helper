import 'package:buff_helper/pag_helper/model/acl/mdl_pag_role.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pagrid_helper/comm_helper/local_storage.dart';
import 'package:flutter/material.dart';

class WgtRoleSelector extends StatefulWidget {
  const WgtRoleSelector({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    // required this.roleList,
    required this.onRoleSelected,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  // final List<MdlPagRole> roleList;
  final Function(MdlPagRole) onRoleSelected;

  @override
  State<WgtRoleSelector> createState() => _WgtRoleSelectorState();
}

class _WgtRoleSelectorState extends State<WgtRoleSelector> {
  MdlPagRole? _selectedRole;
  final List<MdlPagRole> roleList = [];

  void _saveScopePref() {
    if (_selectedRole == null) return;

    Map<String, dynamic> rolePref = {};
    rolePref['selected_role_name'] = _selectedRole!.name;
    saveToSharedPref('role_pref', rolePref, removeBeforeSave: true);
  }

  @override
  void initState() {
    super.initState();

    _selectedRole = widget.loggedInUser.selectedRole;

    roleList.addAll(
        widget.loggedInUser.getRoleList(widget.appConfig.portalType.value));

    assert(_selectedRole != null);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: DropdownButton<MdlPagRole>(
        isDense: true,
        value: _selectedRole,
        onChanged: (MdlPagRole? role) {
          if (role != null) {
            setState(() {
              widget.loggedInUser.updateSelectedRole(
                role,
                lazyLoadScope: widget.appConfig.lazyLoadScope,
              );
              _selectedRole = role;
            });

            widget.onRoleSelected(role);

            _saveScopePref();

            //close
            Navigator.of(context).pop();
          }
        },
        items:
            // widget.roleList
            roleList
                .map(
                  (MdlPagRole role) => DropdownMenuItem<MdlPagRole>(
                    value: role,
                    child: Text(role.label ?? role.name),
                  ),
                )
                .toList(),
      ),
    );
  }
}
