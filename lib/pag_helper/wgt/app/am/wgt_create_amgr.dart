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

class WgtCreateAmgr extends StatefulWidget {
  const WgtCreateAmgr({
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
  State<WgtCreateAmgr> createState() => _CreateAmgrState();
}

class _CreateAmgrState extends State<WgtCreateAmgr> {
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

  String? _companyTradingName;
  bool _isCompanyTradingNameValidated = false;
  UniqueKey? _companyTradingNameResetKey;

  String? _coRegNumber;
  bool _isCoRegNumberValidated = false;
  UniqueKey? _coRegNumberResetKey;

  String? _gstRegNumber;
  bool _isGstRegNumberValidated = false;
  UniqueKey? _gstRegNumberResetKey;

  String? _uen;
  bool _isUenValidated = false;
  UniqueKey? _uenResetKey;

  String? _addressLine1;
  bool _isAddressLine1Validated = false;
  UniqueKey? _addressLine1ResetKey;

  String? _addressLine2;
  bool _isAddressLine2Validated = false;
  UniqueKey? _addressLine2ResetKey;

  String? _addressLine3;
  bool _isAddressLine3Validated = false;
  UniqueKey? _addressLine3ResetKey;

  Future<dynamic> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
    });

    try {
      Map<String, dynamic> queryMap = {};
      queryMap['item_type'] = PagOrgType.amgr.name;
      queryMap['scope'] = widget.loggedInUser.selectedScope.toScopeMap();
      queryMap['label'] = _label;
      queryMap['company_trading_name'] = _companyTradingName;
      queryMap['company_reg_number'] = _coRegNumber;
      queryMap['gst_reg_number'] = _gstRegNumber;
      queryMap['uen'] = _uen;
      queryMap['address_line_1'] = _addressLine1;
      queryMap['address_line_2'] = _addressLine2;
      queryMap['address_line_3'] = _addressLine3;

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

    if (!_isLabelValidated ||
        ((_companyTradingName ?? '').isNotEmpty &&
            !_isCompanyTradingNameValidated) ||
        ((_coRegNumber ?? '').isNotEmpty && !_isCoRegNumberValidated) ||
        ((_gstRegNumber ?? '').isNotEmpty && !_isGstRegNumberValidated) ||
        ((_uen ?? '').isNotEmpty && !_isUenValidated) ||
        ((_addressLine1 ?? '').isNotEmpty && !_isAddressLine1Validated) ||
        ((_addressLine2 ?? '').isNotEmpty && !_isAddressLine2Validated) ||
        ((_addressLine3 ?? '').isNotEmpty && !_isAddressLine3Validated)) {
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
                        ? 'Adding Asset Manager...'
                        : _createSuccess
                            ? '✓ Asset Manager added'
                            : 'Add Asset Manager',
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
                                  _companyTradingName = null;
                                  _coRegNumber = null;
                                  _gstRegNumber = null;
                                  _uen = null;
                                  _addressLine1 = null;
                                  _addressLine2 = null;
                                  _addressLine3 = null;

                                  _isLabelValidated = false;
                                  _isCompanyTradingNameValidated = false;
                                  _labelResetKey = UniqueKey();
                                  _companyTradingNameResetKey = UniqueKey();
                                  _coRegNumberResetKey = UniqueKey();
                                  _gstRegNumberResetKey = UniqueKey();
                                  _uenResetKey = UniqueKey();
                                  _addressLine1ResetKey = UniqueKey();
                                  _addressLine2ResetKey = UniqueKey();
                                  _addressLine3ResetKey = UniqueKey();
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
                        'Asset Manager ${_newItemName ?? ''} created',
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
                itemTableName: '$projectName.meter_$projectName',
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
                key: _companyTradingNameResetKey,
                appConfig: widget.appConfig,
                hintText: 'Company Trading Name (Required)',
                labelText: 'Company Trading Name (Required)',
                maxLength: maxFullNameLength,
                maxLines: 2,
                validator: validateCompanyTradingName,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'company_trading_name',
                itemTableName: '$projectName.amgr_$projectName',
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _companyTradingName) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _companyTradingName = val;
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
                      _isCompanyTradingNameValidated = true;
                    } else {
                      _isCompanyTradingNameValidated = false;
                    }
                  });
                },
              ),
              WgtTextField(
                key: _coRegNumberResetKey,
                appConfig: widget.appConfig,
                hintText: 'Company Registration Number (Required)',
                labelText: 'Company Registration Number (Required)',
                maxLength: maxFullNameLength,
                validator: validateTenantAccountNumber,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'company_reg_number',
                itemTableName: '$projectName.amgr_$projectName',
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _coRegNumber) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _coRegNumber = val;
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
                      _isCoRegNumberValidated = true;
                    } else {
                      _isCoRegNumberValidated = false;
                    }
                  });
                },
              ),
              WgtTextField(
                key: _gstRegNumberResetKey,
                appConfig: widget.appConfig,
                hintText: 'GST Registration Number',
                labelText: 'GST Registration Number',
                maxLength: maxFullNameLength,
                validator: validateTenantAccountNumber,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'gst_reg_number',
                itemTableName: '$projectName.amgr_$projectName',
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _gstRegNumber) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _gstRegNumber = val;
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
                      _isGstRegNumberValidated = true;
                    } else {
                      _isGstRegNumberValidated = false;
                    }
                  });
                },
              ),
              WgtTextField(
                key: _uenResetKey,
                appConfig: widget.appConfig,
                hintText: 'UEN',
                labelText: 'UEN',
                maxLength: maxFullNameLength,
                validator: validateTenantAccountNumber,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'uen',
                itemTableName: '$projectName.amgr_$projectName',
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _uen) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _uen = val;
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
                      _isUenValidated = true;
                    } else {
                      _isUenValidated = false;
                    }
                  });
                },
              ),
              WgtTextField(
                key: _addressLine1ResetKey,
                appConfig: widget.appConfig,
                hintText: 'Address Line 1 (Required)',
                labelText: 'Address Line 1 (Required)',
                maxLength: maxFullNameLength,
                validator: validateBillingAddressLine1,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'address_line_1',
                itemTableName: '$projectName.amgr_$projectName',
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _addressLine1) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _addressLine1 = val;
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
                      _isAddressLine1Validated = true;
                    } else {
                      _isAddressLine1Validated = false;
                    }
                  });
                },
              ),
              WgtTextField(
                key: _addressLine2ResetKey,
                appConfig: widget.appConfig,
                hintText: 'Address Line 2',
                labelText: 'Address Line 2',
                maxLength: maxFullNameLength,
                validator: validateBillingAddressLine2,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'address_line_2',
                itemTableName: '$projectName.amgr_$projectName',
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _addressLine2) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _addressLine2 = val;
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
                      _isAddressLine2Validated = true;
                    } else {
                      _isAddressLine2Validated = false;
                    }
                  });
                },
              ),
              WgtTextField(
                key: _addressLine3ResetKey,
                appConfig: widget.appConfig,
                hintText: 'Address Line 3',
                labelText: 'Address Line 3',
                maxLength: maxFullNameLength,
                validator: validateBillingAddressLine3,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'address_line_3',
                itemTableName: '$projectName.amgr_$projectName',
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _addressLine3) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _addressLine3 = val;
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
                      _isAddressLine3Validated = true;
                    } else {
                      _isAddressLine3Validated = false;
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
