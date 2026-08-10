import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_billing_cost_item.dart';
import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
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
import 'package:buff_helper/xt_ui/wdgt/datetime/wgt_date_picker.dart';
import 'package:flutter/material.dart';

import '../../../model/mdl_pag_app_config.dart';

class WgtCreateBillingCostItem extends StatefulWidget {
  const WgtCreateBillingCostItem({
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
  State<WgtCreateBillingCostItem> createState() =>
      _WgtCreateBillingCostItemState();
}

class _WgtCreateBillingCostItemState extends State<WgtCreateBillingCostItem> {
  // late MdlPagUser? _loggedInUser;
  final double width = 395;

  final int minCycleDay = 1;
  final int maxCycleDay = 25;

  final int minPaymentTerm = 1;
  final int maxPaymentTerm = 30;

  bool _isEditing = false;
  bool _newItem = true;
  bool _createWait = false;
  bool _createSuccess = false;
  String _errorText = '';

  String? _newItemLabel;
  String? _newItemName;
  bool _isNewItemLabelValidated = false;

  final Map<String, dynamic> _itemScopeMap = {};
  UniqueKey? _scopeSetterKey;

  String? _label;
  bool _isLabelValidated = false;
  UniqueKey? _labelResetKey;

  String? _remark;
  bool _isRemarkValidated = false;
  UniqueKey? _remarkResetKey;

  DateTime? _selectedFromDateTime;
  DateTime? _selectedToDateTime;
  UniqueKey? _timePickerFromKey;
  UniqueKey? _timePickerToKey;

  Future<dynamic> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
    });

