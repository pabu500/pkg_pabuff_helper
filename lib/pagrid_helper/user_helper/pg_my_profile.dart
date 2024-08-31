import 'package:buff_helper/pagrid_helper/pagrid_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PgMyProfile extends StatefulWidget {
  const PgMyProfile({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.scopeProfile,
  });

  final PaGridAppConfig appConfig;
  final Evs2User loggedInUser;
  final ScopeProfile scopeProfile;

  @override
  _PgMyProfileState createState() => _PgMyProfileState();
}

class _PgMyProfileState extends State<PgMyProfile> {
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
  String _errorTextOldPassword = '';
  String _errorTextNewPassword = '';
  String _errorTextConfirmPassword = '';
  bool _showUpdatePasswordButton = false;
  bool _updatingPassword = false;
  bool _passwordUpdated = false;
  bool _subMonthlyDailyKwhByUnit = true;

  String _currentField = '';

  Future<dynamic> _updateProfile(String key, String value,
      {String? oldVal}) async {
    // if (key == 'username') _usernameErrorText = '';
    // if (key == 'email') _emailErrorText = '';

    try {
      Map<String, dynamic> result = await doUpdateKeyValue(
        widget.appConfig,
        widget.loggedInUser.id!,
        key,
        value,
        SvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: AclScope.self.name,
          target: getAclTargetStr(AclTarget.evs2user_p_profile),
          operation: AclOperation.update.name,
        ),
        checkOldPassword: 'true',
        oldVal: oldVal,
      );

      return result;
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

  Future<dynamic> _checkValue(String key) async {
    try {
      Map<String, dynamic> result = await doCheckKeyVal(
        widget.appConfig,
        widget.loggedInUser.id!,
        key,
        SvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: AclScope.self.name,
          target: getAclTargetStr(AclTarget.evs2user_p_profile),
          operation: AclOperation.read.name,
        ),
      );
      if (result['value'] == 'verified') {
        setState(() {
          widget.loggedInUser.emailVerified = true;
        });
      }
      return result;
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
        _errorTextOldPassword.isEmpty &&
        _errorTextNewPassword.isEmpty &&
        _errorTextConfirmPassword.isEmpty &&
        (_controllerNewPassword.text == _controllerConfirmPassword.text) &&
        (_controllerNewPassword.text != _controllerOldPassword.text);
  }

  @override
  void initState() {
    super.initState();

    _originalUsername = widget.loggedInUser.username;
    _originalEmail = widget.loggedInUser.email;
    _originalFullname = widget.loggedInUser.fullName;
    _originalContactNumber = widget.loggedInUser.phone;
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

    _subMonthlyDailyKwhByUnit = false;
    if ((widget.loggedInUser.hasRole2(AclRole.EVS2_Ops_Site_NTU_MR) ||
        widget.loggedInUser.isFullOpsAndUp())) {
      if (widget.loggedInUser.emailVerified ?? false) {
        _subMonthlyDailyKwhByUnit = true;
      }
    }

    _emailSuffixes = _emailSuffixes = [
      {
        'key': 'verified',
        'widget': Tooltip(
          message: (widget.loggedInUser.emailVerified ?? false)
              ? ''
              : 'Re-send verification email',
          waitDuration: const Duration(milliseconds: 500),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: (widget.loggedInUser.emailVerified ?? false)
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error.withOpacity(0.7)),
            child: Text(
              (widget.loggedInUser.emailVerified ?? false)
                  ? 'Verified'
                  : 'Unverified',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
        'onTap': (widget.loggedInUser.emailVerified ?? false)
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
                Map<String, dynamic> result = await _updateProfile(
                  'email',
                  emailToVerify,
                );
                if (result['error'] == null) {
                  result['message'] = 'Verification email sent';
                  setState(() {
                    _originalEmail = emailToVerify;
                    widget.loggedInUser.email = emailToVerify;
                    widget.loggedInUser.emailVerified = false;
                  });
                  return result;
                }
              },
      },
      {
        'key': 'refresh',
        'widget': Icon(
          Icons.refresh,
          color: Theme.of(context).colorScheme.primary,
          size: 21,
        ),
        'onTap': () async {
          String emailToVerify = _originalEmail ?? '';
          if (emailToVerify.isEmpty) {
            return {'error': 'Email is empty'};
          }
          //validate email
          String? validated = validateEmail(emailToVerify);
          if (validated != null) {
            return {'error': 'Invalid email'};
          }
          //check if email is verified
          Map<String, dynamic> result = await _checkValue('verification_code');
          if (result['error'] == null) {
            return {
              'show_committed': false,
            };
          }
        },
      },
    ];

    if (widget.loggedInUser.emailVerified ?? false) {
      _emailSuffixes.removeWhere((element) => element['key'] == 'refresh');
    } else {
      //remove refresh icon
    }

    return Container(
      width: 360,
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
              labelText: 'Username',
              originalValue: _originalUsername ?? '',
              onFocus: (hasFocus) {
                setState(() {
                  _currentField = 'username';
                });
              },
              hasFocus: _currentField == 'username',
              onSetValue: (newValue) async {
                Map<String, dynamic> result = await _updateProfile(
                  'username',
                  newValue,
                );
                if (result['error'] == null) {
                  setState(() {
                    // _usernameErrorText = '';
                    _originalUsername = newValue;
                    widget.loggedInUser.username = newValue;
                  });
                }
                return result;
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
              width: _width,
              textStyle: null,
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
                Map<String, dynamic> result = await _updateProfile(
                  'fullname',
                  newValue,
                );
                if (result['error'] == null) {
                  setState(() {
                    _originalFullname = newValue;
                    widget.loggedInUser.fullName = newValue;
                  });
                }
                return result;
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
              originalValue: _originalEmail ?? '',
              onFocus: (hasFocus) {
                setState(() {
                  _currentField = 'email';
                });
              },
              hasFocus: _currentField == 'email',
              onSetValue: (newValue) async {
                Map<String, dynamic> result = await _updateProfile(
                  'email',
                  newValue,
                );
                if (result['error'] == null) {
                  setState(() {
                    _originalEmail = newValue;
                    widget.loggedInUser.email = newValue;
                    widget.loggedInUser.emailVerified = false;
                  });
                }
                result['message'] = 'Change committed. Verification email sent';
                return result;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter email';
                }
                return validateEmail(value);
              },
              width: _width,
              textStyle: null,
              suffixes: _emailSuffixes,
            ),
            verticalSpaceSmall,
            WgtViewEditField(
              labelText: 'Contact Number',
              originalValue: _originalContactNumber ?? '',
              onFocus: (hasFocus) {
                setState(() {
                  _currentField = 'contact_number';
                });
              },
              hasFocus: _currentField == 'contact_number',
              onSetValue: (newValue) async {
                Map<String, dynamic> result = await _updateProfile(
                  'contact_number',
                  newValue,
                );
                if (result['error'] == null) {
                  setState(() {
                    _originalContactNumber = newValue;
                    widget.loggedInUser.phone = newValue;
                  });
                }
                return result;
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
            Padding(
              padding: const EdgeInsets.only(left: 5.0),
              child: Text(
                'Change Password',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            verticalSpaceSmall,
            Container(
              height: 330,
              padding: const EdgeInsets.only(right: 40),
              child: WgtUpdatePassword(
                appConfig: widget.appConfig,
                width: _width,
                padding: EdgeInsets.zero,
                showUsername: false,
                showBorder: false,
                sideExpanded: false,
                loggedInUser: widget.loggedInUser,
                changeTargetUserId: widget.loggedInUser.id!,
                // requestByUsername: widget.loggedInUser.username!,
                // userId: widget.loggedInUser.id!,
                updatePassword: doUpdateKeyValue,
              ),
            ),
            if (false)
              Column(
                children: [
                  verticalSpaceMedium,
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Text(
                      'Report Subscription',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                  verticalSpaceSmall,
                  SizedBox(
                    width: 320,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _subMonthlyDailyKwhByUnit,
                              onChanged: (value) {},
                            ),
                            horizontalSpaceSmall,
                            Text(
                              'Monthly Summary on Daily kWh by Unit',
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
