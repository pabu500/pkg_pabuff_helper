import 'dart:developer' as dev;

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

class WgtCreateMcu extends StatefulWidget {
  const WgtCreateMcu({
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
  State<WgtCreateMcu> createState() => _WgtCreateMcuState();
}

class _WgtCreateMcuState extends State<WgtCreateMcu> {
  // late MdlPagUser? _loggedInUser;
  final double width = 395;

  bool _isEditing = false;
  bool _newItem = true;

  bool _newCreate = false;
  bool _createWait = false;
  bool _createSuccess = false;
  String _errorText = '';

  PagDeviceLsStatus? _McuLcStatus;

  // String? _newItemLabel;
  String? _newItemName;

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
      queryMap['device_cat'] = PagDeviceCat.mcu.value;
      queryMap['scope'] = widget.loggedInUser.selectedScope.toScopeMap();
      queryMap['motherboard_sn'] = _sn;
      //      queryMap['iccid'] = _iccid;
      // queryMap['ip'] = _ip;
      // queryMap['lc_status'] = _McuLcStatus!.name;

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

// _iccid = result['iccid'];
//       _ip = result['ip'];
      _sn = result['motherboard_sn'];
      _newItemName = result['name'];

      _newItem = false;
      _createSuccess = true;
    } catch (e) {
      dev.log('error: $e');
      // setState(() {
      _errorText = 'Error creating item';
      String eStr = e.toString().toLowerCase();
      if (kDebugMode) {
        print('error: $eStr');
      }
      final match = RegExp(r'message:\s*([^}]*)').firstMatch(e.toString());
      final errMsg = match?.group(1) ?? 'Unknown error';
      _errorText = 'Error checking device link: $errMsg';

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
                  // getMcuLcStatusSelector(),
                  verticalSpaceRegular,
                  WgtCommButton(
                    enabled: _checkEnableButton(),
                    label: _createWait
                        ? 'Adding MCU...'
                        : _createSuccess
                            ? '✓ MCU added'
                            : 'Add MCU',
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

                                  _isSnValidated = false;
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
                        'MCU ${_newItemName ?? ''} created',
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
              key: _snResetKey,
              appConfig: widget.appConfig,
              hintText: 'Serial Number',
              labelText: 'Serial Number',
              maxLength: maxRawFullNameLength,
              validator: validateSerialNumber,
              checkUnique: doPagCheckUnique,
              uniqueKey: 'sn',
              itemTableName: '$projectName.mcu_$projectName',
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

  Widget getMcuLcStatusSelector() {
    // hard code for now
    List<PagDeviceLsStatus> lcStatusList = PagDeviceLsStatus.values;
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
            value: _McuLcStatus,
            focusColor: Theme.of(context).hoverColor,
            underline: dropDownUnderline,
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 21,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            onChanged: (PagDeviceLsStatus? value) async {
              if (value != null) {
                if (value == _McuLcStatus) {
                  return;
                }
                setState(() {
                  _McuLcStatus = value;
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
}
