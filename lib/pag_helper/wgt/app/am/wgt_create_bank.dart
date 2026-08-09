import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/comm/comm_org.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_org.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

import '../../../model/mdl_pag_app_config.dart';

class WgtCreateBank extends StatefulWidget {
  const WgtCreateBank({
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
  State<WgtCreateBank> createState() => _CreateItemState();
}

class _CreateItemState extends State<WgtCreateBank> {
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

  String? _bankCode;
  bool _isBankCodeValidated = false;
  UniqueKey? _bankCodeResetKey;

  String? _branchCode;
  bool _isBranchCodeValidated = false;
  UniqueKey? _branchCodeResetKey;

  String? _swiftCode;
  bool _isSwiftCodeValidated = false;
  UniqueKey? _swiftCodeResetKey;

  String? _payNow;
  bool _isPayNowValidated = false;
  UniqueKey? _payNowResetKey;

  String? _tag;
  bool _isTagValidated = false;
  UniqueKey? _tagResetKey;

  Future<dynamic> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
    });

    try {
      Map<String, dynamic> queryMap = {};
      queryMap['item_type'] = PagOrgType.bank.name;
      queryMap['scope'] = widget.loggedInUser.selectedScope.toScopeMap();
      queryMap['label'] = _label;
      queryMap['bank_code'] = _bankCode;
      queryMap['branch_code'] = _branchCode;
      queryMap['swift_code'] = _swiftCode;
      queryMap['paynow'] = _payNow;
      queryMap['tag'] = _tag;

      dynamic result;

      result = await doPagCreateOrg(
        widget.loggedInUser,
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
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
      _errorText = 'Error creating item';
      String eStr = e.toString().toLowerCase();

      dev.log('error: $eStr');

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

    // required fields
    if (_label == null || _label!.trim().isEmpty) {
      return false;
    }
    if (_bankCode == null || _bankCode!.trim().isEmpty) {
      return false;
    }
    if (_branchCode == null || _branchCode!.trim().isEmpty) {
      return false;
    }
    if (_swiftCode == null || _swiftCode!.trim().isEmpty) {
      return false;
    }
    if (_tag == null || _tag!.trim().isEmpty) {
      return false;
    }

    if (!_isLabelValidated ||
        ((_bankCode ?? '').isNotEmpty && !_isBankCodeValidated) ||
        ((_branchCode ?? '').isNotEmpty && !_isBranchCodeValidated) ||
        ((_swiftCode ?? '').isNotEmpty && !_isSwiftCodeValidated) ||
        ((_payNow ?? '').isNotEmpty && !_isPayNowValidated) ||
        ((_tag ?? '').isNotEmpty && !_isTagValidated)) {
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
                        ? 'Adding Bank...'
                        : _createSuccess
                            ? '✓ Bank added'
                            : 'Add Bank',
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
                                  _bankCode = null;
                                  _branchCode = null;
                                  _swiftCode = null;
                                  _payNow = null;

                                  _isLabelValidated = false;
                                  _isBankCodeValidated = false;
                                  _isBranchCodeValidated = false;
                                  _labelResetKey = UniqueKey();
                                  _bankCodeResetKey = UniqueKey();
                                  _branchCodeResetKey = UniqueKey();
                                  _swiftCodeResetKey = UniqueKey();
                                  _payNowResetKey = UniqueKey();
                                  _tagResetKey = UniqueKey();
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
                        'Bank ${_newItemName ?? ''} created',
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
                maxLines: 2,
                validator: validateTenantLabel,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'label',
                itemTableName: '$projectName.bank_$projectName',
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
              WgtTextField(
                key: _bankCodeResetKey,
                appConfig: widget.appConfig,
                hintText: 'Bank Code (Required)',
                labelText: 'Bank Code (Required)',
                maxLength: maxFullNameLength,
                maxLines: 2,
                validator: validateBankCode,
                // checkUnique: doPagCheckUnique,
                // uniqueKey: 'bank_code',
                itemTableName: '$projectName.bank_$projectName',
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _bankCode) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _bankCode = val;
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
                      _isBankCodeValidated = true;
                    } else {
                      _isBankCodeValidated = false;
                    }
                  });
                },
              ),
              WgtTextField(
                key: _branchCodeResetKey,
                appConfig: widget.appConfig,
                hintText: 'Branch Code (Required)',
                labelText: 'Branch Code (Required)',
                maxLength: maxFullNameLength,
                maxLines: 2,
                validator: validateBranchCode,
                // checkUnique: doPagCheckUnique,
                // uniqueKey: 'branch_code',
                itemTableName: '$projectName.bank_$projectName',
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _branchCode) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _branchCode = val;
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
                      _isBranchCodeValidated = true;
                    } else {
                      _isBranchCodeValidated = false;
                    }
                  });
                },
              ),
              WgtTextField(
                key: _swiftCodeResetKey,
                appConfig: widget.appConfig,
                hintText: 'SWIFT Code (Required)',
                labelText: 'SWIFT Code (Required)',
                maxLength: maxFullNameLength,
                validator: validateSwiftCode,
                // checkUnique: doPagCheckUnique,
                // uniqueKey: 'swift_code',
                itemTableName: '$projectName.bank_$projectName',
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _swiftCode) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _swiftCode = val;
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
                      _isSwiftCodeValidated = true;
                    } else {
                      _isSwiftCodeValidated = false;
                    }
                  });
                },
              ),
              WgtTextField(
                key: _payNowResetKey,
                appConfig: widget.appConfig,
                hintText: 'PayNow',
                labelText: 'PayNow',
                maxLength: maxFullNameLength,
                validator: validateTenantAccountNumber,
                // checkUnique: doPagCheckUnique,
                // uniqueKey: 'paynow',
                itemTableName: '$projectName.bank_$projectName',
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _payNow) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _payNow = val;
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
                      _isPayNowValidated = true;
                    } else {
                      _isPayNowValidated = false;
                    }
                  });
                },
              ),
              WgtTextField(
                key: _tagResetKey,
                appConfig: widget.appConfig,
                hintText: 'Tag (Required)',
                labelText: 'Tag (Required)',
                maxLength: 8,
                validator: validateBankTag,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'tag',
                itemTableName: '$projectName.bank_$projectName',
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _tag) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
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
            ],
          ),
        ),
      ],
    );
  }
}
