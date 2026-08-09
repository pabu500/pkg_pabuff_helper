import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_user_service.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/up_helper/helper/auth_helper.dart';
import 'package:buff_helper/xt_ui/util/xt_util_InputFieldValidator.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_error_text_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/input/wgt_pag_text_field2.dart';
import 'package:buff_helper/xt_ui/wdgt/input/wgt_text_field2.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:buff_helper/xt_ui/wdgt/xtTextField.dart';
import 'package:buff_helper/xt_ui/xt_globals.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_user.dart';
import 'package:provider/provider.dart';

import '../../../../model/mdl_pag_app_config.dart';

class WgtCreateUser2 extends StatefulWidget {
  const WgtCreateUser2({
    super.key,
    required this.appConfig,
    this.showTitle = true,
    this.showPortalType = true,
    this.showEnabled = true,
    this.requirePhone = false,
    this.passwordValidator,
    this.requireUniqueEmail = false,
    this.sendVerificationEmail = false,
    this.postRegRedirect = false,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final bool showTitle;
  final bool showPortalType;
  final bool showEnabled;
  final bool requirePhone;
  final String? Function(String)? passwordValidator;
  final bool requireUniqueEmail;
  final bool sendVerificationEmail;
  final bool postRegRedirect;
  final Function? onCreated;
  @override
  State<WgtCreateUser2> createState() => _CreateUserState();
}

class _CreateUserState extends State<WgtCreateUser2> {
  late MdlPagUser? _loggedInUser;
  final double width = 395;

  bool _passwordVisible = false;

  bool _isEditing = false;
  bool _newItem = true;
  String? _newItemLabel;
  String? _newItemName;
  bool _isNewItemLabelValidated = false;
  bool _newCreate = true;
  bool _createWait = false;
  bool _createSuccess = false;
  String _errorText = '';

  String? _fullName;
  bool _isFullNameValidated = false;
  String? _loginName;
  bool _isLoginNameValidated = false;
  String? _email;
  bool _isEmailValidated = false;
  String? _phone;
  bool _isPhoneValidated = false;
  String? _password;
  bool _isPasswordValidated = false;
  String? _confirmPassword;
  bool _isConfirmPasswordValidated = false;
  String? _designation;
  bool _isDesignationValidated = false;
  String? _remark;
  bool _isRemarkValidated = false;

  // String? _portalTypeStr;
  // PagPortalType? _portalType;

  bool _enabled = true;
  bool _resetPasswordOnFirstLogin = true;

  // MdlPagScope2? _userScope;

  UniqueKey? _fullNameResetKey;
  UniqueKey? _loginNameResetKey;
  UniqueKey? _emailResetKey;
  UniqueKey? _phoneResetKey;
  UniqueKey? _passwordResetKey;
  UniqueKey? _confirmPasswordResetKey;
  UniqueKey? _designationResetKey;
  UniqueKey? _remarkResetKey;

  AuthProvider _selectedAuthProvider = AuthProvider.local;

  String _errorTextRoleList = '';
  // raw list from be
  final List<Map<String, dynamic>> _visibleRoleList = [];
  // scope list sorted by scope type
  final List<Map<String, dynamic>> _sortedScopeList = [];
  // for the first dropdown for scope type
  final List<String> _condensedScopeTypeLabelList = [];
  String? _selectedRoleScopeTypeLabel;
  String? _selectedScopeLabel;
  // to hold the selected role list to be sent to the backend
  final List<Map<String, dynamic>> _selectedRoleList = [];

  Future<void> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
    });

