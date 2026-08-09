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

class WgtCreateSim extends StatefulWidget {
  const WgtCreateSim({
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
  State<WgtCreateSim> createState() => _WgtCreateSimState();
}

class _WgtCreateSimState extends State<WgtCreateSim> {
  // late MdlPagUser? _loggedInUser;
  final double width = 395;

  bool _isEditing = false;
  bool _newItem = true;

  bool _newCreate = false;
  bool _createWait = false;
  bool _createSuccess = false;
  String _errorText = '';

  PagSimPackageEnum? _package;
  String? _adapterType;

  // String? _newItemLabel;
  String? _newItemName;

  String? _iccid;
  bool _isIccidValidated = false;
  UniqueKey? _iccidResetKey;

  String? _ip;
  bool _isIpValidated = false;
  UniqueKey? _ipResetKey;

  String? _sn;
  bool _isSnValidated = false;
  UniqueKey? _snResetKey;

  final List<Map<String, dynamic>> _itemChildrenList = [];

  Future<dynamic> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
    });

    try {
      Map<String, dynamic> queryMap = {};
      queryMap['device_cat'] = PagDeviceCat.sim.value;
      queryMap['scope'] = widget.loggedInUser.selectedScope.toScopeMap();
      queryMap['iccid'] = _iccid;
      queryMap['ip'] = _ip;
      queryMap['package'] = _package!.name;
      queryMap['adapter_type'] = _adapterType;
      queryMap['sn'] = _sn;

      dynamic result;

      result = await doPagCreateDevice(
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

      _iccid = result['iccid'];
      _ip = result['ip'];
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
      try {
        if (eStr.contains('iccid')) {
          _errorText += ': ICCID already exists';
        } else if (eStr.contains('ip')) {
          _errorText += ': IP already exists';
        } else if (eStr.contains('sn')) {
          _errorText += ': SN already exists';
        }
      } catch (e) {
        if (kDebugMode) {
          print('error parsing error message: $e');
        }
      }
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
    if (!_isIccidValidated || !_isIpValidated || !_isSnValidated) {
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
                  verticalSpaceRegular,
                  getItemBlock(),
                  verticalSpaceTiny,
                  getSimpackgeSelector(),
                  verticalSpaceRegular,
                  getAdapterTypeSelector(),
                  verticalSpaceRegular,
                  WgtCommButton(
                    enabled: _checkEnableButton(),
                    label: _createWait
                        ? 'Adding SIM...'
                        : _createSuccess
                            ? '✓ SIM added'
                            : 'Add SIM',
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

                                  _iccid = null;
                                  _ip = null;
                                  _sn = null;
                                  _isIccidValidated = false;
                                  _isIpValidated = false;
                                  _isSnValidated = false;
                                  _iccidResetKey = UniqueKey();
                                  _ipResetKey = UniqueKey();
                                  _snResetKey = UniqueKey();
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
                        'SIM ${_newItemName ?? ''} created',
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
              key: _iccidResetKey,
              appConfig: widget.appConfig,
              hintText: 'ICCID',
              labelText: 'ICCID',
              maxLength: maxRawFullNameLength,
              validator: validateDeviceIccid,
              checkUnique: doPagCheckUnique,
              uniqueKey: 'iccid',
              itemTableName: '$projectName.mcu_$projectName',
              onUniqueCheck: (dynamic result) {
                if (result is bool) {
                  if (result) {
                    setState(() {
                      _isIccidValidated = false;
                      _errorText = 'ICCID already exists';
                    });
                  } else {
                    setState(() {
                      _isIccidValidated = true;
                    });
                  }
                } else if (result is String) {
                  if (result == 'taken') {
                    setState(() {
                      _isIccidValidated = false;
                      _errorText = 'ICCID already exists';
                    });
                  } else {
                    setState(() {
                      _isIccidValidated = false;
                      _errorText = result; // handle other error messages
                    });
                  }
                }
              },
              onChanged: (val) {
                setState(() {
                  _isEditing = true;
                  if (val != _iccid) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _newCreate = true;
                    _createSuccess = false;
                  });
                }
                _iccid = val;
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
                    _isIccidValidated = true;
                  } else {
                    _isIccidValidated = false;
                  }
                });
              },
            ),
            WgtTextField(
              key: _ipResetKey,
              appConfig: widget.appConfig,
              hintText: 'IP',
              labelText: 'IP',
              maxLength: maxFullNameLength,
              validator: validateIp,
              checkUnique: doPagCheckUnique,
              uniqueKey: 'ip',
              itemTableName: '$projectName.mcu_$projectName',
              onChanged: (val) {
                setState(() {
                  _isEditing = true;
                  if (val != _ip) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _newCreate = true;
                    _createSuccess = false;
                  });
                }
                _ip = val;
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
                    _isIpValidated = true;
                  } else {
                    _isIpValidated = false;
                  }
                });
              },
            ),
            WgtTextField(
              key: _snResetKey,
              appConfig: widget.appConfig,
              hintText: 'SN',
              labelText: 'SN',
              maxLength: maxFullNameLength,
              validator: validateSerialNumber,
              checkUnique: doPagCheckUnique,
              uniqueKey: 'sn',
              itemTableName: '$projectName.sim_$projectName',
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

  Widget getSimpackgeSelector() {
    // hard code for now
    List<PagSimPackageEnum> simPackageList = PagSimPackageEnum.values;
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
            child: Text('Package:',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 102,
          child: DropdownButton<PagSimPackageEnum>(
            alignment: AlignmentDirectional.centerStart,
            hint: Padding(
                padding: const EdgeInsets.only(bottom: 3.0),
                child: Text('Package', style: dropDownListHintStyle)),
            value: _package,
            focusColor: Theme.of(context).hoverColor,
            underline: dropDownUnderline,
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 21,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            onChanged: (PagSimPackageEnum? value) async {
              if (value != null) {
                if (value == _package) {
                  return;
                }
                setState(() {
                  _package = value;
                });
              }
            },
            items: simPackageList.map<DropdownMenuItem<PagSimPackageEnum>>(
                (PagSimPackageEnum value) {
              return DropdownMenuItem<PagSimPackageEnum>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text(value.label),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget getAdapterTypeSelector() {
    List<Map<String, String>> _typeList = [
      {"name": "jbs2", "value": "jbs2"},
      {"name": "evs2sim", "value": "evs2sim"},
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
            child: Text(
              'Adapter Type:',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 140,
          child: DropdownButton<String>(
            alignment: AlignmentDirectional.centerStart,
            hint: Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Text('Adapter Type', style: dropDownListHintStyle),
            ),
            value: _adapterType,
            focusColor: Theme.of(context).hoverColor,
            underline: dropDownUnderline,
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 21,
            style: dropDownListTextStyle,
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  _adapterType = value;
                });
              }
            },
            items: _typeList.map((item) {
              return DropdownMenuItem<String>(
                value: item["value"],
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text(item["name"] ?? ""),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
