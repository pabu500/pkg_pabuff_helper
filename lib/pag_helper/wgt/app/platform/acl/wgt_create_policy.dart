import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_ex.dart';
import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_building_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_profile.dart';
import 'package:buff_helper/pag_helper/wgt/scope/wgt_scope_setter.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

import '../../../../def_helper/dh_acl.dart';
import '../../../../model/mdl_pag_app_config.dart';

class WgtCreatePolicy extends StatefulWidget {
  const WgtCreatePolicy({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Function? onCreated;

  @override
  State<WgtCreatePolicy> createState() => _WgtCreatePolicyState();
}

class _WgtCreatePolicyState extends State<WgtCreatePolicy> {
  // late MdlPagUser? _loggedInUser;
  final double width = 395;

  bool _isEditing = false;
  bool _newItem = true;
  bool _createWait = false;
  bool _createSuccess = false;
  String _errorText = '';

  String? _newItemLabel;
  String? _newItemName;
  bool _isNewItemLabelValidated = false;
  UniqueKey? _newItemLabelResetKey;

  final Map<String, dynamic> _itemScopeMap = {};
  UniqueKey? _scopeSetterKey;

  Future<dynamic> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
      _newItemName = null;
    });

    try {
      _itemScopeMap['project_id'] =
          widget.loggedInUser.selectedScope.projectProfile!.id.toString();
      _itemScopeMap['project_name'] =
          widget.loggedInUser.selectedScope.projectProfile!.name;

      Map<String, dynamic> queryMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'item_kind': PagItemKind.acl.value,
        'acl_type': PagAclType.policy.value,
        'label': _newItemLabel,
        'item_scope_info': _itemScopeMap,
      };

      final result = await ex(
        endpoint: PagUrlBase.eptCreateAclItem,
        crudType: 'create',
        opStr: 'create policy',
        appConfig: widget.appConfig,
        queryMap: queryMap,
        svcClaim: MdlPagSvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          roleId: widget.loggedInUser.selectedRole?.id,
          roleName: widget.loggedInUser.selectedRole?.name,
          roleLabel: widget.loggedInUser.selectedRole?.label,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      _newItemLabel = result['label'];
      _newItemName = result['name'];

      _newItem = false;
      _createSuccess = true;
    } catch (e) {
      dev.log('error: $e');

      // _errorText = 'Error creating resource';
      // String eStr = e.toString().toLowerCase();
      _errorText = getErrorText(e, defaultErrorText: 'Error creating policy');

      _newItem = true;
      _createSuccess = false;

      return;
    } finally {
      setState(() {
        _createWait = false;
      });
    }
  }

  bool _checkEnableButton() {
    if (!_newItem) {
      return false;
    }
    if (_createWait) {
      return false;
    }
    if (_errorText.isNotEmpty) {
      return false;
    }
    if (_newItemLabel == null || !_isNewItemLabelValidated) {
      return false;
    }

    return _newItemLabel != null && _itemScopeMap.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    // _loggedInUser =
    //     Provider.of<PagUserProvider>(context, listen: false).currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: width,
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: [
                  // verticalSpaceRegular,
                  // getServiceTypeSelector(),
                  // verticalSpaceTiny,
                  getBasicInfoBlock(),
                  verticalSpaceTiny,
                  getItemScopeSetter(),
                  verticalSpaceRegular,
                  WgtCommButton(
                    enabled: _checkEnableButton(),
                    label: _createWait
                        ? 'Creating policy...'
                        : _createSuccess
                            ? '✓ Policy created'
                            : 'Create Policy',
                    onPressed:
                        !_checkEnableButton() //_selectedProjectScope == null
                            ? null
                            : () async {
                                await _createItem();
                                if (_newItem &&
                                    !_createSuccess &&
                                    _errorText.isNotEmpty) {
                                  // don't reset the form if there is an error creating the item, allow user to fix the error
                                } else {
                                  // reset the form
                                  setState(() {
                                    // _newItem = true;
                                    _newItemLabel = null;
                                    _isNewItemLabelValidated = false;
                                    _newItemLabelResetKey = UniqueKey();

                                    _itemScopeMap.clear();
                                    _scopeSetterKey = UniqueKey();
                                  });

                                  widget.onCreated?.call();
                                }
                              },
                  ),
                  if (_newItem && !_createSuccess && _errorText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(_errorText,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ),
                  if (!_newItem && _createSuccess && _errorText.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        'Policy ${_newItemName ?? ''} created',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  verticalSpaceRegular,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getBasicInfoBlock() {
    MdlPagScopeProfile scopeProfile = widget.loggedInUser.selectedScope;
    String projectName = scopeProfile.projectProfile!.name;

    return Column(
      children: [
        verticalSpaceTiny,
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).hintColor.withAlpha(30),
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Column(children: [
            WgtTextField(
              key: _newItemLabelResetKey,
              appConfig: widget.appConfig,
              hintText: 'Label',
              labelText: 'Label',
              maxLength: maxFullNameLength,
              validator: validateTenantLabel,
              checkUnique: doPagCheckUnique,
              uniqueKey: 'label',
              itemTableName: '$projectName.acl_policy_$projectName',
              onChanged: (val) {
                setState(() {
                  _isEditing = true;
                  if (val != _newItemLabel) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _newItem = true;
                    _createSuccess = false;
                  });
                }
                _newItemLabel = val;
                return null;
              },
              onEditingComplete: () {
                setState(() {
                  _isEditing = false;
                });
              },
              onValidate: (String? result) {
                setState(() {
                  if (result == null) {
                    _isNewItemLabelValidated = true;
                  } else {
                    _isNewItemLabelValidated = false;
                  }
                });
              },
            ),
          ]),
        ),
      ],
    );
  }

  Widget getItemScopeSetter() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: WgtScopeSetter(
        key: _scopeSetterKey,
        appConfig: widget.appConfig,
        width: width,
        labelWidth: 130,
        // itemScopeMap: widget.itemScopeMap!,
        forItemKind: PagItemKind.acl,
        // forScopeType: widget.itemType is PagScopeType ? widget.itemType : null,
        onScopeSet: (dynamic profile) {
          if (profile == null) {
            dev.log('Profile is null');
            return {};
          }
          String scopeIdColName = '';
          String scopeNameColName = '';
          if (profile is MdlPagSiteGroupProfile) {
            scopeIdColName = 'site_group_id';
            scopeNameColName = 'site_group_name';
          } else if (profile is MdlPagSiteProfile) {
            scopeIdColName = 'site_id';
            scopeNameColName = 'site_name';
          } else if (profile is MdlPagBuildingProfile) {
            scopeIdColName = 'building_id';
            scopeNameColName = 'building_name';
          } else if (profile is MdlPagLocationGroupProfile) {
            scopeIdColName = 'location_group_id';
            scopeNameColName = 'location_group_name';
          } else if (profile is MdlPagLocation) {
            scopeIdColName = 'location_id';
            scopeNameColName = 'location_name';
          }
          if (scopeIdColName.isEmpty) {
            dev.log('Invalid profile type');
            return {};
          }
          setState(() {
            _itemScopeMap[scopeIdColName] = profile.id.toString();
            _itemScopeMap[scopeNameColName] = profile.name;
          });
        },
      ),
    );
  }
}
