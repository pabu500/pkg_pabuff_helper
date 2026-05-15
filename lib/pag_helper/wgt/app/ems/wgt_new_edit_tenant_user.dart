import 'package:buff_helper/pag_helper/comm/comm_batch_op.dart';
import 'package:buff_helper/pag_helper/comm/comm_pag_job.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/xt_ui/util/xt_util_InputFieldValidator.dart';
import 'package:buff_helper/xt_ui/wdgt/input/wgt_text_field2.dart';
import 'package:buff_helper/xt_ui/xt_globals.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/mdl_pag_app_config.dart';

class WgtNewEditTenantUser extends StatefulWidget {
  const WgtNewEditTenantUser({
    super.key,
    required this.appConfig,
    // required this.jobTypeIdStr,
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
  // final String jobTypeIdStr;
  final bool readOnly;
  final Function? onInsert;
  final Function? onClose;
  final Function? onUpdate;
  final Function? onRemove;
  final Map<String, dynamic>? initialValueMap;
  final bool compactViewOnly;
  final double width;

  @override
  State<WgtNewEditTenantUser> createState() => _WgtNewEditTenantUserState();
}

class _WgtNewEditTenantUserState extends State<WgtNewEditTenantUser> {
  late MdlPagUser? _loggedInUser;

  late final isUpdate = widget.initialValueMap != null;

  String? _username;

  bool _isEditing = false;
  bool _isUsernameValidated = false;

  bool _receiveBillingNotification = false;

  String _errorText = '';

  String _resultStatusErrorText = '';

  Future<dynamic> _doSubmit() async {
    if (_username == null) {
      return;
    }

    setState(() {
      _resultStatusErrorText = '';
    });

    try {
      Map<String, dynamic> result = await doPagAddTenantUser(
        widget.appConfig,
        _loggedInUser!,
        {
          'username': _username,
          'receive_billing_notification': _receiveBillingNotification,
        },
        MdlPagSvcClaim(
          username: _loggedInUser!.username,
          userId: _loggedInUser!.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );
      if (result['code'] == 0) {
        _resultStatusErrorText = 'Subscriber added';
      } else {
        _resultStatusErrorText = 'Failed to add subscriber';
      }
      return _resultStatusErrorText;
    } catch (err) {
      if (kDebugMode) {
        print(err);
      }
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
      Map<String, dynamic> result = await doPagRemoveTenantUser(
        widget.appConfig,
        _loggedInUser!,
        {
          'id': widget.initialValueMap?['id'].toString(),
        },
        MdlPagSvcClaim(
          username: _loggedInUser!.username,
          userId: _loggedInUser!.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );
      if (result['code'] == 0) {
        _resultStatusErrorText = 'Subscriber deleted';
      } else {
        _resultStatusErrorText = 'Failed to delete subscriber';
      }
      return _resultStatusErrorText;
    } catch (err) {
      if (kDebugMode) {
        print(err);
      }
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
          'id': widget.initialValueMap?['id'].toString(),
          'username': _username,
          'receive_billing_notification': _receiveBillingNotification,
          'checked': true,
        }
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
      if (kDebugMode) {
        print(err);
      }
      _resultStatusErrorText = 'Failed to update subscriber';
      return _resultStatusErrorText;
    } finally {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    if (widget.initialValueMap != null) {
      _username = widget.initialValueMap?['username'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WgtTextField(
          enabled: !widget.readOnly,
          appConfig: widget.appConfig,
          hintText: 'Username',
          labelText: 'Username',
          initialValue: widget.initialValueMap?['username'],
          maxLength: maxFullNameLength,
          validator: validateFullName,
          onChanged: (val) {
            setState(() {
              _isEditing = true;
              if (val != _fullname) {
                _errorText = '';
              }
            });
            if (val.trim().isNotEmpty) {
              setState(() {
                _fullname = val;
              });
            }

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
                _isUsernameValidated = true;
              } else {
                _isUsernameValidated = false;
              }
            });
          },
        ),
        // checkbox for receive billing notification
        Row(
          children: [
            Checkbox(
              value: _receiveBillingNotification,
              onChanged: widget.readOnly
                  ? null
                  : (val) {
                      setState(() {
                        _receiveBillingNotification = val ?? false;
                      });
                    },
            ),
            const Text('Receive billing notification'),
          ],
        ),
        verticalSpaceSmall,
        getOpButton(),
      ],
    );
  }

  Widget getOpButton() {
    bool enableAdd = _username != null &&
        _username!.trim().isNotEmpty &&
        _isUsernameValidated;

    bool enableUpdate = _username != widget.initialValueMap?['username'];

    bool enableOp = isUpdate ? enableUpdate : enableAdd;

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
                      Map<String, dynamic> userInfo = {
                        'username': _username,
                      };
                      if (isUpdate) {
                        widget.onUpdate?.call(userInfo);
                      } else {
                        widget.onInsert?.call(userInfo);
                      }
                    },
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text(
                    isUpdate ? 'Update' : 'Add',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary),
                  )),
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