    try {
      Map<String, dynamic> queryMap = {};
      queryMap['scope'] = _loggedInUser!.selectedScope.toScopeMap();
      // queryMap['user_scope'] = _userScope!.toScopeMap();
      // queryMap['portal_type'] = _portalType!.name;
      queryMap['fullname'] = _fullName;
      queryMap['username'] = _loginName;
      queryMap['email'] = _email;
      queryMap['phone'] = _phone;
      queryMap['designation'] = _designation;
      queryMap['remark'] = _remark;
      queryMap['password'] = _password;
      queryMap['confirmed_password'] = _confirmPassword;
      queryMap['enabled'] = _enabled.toString();
      queryMap['reset_password_on_first_login'] =
          _resetPasswordOnFirstLogin.toString();
      queryMap['auth_provider'] = _selectedAuthProvider.name;
      queryMap['send_verification_email'] =
          widget.sendVerificationEmail.toString();
      queryMap['role_list'] = _selectedRoleList;

      await doCreateUser(
        _loggedInUser!,
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: _loggedInUser!.username,
          userId: _loggedInUser!.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );
      _newCreate = false;
      _createSuccess = true;
    } catch (e) {
      dev.log('error: $e');

      // setState(() {
      _errorText = 'Error creating user';
      String eStr = e.toString().toLowerCase();

      dev.log('error: $eStr');

      if (eStr.contains('email')) {
        _errorText = 'Email already exists';
      } else if (eStr.contains('username')) {
        _errorText = 'Username already exists';
      } else if (eStr.contains('password')) {
        _errorText = 'password validation failed';
      }

      _newCreate = true;
      _createSuccess = false;
      // });

      return;
    } finally {
      setState(() {
        _createWait = false;
      });
    }

