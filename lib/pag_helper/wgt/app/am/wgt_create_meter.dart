import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_ex.dart';
import 'package:buff_helper/pag_helper/comm/comm_meter.dart';
import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/op_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/wgt/scope/wgt_scope_setter.dart';
import 'package:buff_helper/pag_helper/wgt/tree/wgt_tree_element.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/mdl_pag_app_config.dart';

class WgtCreateMeter extends StatefulWidget {
  const WgtCreateMeter({
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
  State<WgtCreateMeter> createState() => _CreateItemState();
}

class _CreateItemState extends State<WgtCreateMeter> {
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
  bool _isLabelRequired = false;

  String? _sn;
  bool _isSnValidated = false;
  UniqueKey? _snResetKey;
  bool _isSnRequired = false;

  String? _tag;
  bool _isTagValidated = false;
  UniqueKey? _tagResetKey;
  bool _isTagRequired = false;

  String? _model;
  bool _isModelValidated = false;
  UniqueKey? _modelResetKey;
  bool _isModelRequired = false;

  PagMeterPhaseType? _selectedPhaseType;

  MeterTypeTag? _selectedMeterType;
  bool _isMeterTypeRequired = false;

  MeterDataType? _selectedMeterDataType;
  bool _isMeterDataTypeRequired = false;

  String? _multiplierFactor;
  bool _isMultiplierFactorValidated = false;
  UniqueKey? _multiplierFactorResetKey;
  bool _isMultiplierFactorRequired = false;

  String? _mainSubMeter;

  PagDeviceLsStatus? _meterLcStatus;

  PagTreeNode? _itemChildrenGroupTreeRoot;
  final List<Map<String, dynamic>> _itemChildrenList = [];

  Map<String, dynamic> _itemScopeMap = {};
  UniqueKey? _scopeSetterKey;

  final List<Map<String, dynamic>> opListConfig = [];

  bool _isFetchingListConfig = false;
  String _fetchErrorText = '';
  final List<MdlListColController> listColControllerList = [];
  int _failedPullListInfo = 0;

  Future<dynamic> _getListConfig() async {
    dev.log('fetching list config');

    // if (widget.loggedInUser == null) {
    //   return;
    // }

    if (_isFetchingListConfig) {
      return;
    }

    listColControllerList.clear();
    opListConfig.clear();
    _fetchErrorText = '';

    try {
      Map<String, dynamic> queryMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'item_kind': PagItemKind.device.value,
        'item_type': PagDeviceCat.meter.value,
        // 'item_type_list_str': widget.itemTypeListStr ?? 'NOT_SET',
      };

      _isFetchingListConfig = true;

      final result = await ex(
        endpoint: PagUrlBase.eptGetListInfoList2,
        crudType: 'read',
        opStr: 'get list info list',
        appConfig: widget.appConfig,
        queryMap: queryMap,
        svcClaim: MdlPagSvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      final listInfoList = result as List<dynamic>?;
      if (listInfoList == null || listInfoList.length > 1) {
        throw Exception('Failed to get list info list');
      }

      final listConfig = listInfoList.first['list_config'] as List<dynamic>?;
      final customOpConfig =
          listInfoList.first['custom_op_config'] as List<dynamic>?;

      final fullListConfig = [];
      fullListConfig.addAll(listConfig ?? []);
      fullListConfig.addAll(customOpConfig ?? []);

      opListConfig.addAll(getOpListConfig(
        fullListConfig,
        listColControllerList,
        PagDeviceOpType.onboarding,
        PagItemKind.device,
        itemType: PagDeviceCat.meter,
      ));

      for (MdlListColController colController in listColControllerList) {
        final colKey = colController.colKey;
        if (colKey == 'label') {
          _isLabelRequired = colController.requiredOnFormCreate;
        } else if (colKey == 'sn' || colKey == 'meter_sn') {
          _isSnRequired = colController.requiredOnFormCreate;
        } else if (colKey == 'tag') {
          _isTagRequired = colController.requiredOnFormCreate;
        } else if (colKey == 'model') {
          _isModelRequired = colController.requiredOnFormCreate;
        } else if (colKey == 'meter_type') {
          _isMeterTypeRequired = colController.requiredOnFormCreate;
        } else if (colKey == 'main_sub_meter') {
          // no action needed
        } else if (colKey == 'lc_status') {
          // no action needed
        } else if (colKey == 'phase_type') {
          // no action needed
        } else if (colKey == 'data_type') {
          _isMeterDataTypeRequired = colController.requiredOnFormCreate;
        } else if (colKey == 'multiplier_factor') {
          _isMultiplierFactorRequired = colController.requiredOnFormCreate;
        } else {
          dev.log('unrecognized col key: $colKey');
        }
      }
    } catch (e) {
      dev.log(e.toString());

      _fetchErrorText =
          getErrorText(e, defaultErrorText: 'Failed to get op list config');

      _failedPullListInfo++;
    } finally {
      setState(() {
        _isFetchingListConfig = false;
      });
    }
  }

  Future<dynamic> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
    });

