import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_ex.dart';
import 'package:buff_helper/pag_helper/comm/comm_meter.dart';
import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_meter_group.dart';
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

import '../../../model/mdl_pag_app_config.dart';

class WgtCreateMeterGroup extends StatefulWidget {
  const WgtCreateMeterGroup({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.serviceType,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final MeterGroupServiceType serviceType;
  final Function? onCreated;

  @override
  State<WgtCreateMeterGroup> createState() => _CreateItemState();
}

class _CreateItemState extends State<WgtCreateMeterGroup> {
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

  late final MeterGroupServiceType selectedServiceType;
  MeterTypeTag? _selectedMeterType;
  String? _selectedPollingLaw;

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
        'item_kind': PagItemKind.meterGroup.value,
        'device_cat': PagDeviceCat.meterGroup.value,
        'label': _newItemLabel,
        'meter_type': _selectedMeterType!.name,
        'polling_id_mapping_law': _selectedPollingLaw ?? '0',
        'service_type': selectedServiceType.value,
        'item_scope_info': _itemScopeMap,
        'item_list': [],
      };

      if (selectedServiceType == MeterGroupServiceType.comm) {
        final result = await doPagCreateDevice(
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
        dev.log('Created AM meter group: $_newItemName');
      } else if (selectedServiceType == MeterGroupServiceType.ems) {
        final result = await ex(
          endpoint: PagUrlBase.eptPagCreateMeterGroup,
          crudType: 'create',
          opStr: 'create meter group',
          appConfig: widget.appConfig,
          queryMap: queryMap,
          svcClaim: MdlPagSvcClaim(
            userId: widget.loggedInUser.id,
            username: widget.loggedInUser.username,
            scope: '',
            target: '',
            operation: 'create',
          ),
        );
        _newItemName = result['name'];
        dev.log('Created EMS meter group: $_newItemName');
      } else {
        throw Exception('Invalid service type: $selectedServiceType');
      }

      _newItem = false;
      _createSuccess = true;
    } catch (e) {
      dev.log('error: $e');

      _errorText = 'Error creating meter group';
      String eStr = e.toString().toLowerCase();

      dev.log('error: $eStr');

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

    if (selectedServiceType == MeterGroupServiceType.comm) {
      if (_selectedPollingLaw == null) {
        return false;
      }
    }

    return _newItemLabel != null &&
        _selectedMeterType != null &&
        _itemScopeMap.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    // _loggedInUser =
    //     Provider.of<PagUserProvider>(context, listen: false).currentUser;

    selectedServiceType = widget.serviceType;
    assert([MeterGroupServiceType.comm, MeterGroupServiceType.ems]
        .contains(selectedServiceType));
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
                  getPollingLawSelector(),
                  verticalSpaceTiny,
                  getMeterTypeSelector(),
                  verticalSpaceTiny,
                  getItemScopeSetter(),
                  verticalSpaceRegular,
                  WgtCommButton(
                    enabled: _checkEnableButton(),
                    label: _createWait
                        ? 'Creating meter group...'
                        : _createSuccess
                            ? '✓ Meter Group created'
                            : 'Create Meter Group',
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

                                    _selectedMeterType = null;
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
                        'Meter Group ${_newItemName ?? ''} created',
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

  // Widget getServiceTypeSelector() {
  //   // hard code for now
  //   List<String> serviceTypeList = ["comm", "ems", "evs"];
  //   TextStyle dropDownListTextStyle = TextStyle(
  //       fontSize: 15,
  //       color: Theme.of(context).colorScheme.onSurface,
  //       fontWeight: FontWeight.w500);
  //   TextStyle dropDownListHintStyle =
  //       TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
  //   Widget dropDownUnderline =
  //       Container(height: 1, color: Theme.of(context).hintColor.withAlpha(75));
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.start,
  //     children: [
  //       SizedBox(
  //         width: 95,
  //         child: Align(
  //           alignment: AlignmentDirectional.centerEnd,
  //           child: Text('Service Type:',
  //               style: TextStyle(color: Theme.of(context).hintColor)),
  //         ),
  //       ),
  //       horizontalSpaceSmall,
  //       SizedBox(
  //         width: 110,
  //         child: DropdownButton<String>(
  //             alignment: AlignmentDirectional.centerStart,
  //             hint: Padding(
  //                 padding: const EdgeInsets.only(bottom: 3.0),
  //                 child: Text('Service Type', style: dropDownListHintStyle)),
  //             value: _selectedServiceType,
  //             focusColor: Theme.of(context).hoverColor,
  //             underline: dropDownUnderline,
  //             icon: const Icon(Icons.arrow_drop_down),
  //             iconSize: 21,
  //             style: TextStyle(color: Theme.of(context).colorScheme.primary),
  //             onChanged: (String? value) async {
  //               if (value != null) {
  //                 if (value == _selectedServiceType) {
  //                   return;
  //                 }
  //               }
  //               setState(() {
  //                 _selectedServiceType = value!;
  //                 _newItem = true;
  //                 _createSuccess = false;
  //               });
  //             },
  //             items:
  //                 serviceTypeList.map<DropdownMenuItem<String>>((String value) {
  //               return DropdownMenuItem<String>(
  //                 value: value,
  //                 child: Padding(
  //                   padding: const EdgeInsets.only(bottom: 3.0),
  //                   child: Text(value),
  //                 ),
  //               );
  //             }).toList()),
  //       ),
  //     ],
  //   );
  // }

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
              itemTableName: '$projectName.tenant_$projectName',
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

  Widget getMeterTypeSelector() {
    // hard code for now
    List<MeterTypeTag> meterTypeList = [
      MeterTypeTag.E,
      MeterTypeTag.W,
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
          width: 95,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text('Meter Type:',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 96,
          child: DropdownButton<MeterTypeTag>(
              alignment: AlignmentDirectional.centerStart,
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Meter Type', style: dropDownListHintStyle)),
              value: _selectedMeterType,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (MeterTypeTag? value) async {
                if (value != null) {
                  if (value == _selectedMeterType) {
                    return;
                  }
                }
                setState(() {
                  _selectedMeterType = value!;
                  _newItem = true;
                  _createSuccess = false;
                });
              },
              items: meterTypeList
                  .map<DropdownMenuItem<MeterTypeTag>>((MeterTypeTag value) {
                return DropdownMenuItem<MeterTypeTag>(
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

  Widget getPollingLawSelector() {
    if (selectedServiceType != 'comm') {
      return Container();
    }

    // hard code for now
    List<String> meterLawList = ["1", "2"];
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
            child: Text('Polling Law:',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 100,
          child: DropdownButton<String>(
              alignment: AlignmentDirectional.centerStart,
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Polling Law', style: dropDownListHintStyle)),
              value: _selectedPollingLaw,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (String? value) async {
                if (value != null) {
                  if (value == _selectedPollingLaw) {
                    return;
                  }
                }
                setState(() {
                  _selectedPollingLaw = value!;
                  _newItem = true;
                  _createSuccess = false;
                });
              },
              items: meterLawList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(value),
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
        forItemKind: PagItemKind.tariff,
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
