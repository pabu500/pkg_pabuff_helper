import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_org.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

import '../../../../comm/comm_ex.dart';
import '../../../../comm/pag_be_api_base.dart';
import '../../../../def_helper/dh_acl.dart';
import '../../../../def_helper/dh_pag_item.dart';
import '../../../../model/scope/mdl_pag_building_profile.dart';
import '../../../../model/scope/mdl_pag_location.dart';
import '../../../../model/scope/mdl_pag_location_group_profile.dart';
import '../../../../model/scope/mdl_pag_site_group_profile.dart';
import '../../../../model/scope/mdl_pag_site_profile.dart';
import '../../../scope/wgt_scope_setter.dart';

class WgtCreatePermission extends StatefulWidget {
  const WgtCreatePermission({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    this.showTitle = true,
    this.showPortalType = true,
    this.showEnabled = true,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final bool showTitle;
  final bool showPortalType;
  final bool showEnabled;
  final Function? onCreated;

  @override
  State<WgtCreatePermission> createState() => _CreatePermissionState();
}

class _CreatePermissionState extends State<WgtCreatePermission> {
  // late MdlPagUser? _loggedInUser;
  final double width = 395;

  bool _isEditing = false;
  bool _newItem = true;

  bool _newCreate = false;
  bool _createWait = false;
  bool _createSuccess = false;
  String _errorText = '';

  // String? _newItemLabel;
  String? _newItemName;

  String? _label;
  bool _isLabelValidated = false;
  UniqueKey? _labelResetKey;

  PagAclOperationType? _selectedOperationType;

  final Map<String, dynamic> _itemScopeMap = {};
  UniqueKey? _scopeSetterKey;

  Future<dynamic> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
    });

    try {
      Map<String, dynamic> queryMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'acl_type': PagAclType.permission.value,
        'label': _label,
        'operation': _selectedOperationType?.value,
        'item_scope_info': _itemScopeMap,
      };

      final result = await ex(
        endpoint: PagUrlBase.eptCreateAclItem,
        crudType: 'create',
        opStr: 'create permission',
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

      _label = result['label'];
      _newItemName = result['name'];

      _newItem = false;
      _createSuccess = true;
    } catch (e) {
      dev.log('error: $e');

      // setState(() {
      // _errorText = 'Error creating item';
      // String eStr = e.toString().toLowerCase();
      _errorText =
          getErrorText(e, defaultErrorText: 'Error creating permission');

      // dev.log('error: $eStr');

      _newItem = true;
      _createSuccess = false;
      // });

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

    if (!_isLabelValidated) {
      return false;
    }

    if (_selectedOperationType == null) {
      return false;
    }

    if (_itemScopeMap.isEmpty) {
      return false;
    }

    return true;
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
                  getItemBlock(),
                  verticalSpaceTiny,
                  getOperationSelector(),
                  verticalSpaceTiny,
                  getItemScopeSetter(),
                  verticalSpaceRegular,
                  WgtCommButton(
                    enabled: _checkEnableButton(),
                    label: _createWait
                        ? 'Adding Permission...'
                        : _createSuccess
                            ? '✓ Permission added'
                            : 'Add Permission',
                    onPressed:
                        !_checkEnableButton() //_selectedProjectScope == null
                            ? null
                            : () async {
                                await _createItem();

                                // reset the form
                                setState(() {
                                  // _newItem = true;
                                  _newCreate = false;
                                  _createWait = false;
                                  // _createSuccess = false;
                                  // _errorText = '';
                                  // _newItem = true;

                                  _label = null;
                                  _isLabelValidated = false;
                                  _labelResetKey = UniqueKey();
                                });

                                widget.onCreated?.call();
                              },
                  ),
                  if (_newItem && !_createSuccess && _errorText.isNotEmpty)
                    getErrorTextPrompt(context: context, errorText: _errorText),
                  if (!_newItem && _createSuccess && _errorText.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        'Permission ${_newItemName ?? ''} created',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  verticalSpaceMedium,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getItemBlock() {
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
          child: Column(
            children: [
              WgtTextField(
                key: _labelResetKey,
                appConfig: widget.appConfig,
                hintText: 'Label (Required)',
                labelText: 'Label (Required)',
                maxLength: maxFullNameLength,
                maxLines: 1,
                validator: validateItemLabel,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'label',
                itemTableName: '$projectName.acl_perm_$projectName',
                onUniqueCheck: (dynamic result) {
                  if (result is bool) {
                    if (result) {
                      setState(() {
                        _isLabelValidated = false;
                        _errorText = 'Label already exists';
                      });
                    } else {
                      setState(() {
                        _isLabelValidated = true;
                      });
                    }
                  } else if (result is String) {
                    if (result == 'taken') {
                      setState(() {
                        _isLabelValidated = false;
                        _errorText = 'Label already exists';
                      });
                    } else {
                      setState(() {
                        _isLabelValidated = false;
                        _errorText = result; // handle other error messages
                      });
                    }
                  }
                },
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _label) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _label = val;
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
                      _isLabelValidated = true;
                    } else {
                      _isLabelValidated = false;
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget getOperationSelector() {
    // hard code for now
    List<PagAclOperationType> meterTypeList = [
      PagAclOperationType.create,
      PagAclOperationType.read,
      PagAclOperationType.update,
      PagAclOperationType.delete,
      PagAclOperationType.list,
      PagAclOperationType.all,
    ];
    TextStyle dropDownListTextStyle = TextStyle(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500);
    TextStyle dropDownListHintStyle =
        TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
    Widget dropDownUnderline =
        Container(height: 1, color: Theme.of(context).hintColor.withAlpha(75));
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text('Operation Type:',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 130,
          child: DropdownButton<PagAclOperationType>(
              alignment: AlignmentDirectional.centerStart,
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Operation Type', style: dropDownListHintStyle)),
              value: _selectedOperationType,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (PagAclOperationType? value) async {
                if (value != null) {
                  if (value == _selectedOperationType) {
                    return;
                  }
                }
                setState(() {
                  _selectedOperationType = value!;
                  _newItem = true;
                  _createSuccess = false;
                });
              },
              items: meterTypeList.map<DropdownMenuItem<PagAclOperationType>>(
                  (PagAclOperationType value) {
                return DropdownMenuItem<PagAclOperationType>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(value.name),
                  ),
                );
              }).toList()),
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
