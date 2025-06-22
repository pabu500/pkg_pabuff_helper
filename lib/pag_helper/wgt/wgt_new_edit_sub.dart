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

import '../model/mdl_pag_app_config.dart';

class WgtNewEditSub extends StatefulWidget {
  const WgtNewEditSub({
    super.key,
    required this.appConfig,
    required this.jobTypeIdStr,
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
  final String jobTypeIdStr;
  final bool readOnly;
  final Function? onInsert;
  final Function? onClose;
  final Function? onUpdate;
  final Function? onRemove;
  final Map<String, dynamic>? initialValueMap;
  final bool compactViewOnly;
  final double width;

  @override
  State<WgtNewEditSub> createState() => _WgtNewEditSubState();
}

class _WgtNewEditSubState extends State<WgtNewEditSub> {
  late MdlPagUser? _loggedInUser;

  late final isUpdate = widget.initialValueMap != null;

  String? _fullname;
  String? _email;
  String? _salutation;

  bool _isEditing = false;
  bool _isFullNameValidated = false;
  bool _isSalutationValidated = false;
  bool _isEmailValidated = false;

  String _errorText = '';

  String _resultStatusErrorText = '';

  Future<dynamic> _doSubmit() async {
    if (_fullname == null || _email == null || _salutation == null) {
      return;
    }
    if (_salutation!.isEmpty || _email!.isEmpty) {
      return;
    }
    setState(() {
      _resultStatusErrorText = '';
    });

    try {
      Map<String, dynamic> result = await doPagAddSub(
        widget.appConfig,
        _loggedInUser!,
        {
          'job_type_id': widget.jobTypeIdStr,
          'name': _fullname,
          'email': _email,
          'salutation': _salutation,
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
      Map<String, dynamic> result = await doPagRemoveSub(
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
          'sub_fullname': _fullname,
          'sub_email': _email,
          'sub_salutation': _salutation,
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
      _fullname = widget.initialValueMap?['sub_fullname'];
      _email = widget.initialValueMap?['sub_email'];
      _salutation = widget.initialValueMap?['sub_salutation'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WgtTextField(
          enabled: !widget.readOnly,
          appConfig: widget.appConfig,
          hintText: 'Full Name',
          labelText: 'Full Name (Optional)',
          initialValue: widget.initialValueMap?['sub_fullname'],
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
                _isFullNameValidated = true;
              } else {
                _isFullNameValidated = false;
              }
            });
          },
        ),
        WgtTextField(
          enabled: !widget.readOnly,
          appConfig: widget.appConfig,
          hintText: 'Salutation',
          labelText: 'Salutation',
          initialValue: widget.initialValueMap?['sub_salutation'],
          maxLength: maxSalutationLength,
          validator: validateSalutation,
          onChanged: (val) {
            setState(() {
              _isEditing = true;
              if (val != _salutation) {
                _errorText = '';
              }
            });
            if (val.trim().isNotEmpty) {
              setState(() {
                _salutation = val;
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
                _isSalutationValidated = true;
              } else {
                _isSalutationValidated = false;
              }
            });
          },
        ),
        WgtTextField(
          enabled: !widget.readOnly,
          appConfig: widget.appConfig,
          hintText: 'Email',
          labelText: 'Email',
          // key: _emailResetKey,
          initialValue: widget.initialValueMap?['sub_email'],
          maxLength: maxEmailLength,
          validator: validateEmail,
          onChanged: (val) {
            setState(() {
              _isEditing = true;
              if (val != _email) {
                _errorText = '';
              }
            });
            if (val.trim().isNotEmpty) {
              setState(() {
                _email = val;
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
                _isEmailValidated = true;
              } else {
                _isEmailValidated = false;
              }
            });
          },
        ),
        verticalSpaceSmall,
        getOpButton(),
      ],
    );
  }

  Widget getOpButton() {
    bool enableAdd =
        /*_fullname != null && _fullname!.isNotEmpty &&*/
        _salutation != null &&
            _salutation!.isNotEmpty &&
            _email != null &&
            _email!.isNotEmpty;

    bool enableUpdate = _fullname != widget.initialValueMap?['sub_fullname'] ||
        _salutation != widget.initialValueMap?['sub_salutation'] ||
        _email != widget.initialValueMap?['sub_email'];

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
                      Map<String, dynamic> subInfo = {
                        'sub_fullname': _fullname,
                        'sub_salutation': _salutation,
                        'sub_email': _email,
                      };
                      if (isUpdate) {
                        widget.onUpdate?.call(subInfo);
                      } else {
                        widget.onInsert?.call(subInfo);
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
