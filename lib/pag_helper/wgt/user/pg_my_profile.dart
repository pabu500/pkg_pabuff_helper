import 'package:buff_helper/pag_helper/def/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../pkg_buff_helper.dart';
import '../../comm/comm_batch_op.dart';
import '../../comm/comm_user_service.dart';
import '../../model/acl/mdl_pag_svc_claim.dart';
import '../../model/mdl_pag_app_config.dart';
import 'wgt_update_password.dart';
import 'package:provider/provider.dart';

class PagPgMyProfile extends StatefulWidget {
  const PagPgMyProfile({
    super.key,
    required this.appConfig,
  });

  final MdlPagAppConfig appConfig;

  @override
  State<PagPgMyProfile> createState() => _PagPgMyProfileState();
}

class _PagPgMyProfileState extends State<PagPgMyProfile> {
  late MdlPagUser? loggedInUser;

  final double _width = 360;
  String? _originalUsername;
  // String _usernameErrorText = '';
  String? _originalFullname;
  String? _originalEmail;
  String? _originalContactNumber;
  List<Map<String, dynamic>> _emailSuffixes = [];
  // String _emailErrorText = '';
  final TextEditingController _controllerOldPassword = TextEditingController();
  final TextEditingController _controllerNewPassword = TextEditingController();
  final TextEditingController _controllerConfirmPassword =
      TextEditingController();
  // String _errorTextOldPassword = '';
  // String _errorTextNewPassword = '';
  // String _errorTextConfirmPassword = '';
  // bool _showUpdatePasswordButton = false;
  // bool _updatingPassword = false;
  // bool _passwordUpdated = false;
  // bool _subMonthlyDailyKwhByUnit = true;

  String _currentField = '';

  bool _isCoolingDownSendVerify = false;
  bool _isCoolingDownCheckVerify = false;