    try {
      _itemScopeMap['project_id'] =
          widget.loggedInUser.selectedScope.projectProfile!.id.toString();
      _itemScopeMap['project_name'] =
          widget.loggedInUser.selectedScope.projectProfile!.name;

      Map<String, dynamic> queryMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'item_scope_info': _itemScopeMap,
        'item_kind': PagItemKind.device.value,
        'device_cat': PagDeviceCat.meter.value,
        'label': _label,
        'meter_sn': _sn,
        'multiplier_factor': _multiplierFactor,
        'meter_type': _selectedMeterType?.name,
        'data_type': _selectedMeterDataType?.value,
        'main_sub_meter': _mainSubMeter,
        'lc_status': _meterLcStatus?.value,
        'tag': _tag,
        'model': _model,
        'phase_type': _selectedPhaseType?.value,
      };

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

      _newItem = false;
      _createSuccess = true;
    } catch (e) {
      dev.log('error: $e');

      // setState(() {
      _errorText = getErrorText(e, defaultErrorText: 'Failed to create meter');

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

    if (_label == null || !_isLabelValidated) {
      return false;
    }
    if (_sn == null) {
      if (_isSnRequired) {
        return false;
      }
    } else if (!_isSnValidated) {
      return false;
    }
    if (_tag == null) {
      if (_isTagRequired) {
        return false;
      }
    } else if (!_isTagValidated) {
      return false;
    }
    if (_model == null) {
      if (_isModelRequired) {
        return false;
      }
    } else if (!_isModelValidated) {
      return false;
    }

    if (_selectedMeterType == null) {
      if (_isMeterTypeRequired) {
        return false;
      }
    }

    if (_selectedMeterDataType == null) {
      if (_isMeterDataTypeRequired) {
        return false;
      }
    }
    if (_multiplierFactor == null) {
      if (_isMultiplierFactorRequired) {
        return false;
      }
    } else if (!_isMultiplierFactorValidated) {
      return false;
    }

    return _itemScopeMap.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    // _loggedInUser =
    //     Provider.of<PagUserProvider>(context, listen: false).currentUser;
  }

  @override
  Widget build(BuildContext context) {
    bool fetchListInfo = listColControllerList.isEmpty &&
        !_isFetchingListConfig &&
        !_fetchErrorText.isNotEmpty;

    return SingleChildScrollView(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: width,
            child: fetchListInfo
                ? FutureBuilder(
                    future: _getListConfig(),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                          return const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [WgtPagWait()],
                            ),
                          );
                        default:
                          if (snapshot.hasError) {
                            return getErrorTextPrompt(
                              context: context,
                              errorText: 'Error fetching data',
                            );
                          }
                          return getForm();
                      }
                    },
                  )
                : getForm(),
          ),
        ],
      ),
    );
  }

  Widget getForm() {
    if (_fetchErrorText.isNotEmpty) {
      return getErrorTextPrompt(context: context, errorText: _fetchErrorText);
    }
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        children: [
          verticalSpaceRegular,
          getItemBlock(),
          verticalSpaceTiny,
          getMeterTypeSelector(),
          verticalSpaceTiny,
          getMeterDataTypeSelector(),
          verticalSpaceTiny,
          getMainSubSelector(),
          verticalSpaceTiny,
          getMeterLcStatusSelector(),
          verticalSpaceTiny,
          getMeterPhaseSelector(),
          verticalSpaceTiny,
          getItemScopeSetter(),
          verticalSpaceRegular,
          WgtCommButton(
            enabled: _checkEnableButton(),
            label: _createWait
                ? 'Adding meter...'
                : _createSuccess
                    ? '✓ Meter added'
                    : 'Add Meter',
            onPressed: !_checkEnableButton() //_selectedProjectScope == null
                ? null
                : () async {
                    await _createItem();

                    // reset the form
                    setState(() {
                      _newCreate = false;
                      _createWait = false;

                      _mainSubMeter = null;
                      _meterLcStatus = null;
                      _selectedMeterType = null;
                      _selectedPhaseType = null;
                      _selectedMeterDataType = null;

                      _label = null;
                      _isLabelValidated = false;
                      _labelResetKey = UniqueKey();

                      _sn = null;
                      _isSnValidated = false;
                      _snResetKey = UniqueKey();

                      _tag = null;
                      _isTagValidated = false;
                      _tagResetKey = UniqueKey();

                      _multiplierFactor = null;
                      _isMultiplierFactorValidated = false;
                      _multiplierFactorResetKey = UniqueKey();

                      _model = null;
                      _isModelValidated = false;
                      _modelResetKey = UniqueKey();

                      // _newItemName = null;
                      _itemChildrenGroupTreeRoot = null;
                      _itemChildrenList.clear();
                      _itemScopeMap.clear();
                      _scopeSetterKey = UniqueKey();
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
                'Meter ${_newItemName ?? ''} created',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
          child: Column(children: [
            if (listColControllerList.any(
                (col) => col.colKey == 'label' && col.showInputOnFormCreate))
              WgtTextField(
                key: _labelResetKey,
                appConfig: widget.appConfig,
                hintText: 'Label',
                labelText: 'Label ${_isLabelRequired ? '(Required)' : ''}',
                maxLength: maxFullNameLength,
                validator: getValidator(validateDeviceLabel, _isLabelRequired),
                // _isLabelRequired
                //     ? validateDeviceLabel
                //     : (val) => val != null && val.trim().isNotEmpty
                //         ? validateDeviceLabel
                //         : null,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'label',
                itemTableName: '$projectName.meter_$projectName',
                validateOnChange: false,
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
                    if (val.trim().isNotEmpty) {
                      _newCreate = true;
                      _createSuccess = false;
                    }
                  });
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
            if (listColControllerList.any((col) =>
                (col.colKey == 'sn' || col.colKey == 'meter_sn') &&
                col.showInputOnFormCreate))
              WgtTextField(
                key: _snResetKey,
                appConfig: widget.appConfig,
                hintText: 'Serial Number',
                labelText: 'Serial Number ${_isSnRequired ? '(Required)' : ''}',
                maxLength: maxFullNameLength,
                validator: getValidator(validateSerialNumber, _isSnRequired),
                // _isSnRequired
                //     ? validateSerialNumber
                //     : (val) => val != null && val.trim().isNotEmpty
                //         ? validateSerialNumber
                //         : null,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'sn',
                itemTableName: '$projectName.meter_$projectName',
                validateOnChange: false,
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _sn) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _sn = val;
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
                      _isSnValidated = true;
                    } else {
                      _isSnValidated = false;
                    }
                  });
                },
              ),
            if (listColControllerList
                .any((col) => col.colKey == 'tag' && col.showInputOnFormCreate))
              WgtTextField(
                key: _tagResetKey,
                appConfig: widget.appConfig,
                hintText: 'Tag',
                labelText: 'Tag ${_isTagRequired ? '(Required)' : ''}',
                maxLength: maxFullNameLength,
                validator: getValidator(validateTag, _isTagRequired),
                // _isTagRequired
                //     ? validateTag
                //     : (val) => val != null && val.trim().isNotEmpty
                //         ? validateTag
                //         : null,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'tag',
                itemTableName: '$projectName.meter_$projectName',
                validateOnChange: false,
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
            if (listColControllerList.any(
                (col) => col.colKey == 'model' && col.showInputOnFormCreate))
              WgtTextField(
                key: _modelResetKey,
                appConfig: widget.appConfig,
                hintText: 'Model',
                labelText: 'Model ${_isModelRequired ? '(Required)' : ''}',
                maxLength: maxFullNameLength,
                validator: getValidator(validateDeviceModel, _isModelRequired),
                // _isModelRequired
                //     ? validateDeviceModel
                //     : (val) => val != null && val.trim().isNotEmpty
                //         ? validateDeviceModel
                //         : null,
                checkUnique: doPagCheckUnique,
                uniqueKey: 'model',
                itemTableName: '$projectName.meter_$projectName',
                validateOnChange: false,
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _model) {
                      _errorText = '';
                    }
                  });
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _newCreate = true;
                      _createSuccess = false;
                    });
                  }
                  _model = val;
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
                      _isModelValidated = true;
                    } else {
                      _isModelValidated = false;
                    }
                  });
                },
              ),
            if (listColControllerList.any((col) =>
                col.colKey == 'multiplier_factor' && col.showInputOnFormCreate))
              WgtTextField(
                key: _multiplierFactorResetKey,
                appConfig: widget.appConfig,
                hintText: 'Multiplier Factor',
                labelText:
                    'Multiplier Factor ${_isMultiplierFactorRequired ? '(Required)' : ''}',
                maxLength: maxFullNameLength,
                validator: getValidator(
                    validateMeterMultiplierFactor, _isMultiplierFactorRequired),
                validateOnChange: false,
                onChanged: (val) {
                  setState(() {
                    _isEditing = true;
                    if (val != _multiplierFactor) {
                      _errorText = '';
                    }
                    if (val.trim().isNotEmpty) {
                      _newCreate = true;
                      _createSuccess = false;
                    }
                  });
                  _multiplierFactor = val;
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
                      _isMultiplierFactorValidated = true;
                    } else {
                      _isMultiplierFactorValidated = false;
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
      MeterTypeTag.SE1
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
          width: 102,
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

  Widget getMeterDataTypeSelector() {
    // hard code for now
    List<MeterDataType> meterDataTypeList = [
      MeterDataType.amr,
      MeterDataType.manual,
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
            child: Text('Data Type:',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 102,
          child: DropdownButton<MeterDataType>(
              alignment: AlignmentDirectional.centerStart,
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Data Type', style: dropDownListHintStyle)),
              value: _selectedMeterDataType,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (MeterDataType? value) async {
                if (value != null) {
                  if (value == _selectedMeterDataType) {
                    return;
                  }
                }
                setState(() {
                  _selectedMeterDataType = value!;
                  _newItem = true;
                  _createSuccess = false;
                });
              },
              items: meterDataTypeList
                  .map<DropdownMenuItem<MeterDataType>>((MeterDataType value) {
                return DropdownMenuItem<MeterDataType>(
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

  Widget getMeterPhaseSelector() {
    if (_selectedMeterType != MeterTypeTag.E) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            'Phase Type:',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 170,
          child: DropdownButton<PagMeterPhaseType?>(
            value: _selectedPhaseType,
            isExpanded: true,
            underline: Container(
              height: 1,
              color: Theme.of(context).hintColor.withAlpha(75),
            ),
            icon: const Icon(Icons.arrow_drop_down),
            onChanged: (PagMeterPhaseType? value) {
              setState(() {
                _selectedPhaseType = value;
              });
            },
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text(''),
              ),
              ...PagMeterPhaseType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.key),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget getMeterLcStatusSelector() {
    // hard code for now
    List<PagDeviceLsStatus> lcStatusList = PagDeviceLsStatus.values;
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
            child: Text('Status:',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 102,
          child: DropdownButton<PagDeviceLsStatus>(
            alignment: AlignmentDirectional.centerStart,
            hint: Padding(
                padding: const EdgeInsets.only(bottom: 3.0),
                child: Text('Status', style: dropDownListHintStyle)),
            value: _meterLcStatus,
            focusColor: Theme.of(context).hoverColor,
            underline: dropDownUnderline,
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 21,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            onChanged: (PagDeviceLsStatus? lcStatus) async {
              if (lcStatus != null) {
                if (lcStatus == _meterLcStatus) {
                  return;
                }
                setState(() {
                  _meterLcStatus = lcStatus;
                });
              }
            },
            items: lcStatusList.map<DropdownMenuItem<PagDeviceLsStatus>>(
                (PagDeviceLsStatus value) {
              return DropdownMenuItem<PagDeviceLsStatus>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text(value.name),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget getMainSubSelector() {
    // hard code for now
    List<String> mainSubList = [
      'Main Meter',
      'Sub Meter',
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
            child: Text('Main/Sub:',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 102,
          child: DropdownButton<String>(
              alignment: AlignmentDirectional.centerStart,
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Main/Sub', style: dropDownListHintStyle)),
              value: _mainSubMeter,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (String? value) async {
                if (value != null) {
                  if (value == _mainSubMeter) {
                    return;
                  }
                }
                setState(() {
                  _mainSubMeter = value!;
                  _newItem = true;
                  _createSuccess = false;
                });
              },
              items: mainSubList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(
                      value,
                      // style: dropDownListTextStyle,
                    ),
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
        forItemKind: PagItemKind.device,
        // forScopeType: PagScopeType.location,
        onScopeSet: (dynamic profile) {
          if (profile == null) {
            dev.log('Profile is null');

            return {};
          }
          String scopeIdColName = '';
          String scopeNameColName = '';
          if (profile is MdlPagLocation) {
            scopeIdColName = 'location_id';
            scopeNameColName = 'location_name';
          }
          if (scopeIdColName.isEmpty) {
            dev.log('Invalid profile type');
            return {};
          }
          setState(() {
            _itemScopeMap[scopeNameColName] = profile.name;
            _itemScopeMap[scopeIdColName] = profile.id.toString();
          });
        },
      ),
    );
  }
}
