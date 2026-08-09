import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_ex.dart';
import 'package:buff_helper/pag_helper/comm/comm_meter.dart';
import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/def_helper/op_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';

import '../../../model/mdl_pag_app_config.dart';

class WgtCreateGateway extends StatefulWidget {
  const WgtCreateGateway({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    this.showTitle = true,
    this.showPortalType = true,
    this.showEnabled = true,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final bool showTitle;
  final bool showPortalType;
  final bool showEnabled;
  final MdlPagUser loggedInUser;
  final Function? onCreated;

  @override
  State<WgtCreateGateway> createState() => _WgtCreateGatewayState();
}

class _WgtCreateGatewayState extends State<WgtCreateGateway> {
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

  String? _iccid;
  bool _isIccidRequired = false;
  UniqueKey? _iccidResetKey;
  bool _isIccidValidated = false;

  String? _ip;
  bool _isIpRequired = false;
  UniqueKey? _ipResetKey;
  bool _isIpValidated = false;

  String? _sn;
  bool _isSnRequired = false;
  UniqueKey? _snResetKey;
  bool _isSnValidated = false;

  String? _model;
  bool _isModelRequired = false;
  UniqueKey? _modelResetKey;
  bool _isModelValidated = false;

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
        'item_type': PagDeviceCat.gateway.value,
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
        itemType: PagDeviceCat.gateway,
      ));

