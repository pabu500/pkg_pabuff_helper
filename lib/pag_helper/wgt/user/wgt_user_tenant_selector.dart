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
    this.initialTenant,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  // final List<MdlPagRole> roleList;
  final Function(MdlPagTenant?) onTenantSelected;
  final MdlPagTenant? initialTenant;

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
    }
    if (widget.initialTenant != null) {
      _selectedTenant = widget.initialTenant;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTenantSelected(_selectedTenant);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> tenantLabelList =
        tenantList.map((MdlPagTenant tenant) => tenant.label).toList();

    // NOTE: do not use class as value for Dropdown,
    // assigning a different class instance, even if it has the same values,
    // will be considered a different value, causing assertation error.
    // instead, use simple string labels as values.
    return SizedBox(
        child: DropdownButton<String>(
      isDense: true,
      value: _selectedTenant?.label,
      onChanged: (String? tenantLabel) {
        MdlPagTenant? tenant;
        if (tenantLabel != null) {
          for (MdlPagTenant t in tenantList) {
            if (t.label == tenantLabel) {
              tenant = t;
              break;
            }
          }
        }

        setState(() {
          _selectedTenant = tenant;
        });

        widget.onTenantSelected(tenant);

        _saveScopePref();
      },
      items: tenantLabelList.map<DropdownMenuItem<String>>(
        (String label) {
          return DropdownMenuItem<String>(
            value: label,
            child: Text(label),
          );
        },
      ).toList(),
    ));
  }
}
