import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_ex.dart';
import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
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
import 'package:provider/provider.dart';

import '../../../../model/mdl_pag_app_config.dart';

class WgtCreateRole extends StatefulWidget {
  const WgtCreateRole({
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
  State<WgtCreateRole> createState() => _CreateRoleState();
}

class _CreateRoleState extends State<WgtCreateRole> {
  // late MdlPagUser? _loggedInUser;
  final double width = 395;

  bool _isEditing = false;
  bool _newItem = true;
  bool _createWait = false;
  bool _createSuccess = false;
  String _errorText = '';

  String? _newItemLabel;
  bool _isNewItemLabelValidated = false;

  String? _tag;
  bool _isTagValidated = false;
  bool _isTagRequired = false;

  PagPortalType? _portalType;

  PagRoleType? _roleType;

  String? _newItemName;

  final List<Map<String, dynamic>> _visibleRoleList = [];

  Map<String, dynamic> _itemScopeMap = {};
  UniqueKey? _scopeSetterKey;

  Future<dynamic> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
    });

    try {
      Map<String, dynamic> queryMap = {};
      queryMap['scope'] = widget.loggedInUser.selectedScope.toScopeMap();
      queryMap['label'] = _newItemLabel;
      queryMap['tag'] = _tag;
      queryMap['portal_type'] = _portalType?.value;
      queryMap['role_type'] = _roleType?.value;
      queryMap['item_scope_info'] = _itemScopeMap;

      final result = await ex(
        endpoint: PagUrlBase.eptPagCreateRole,
        crudType: 'create',
        opStr: 'create role',
        appConfig: widget.appConfig,
        queryMap: queryMap,
        svcClaim: MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      _newItemName = result['name'];

      _newItem = false;
      _createSuccess = true;
    } catch (e) {
      dev.log('error: $e');

      // setState(() {
      _errorText = getErrorText(e, defaultErrorText: 'Error creating role');

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

    if ((_tag ?? '').trim().isNotEmpty) {
      if (!_isTagValidated) {
        return false;
      }
    } else if (_isTagRequired) {
      return false;
    }

    return (_newItemLabel ?? '').trim().isNotEmpty &&
        _isNewItemLabelValidated &&
        _portalType != null &&
        _roleType != null &&
        _itemScopeMap.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    // _loggedInUser =
    //     Provider.of<PagUserProvider>(context, listen: false).currentUser;

    _visibleRoleList.clear();
    _visibleRoleList.addAll(widget.loggedInUser.selectedScope.projectProfile!
        .getVisibleRoleInfoList());
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
                  getItemBlock(),
                  verticalSpaceSmall,
                  getRoleTypeBlock(),
                  verticalSpaceSmall,
                  getPortalTypeBlock(),
                  verticalSpaceSmall,
                  getItemScopeSetter(),
                  verticalSpaceRegular,
                  WgtCommButton(
                    enabled: _checkEnableButton(),
                    label: _createWait
                        ? 'Creating role...'
                        : _createSuccess
                            ? '✓ Role created'
                            : 'Create Role',
                    onPressed:
                        !_checkEnableButton() //_selectedProjectScope == null
                            ? null
                            : () async {
                                await _createItem();

                                // reset the form
                                setState(() {
                                  // _newItem = true;
                                  _newItemLabel = null;
                                  // _newItemName = null;
                                  _itemScopeMap.clear();
                                  _scopeSetterKey = UniqueKey();
                                });
                                widget.onCreated?.call();
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
                        'Role ${_newItemName ?? ''} created',
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

    _isTagRequired = false;
    if (_portalType != PagPortalType.pagEmsTp &&
        _portalType != PagPortalType.pagEvsCp) {
      _isTagRequired = true;
    }

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
              // key: _labelResetKey,
              appConfig: widget.appConfig,
              hintText: 'Label',
              labelText: 'Label',
              maxLength: maxFullNameLength,
              requireUnique: true,
              validator: validateItemLabel,
              checkUnique: doPagCheckUnique,
              uniqueKey: 'label',
              itemTableName: 'pag.pag_acl_role',
              onUniqueCheck: (dynamic result) {
                if (result is bool) {
                  if (result) {
                    setState(() {
                      _isNewItemLabelValidated = false;
                      _errorText = 'Label already exists';
                    });
                  } else {
                    setState(() {
                      _isNewItemLabelValidated = true;
                    });
                  }
                } else if (result is String) {
                  if (result == 'taken') {
                    setState(() {
                      _isNewItemLabelValidated = false;
                      _errorText = 'Label already exists';
                    });
                  } else {
                    setState(() {
                      _isNewItemLabelValidated = false;
                      _errorText = result; // handle other error messages
                    });
                  }
                }
              },
              onChanged: (val) {
                setState(() {
                  _newItem = true;
                  _isEditing = true;
                  if (val != _newItemLabel) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    // _newCreate = true;
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
            WgtTextField(
              // key: _labelResetKey,
              appConfig: widget.appConfig,
              hintText: _isTagRequired ? 'Tag' : 'Tag (Optional)',
              labelText: _isTagRequired ? 'Tag' : 'Tag (Optional)',
              maxLength: maxFullNameLength,
              requireUnique: _isTagRequired,
              validator: validateRoleTag,
              checkUnique: doPagCheckUnique,
              uniqueKey: 'tag',
              itemTableName: 'pag.pag_acl_role',
              onUniqueCheck: (dynamic result) {
                if (result is bool) {
                  if (result) {
                    setState(() {
                      _isTagValidated = false;
                      _errorText = 'Tag already exists';
                    });
                  } else {
                    setState(() {
                      _isTagValidated = true;
                    });
                  }
                } else if (result is String) {
                  if (result == 'taken') {
                    setState(() {
                      _isTagValidated = false;
                      _errorText = 'Tag already exists';
                    });
                  } else {
                    setState(() {
                      _isTagValidated = false;
                      _errorText = result; // handle other error messages
                    });
                  }
                }
              },
              onChanged: (val) {
                setState(() {
                  _newItem = true;
                  _isEditing = true;
                  if (val != _tag) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    // _newCreate = true;
                    _createSuccess = false;
                  });
                }
                _tag = val;
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
                    _isTagValidated = true;
                  } else {
                    _isTagValidated = false;
                  }
                });
              },
            ),
          ]),
        )
      ],
    );
  }

  Widget getPortalTypeBlock() {
    // add all
    List<PagPortalType> availablePortalTypeList = [];
    for (var portalType in PagPortalType.values) {
      if (portalType == PagPortalType.none) {
        continue;
      }
      availablePortalTypeList.add(portalType);
    }

    return Row(
      children: [
        const Text('Portal Type:'),
        horizontalSpaceSmall,
        //dropdown to select portal type
        DropdownButton<PagPortalType>(
          value: _portalType,
          items: availablePortalTypeList
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  ))
              .toList(),
          onChanged: (val) {
            setState(() {
              _portalType = val;
              _newItem = true;
              _errorText = '';
            });
          },
        ),
      ],
    );
  }

  Widget getRoleTypeBlock() {
    // add all
    List<PagRoleType> availableRoleTypeList = [];
    for (var roleType in PagRoleType.values) {
      if (roleType == PagRoleType.unknown) {
        continue;
      }
      availableRoleTypeList.add(roleType);
    }

    return Row(
      children: [
        const Text('Role Type:'),
        horizontalSpaceSmall,
        //dropdown to select role type
        DropdownButton<PagRoleType>(
          value: _roleType,
          items: availableRoleTypeList
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  ))
              .toList(),
          onChanged: (val) {
            setState(() {
              _roleType = val;
              _newItem = true;
              _errorText = '';
            });
          },
        ),
      ],
    );
  }

  Widget getItemScopeSetter() {
    String projectName = widget.loggedInUser.selectedScope.projectProfile!.name;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: WgtScopeSetter(
        key: _scopeSetterKey,
        appConfig: widget.appConfig,
        width: width,
        labelWidth: 130,
        // itemScopeMap: widget.itemScopeMap!,
        forItemKind: PagItemKind.role,
        // forScopeType: widget.itemType is PagScopeType ? widget.itemType : null,
        onScopeSet: (dynamic profile) {
          if (profile == null) {
            dev.log('Profile is null');
            return {};
          }
          String scopeIdColName = '';
          String scopeName = '';
          if (profile is MdlPagSiteGroupProfile) {
            scopeIdColName = 'site_group_id';
            scopeName = 'site_group_name';
          } else if (profile is MdlPagSiteProfile) {
            scopeIdColName = 'site_id';
            scopeName = 'site_name';
          } else if (profile is MdlPagBuildingProfile) {
            scopeIdColName = 'building_id';
            scopeName = 'building_name';
          } else if (profile is MdlPagLocationGroupProfile) {
            scopeIdColName = 'location_group_id';
            scopeName = 'location_group_name';
          } else if (profile is MdlPagLocation) {
            scopeIdColName = 'location_id';
            scopeName = 'location_name';
          }
          if (scopeIdColName.isEmpty) {
            dev.log('Invalid profile type');

            return {};
          }
          setState(() {
            _newItem = true;
            _itemScopeMap['project_name'] = projectName;
            _itemScopeMap[scopeIdColName] = profile.id.toString();
            _itemScopeMap[scopeName] = profile.name;
          });
        },
      ),
    );
  }
}