      for (MdlListColController colController in listColControllerList) {
        final colKey = colController.colKey;
        if (colKey == 'label') {
          _isLabelRequired = colController.requiredOnFormCreate;
        } else if (colKey == 'sn' || colKey == 'motherboard_sn') {
          _isSnRequired = colController.requiredOnFormCreate;
        } else if (colKey == 'iccid') {
          _isIccidRequired = colController.requiredOnFormCreate;
        } else if (colKey == 'ip') {
          _isIpRequired = colController.requiredOnFormCreate;
        } else if (colKey == 'model') {
          _isModelRequired = colController.requiredOnFormCreate;
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
      // Map<String, dynamic> queryMap = {};
      // queryMap['device_cat'] = PagDeviceCat.gateway.value;
      // queryMap['scope'] = _loggedInUser!.selectedScope.toScopeMap();
      // queryMap['iccid'] = _iccid;
      // queryMap['ip'] = _ip;
      // queryMap['sn'] = _sn;
      // queryMap['gen'] = _gwGen!.name;
      Map<String, dynamic> queryMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'item_kind': PagItemKind.device.value,
        'device_cat': PagDeviceCat.gateway.value,
        'iccid': _iccid,
        'ip': _ip,
        'sn': _sn,
        'model': _model,
      };

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

      _label = result['label'];
      _newItemName = result['name'];

      _newItem = false;
      _createSuccess = true;
    } catch (e) {
      if (kDebugMode) {
        print('error: $e');
      }
      // setState(() {
      // _errorText = 'Error creating item';
      _errorText = getErrorText(e, defaultErrorText: 'Error creating item');
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
    if (_model == null) {
      if (_isModelRequired) {
        return false;
      }
    } else if (!_isModelValidated) {
      return false;
    }
    if (_iccid == null) {
      if (_isIccidRequired) {
        return false;
      }
    } else if (!_isIccidValidated) {
      return false;
    }
    if (_ip == null) {
      if (_isIpRequired) {
        return false;
      }
    } else if (!_isIpValidated) {
      return false;
    }
    if (_sn == null) {
      if (_isSnRequired) {
        return false;
      }
    } else if (!_isSnValidated) {
      return false;
    }
    if (_label == null) {
      if (_isLabelRequired) {
        return false;
      }
    } else if (!_isLabelValidated) {
      return false;
    }
    // if ((_iccid == null || _ip == null) && _sn == null) {
    //   return false;
    // }
    // if (_model == PagModelEnum.gen1 || _model == PagModelEnum.gen2) {
    //   if (!_isIccidValidated || !_isIpValidated) {
    //     return false;
    //   }
    // }
    // if (_model == PagModelEnum.gen3) {
    //   if (!_isSnValidated) {
    //     return false;
    //   }
    // }

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
          verticalSpaceTiny,
          // getModelSelector(),
          // verticalSpaceRegular,
          getItemBlock(),
          verticalSpaceRegular,
          WgtCommButton(
            enabled: _checkEnableButton(),
            label: _createWait
                ? 'Adding Gateway...'
                : _createSuccess
                    ? '✓ Gateway added'
                    : 'Add Gateway',
            onPressed: !_checkEnableButton() //_selectedProjectScope == null
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
                      _iccid = null;
                      _ip = null;
                      _model = null;
                      _sn = null;

                      _isIccidValidated = false;
                      _isIpValidated = false;
                      _isSnValidated = false;
                      _isModelValidated = false;

                      _labelResetKey = UniqueKey();
                      _ipResetKey = UniqueKey();
                      _snResetKey = UniqueKey();
                      _modelResetKey = UniqueKey();
                      _iccidResetKey = UniqueKey();
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
                'Gateway ${_newItemName ?? ''} created',
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
    // bool isNotGen3Gateway =
    //     _model == PagModelEnum.gen1 || _model == PagModelEnum.gen2;

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
            // if (isNotGen3Gateway) ...[
            WgtTextField(
              key: _modelResetKey,
              appConfig: widget.appConfig,
              hintText: 'Model',
              labelText: 'Model',
              maxLength: maxFullNameLength,
              validator: getValidator(validateDeviceModel, _isModelRequired),
              checkUnique: doPagCheckUnique,
              uniqueKey: 'model',
              itemTableName: '$projectName.gateway_$projectName',
              onUniqueCheck: (dynamic result) {
                if (result is bool) {
                  if (result) {
                    setState(() {
                      _isModelValidated = false;
                      _errorText = 'Model already exists';
                    });
                  } else {
                    setState(() {
                      _isModelValidated = true;
                    });
                  }
                } else if (result is String) {
                  if (result == 'taken') {
                    setState(() {
                      _isModelValidated = false;
                      _errorText = 'Model already exists';
                    });
                  } else {
                    setState(() {
                      _isModelValidated = false;
                      _errorText = result; // handle other error messages
                    });
                  }
                }
              },
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
                  _newItem = true;
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
            WgtTextField(
              key: _iccidResetKey,
              appConfig: widget.appConfig,
              hintText: 'ICCID',
              labelText: 'ICCID',
              maxLength: maxFullNameLength,
              validator: getValidator(validateDeviceIccid, _isIccidRequired),
              checkUnique: doPagCheckUnique,
              uniqueKey: 'iccid',
              itemTableName: '$projectName.gateway_$projectName',
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
              validator: getValidator(validateIp, _isIpRequired),
              checkUnique: doPagCheckUnique,
              uniqueKey: 'ip',
              itemTableName: '$projectName.gateway_$projectName',
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
            // ] else ...[
            WgtTextField(
              key: _snResetKey,
              appConfig: widget.appConfig,
              hintText: 'SN',
              labelText: 'SN',
              maxLength: maxFullNameLength,
              validator: getValidator(validateSerialNumber, _isSnRequired),
              checkUnique: doPagCheckUnique,
              uniqueKey: 'sn',
              itemTableName: '$projectName.gateway_$projectName',
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
            // ]
          ]),
        ),
      ],
    );
  }

  // Widget getModelSelector() {
  //   // hard code for now
  //   List<PagModelEnum> lcStatusList = PagModelEnum.values;
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
  //           child: Text('Type:',
  //               style: TextStyle(color: Theme.of(context).hintColor)),
  //         ),
  //       ),
  //       horizontalSpaceSmall,
  //       SizedBox(
  //         width: 102,
  //         child: DropdownButton<PagModelEnum>(
  //           alignment: AlignmentDirectional.centerStart,
  //           hint: Padding(
  //               padding: const EdgeInsets.only(bottom: 3.0),
  //               child: Text('Type', style: dropDownListHintStyle)),
  //           value: _model,
  //           key: _modelResetKey,
  //           focusColor: Theme.of(context).hoverColor,
  //           underline: dropDownUnderline,
  //           icon: const Icon(Icons.arrow_drop_down),
  //           iconSize: 21,
  //           style: TextStyle(color: Theme.of(context).colorScheme.primary),
  //           onChanged: (PagModelEnum? value) async {
  //             if (value != null) {
  //               if (value == _model) {
  //                 return;
  //               }
  //               setState(() {
  //                 _model = value;
  //                 _newItem = true;
  //                 _isModelValidated = true;
  //               });
  //             }
  //           },
  //           items: lcStatusList
  //               .map<DropdownMenuItem<PagModelEnum>>((PagModelEnum value) {
  //             return DropdownMenuItem<PagModelEnum>(
  //               value: value,
  //               child: Padding(
  //                 padding: const EdgeInsets.only(bottom: 3.0),
  //                 child: Text(value.name),
  //               ),
  //             );
  //           }).toList(),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
