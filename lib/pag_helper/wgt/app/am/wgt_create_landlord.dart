import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_org.dart';
import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_org.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_tenant.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/def_helper/list_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_group_profile.dart';
import 'package:buff_helper/pag_helper/wgt/scope/wgt_scope_setter.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_input_dropdown.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

class WgtCreateLandlord extends StatefulWidget {
  const WgtCreateLandlord({
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
  State<WgtCreateLandlord> createState() => _WgtCreateLandlordState();
}

class _WgtCreateLandlordState extends State<WgtCreateLandlord> {
  static const double _width = 395;

  final TextEditingController _bankNameController = TextEditingController();

  String? _label;
  String? _bankAccountUtil;
  String? _bankName;
  String? _giroAccountNumber;
  String? _newItemName;

  bool _isLabelValidated = false;
  bool _isBankAccountUtilValidated = false;
  bool _isGiroAccountNumberValidated = false;
  bool _bankListWait = true;
  bool _createWait = false;
  bool _createSuccess = false;

  String _bankListErrorText = '';
  String _errorText = '';
  List<Map<String, dynamic>> _bankList = [];
  final Map<String, dynamic> _itemScopeMap = {};

  UniqueKey? _labelResetKey;
  UniqueKey? _bankAccountUtilResetKey;
  UniqueKey? _giroAccountNumberResetKey;
  UniqueKey? _scopeSetterKey;

  @override
  void initState() {
    super.initState();
    _loadBankList();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _loadBankList() async {
    setState(() {
      _bankListWait = true;
      _bankListErrorText = '';
    });

    try {
      final result = await fetchItemList(
        widget.loggedInUser,
        widget.appConfig,
        {
          'scope': widget.loggedInUser.selectedScope.toScopeMap(),
          'item_kind': PagItemKind.org.value,
          'item_type': PagOrgType.bank.value,
          'max_rows_per_page': '300',
          'current_page': '1',
          'sort_by': 'name',
          'sort_order': 'asc',
          'get_count_only': 'false',
          'list_context_type': PagListContextType.info.name,
          'allow_flexi_label': 'false',
        },
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: 'get_bank_list',
        ),
      );

      final bankList = <Map<String, dynamic>>[];
      for (final item in result['item_list'] ?? []) {
        final bank = Map<String, dynamic>.from(item);
        final bankName = bank['name']?.toString();
        if (bankName == null || bankName.isEmpty) {
          continue;
        }
        bank['label'] = bankName;
        bankList.add(bank);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _bankList = bankList;
      });
    } catch (e) {
      dev.log('Error loading bank list: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _bankListErrorText =
            getErrorText(e, defaultErrorText: 'Error loading bank list');
      });
    } finally {
      if (mounted) {
        setState(() {
          _bankListWait = false;
        });
      }
    }
  }

  bool _checkEnableButton() {
    return !_createWait &&
        !_createSuccess &&
        _errorText.isEmpty &&
        (_label?.trim().isNotEmpty ?? false) &&
        (_bankAccountUtil?.trim().isNotEmpty ?? false) &&
        (_bankName?.trim().isNotEmpty ?? false) &&
        (_giroAccountNumber?.trim().isNotEmpty ?? false) &&
        _itemScopeMap['site_group_id'] != null &&
        _isLabelValidated &&
        _isBankAccountUtilValidated &&
        _isGiroAccountNumberValidated;
  }

