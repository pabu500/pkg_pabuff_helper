import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

import '../../../../comm/comm_ex.dart';
import '../../../../comm/pag_be_api_base.dart';

class WgtCreateResourceType extends StatefulWidget {
  const WgtCreateResourceType({
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
  State<WgtCreateResourceType> createState() => _CreateResourceTypeState();
}

class _CreateResourceTypeState extends State<WgtCreateResourceType> {
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
  bool _isLabelRequired = false;

  Future<dynamic> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
    });

    try {
      Map<String, dynamic> queryMap = {
        'item_kind': PagItemKind.resourceType.value,
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'label': _label,
      };

      final result = await ex(
        endpoint: PagUrlBase.eptCreateResourceType,
        crudType: 'create',
        opStr: 'create resource type',
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
      _errorText = getErrorText(e, defaultErrorText: 'Error creating resource');

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
                  verticalSpaceRegular,
                  WgtCommButton(
                    enabled: _checkEnableButton(),
                    label: _createWait
                        ? 'Adding Resource Type...'
                        : _createSuccess
                            ? '✓ Resource Type added'
                            : 'Add Resource Type',
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
                        'Resource Type ${_newItemName ?? ''} created',
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
                validateOnChange: false,
                validator: validateTenantLabel,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'label',
                itemTableName: 'pag.pag_acl_resource_type',
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
}
