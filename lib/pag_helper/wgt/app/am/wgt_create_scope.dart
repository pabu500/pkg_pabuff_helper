import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_geo.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
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
import 'package:buff_helper/pag_helper/comm/comm_scope.dart';
import 'package:provider/provider.dart';

import '../../../model/mdl_pag_app_config.dart';
import '../../../pag_app_context_list.dart';
import '../../ls/wgt_item_type_selector.dart';

class WgtCreateScope extends StatefulWidget {
  const WgtCreateScope({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    this.itemTypeEnum,
    this.onScopeTreeUpdate,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Function? onScopeTreeUpdate;
  final Function? onCreated;
  final PagScopeType? itemTypeEnum;

  @override
  State<WgtCreateScope> createState() => _CreateScopeState();
}

class _CreateScopeState extends State<WgtCreateScope> {
  // late MdlPagUser? _loggedInUser;
  final double width = 395;

  final String defaultErrorText = 'Error creating scope';

  bool _isEditing = false;
  bool _newItem = true;
  bool _createWait = false;
  bool _createSuccess = false;
  String _errorText = '';

  String? _label;
  String? _newItemName;
  bool _isNewItemLabelValidated = false;
  UniqueKey? _newItemLabelResetKey;

  String? _lat;
  String? _lng;
  bool _isLatValidated = false;
  bool _isLngValidated = false;
  UniqueKey? _latResetKey;
  UniqueKey? _lngResetKey;

  Map<String, dynamic> _itemScopeMap = {};
  UniqueKey? _scopeSetterKey;

  // dynamic _selectedItemType;

  final List<PagScopeType> scopeTypeList = [
    PagScopeType.location,
    PagScopeType.locationGroup,
    PagScopeType.building,
    PagScopeType.site,
    PagScopeType.siteGroup,
  ];
  PagScopeType? _selectedScopeType;

  final List<String> timezoneOffsetList =
      List.generate(25, (i) => (i - 12).toString());
  String _selectedTimezoneOffset = '8';

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
      queryMap['item_type'] = _selectedScopeType!.name;
      queryMap['lat'] = _lat;
      queryMap['lng'] = _lng;
      queryMap['item_scope_info'] = _itemScopeMap;

      if (_selectedScopeType == PagScopeType.site) {
        queryMap['timezone'] = _selectedTimezoneOffset;
      }

      final result = await doPagCreateScope(
        widget.loggedInUser,
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          selectedRoleId: widget.loggedInUser.selectedRole!.id,
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

      _errorText = getErrorText(e, defaultErrorText: defaultErrorText);

      _newItem = true;
      _createSuccess = false;

      // widget.onScopeTreeUpdate?.call();

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

    return _label != null &&
        _selectedScopeType != null &&
        (_selectedScopeType == PagScopeType.siteGroup ||
            _itemScopeMap.isNotEmpty);
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
                  verticalSpaceTiny,
                  WgtItemTypeSelector(
                    pagAppContext: appCtxAm,
                    appConfig: widget.appConfig,
                    itemKind: PagItemKind.scope,
                    enabledItemTypeList: widget.itemTypeEnum?.value != null
                        ? [widget.itemTypeEnum!.value]
                        : [
                            PagScopeType.location.value,
                            PagScopeType.locationGroup.value,
                            PagScopeType.building.value,
                            PagScopeType.site.value,
                            PagScopeType.siteGroup.value,
                          ],
                    prefKey: 'create_scope_item_type',
                    onItemTypeSelected: (itemType) {
                      setState(() {
                        _selectedScopeType = itemType;

                        _checkEnableButton();
                        _itemScopeMap.clear();
                        _newItem = true;
                        _createSuccess = false;
                      });
                    },
                  ),
                  verticalSpaceSmall,
                  // getScopeTypeSelector(),
                  // verticalSpaceTiny,
                  getItemPropBlock(),
                  verticalSpaceTiny,
                  getItemScopeSetter(),
                  verticalSpaceRegular,
                  WgtCommButton(
                    enabled: _checkEnableButton(),
                    label: _createWait
                        ? 'Creating scope...'
                        : _createSuccess
                            ? '✓ Scope created'
                            : 'Create Scope',
                    onPressed:
                        !_checkEnableButton() //_selectedProjectScope == null
                            ? null
                            : () async {
                                await _createItem();

                                // reset the form
                                setState(() {
                                  // _newItem = true;
                                  _label = null;
                                  _isNewItemLabelValidated = false;
                                  _newItemLabelResetKey = UniqueKey();

                                  _selectedScopeType = null;

                                  _lat = null;
                                  _isLatValidated = false;
                                  _latResetKey = UniqueKey();
                                  _lng = null;
                                  _isLngValidated = false;
                                  _lngResetKey = UniqueKey();

                                  _itemScopeMap.clear();
                                  _scopeSetterKey = UniqueKey();
                                });

                                // pause for 1 second to show the error message before reset
                                await Future.delayed(
                                    const Duration(seconds: 1));
                                widget.onScopeTreeUpdate?.call();
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
                        'Scope ${_newItemName ?? ''} created, refreshing portal...',
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

  Widget getItemPropBlock() {
    MdlPagScopeProfile scopeProfile = widget.loggedInUser.selectedScope;
    String projectName = scopeProfile.projectProfile!.name;

    TextStyle dropDownListTextStyle = TextStyle(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500);
    TextStyle dropDownListHintStyle =
        TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
    Widget dropDownUnderline =
        Container(height: 1, color: Theme.of(context).hintColor.withAlpha(75));

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
              labelText: 'Label (Required)',
              maxLength: maxFullNameLength,
              validator: validateLabelScope,
              checkUnique: doPagCheckUnique,
              requireUnique: _selectedScopeType == PagScopeType.siteGroup ||
                  _selectedScopeType == PagScopeType.site ||
                  _selectedScopeType == PagScopeType.building,
              uniqueKey: 'label',
              itemTableName:
                  '$projectName.${_selectedScopeType != null ? _selectedScopeType!.value : ''}_$projectName',
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
                    _isNewItemLabelValidated = true;
                  } else {
                    _isNewItemLabelValidated = false;
                  }
                });
              },
            ),
            //lat, lng
            WgtTextField(
              appConfig: widget.appConfig,
              hintText: 'Lattitude',
              labelText: 'Lattitude',
              maxLength: 20,
              validator: validatorLat,
              key: _latResetKey,
              onChanged: (val) {
                setState(() {
                  _isEditing = true;
                  if (val != _lat) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _newItem = true;
                    _createSuccess = false;
                  });
                }
                _lat = val;
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
                    _isLatValidated = true;
                  } else {
                    _isLatValidated = false;
                  }
                });
              },
            ),
            WgtTextField(
              appConfig: widget.appConfig,
              hintText: 'Longitude',
              labelText: 'Longitude',
              maxLength: 20,
              validator: validatorLng,
              key: _lngResetKey,
              onChanged: (val) {
                setState(() {
                  _isEditing = true;
                  if (val != _lng) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _newItem = true;
                    _createSuccess = false;
                  });
                }
                _lng = val;
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
                    _isLngValidated = true;
                  } else {
                    _isLngValidated = false;
                  }
                });
              },
            ),
            _selectedScopeType == PagScopeType.site
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 80,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text('Timezone:',
                              style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 16)),
                        ),
                      ),
                      DropdownButton<String>(
                          alignment: AlignmentDirectional.centerStart,
                          hint: Padding(
                              padding: const EdgeInsets.only(bottom: 3.0),
                              child: Text('Timezone',
                                  style: dropDownListHintStyle)),
                          value: _selectedTimezoneOffset,
                          focusColor: Theme.of(context).hoverColor,
                          underline: dropDownUnderline,
                          icon: const Icon(Icons.arrow_drop_down),
                          iconSize: 21,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                          onChanged: (String? value) async {
                            if (value != null) {
                              if (value == _selectedTimezoneOffset) {
                                return;
                              }
                            }
                            setState(() {
                              _selectedTimezoneOffset = value!;
                              _newItem = true;
                              _createSuccess = false;
                            });
                          },
                          items: timezoneOffsetList
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 3.0),
                                child: Text(value.toString()),
                              ),
                            );
                          }).toList())
                    ],
                  )
                : const SizedBox.shrink(),
          ]),
        ),
      ],
    );
  }

  Widget getScopeTypeSelector() {
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
          width: 95,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text('Scope Type:',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 110,
          child: DropdownButton<PagScopeType>(
              alignment: AlignmentDirectional.centerStart,
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Scope Type', style: dropDownListHintStyle)),
              value: _selectedScopeType,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (PagScopeType? value) async {
                if (value != null) {
                  if (value == _selectedScopeType) {
                    return;
                  }
                }
                _checkEnableButton();
                setState(() {
                  _selectedScopeType = value!;
                  _itemScopeMap.clear();
                  _newItem = true;
                  _createSuccess = false;
                });
              },
              items: scopeTypeList
                  .map<DropdownMenuItem<PagScopeType>>((PagScopeType value) {
                return DropdownMenuItem<PagScopeType>(
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
    if (_selectedScopeType == null) {
      return const SizedBox.shrink();
    }
    if (_selectedScopeType == PagScopeType.siteGroup) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: WgtScopeSetter(
        key: _scopeSetterKey,
        appConfig: widget.appConfig,
        width: width,
        labelWidth: 130,
        forItemKind: PagItemKind.scope,
        forScopeType: _selectedScopeType,
        updateUiOnly: true,
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