  Future<bool> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
    });

    try {
      final queryMap = <String, dynamic>{
        'item_type': PagOrgType.landlord.name,
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'label': _label?.trim(),
        'bank_account_util': _bankAccountUtil?.trim(),
        'bank_name': _bankName,
        'giro_account_number': _giroAccountNumber?.trim(),
        'item_scope_info': _itemScopeMap,
      };

      final result = await doPagCreateOrg(
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

      _newItemName = result['name'];
      _createSuccess = true;
      return true;
    } catch (e) {
      dev.log('Error creating landlord: $e');
      _errorText = getErrorText(e, defaultErrorText: 'Error creating landlord');
      _createSuccess = false;
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _createWait = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: _width,
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: [
                  _getItemBlock(),
                  verticalSpaceTiny,
                  _getItemScopeSetter(),
                  verticalSpaceRegular,
                  WgtCommButton(
                    enabled: _checkEnableButton(),
                    label: _createWait
                        ? 'Adding Landlord...'
                        : _createSuccess
                            ? '✓ Landlord added'
                            : 'Add Landlord',
                    onPressed: !_checkEnableButton()
                        ? null
                        : () async {
                            if (!await _createItem() || !mounted) {
                              return;
                            }

                            setState(() {
                              _label = null;
                              _bankAccountUtil = null;
                              _bankName = null;
                              _giroAccountNumber = null;
                              _isLabelValidated = false;
                              _isBankAccountUtilValidated = false;
                              _isGiroAccountNumberValidated = false;
                              _labelResetKey = UniqueKey();
                              _bankAccountUtilResetKey = UniqueKey();
                              _giroAccountNumberResetKey = UniqueKey();
                              _itemScopeMap.clear();
                              _scopeSetterKey = UniqueKey();
                              _bankNameController.clear();
                            });
                            widget.onCreated?.call();
                          },
                  ),
                  if (!_createSuccess && _errorText.isNotEmpty)
                    getErrorTextPrompt(
                      context: context,
                      errorText: _errorText,
                    ),
                  if (_createSuccess && _errorText.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(
                        'Landlord ${_newItemName ?? ''} created',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
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

  Widget _getItemBlock() {
    final projectName = widget.loggedInUser.selectedScope.projectProfile!.name;

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
                validator: validateTenantLabel,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'label',
                itemTableName: '$projectName.landlord_$projectName',
                onUniqueCheck: (dynamic result) {
                  setState(() {
                    if (result is bool) {
                      _isLabelValidated = !result;
                      _errorText = result ? 'Label already exists' : '';
                    } else if (result is String) {
                      _isLabelValidated = false;
                      _errorText =
                          result == 'taken' ? 'Label already exists' : result;
                    }
                  });
                },
                onChanged: (val) {
                  setState(() {
                    if (val != _label) {
                      _errorText = '';
                      _createSuccess = false;
                    }
                    _label = val;
                  });
                  return null;
                },
                onValidate: (String? result) {
                  setState(() {
                    _isLabelValidated = result == null;
                  });
                },
              ),
              WgtTextField(
                key: _bankAccountUtilResetKey,
                appConfig: widget.appConfig,
                hintText: 'Utility Bank Account (Required)',
                labelText: 'Utility Bank Account (Required)',
                maxLength: maxFullNameLength,
                maxLines: 1,
                validator: validateBankAccountNumber,
                onChanged: (val) {
                  setState(() {
                    _bankAccountUtil = val;
                    _errorText = '';
                    _createSuccess = false;
                  });
                  return null;
                },
                onValidate: (String? result) {
                  setState(() {
                    _isBankAccountUtilValidated = result == null;
                  });
                },
              ),
              WgtTextField(
                key: _giroAccountNumberResetKey,
                appConfig: widget.appConfig,
                hintText: 'GIRO Account (Required)',
                labelText: 'GIRO Account (Required)',
                maxLength: maxFullNameLength,
                maxLines: 1,
                validator: validateBankAccountNumber,
                onChanged: (val) {
                  setState(() {
                    _giroAccountNumber = val;
                    _errorText = '';
                    _createSuccess = false;
                  });
                  return null;
                },
                onValidate: (String? result) {
                  setState(() {
                    _isGiroAccountNumberValidated = result == null;
                  });
                },
              ),
              _getBankSelector(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getBankSelector() {
    if (_bankListWait) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_bankListErrorText.isNotEmpty) {
      return getErrorTextPrompt(
        context: context,
        errorText: _bankListErrorText,
      );
    }
    if (_bankList.isEmpty) {
      return getErrorTextPrompt(
        context: context,
        errorText: 'No banks are available for this project',
      );
    }

    return WgtInputDropdown(
      controller: _bankNameController,
      items: _bankList,
      width: _width - 18,
      hint: 'Bank Name (Required)',
      onSelected: (bankInfo) {
        setState(() {
          _bankName = bankInfo?['name']?.toString();
          _errorText = '';
          _createSuccess = false;
        });
      },
    );
  }

  Widget _getItemScopeSetter() {
    return WgtScopeSetter(
      key: _scopeSetterKey,
      appConfig: widget.appConfig,
      width: _width,
      labelWidth: 130,
      forItemKind: PagItemKind.scope,
      forScopeType: PagScopeType.site,
      updateUiOnly: true,
      showCommitted: false,
      onScopeSet: (dynamic profile) {
        if (profile is! MdlPagSiteGroupProfile) {
          return {};
        }
        setState(() {
          _itemScopeMap
            ..clear()
            ..['site_group_id'] = profile.id.toString()
            ..['site_group_name'] = profile.name;
          _errorText = '';
          _createSuccess = false;
        });
      },
    );
  }
}
