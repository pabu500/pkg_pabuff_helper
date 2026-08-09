import 'package:buff_helper/pag_helper/comm/comm_meter.dart';
import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/mdl_pag_app_config.dart';

class WgtCreateMotherboard extends StatefulWidget {
  const WgtCreateMotherboard({
    super.key,
    required this.appConfig,
    this.showTitle = true,
    this.showPortalType = true,
    this.showEnabled = true,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final bool showTitle;
  final bool showPortalType;
  final bool showEnabled;
  final Function? onCreated;

  @override
  State<WgtCreateMotherboard> createState() => _WgtCreateMotherboardState();
}

class _WgtCreateMotherboardState extends State<WgtCreateMotherboard> {
  late MdlPagUser? _loggedInUser;
  final double width = 395;

  bool _isEditing = false;
  bool _newItem = true;

  String? _selectedType;
  MeterTypeTag? _selectedMeterType;

  bool _newCreate = false;
  bool _createWait = false;
  bool _createSuccess = false;
  String _errorText = '';

  // String? _newItemLabel;
  String? _newItemName;

  String? _sn;
  bool _isSnValidated = false;
  UniqueKey? _snResetKey;

  String? _model;
  bool _isModelValidated = false;
  UniqueKey? _modelResetKey;

  Future<dynamic> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
    });

    try {
      Map<String, dynamic> queryMap = {};
      queryMap['device_cat'] = PagDeviceCat.motherboard.name;
      queryMap['scope'] = _loggedInUser!.selectedScope.toScopeMap();
      queryMap['sn'] = _sn;
      queryMap['model'] = _model;
      queryMap['type'] = _selectedType;

      dynamic result;

      result = await doPagCreateDevice(
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

      _sn = result['sn'];
      _newItemName = result['name'];

      _newItem = false;
      _createSuccess = true;
    } catch (e) {
      if (kDebugMode) {
        print('error: $e');
      }
      // setState(() {
      _errorText = 'Error creating item';
      String eStr = e.toString().toLowerCase();
      if (kDebugMode) {
        print('error: $eStr');
      }

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

    if (!_isSnValidated) {
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();

    _loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;
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
                  verticalSpaceTiny,
                  getModel(),
                  verticalSpaceTiny,
                  getTypeSelector(),
                  verticalSpaceRegular,
                  WgtCommButton(
                    enabled: _checkEnableButton(),
                    label: _createWait
                        ? 'Adding Mother Board...'
                        : _createSuccess
                            ? '✓ Mother Board added'
                            : 'Add Mother Board',
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

                                  _sn = null;
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
                        'Mother Board ${_newItemName ?? ''} created',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getItemBlock() {
    MdlPagScopeProfile scopeProfile = _loggedInUser!.selectedScope;
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
              key: _snResetKey,
              appConfig: widget.appConfig,
              hintText: 'Serial Number',
              labelText: 'Serial Number',
              maxLength: maxRawFullNameLength,
              validator: validateSerialNumber,
              checkUnique: doPagCheckUnique,
              uniqueKey: 'sn',
              itemTableName: '$projectName.motherboard_$projectName',
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
          ]),
        ),
      ],
    );
  }

  Widget getModel() {
    MdlPagScopeProfile scopeProfile = _loggedInUser!.selectedScope;
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
              key: _modelResetKey,
              appConfig: widget.appConfig,
              hintText: 'Model',
              labelText: 'Model',
              maxLength: maxFullNameLength,
              validator: validateModel,
              uniqueKey: 'model',
              itemTableName: '$projectName.motherboard_$projectName',
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
          ]),
        ),
      ],
    );
  }

  Widget getTypeSelector() {
    // hard code for now
    List<Map<String, String>> typeList = [
      {"name": "mcu", "value": "mcu"},
      {"name": "gateway", "value": "gateway"},
    ];

    TextStyle dropDownListTextStyle = TextStyle(
      fontSize: 15,
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w500,
    );

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
            child: Text('Type:',
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
              child: Text('Type', style: dropDownListHintStyle),
            ),
            value: _selectedType,
            focusColor: Theme.of(context).hoverColor,
            underline: dropDownUnderline,
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 21,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            onChanged: (String? value) async {
              if (value != null && value == _selectedType) return;
              setState(() {
                _selectedType = value!;
                _newItem = true;
                _createSuccess = false;
              });
            },
            items: typeList.map<DropdownMenuItem<String>>((type) {
              return DropdownMenuItem<String>(
                value: type['value'], // store the value
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text(
                    type['name']!, // show the name
                    style: dropDownListTextStyle,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
