import 'package:buff_helper/pag_helper/model/ems/mdl_pag_tenant.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pagrid_helper/comm_helper/local_storage.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
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
  TenantItem? _selectedTenantItem;
  final List<MdlPagTenant> tenantList = [];
  final List<TenantItem> tenantItemList = [];
  final List<DropdownMenuItem<TenantItem>> tenantDropdownItemList = [];

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

    for (var tenant in tenantList) {
      tenantItemList.add(TenantItem(
        name: tenant.name,
        label: tenant.label,
        accountNumber: tenant.accountNumber,
      ));
    }
    tenantDropdownItemList.addAll(
      tenantItemList.map((tenantItem) {
        return DropdownMenuItem<TenantItem>(
          value: tenantItem,
          child: tenantItem,
        );
      }).toList(),
    );

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
    // NOTE: do not use class as value for Dropdown,
    // assigning a different class instance, even if it has the same values,
    // will be considered a different value, causing assertation error.
    // instead, use simple string labels as values.
    return SizedBox(
        child: DropdownButton<TenantItem>(
      itemHeight: 50,
      value: _selectedTenantItem,
      onChanged: (TenantItem? newValue) {
        if (newValue == null) {
          _selectedTenantItem = null;
        } else {
          _selectedTenantItem = newValue;
          for (var tenant in tenantList) {
            if (tenant.name == _selectedTenantItem!.name) {
              _selectedTenant = tenant;
              break;
            }
          }
        }
        widget.onTenantSelected(_selectedTenant);
        setState(() {});
        _saveScopePref();
      },
      items: tenantDropdownItemList,
    ));
  }
}

class TenantItem extends StatelessWidget {
  const TenantItem({
    super.key,
    required this.name,
    required this.label,
    required this.accountNumber,
  });

  final String name;
  final String label;
  final String? accountNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                accountNumber ?? '',
                style: TextStyle(
                    fontSize: 13.5,
                    color: Theme.of(context).hintColor.withAlpha(150)),
              ),
              horizontalSpaceSmall,
              Text(name,
                  style: TextStyle(
                      fontSize: 13.5, color: Theme.of(context).hintColor)),
            ],
          ),
        ],
      ),
    );
  }
}