    if (widget.postRegRedirect) {
      if (mounted) {
        context.go('/post_reg_landing');
      }
    }
  }

  Future<dynamic> _getVisibleRoleList() async {
    dev.log('_getVisibleRoleList()');

    Map<String, dynamic> queryMap = {
      'scope': _loggedInUser!.selectedScope.toScopeMap(),
      'user_id': _loggedInUser!.id.toString(),
    };

    _errorTextRoleList = '';

    try {
      var result = await doGetVisibleRoleList(
        _loggedInUser!,
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: _loggedInUser!.username,
          userId: _loggedInUser!.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      if (result['visible_role_list'] != null) {
        _visibleRoleList.clear();
        _visibleRoleList.addAll(result['visible_role_list']);
        _sortScopeList();
      }
    }
    // catch (e) {
    //   if (kDebugMode) {
    //     print('error: $e');
    //   }
    // }
    finally {
      _errorTextRoleList = 'Error getting role list';
    }
  }

  bool _checkEnableButton() {
    if (!_newCreate) {
      return false;
    }
    if (_createWait) {
      return false;
    }
    if (_errorText.isNotEmpty) {
      return false;
    }

    // if (_portalType == null) {
    //   return false;
    // }

    // if (_userScope == null) {
    //   return false;
    // }

    // if (_visibleRoleList.isEmpty) {
    //   return false;
    // }

    if (_selectedRoleList.isEmpty) {
      return false;
    }

    if (_selectedScopeLabel == null) {
      return false;
    }

    if ((_fullName ?? '').isEmpty ||
        (_loginName ?? '').isEmpty ||
        (_email ?? '').isEmpty ||
        (_phone ?? '').isEmpty) {
      return false;
    }
    if (_selectedAuthProvider == AuthProvider.local && _password == null) {
      return false;
    }

    if (_designation == null) {
      _isDesignationValidated = true;
    }
    if (_remark == null) {
      _isRemarkValidated = true;
    }

    if (!_isFullNameValidated ||
        !_isLoginNameValidated ||
        !_isEmailValidated ||
        !_isPhoneValidated ||
        !_isDesignationValidated ||
        !_isRemarkValidated) {
      return false;
    }

    // for testing backend validation
    // _password = '123';
    // _confirmPassword = '321';
    // _isPasswordValidated = true;
    // _isConfirmPasswordValidated = true;

    if (_selectedAuthProvider == AuthProvider.local) {
      if (_password == null) {
        return false;
      }
      if (_confirmPassword == null) {
        return false;
      }
      if (!_isPasswordValidated) {
        return false;
      }
      if (!_isConfirmPasswordValidated) {
        return false;
      }
    }

    return true;
  }

  String? _validateFullName(String val) {
    if (val.trim().isEmpty) {
      return 'required';
    }
    if (val.trim().length < 5) {
      return 'must be at least 5 characters';
    }
    return null;
  }

  void _sortScopeList() {
    List<Map<String, dynamic>> roleScopeList = [];
    roleScopeList.clear();
    for (var role in _visibleRoleList) {
      bool roleNameExists = false;
      String roleName = role['name'];
      String roleLabel = role['label'] ?? role['name'];
      for (var scope in roleScopeList) {
        if (roleName == scope['role_name']) {
          roleNameExists = true;
        }
      }
      if (!roleNameExists) {
        roleScopeList.add({
          'role_name': roleName,
          'role_label': roleLabel,
          'id': role['id'],
          'name': role['name'],
          'label': role['label'],
          'portal_type': role['portal_type'],
          'scope_type_label_list': [
            {
              'scope_type_label': role['scope_type_label'],
              'scope_label': role['scope_label'],
            }
          ],
          // 'selected': false,
        });
      } else {
        for (var scope in roleScopeList) {
          if (roleName == scope['role_name']) {
            scope['scope_type_label_list'].add({
              'scope_type_label': role['scope_type_label'],
              'scope_label': role['scope_label'],
            });
          }
        }
      }
    }

    for (var scope in roleScopeList) {
      List<Map<String, dynamic>> scopeTypeLabelList =
          scope['scope_type_label_list'];
      // if list has multiple Site Goups, add 'Project' to the list
      bool isProjectLevelRole = true;
      if (scopeTypeLabelList.length <= 1) {
        isProjectLevelRole = false;
      } else {
        for (var scopeTypeLabel in scopeTypeLabelList) {
          if (scopeTypeLabel['scope_type_label'] != 'Site Group') {
            isProjectLevelRole = false;
            break;
          }
        }
      }
      Map<String, dynamic> roleinfo = {
        'id': scope['id'],
        'label': scope['label'],
        'name': scope['name'],
        'portal_type': scope['portal_type'],
      };
      if (isProjectLevelRole) {
        String projectName = _loggedInUser!.selectedScope.projectProfile!.name;
        bool projectNameExists = false;
        for (var scope in _sortedScopeList) {
          if (scope['scope_label'] == projectName) {
            projectNameExists = true;
          }
        }

        if (!projectNameExists) {
          _sortedScopeList.add({
            'scope_type_label': 'Project',
            'scope_label': projectName,
            'role_list': [roleinfo],
          });
        } else {
          for (var sortedScope in _sortedScopeList) {
            if (sortedScope['scope_label'] == projectName) {
              sortedScope['role_list'].add(roleinfo);
            }
          }
        }
      } else {
        // sort the rest of the roles
        // site group
        String siteGroupTypeLabel = '';
        bool siteGroupTypeLabelExists = false;
        for (var scopeTypeLabel in scopeTypeLabelList) {
          if (scopeTypeLabel['scope_type_label'] == 'Site Group') {
            siteGroupTypeLabel = scopeTypeLabel['scope_label'];
            siteGroupTypeLabelExists = true;
          }
        }

        if (siteGroupTypeLabelExists) {
          String siteGroupName = siteGroupTypeLabel;
          bool siteGroupNameExists = false;
          for (var scope in _sortedScopeList) {
            if (scope['scope_label'] == siteGroupName) {
              siteGroupNameExists = true;
            }
          }

          if (!siteGroupNameExists) {
            _sortedScopeList.add({
              'scope_type_label': 'Site Group',
              'scope_label': siteGroupName,
              'role_list': [roleinfo],
            });
          } else {
            for (var sortedScope in _sortedScopeList) {
              if (sortedScope['scope_label'] == siteGroupName) {
                sortedScope['role_list'].add(roleinfo);
              }
            }
          }
        }
        // site
        String siteTypeLabel = '';
        bool siteTypeLabelExists = false;
        for (var scopeTypeLabel in scopeTypeLabelList) {
          if (scopeTypeLabel['scope_type_label'] == 'Site') {
            siteTypeLabel = scopeTypeLabel['scope_label'];
            siteTypeLabelExists = true;
          }
        }
        if (siteTypeLabelExists) {
          String siteName = siteTypeLabel;
          bool siteNameExists = false;
          for (var scope in _sortedScopeList) {
            if (scope['scope_label'] == siteName) {
              siteNameExists = true;
            }
          }
          if (!siteNameExists) {
            _sortedScopeList.add({
              'scope_type_label': 'Site',
              'scope_label': siteName,
              'role_list': [roleinfo],
            });
          } else {
            for (var sortedScope in _sortedScopeList) {
              if (sortedScope['scope_label'] == siteName) {
                sortedScope['role_list'].add(roleinfo);
              }
            }
          }
        }
        // building
        String buildingTypeLabel = '';
        bool buildingTypeLabelExists = false;
        for (var scopeTypeLabel in scopeTypeLabelList) {
          if (scopeTypeLabel['scope_type_label'] == 'Building') {
            buildingTypeLabel = scopeTypeLabel['scope_label'];
            buildingTypeLabelExists = true;
          }
        }
        if (buildingTypeLabelExists) {
          String buildingName = buildingTypeLabel;
          bool buildingNameExists = false;
          for (var scope in _sortedScopeList) {
            if (scope['scope_label'] == buildingName) {
              buildingNameExists = true;
            }
          }
          if (!buildingNameExists) {
            _sortedScopeList.add({
              'scope_type_label': 'Building',
              'scope_label': buildingName,
              'role_list': [roleinfo],
            });
          } else {
            for (var sortedScope in _sortedScopeList) {
              if (sortedScope['scope_label'] == buildingName) {
                sortedScope['role_list'].add(roleinfo);
              }
            }
          }
        }
        // location group
        String locationGroupTypeLabel = '';
        bool locationGroupTypeLabelExists = false;
        for (var scopeTypeLabel in scopeTypeLabelList) {
          if (scopeTypeLabel['scope_type_label'] == 'Location Group') {
            locationGroupTypeLabel = scopeTypeLabel['scope_label'];
            locationGroupTypeLabelExists = true;
          }
        }
        if (locationGroupTypeLabelExists) {
          String locationGroupName = locationGroupTypeLabel;
          bool locationGroupNameExists = false;
          for (var scope in _sortedScopeList) {
            if (scope['scope_label'] == locationGroupName) {
              locationGroupNameExists = true;
            }
          }
          if (!locationGroupNameExists) {
            _sortedScopeList.add({
              'scope_type_label': 'Location Group',
              'scope_label': locationGroupName,
              'role_list': [roleinfo],
            });
          } else {
            for (var sortedScope in _sortedScopeList) {
              if (sortedScope['scope_label'] == locationGroupName) {
                sortedScope['role_list'].add(roleinfo);
              }
            }
          }
        }
      }
    }

    // condense the scope type label list
    _condensedScopeTypeLabelList.clear();
    for (var scope in _sortedScopeList) {
      String scopeTypeLabel = scope['scope_type_label'];
      // String str = _condensedScopeTypeLabelList.join(', ').toLowerCase();
      // if (!str.contains(scopeTypeLabel.toLowerCase())) {
      //   _condensedScopeTypeLabelList.add(scopeTypeLabel);
      // }
      bool scopeTypeLabelExists = false;
      for (var label in _condensedScopeTypeLabelList) {
        if (label.toLowerCase() == scopeTypeLabel.toLowerCase()) {
          scopeTypeLabelExists = true;
          break;
        }
      }
      if (!scopeTypeLabelExists) {
        _condensedScopeTypeLabelList.add(scopeTypeLabel);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    _visibleRoleList.clear();
    _visibleRoleList.addAll(
        _loggedInUser!.selectedScope.projectProfile!.getVisibleRoleInfoList());
    _sortScopeList();
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
                  verticalSpaceRegular,
                  getUserBlock(),
                  // verticalSpaceTiny,
                  // getItemScopeSetter(
                  //   scopeSetterKey: _scopeSetterKey,
                  //   itemKind: PagItemKind.user,
                  //   onSetState: (scopeIdColName, profileIdStr) {
                  //     setState(() {
                  //       _itemScopeMap[scopeIdColName] = profileIdStr;
                  //     });
                  //   },
                  // ),
                  verticalSpaceTiny,
                  getVisibleRoleList(),
                  verticalSpaceRegular,
                  WgtCommButton(
                    enabled: _checkEnableButton(),
                    label: _createWait
                        ? 'Creating user...'
                        : _createSuccess
                            ? '✓ User created'
                            : 'Create User',
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
                                  // _itemChildrenGroupTreeRoot = null;
                                  // _itemChildrenList.clear();
                                  // _itemScopeMap.clear();
                                  // _scopeSetterKey = UniqueKey();

                                  _fullName = null;
                                  _fullNameResetKey = UniqueKey();
                                  _loginName = null;
                                  _loginNameResetKey = UniqueKey();
                                  _email = null;
                                  _emailResetKey = UniqueKey();
                                  _phone = null;
                                  _phoneResetKey = UniqueKey();
                                  _password = null;
                                  _passwordResetKey = UniqueKey();
                                  _confirmPassword = null;
                                  _confirmPasswordResetKey = UniqueKey();
                                  _designation = null;
                                  _designationResetKey = UniqueKey();
                                  _remark = null;
                                  _remarkResetKey = UniqueKey();

                                  _selectedRoleScopeTypeLabel = null;
                                  _selectedScopeLabel = null;

                                  _selectedRoleList.clear();
                                  for (var role in _visibleRoleList) {
                                    role['selected'] = false;
                                  }
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
                        'User ${_newItemName ?? ''} created',
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

  Widget getUserBlock() {
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
              getAuthProviderSelector(),
            ],
          ),
        ),
        verticalSpaceSmall,
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
              key: _fullNameResetKey,
              appConfig: widget.appConfig,
              hintText: 'Full Name',
              labelText: 'Full Name',
              maxLength: maxFullNameLength,
              validator: _validateFullName,
              onChanged: (val) {
                setState(() {
                  _isEditing = true;
                  if (val != _fullName) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _newCreate = true;
                    _createSuccess = false;
                  });
                }
                _fullName = val;
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
                    _isFullNameValidated = true;
                  } else {
                    _isFullNameValidated = false;
                  }
                });
              },
            ),
            WgtTextField(
              key: _loginNameResetKey,
              appConfig: widget.appConfig,
              hintText: 'Username',
              labelText: 'Username',
              maxLength: maxLoginNameLength,
              checkUnique: doPagCheckUnique,
              uniqueKey: 'username',
              itemTableName: 'pag.pag_user',
              validator: validateUsername,
              onUniqueCheck: (dynamic existsResult) {
                if (existsResult is String) {
                  if (existsResult == 'error') {
                    setState(() {
                      _isLoginNameValidated = false;
                    });
                  }
                } else if (existsResult is bool) {
                  if (existsResult) {
                    setState(() {
                      _isLoginNameValidated = false;
                    });
                  } else {
                    setState(() {
                      _isLoginNameValidated = true;
                    });
                  }
                }
              },
              onChanged: (val) {
                setState(() {
                  _isEditing = true;
                  if (val != _loginName) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _newCreate = true;
                    _createSuccess = false;
                  });
                }
                _loginName = val;
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
                    _isLoginNameValidated = true;
                  } else {
                    _isLoginNameValidated = false;
                  }
                });
              },
            ),
            WgtPagTextField(
              appConfig: widget.appConfig,
              hintText: 'Email',
              labelText: 'Email',
              key: _emailResetKey,
              maxLength: maxEmailLength,
              checkUnique: _selectedAuthProvider != AuthProvider.local
                  ? doPagCheckUnique
                  : null,
              onUniqueCheck: (dynamic existsResult) {
                if (existsResult is String) {
                  if (existsResult == 'error') {
                    setState(() {
                      _isEmailValidated = false;
                    });
                  }
                } else if (existsResult is bool) {
                  if (existsResult) {
                    setState(() {
                      _isEmailValidated = false;
                    });
                  } else {
                    setState(() {
                      _isEmailValidated = true;
                    });
                  }
                }
              },
              uniqueKey: 'email',
              itemTableName: 'pag.pag_user',
              validator: validateEmail,
              onChanged: (val) {
                setState(() {
                  _isEditing = true;
                  if (val != _email) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _newCreate = true;
                    _createSuccess = false;
                  });
                }
                _email = val;
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
                    _isEmailValidated = true;
                  } else {
                    _isEmailValidated = false;
                  }
                });
              },
            ),
            WgtTextField(
              resetKey: _phoneResetKey,
              hintText: 'Phone',
              labelText: 'Phone',
              initialValue: _phone,
              appConfig: widget.appConfig,
              maxLength: maxPhoneLength,
              validator: validatePhone,
              onChanged: (val) {
                setState(() {
                  _isEditing = true;
                  if (val != _phone) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _newCreate = true;
                    _createSuccess = false;
                  });
                }
                _phone = val;
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
                    _isPhoneValidated = true;
                  } else {
                    _isPhoneValidated = false;
                  }
                });
              },
            ),
            WgtTextField(
              resetKey: _designationResetKey,
              hintText: 'Designation',
              labelText: 'Designation',
              initialValue: _designation,
              appConfig: widget.appConfig,
              maxLength: 55,
              validator: validateDesignation,
              onChanged: (val) {
                setState(() {
                  _isEditing = true;
                  if (val != _designation) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _newCreate = true;
                    _createSuccess = false;
                  });
                }
                _designation = val;
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
                    _isDesignationValidated = true;
                  } else {
                    _isDesignationValidated = false;
                  }
                });
              },
            ),
            WgtTextField(
              resetKey: _remarkResetKey,
              hintText: 'Remark',
              labelText: 'Remark',
              initialValue: _remark,
              appConfig: widget.appConfig,
              maxLength: 55,
              validator: validateUserRemark,
              onChanged: (val) {
                setState(() {
                  _isEditing = true;
                  if (val != _remark) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _newCreate = true;
                    _createSuccess = false;
                  });
                }
                _remark = val;
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
                    _isRemarkValidated = true;
                  } else {
                    _isRemarkValidated = false;
                  }
                });
              },
            ),
          ]),
        ),
        verticalSpaceSmall,
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
              // getAuthProviderSelector(),
              if (_selectedAuthProvider == AuthProvider.local)
                WgtTextField(
                  resetKey: _passwordResetKey,
                  hintText: 'Password',
                  labelText: 'Password',
                  appConfig: widget.appConfig,
                  maxLength: maxPasswordLength,
                  validator: widget.passwordValidator ?? validatePassword,
                  obscureText: !_passwordVisible,
                  onChanged: (val) {
                    setState(() {
                      _isEditing = true;
                      if (val != _password) {
                        _errorText = '';
                        _confirmPassword = null;
                        _confirmPasswordResetKey = UniqueKey();
                      }
                    });
                    if (val.trim().isNotEmpty) {
                      setState(() {
                        _newCreate = true;
                        _createSuccess = false;
                      });
                    }
                    _password = val;
                    return null;
                  },
                  onValidate: (String? result) {
                    setState(() {
                      if (result == null) {
                        _isPasswordValidated = true;
                      } else {
                        _isPasswordValidated = false;
                      }
                    });
                  },
                  decoration: xtBuildInputDecoration(
                    context: context,
                    prefixIcon: Icon(Icons.password_rounded,
                        color: Theme.of(context).hintColor),
                    hintText: 'Password',
                    suffix: Focus(
                      descendantsAreFocusable: false,
                      canRequestFocus: false,
                      child: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          // Update the state i.e. toogle the state of passwordVisible variable
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              if (_selectedAuthProvider == AuthProvider.local)
                WgtTextField(
                  resetKey: _confirmPasswordResetKey,
                  hintText: 'Confirm Password',
                  labelText: 'Confirm Password',
                  initialValue: _confirmPassword,
                  appConfig: widget.appConfig,
                  maxLength: maxPasswordLength,
                  validator: (val) => validateConfirmPassword(val, _password),
                  //NOTE: => is the same as {return ...}
                  //when not using =>, must use {return ...}
                  // (val) {
                  //   return validateConfirmPassword(
                  //       val, formCoordinator.formData[tfKeys.password]);
                  // },
                  onChanged: (val) {
                    setState(() {
                      _isEditing = true;
                    });
                    if (val.trim().isNotEmpty) {
                      setState(() {
                        _newCreate = true;
                        _createSuccess = false;
                      });
                    }
                    // //only validate if confirm password reached the same length as password
                    // if (_password != null) {
                    //   // if (_password!.length == val.length) {
                    //   _confirmPasswordValidateResult =
                    //       validateConfirmPassword(val, _password);
                    //   setState(() {
                    //     if (_confirmPasswordValidateResult == null) {
                    //       _confirmPassword = val;
                    //     } else {
                    //       _confirmPassword = null;
                    //     }
                    //   });
                    //   // }
                    // }
                    _confirmPassword = val;
                    return null;
                  },
                  onValidate: (result) {
                    setState(() {
                      if (result == null) {
                        _isConfirmPasswordValidated = true;
                      } else {
                        _isConfirmPasswordValidated = false;
                      }
                    });
                  },
                  obscureText: true,
                  decoration: xtBuildInputDecoration(
                    context: context,
                    prefixIcon: Icon(Icons.password_rounded,
                        color: Theme.of(context).hintColor),
                    hintText: 'Confirm Password',
                  ),
                ),
              if (_selectedAuthProvider == AuthProvider.local)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 320,
                      height: 34,
                      child: CheckboxListTile(
                        // key: _resetPasswordKey,
                        value: _resetPasswordOnFirstLogin,
                        onChanged: _createWait
                            ? null
                            : (bool? newValue) {
                                setState(() {
                                  _newCreate = true;
                                  _createSuccess = false;
                                  _resetPasswordOnFirstLogin = newValue!;
                                });
                              },
                        title: Align(
                            alignment: Alignment.centerRight,
                            child: Text("Reset password on first login",
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                ))),
                        activeColor: Theme.of(context).hintColor,
                        contentPadding: const EdgeInsets.all(0),
                      ),
                    ),
                  ],
                ),
              // verticalSpaceSmall,
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 130,
                    height: 34,
                    child: CheckboxListTile(
                      // key: _keyEnabled,
                      value: _enabled,
                      onChanged: _createWait
                          ? null
                          : (bool? newValue) {
                              setState(() {
                                _newCreate = true;
                                _createSuccess = false;
                                _enabled = newValue!;
                              });
                            },
                      title: Align(
                          alignment: Alignment.centerRight,
                          child: Text("Enabled",
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ))),
                      activeColor: Theme.of(context).hintColor,
                      contentPadding: const EdgeInsets.all(0),
                    ),
                  ),
                ],
              ),
              verticalSpaceSmall,
            ],
          ),
        )
      ],
    );
  }

  Widget getVisibleRoleList() {
    bool pull = false;

    if (_visibleRoleList.isEmpty) {
      pull = true;
    }
    return Container(
      width: 395,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).hintColor.withAlpha(30),
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pull
          ? FutureBuilder(
              future: _getVisibleRoleList(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return const Center(child: WgtPagWait(size: 21));
                  default:
                    if (snapshot.hasError) {
                      if (kDebugMode) {
                        print(snapshot.error);
                      }
                      return getErrorTextPrompt(
                          context: context, errorText: _errorTextRoleList);
                    } else {
                      if (kDebugMode) {
                        print('FutureBuilder -> getCompletedVisibleRoleList');
                      }
                      return getCompletedVisibleRoleList2();
                    }
                }
              },
            )
          : getCompletedVisibleRoleList2(),
    );
  }

  Widget getCompletedVisibleRoleList() {
    List<Widget> roleList = [];
    for (var role in _visibleRoleList) {
      roleList.add(Row(
        children: [
          Checkbox(
            value: role['selected'] ?? false,
            onChanged: _createWait
                ? null
                : (bool? newValue) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                      role['selected'] = newValue!;
                      if (newValue) {
                        _selectedRoleList.add(role);
                      } else {
                        _selectedRoleList.remove(role);
                      }
                    });
                  },
          ),
          horizontalSpaceTiny,
          Text(
            role['label'] ?? role['name'],
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ],
      ));
    }
    return SizedBox(
      height: 350,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text('Roles', style: TextStyle(color: Theme.of(context).hintColor)),
            verticalSpaceTiny,
            ...roleList,
          ],
        ),
      ),
    );
  }

  Widget getCompletedVisibleRoleList2() {
    List<String> scopeTypeScopeList = [];
    if (_selectedRoleScopeTypeLabel != null) {
      for (var role in _sortedScopeList) {
        if (role['scope_type_label'] == _selectedRoleScopeTypeLabel) {
          scopeTypeScopeList.add(role['scope_label']);
        }
      }
      if (scopeTypeScopeList.length == 1) {
        setState(() {
          _selectedScopeLabel = scopeTypeScopeList[0];
        });
      }
    }
    // List<Widget> roleList = [];
    List<Map<String, dynamic>> roleInfoList = [];
    if (_selectedScopeLabel != null) {
      for (var role in _sortedScopeList) {
        if (_selectedScopeLabel?.toLowerCase() !=
            (role['scope_label'] as String).toLowerCase()) {
          continue;
        }
        if (role['role_list'] == null) {
          continue;
        }

        for (var roleInfo in role['role_list']) {
          roleInfoList.add(roleInfo);
        }
      }
    }
    List<Widget> roleList = [];
    for (var role in roleInfoList) {
      bool isSelected = false;
      for (var selectedRole in _selectedRoleList) {
        if (role['id'] == selectedRole['id']) {
          isSelected = true;
          break;
        }
      }
      roleList.add(Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: _createWait
                ? null
                : (bool? newValue) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;

                      if (newValue!) {
                        _selectedRoleList.add(role);
                      } else {
                        _selectedRoleList.remove(role);
                      }
                    });
                  },
          ),
          horizontalSpaceTiny,
          Text(
            role['label'],
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ],
      ));
    }

    return SizedBox(
      height: roleInfoList.isNotEmpty
          ? 250
          : scopeTypeScopeList.isNotEmpty
              ? 120
              : 50,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // scope role dropdown
            Row(
              children: [
                Text('Scope Type',
                    style: TextStyle(color: Theme.of(context).hintColor)),
                horizontalSpaceTiny,
                DropdownButton(
                  value: _selectedRoleScopeTypeLabel,
                  items: _condensedScopeTypeLabelList
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedScopeLabel = null;
                      _selectedRoleScopeTypeLabel = value;
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  },
                ),
              ],
            ),
            verticalSpaceTiny,
            // role scope list
            if (_selectedRoleScopeTypeLabel != null)
              Row(
                children: [
                  Text('Role Scope',
                      style: TextStyle(color: Theme.of(context).hintColor)),
                  horizontalSpaceTiny,
                  DropdownButton(
                    value: _selectedScopeLabel,
                    items: scopeTypeScopeList
                        .map((String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedScopeLabel = value;
                        _newCreate = true;
                        _createSuccess = false;
                      });
                    },
                  ),
                ],
              ),
            verticalSpaceSmall,
            if (_selectedScopeLabel != null)
              Text('Roles',
                  style: TextStyle(color: Theme.of(context).hintColor)),
            verticalSpaceTiny,
            ...roleList,
          ],
        ),
      ),
    );
  }

  Widget getAuthProviderSelector() {
    List<AuthProvider> authProviders = [
      AuthProvider.local,
      AuthProvider.microsoft,
      AuthProvider.google,
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
        Text('Auth Provider',
            style: TextStyle(color: Theme.of(context).hintColor)),
        horizontalSpaceSmall,
        SizedBox(
          width: 115,
          child: DropdownButton<AuthProvider>(
              alignment: AlignmentDirectional.centerStart,
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Auth Provider', style: dropDownListHintStyle)),
              value: _selectedAuthProvider,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (AuthProvider? value) async {
                if (value != null) {
                  if (value == _selectedAuthProvider) {
                    return;
                  }
                }
                setState(() {
                  _selectedAuthProvider = value!;
                  _newCreate = true;
                  _createSuccess = false;
                  _email = null;
                  _emailResetKey = UniqueKey();
                  // _phone = null;
                  _phoneResetKey = UniqueKey();
                  _password = null;
                  _passwordResetKey = UniqueKey();
                  _confirmPassword = null;
                  _confirmPasswordResetKey = UniqueKey();
                });
              },
              items: authProviders
                  .map<DropdownMenuItem<AuthProvider>>((AuthProvider value) {
                return DropdownMenuItem<AuthProvider>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(
                      value.name,
                      // style: dropDownListTextStyle,
                    ),
                  ),
                );
              }).toList()),
        ),
      ],
    );
  }
}