  Future<List<Map<String, dynamic>>> _updateProfile(String key, String value,
      {String? oldVal}) async {
    try {
      String idStr = loggedInUser!.id!.toString();
      Map<String, dynamic> queryMap = {
        'id': idStr,
        'item_kind': PagItemKind.user.name,
        'item_id_type': ItemIdType.id.name,
        'item_id_key': 'id',
        'item_id': idStr,
        // 'key1, key2, key3, ...'
        'update_key_str': key,
        'op_name': 'multi_key_val_update',
        'op_list': [
          {
            'id': idStr,
            key: value,
            'checked': true,
          }
        ],
      };
      // if (widget.listController != null) {
      queryMap['item_table_name'] = 'pag.pag_user';
      // }

      List<Map<String, dynamic>> result = await doPagOpMultiKeyValUpdate(
        widget.appConfig,
        loggedInUser,
        queryMap,
        MdlPagSvcClaim(
          username: loggedInUser!.username,
          userId: loggedInUser!.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      return result;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      //return a Map
      Map<String, dynamic> result = {};
      result['error'] = explainException(e, defaultMsg: 'Error updating field');

      //result is a List
      return [result];
    }
  }

  Future<dynamic> _checkValue(String key) async {
    Map<String, dynamic> queryMap = {
      'id': loggedInUser!.id!.toString(),
      'key': key,
    };
    try {
      dynamic data = await doCheckKeyVal(
        widget.appConfig,
        loggedInUser!,
        queryMap,
        MdlPagSvcClaim(
          userId: loggedInUser!.id,
          username: loggedInUser!.username,
          scope: '',
          target: '',
          operation: '',
        ),
      );
      if (data == null) {
        throw Exception('Error checking value');
      }

      if (data[key] == 'verified') {
        setState(() {
          loggedInUser!.emailVerified = true;
        });
      }
      return data;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      //return a Map
      Map<String, dynamic> result = {};
      result['error'] = explainException(e);

      return result;
    }
  }

  bool showUpdatePasswordButton() {
    return _controllerOldPassword.text.isNotEmpty &&
        _controllerNewPassword.text.isNotEmpty &&
        _controllerConfirmPassword.text.isNotEmpty &&
        // _errorTextOldPassword.isEmpty &&
        // _errorTextNewPassword.isEmpty &&
        // _errorTextConfirmPassword.isEmpty &&
        (_controllerNewPassword.text == _controllerConfirmPassword.text) &&
        (_controllerNewPassword.text != _controllerOldPassword.text);
  }

  @override
  void initState() {
    super.initState();

    loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    _originalUsername = loggedInUser!.username;
    _originalEmail = loggedInUser!.email;
    _originalFullname = loggedInUser!.fullName;
    _originalContactNumber = loggedInUser!.phone;
  }

  @override
  void dispose() {
    _controllerOldPassword.dispose();
    _controllerNewPassword.dispose();
    _controllerConfirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const EdgeInsets _padding =
        EdgeInsets.symmetric(vertical: 13, horizontal: 8);

    // _subMonthlyDailyKwhByUnit = false;
    // if ((loggedInUser!.hasRole2(AclRole.EVS2_Ops_Site_NTU_MR) ||
    //    loggedInUser!.isFullOpsAndUp())) {
    //   if (loggedInUser!.emailVerified ?? false) {
    //     _subMonthlyDailyKwhByUnit = true;
    //   }
    // }

    _emailSuffixes = _emailSuffixes = [
      {
        'key': 'verified',
        'widget': Tooltip(
          message: (loggedInUser!.emailVerified ?? false)
              ? ''
              : 'Re-send verification email',
          waitDuration: const Duration(milliseconds: 500),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: (loggedInUser!.emailVerified ?? false)
                  ? (_isCoolingDownSendVerify
                      ? Theme.of(context).colorScheme.primary.withAlpha(130)
                      : Theme.of(context).colorScheme.primary)
                  : (_isCoolingDownSendVerify
                      ? Theme.of(context).colorScheme.error.withAlpha(130)
                      : Theme.of(context).colorScheme.error.withAlpha(210)),
            ),
            child: Text(
              (loggedInUser!.emailVerified ?? false)
                  ? 'Verified'
                  : 'Unverified',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
        'onTap':
            _isCoolingDownSendVerify || (loggedInUser!.emailVerified ?? false)
                ? null
                : () async {
                    String emailToVerify = _originalEmail ?? '';
                    if (emailToVerify.isEmpty) {
                      return {'error': 'Email is empty'};
                    }
                    //validate email
                    String? validated = validateEmail(emailToVerify);
                    if (validated != null) {
                      return {'error': 'Invalid email'};
                    }

                    setState(() {
                      _isCoolingDownSendVerify = true;
                    });

                    dynamic data = await doUpdateUserKeyValue(
                      widget.appConfig,
                      loggedInUser!,
                      {
                        'id': loggedInUser!.id!.toString(),
                        'key': 'email',
                        'value': emailToVerify,
                        'send_verification_email': 'true',
                      },
                      MdlPagSvcClaim(
                        userId: loggedInUser!.id,
                        username: loggedInUser!.username,
                        scope: '',
                        target: '',
                        operation: '',
                      ),
                    );
                    if (data == null) {
                      return {'error': 'Error sending verification email'};
                    }
                    Map<String, dynamic> resultMap = data;
                    if (resultMap['error'] == null) {
                      resultMap['message'] = 'Verification email sent';
                      setState(() {
                        _originalEmail = emailToVerify;
                        loggedInUser!.email = emailToVerify;
                        loggedInUser!.emailVerified = false;
                      });
                    }

                    //Timer
                    Future.delayed(const Duration(milliseconds: 2500), () {
                      setState(() {
                        _isCoolingDownSendVerify = false;
                      });
                    });

                    return data;
                  },
      },
      {
        'key': 'refresh',
        'widget': Icon(
          Icons.refresh,
          color: _isCoolingDownCheckVerify
              ? Theme.of(context).colorScheme.primary.withAlpha(130)
              : Theme.of(context).colorScheme.primary,
          size: 21,
        ),
        'onTap': _isCoolingDownCheckVerify
            ? null
            : () async {
                String emailToVerify = _originalEmail ?? '';
                if (emailToVerify.isEmpty) {
                  return {'error': 'Email is empty'};
                }
                //validate email
                String? validated = validateEmail(emailToVerify);
                if (validated != null) {
                  return {'error': 'Invalid email'};
                }
                setState(() {
                  _isCoolingDownCheckVerify = true;
                });
                //check if email is verified
                dynamic result = await _checkValue('verification_code');

                //Timer
                Future.delayed(const Duration(milliseconds: 2500), () {
                  setState(() {
                    _isCoolingDownCheckVerify = false;
                  });
                });

                if (result['error'] == null) {
                  return {
                    'show_committed': false,
                  };
                }
              },
      },
    ];

    if (loggedInUser!.emailVerified ?? false) {
      _emailSuffixes.removeWhere((element) => element['key'] == 'refresh');
    } else {
      //remove refresh icon
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _originalUsername = loggedInUser!.username;
                _originalEmail = loggedInUser!.email;
                _originalFullname = loggedInUser!.fullName;
                _originalContactNumber = loggedInUser!.phone;
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: 395,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Text(
                    _originalFullname ?? '',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                verticalSpaceRegular,
                WgtViewEditField(
                  width: _width,
                  editable: false,
                  labelText: 'Username',
                  originalValue: _originalUsername ?? '',
                  onFocus: (hasFocus) {
                    setState(() {
                      _currentField = 'username';
                    });
                  },
                  hasFocus: _currentField == 'username',
                  onSetValue: (newValue) async {
                    List<Map<String, dynamic>> result = await _updateProfile(
                      'username',
                      newValue,
                    );
                    Map<String, dynamic> resultMap = result[0];
                    if (resultMap['error'] == null) {
                      setState(() {
                        // _usernameErrorText = '';
                        _originalUsername = newValue;
                        loggedInUser!.username = newValue;
                      });
                    }
                    return resultMap;
                  },
                  // errorText: _usernameErrorText,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter username';
                    }
                    if (value.length < 6) {
                      return 'Username must be at least 6 characters';
                    }
                    //alpha numeric, -, _ only
                    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
                      return 'only contain alpha numeric, -, _';
                    }
                    //can't start or end with - or _
                    if (value.startsWith('-') ||
                        value.startsWith('_') ||
                        value.endsWith('-') ||
                        value.endsWith('_')) {
                      return 'cannot start or end with - or _';
                    }

                    return null;
                  },
                ),
                verticalSpaceSmall,
                WgtViewEditField(
                  labelText: 'Fullname',
                  originalValue: _originalFullname ?? '',
                  onFocus: (hasFocus) {
                    setState(() {
                      _currentField = 'fullname';
                    });
                  },
                  hasFocus: _currentField == 'fullname',
                  onSetValue: (newValue) async {
                    List<Map<String, dynamic>> result = await _updateProfile(
                      'fullname',
                      newValue,
                    );
                    Map<String, dynamic> resultMap = result[0];
                    if (resultMap['error'] == null) {
                      setState(() {
                        _originalFullname = newValue;
                        loggedInUser!.fullName = newValue;
                      });
                    }
                    return resultMap;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter fullname';
                    }
                    return validateFullName(value);
                  },
                  width: _width,
                  textStyle: null,
                ),
                verticalSpaceSmall,
                WgtViewEditField(
                  labelText: 'Email',
                  editable: loggedInUser!.authProvider == AuthProvider.local,
                  originalValue: _originalEmail ?? '',
                  width: _width,
                  textStyle: null,
                  suffixes: _emailSuffixes,
                  hasFocus: _currentField == 'email',
                  onFocus: (hasFocus) {
                    setState(() {
                      _currentField = 'email';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    return validateEmail(value);
                  },
                  onSetValue: (newValue) async {
                    // List<Map<String, dynamic>> result = await _updateProfile(
                    //   'email',
                    //   newValue,
                    // );
                    // Map<String, dynamic> resultMap = result[0];
                    // if (resultMap['error'] == null) {
                    //   setState(() {
                    //     _originalEmail = newValue;
                    //     loggedInUser!.email = newValue;
                    //     loggedInUser!.emailVerified = false;
                    //   });
                    // }
                    Map<String, dynamic> resultMap = await doUpdateUserKeyValue(
                      widget.appConfig,
                      loggedInUser!,
                      {
                        'id': loggedInUser!.id!.toString(),
                        'key': 'email',
                        'value': newValue,
                        'send_verification_email': 'true',
                      },
                      MdlPagSvcClaim(
                        userId: loggedInUser!.id,
                        username: loggedInUser!.username,
                        scope: '',
                        target: '',
                        operation: '',
                      ),
                    );

                    if (resultMap['error'] == null) {
                      setState(() {
                        _originalEmail = newValue;
                        loggedInUser!.email = newValue;
                        loggedInUser!.emailVerified = false;
                      });
                    }

                    resultMap['message'] =
                        'Change committed. Verification email sent';
                    return resultMap;
                  },
                ),
                verticalSpaceSmall,
                WgtViewEditField(
                  labelText: 'Contact Number',
                  hintText: 'Contact Number',
                  originalValue: _originalContactNumber ?? '',
                  onFocus: (hasFocus) {
                    setState(() {
                      _currentField = 'contact_number';
                    });
                  },
                  hasFocus: _currentField == 'contact_number',
                  onSetValue: (newValue) async {
                    List<Map<String, dynamic>> result = await _updateProfile(
                      'contact_number',
                      newValue,
                    );
                    Map<String, dynamic> resultMap = result[0];
                    if (resultMap['error'] == null) {
                      setState(() {
                        _originalContactNumber = newValue;
                        loggedInUser!.phone = newValue;
                      });
                    }
                    return resultMap;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter contact number';
                    }
                    return validatePhone(value);
                  },
                  width: _width,
                  textStyle: null,
                ),
                verticalSpaceMedium,
                if (loggedInUser!.authProvider == AuthProvider.local)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Change Password',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ),
                      verticalSpaceSmall,
                      Container(
                        height: 330,
                        padding: const EdgeInsets.only(right: 40),
                        child: WgtPagUpdatePassword(
                          appConfig: widget.appConfig,
                          width: _width,
                          padding: EdgeInsets.zero,
                          showUsername: false,
                          showBorder: false,
                          sideExpanded: false,
                          loggedInUser: loggedInUser!,
                          changeTargetUserId: loggedInUser!.id!,
                          // requestByUsername:loggedInUser!.username!,
                          // userId:loggedInUser!.id!,
                          updatePassword: doUpdateUserKeyValue,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