    try {
      Map<String, dynamic> queryMap = {};
      queryMap['scope'] = widget.loggedInUser.selectedScope.toScopeMap();
      queryMap['label'] = _label;
      queryMap['remark'] = _remark;
      queryMap['item_scope_info'] = _itemScopeMap;

      if (_selectedFromDateTime != null && _selectedToDateTime != null) {
        if (_selectedFromDateTime!.isAfter(_selectedToDateTime!)) {
          setState(() {
            _errorText = 'Effective From Date must be before Effective To Date';
            _createWait = false;
            _createSuccess = false;
          });
          return;
        }
      }

      if (_selectedFromDateTime != null) {
        queryMap['effective_from_timestamp'] =
            _selectedFromDateTime!.toIso8601String();
      }
      if (_selectedToDateTime != null) {
        queryMap['effective_to_timestamp'] =
            _selectedToDateTime!.toIso8601String();
      }

      final result = await doCreatePagBillingCostItem(
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
      final data = result['data'];
      final billingCostItemInfo = data['billing_cost_item_info'];
      _newItemName = billingCostItemInfo['name'];

      _newItem = false;
      _createSuccess = true;
    } catch (e) {
      dev.log('error: $e');

      // setState(() {
      _errorText = 'Error creating billing cost item';
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

  void _resetDuration({bool resetDateRange = false}) {
    setState(() {
      if (resetDateRange) {
        _selectedToDateTime = null;
        _selectedFromDateTime = null;
        _timePickerFromKey = UniqueKey();
        _timePickerToKey = UniqueKey();
      }
    });
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

    return _itemScopeMap.isNotEmpty &&
            _isLabelValidated &&
            ((_remark ?? '').isEmpty || _isRemarkValidated)
        // && _selectedFromDateTime != null
        // && _selectedToDateTime != null
        ;
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
                    verticalSpaceRegular,
                    getItemBlock(),
                    verticalSpaceSmall,
                    getTimeRangePicker(),
                    verticalSpaceTiny,
                    getItemScopeSetter(),
                    verticalSpaceRegular,
                    WgtCommButton(
                      enabled: _checkEnableButton(),
                      label: _createWait
                          ? 'Creating billing cost item...'
                          : _createSuccess
                              ? '✓ Billing cost item created'
                              : 'Create Billing Cost Item',
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

                                    _selectedFromDateTime = null;
                                    _selectedToDateTime = null;
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
                          'Billing Cost Item ${_newItemName ?? ''} created',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget getItemBlock() {
    MdlPagScopeProfile scopeProfile = widget.loggedInUser.selectedScope;
    String projectName = scopeProfile.projectProfile!.name;

    return Column(
      children: [
        WgtTextField(
          key: _labelResetKey,
          appConfig: widget.appConfig,
          hintText: 'Label',
          labelText: 'Label',
          maxLength: maxFullNameLength,
          requireUnique: true,
          validator: validateItemLabel,
          checkUnique: doPagCheckUnique,
          uniqueKey: 'label',
          itemTableName: '$projectName.billing_cost_item_$projectName',
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
                _newItem = true;
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
        verticalSpaceSmall,
        WgtTextField(
          appConfig: widget.appConfig,
          hintText: 'Remark (optional)',
          labelText: 'Remark (optional)',
          maxLength: 200,
          maxLines: 3,
          initialValue: _remark,
          validator: (value) {
            if (value != null && value.length > 200) {
              return 'Remark must be at most 200 characters';
            }
            return null;
          },
          onChanged: (val) {
            setState(() {
              _remark = val;
            });
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
        verticalSpaceRegular,
      ],
    );
  }

  Widget getTimeRangePicker() {
    DateTime leftMostDate =
        DateTime.now().subtract(const Duration(days: 365 * 5));
    DateTime rightMostDate = DateTime.now().add(const Duration(days: 365 * 5));

    return Column(
      children: [
        WgtDatePicker(
          key: _timePickerFromKey,
          defaultFirstDate: leftMostDate,
          defaultLastDate: _selectedToDateTime ?? rightMostDate,
          initialDate: _selectedFromDateTime,
          labelFontSize: 15,
          timeZone: widget.loggedInUser.selectedScope.getProjectTimezone(),
          label: 'Effective From Date (optional)',
          onDateChanged: (DateTime selectedDate) {
            setState(() {
              _selectedFromDateTime = DateTime(selectedDate.year,
                  selectedDate.month, selectedDate.day, 0, 0, 0, 0);
            });
          },
          onDateCleared: () {
            setState(() {
              _selectedFromDateTime = null;
            });
          },
        ),
        verticalSpaceSmall,
        WgtDatePicker(
          key: _timePickerToKey,
          defaultFirstDate: _selectedFromDateTime ?? leftMostDate,
          defaultLastDate: rightMostDate,
          initialDate: _selectedToDateTime,
          labelFontSize: 15,
          timeZone: widget.loggedInUser.selectedScope.getProjectTimezone(),
          label: 'Effective To Date (optional)     ',
          onDateChanged: (DateTime selectedDate) {
            setState(() {
              _selectedToDateTime = DateTime(selectedDate.year,
                      selectedDate.month, selectedDate.day, 0, 0, 0, 0)
                  .add(const Duration(days: 1));
            });
          },
          onDateCleared: () {
            setState(() {
              _selectedToDateTime = null;
            });
          },
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
        forItemKind: PagItemKind.tariff,
        // forScopeType: widget.itemType is PagScopeType ? widget.itemType : null,
        onScopeSet: (dynamic profile) {
          if (profile == null) {
            dev.log('Profile is null');
            return {};
          }
          String scopeIdColName = '';
          if (profile is MdlPagSiteGroupProfile) {
            scopeIdColName = 'site_group_id';
          } else if (profile is MdlPagSiteProfile) {
            scopeIdColName = 'site_id';
          } else if (profile is MdlPagBuildingProfile) {
            scopeIdColName = 'building_id';
          } else if (profile is MdlPagLocationGroupProfile) {
            scopeIdColName = 'location_group_id';
          } else if (profile is MdlPagLocation) {
            scopeIdColName = 'location_id';
          }
          if (scopeIdColName.isEmpty) {
            dev.log('Invalid profile type');

            return {};
          }
          setState(() {
            _itemScopeMap[scopeIdColName] = profile.id.toString();
          });
        },
      ),
    );
  }
}
