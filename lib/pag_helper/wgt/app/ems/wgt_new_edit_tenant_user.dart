import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_batch_op.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/xt_ui/util/xt_util_InputFieldValidator.dart';
import 'package:buff_helper/xt_ui/wdgt/input/wgt_text_field2.dart';
import 'package:buff_helper/xt_ui/xt_globals.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../up_helper/enum/enum_item.dart';
import '../../../../up_helper/exceptions.dart';
import '../../../comm/comm_pag_item.dart';
import '../../../model/mdl_pag_app_config.dart';

class WgtNewEditTenantUser extends StatefulWidget {
  const WgtNewEditTenantUser({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.strItemGroupId,
    this.groupItemList,
    this.initialValueMap,
    this.compactViewOnly = false,
    this.readOnly = false,
    this.onInsert,
    this.onClose,
    this.onUpdate,
    this.onRemove,
    this.width = 360,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final String strItemGroupId;
  final bool readOnly;
  final Function? onInsert;
  final Function? onClose;
  final Function? onUpdate;
  final Function? onRemove;
  final Map<String, dynamic>? initialValueMap;
  final bool compactViewOnly;
  final double width;
  final List<Map<String, dynamic>>? groupItemList;

  @override
  State<WgtNewEditTenantUser> createState() => _WgtNewEditTenantUserState();
}

class _WgtNewEditTenantUserState extends State<WgtNewEditTenantUser> {
  late MdlPagUser? _loggedInUser;

  late final isUpdate = widget.initialValueMap != null;

  final String defaultErrorText = 'Error getting user info';

  String? _username;
  String? _strUserId;

  bool _isEditing = false;
  bool _isUsernameValidated = false;

  bool? _receiveBillingNotification;

  String _errorText = '';

  String _resultStatusErrorText = '';

  bool _isSearchingNewItemInfo = false;
  String _addNewItemErrorText = '';

  int _lookupVersion = 0;

  bool _userAlreadyListed({String? userId}) {
    return (widget.groupItemList ?? []).any((item) {
      if (item['edit_type'] == 'remove') return false;
      final existingId = (item['user_id'] ?? item['id'])?.toString();
      final existingUsername =
          (item['username'] ?? item['item_name'] ?? item['name'])
              ?.toString()
              .trim();
      return (userId != null && existingId == userId) ||
          (existingUsername != null && existingUsername == _username?.trim());
    });
  }

  Future<dynamic> _getItemInfo() async {
    if (isUpdate || _username == null || _username!.trim().isEmpty) {
      return;
    }
    final lookupVersion = ++_lookupVersion;
    final username = _username!.trim();
    setState(() {
      _isEditing = false;
      _isSearchingNewItemInfo = true;
      _addNewItemErrorText = '';
      _strUserId = null;
    });

    if (_userAlreadyListed()) {
      setState(() {
        _addNewItemErrorText = 'User already belongs to this tenant';
        _isSearchingNewItemInfo = false;
      });
      return;
    }

    try {
      Map<String, dynamic> queryMap = {
        "scope": widget.loggedInUser.selectedScope.toScopeMap(),
        "item_kind": PagItemKind.user.name,
        "item_id_type": ItemIdType.name.name,
        "item_id_value": username,
      };
      final itemInfo = await getPagItemInfo(
        widget.loggedInUser,
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: 'read',
        ),
      );
      if (!mounted || lookupVersion != _lookupVersion) return;
      final userId = itemInfo?['id']?.toString();
      if (userId == null || userId.isEmpty) {
        _addNewItemErrorText = defaultErrorText;
      } else if (_userAlreadyListed(userId: userId)) {
        _addNewItemErrorText = 'User already belongs to this tenant';
      } else {
        _strUserId = userId;
      }
    } catch (e) {
      if (!mounted || lookupVersion != _lookupVersion) return;
      dev.log(e.toString());
      _addNewItemErrorText = getErrorText(
        e,
        defaultErrorText: defaultErrorText,
      );
    } finally {
      if (mounted && lookupVersion == _lookupVersion) {
        setState(() {
          _isSearchingNewItemInfo = false;
        });
      }
    }
  }

  Future<dynamic> _doSubmit() async {
    if (_username == null) {
      return;
    }

    setState(() {
      _resultStatusErrorText = '';
    });

    try {
      // Map<String, dynamic> result = await doPagAddTenantUser(
      //   widget.appConfig,
      //   _loggedInUser!,
      //   {
      //     'username': _username,
      //     'receive_billing_notification': _receiveBillingNotification,
      //   },
      //   MdlPagSvcClaim(
      //     username: _loggedInUser!.username,
      //     userId: _loggedInUser!.id,
      //     scope: '',
      //     target: '',
      //     operation: '',
      //   ),
      // );
      // if (result['code'] == 0) {
      //   _resultStatusErrorText = 'Subscriber added';
      // } else {
      //   _resultStatusErrorText = 'Failed to add subscriber';
      // }
      return _resultStatusErrorText;
    } catch (err) {
      dev.log(err.toString());

      _resultStatusErrorText = 'Failed to add subscriber';
      return _resultStatusErrorText;
    } finally {
      setState(() {});
    }
  }

  Future<dynamic> _doDelete() async {
    setState(() {
      _resultStatusErrorText = '';
    });

    try {
      // Map<String, dynamic> result = await doPagRemoveTenantUser(
      //   widget.appConfig,
      //   _loggedInUser!,
      //   {
      //     'id': widget.initialValueMap?['id'].toString(),
      //   },
      //   MdlPagSvcClaim(
      //     username: _loggedInUser!.username,
      //     userId: _loggedInUser!.id,
      //     scope: '',
      //     target: '',
      //     operation: '',
      //   ),
      // );
      // if (result['code'] == 0) {
      //   _resultStatusErrorText = 'Subscriber deleted';
      // } else {
      //   _resultStatusErrorText = 'Failed to delete subscriber';
      // }
      return _resultStatusErrorText;
    } catch (err) {
      dev.log(err.toString());

      _resultStatusErrorText = 'Failed to delete subscriber';
      return _resultStatusErrorText;
    } finally {
      setState(() {});
    }
  }

  Future<dynamic> _doUpdate() async {
    setState(() {
      _resultStatusErrorText = '';
    });

    Map<String, dynamic> queryMap = {
      'op_name': 'multi_key_val_update',
      'op_list': [
        {
          'user_id': widget.initialValueMap?['id'].toString(),
          'username': _username,
          'receive_billing_notification': _receiveBillingNotification
              .toString(),
          'checked': true,
        },
      ],
    };

    try {
      List<Map<String, dynamic>> result = await doPagOpMultiKeyValUpdate(
        widget.appConfig,
        _loggedInUser,
        queryMap,
        MdlPagSvcClaim(
          username: _loggedInUser!.username,
          userId: _loggedInUser!.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );
      if (result.isNotEmpty) {
        _resultStatusErrorText = 'Subscriber updated';
      } else {
        _resultStatusErrorText = 'Failed to update subscriber';
      }
      return _resultStatusErrorText;
    } catch (err) {
      dev.log(err.toString());
      _resultStatusErrorText = 'Failed to update subscriber';
      return _resultStatusErrorText;
    } finally {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _loggedInUser = Provider.of<PagUserProvider>(
      context,
      listen: false,
    ).currentUser;

    if (widget.initialValueMap != null) {
      _username = widget.initialValueMap?['username'];
      _strUserId = widget.initialValueMap?['user_id']?.toString();

      _receiveBillingNotification =
          'true' == widget.initialValueMap?['receive_billing_notification'];
    }
  }

  @override
  Widget build(BuildContext context) {
    bool enableEditUsername =
        !widget.readOnly && widget.initialValueMap?['username'] == null;

    return Column(
      children: [
        WgtTextField(
          enabled: enableEditUsername,
          appConfig: widget.appConfig,
          hintText: 'Username',
          labelText: 'Username',
          initialValue: widget.initialValueMap?['username'],
          maxLength: maxLoginNameLength,
          validator: validateUsername,
          onChanged: (val) {
            setState(() {
              _lookupVersion++;
              _username = val;
              _isEditing = true;
              _isSearchingNewItemInfo = false;
              _strUserId = null;
              _errorText = '';
              _addNewItemErrorText = '';
            });
            return null;
          },
          onEditingComplete: _getItemInfo,
          onValidate: (String? result) {
            setState(() {
              if (result == null) {
                _isUsernameValidated = true;
              } else {
                _isUsernameValidated = false;
              }
            });
          },
        ),
        if (_addNewItemErrorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _addNewItemErrorText,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        // checkbox for receive billing notification
        Row(
          children: [
            Checkbox(
              value: _receiveBillingNotification ?? false,
              onChanged: widget.readOnly
                  ? null
                  : (val) {
                      if (mounted) {
                        setState(() {
                          _receiveBillingNotification = val ?? false;
                        });
                      }
                    },
            ),
            const Text('Receive billing notification'),
          ],
        ),
        // verticalSpaceSmall,
        getOpButton(),
      ],
    );
  }

  Widget getOpButton() {
    bool enableAdd =
        _username != null &&
        _username!.trim().isNotEmpty &&
        _isUsernameValidated &&
        _strUserId != null &&
        !_isSearchingNewItemInfo;

    String? strReceiveBillingNotificationIniVal =
        widget.initialValueMap?['receive_billing_notification'];
    bool recevieBillingNotificationIniVal =
        'true' == strReceiveBillingNotificationIniVal;
    bool enableUpdate =
        _username != widget.initialValueMap?['username'] ||
        _receiveBillingNotification != recevieBillingNotificationIniVal;

    bool enableOp = isUpdate ? enableUpdate : enableAdd;

    if (_isEditing) {
      enableOp = false;
    }
    if (_addNewItemErrorText.isNotEmpty) {
      enableOp = false;
    }

    return Row(
      children: [
        Expanded(child: Container()),
        if (!widget.readOnly)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: !enableOp
                  ? Theme.of(context).colorScheme.secondary.withAlpha(55)
                  : Theme.of(context).colorScheme.secondary,
            ),
            child: InkWell(
              onTap: !enableOp
                  ? null
                  : () {
                      if (!isUpdate && _userAlreadyListed(userId: _strUserId)) {
                        setState(() {
                          _addNewItemErrorText =
                              'User already belongs to this tenant';
                        });
                        return;
                      }
                      Map<String, dynamic> userInfo = {
                        'tenant_id': widget.strItemGroupId,
                        'username': _username?.trim(),
                        'user_id': _strUserId,
                        'id': _strUserId,
                        'receive_billing_notification':
                            (_receiveBillingNotification ?? false).toString(),
                      };
                      if (isUpdate) {
                        widget.onUpdate?.call(userInfo);
                      } else {
                        widget.onInsert?.call(userInfo);
                      }
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Text(
                  isUpdate ? 'Update' : 'Add',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
          ),
        horizontalSpaceSmall,
        IconButton(
          onPressed: () {
            widget.onClose?.call();
          },
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}
