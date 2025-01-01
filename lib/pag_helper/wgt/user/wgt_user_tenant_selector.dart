import 'package:buff_helper/pag_helper/model/ems/mdl_pag_tenant.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pagrid_helper/comm_helper/local_storage.dart';
import 'package:flutter/material.dart';

class WgtUserTenantSelector extends StatefulWidget {
  const WgtUserTenantSelector({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    // required this.roleList,
    required this.onTenantSelected,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  // final List<MdlPagRole> roleList;
  final Function(MdlPagTenant) onTenantSelected;

  @override
  State<WgtUserTenantSelector> createState() => _WgtUserTenantSelectorState();
}

class _WgtUserTenantSelectorState extends State<WgtUserTenantSelector> {
  MdlPagTenant? _selectedTenant;
  final List<MdlPagTenant> tenantList = [];

  void _saveScopePref() {
    if (_selectedTenant == null) return;

    Map<String, dynamic> tenantPref = {};
    tenantPref['selected_tenant_name'] = _selectedTenant!.name;
    saveToSharedPref('tenant_pref', tenantPref, removeBeforeSave: true);
  }

  @override
  void initState() {
    super.initState();

    // _selectedTenant = widget.loggedInUser.selectedRole;
    // assert(_selectedTenant != null);
    tenantList.addAll(widget.loggedInUser.getScopeTenantList());

    if (tenantList.length == 1) {
      _selectedTenant = tenantList[0];
      widget.onTenantSelected(_selectedTenant!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: DropdownButton<MdlPagTenant>(
        isDense: true,
        value: _selectedTenant,
        onChanged: (MdlPagTenant? tenant) {
          if (tenant != null) {
            setState(() {
              // widget.loggedInUser.updateSelectedRole(
              //   tenant,
              //   lazyLoadScope: widget.appConfig.lazyLoadScope,
              // );
              _selectedTenant = tenant;
            });

            widget.onTenantSelected(tenant);

            _saveScopePref();
          }
        },
        items: tenantList
            .map(
              (MdlPagTenant tenant) => DropdownMenuItem<MdlPagTenant>(
                value: tenant,
                child: Text(tenant.label),
              ),
            )
            .toList(),
      ),
    );
  }
}
