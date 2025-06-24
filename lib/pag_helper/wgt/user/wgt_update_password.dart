import 'dart:async';

import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../model/acl/mdl_pag_svc_claim.dart';
import '../../model/provider/pag_data_provider.dart';
import '../../model/provider/pag_user_provider.dart';
import '../../comm/comm_sso.dart';
import 'package:provider/provider.dart';

class WgtPagUpdatePassword extends StatefulWidget {
  const WgtPagUpdatePassword({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.changeTargetUserId,
    this.titleWidget,
    this.showUsername = true,
    this.showBorder = true,
    this.requireOldPassword = true,
    this.passwordLengthMin = 6,
    this.width = 320,
    this.aclScopeStr = 'self',
    this.sideExpanded = true,
    this.padding,
    required this.updatePassword,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final int changeTargetUserId;
  final Widget? titleWidget;
  final bool showUsername;
  final bool showBorder;
  final bool requireOldPassword;
  final int passwordLengthMin;
  final String aclScopeStr;
  final double width;
  final bool sideExpanded;
  final EdgeInsetsGeometry? padding;
  final Function updatePassword;

  @override
  State<WgtPagUpdatePassword> createState() => _WgtPagUpdatePasswordState();
}

class _WgtPagUpdatePasswordState extends State<WgtPagUpdatePassword> {
  late final TextStyle inputLabelStyle =
      TextStyle(color: Theme.of(context).hintColor.withAlpha(130));
  // String? _newPassword;
  late double _width;
  final double _height = 180;

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
  String _errorText = '';

  final Color _okToSubmitColor = Colors.amber.shade900.withAlpha(235);

  Future<dynamic> _updatePassword() async {
    setState(() {
      _updatingPassword = true;
      _errorText = '';
    });

    Map<String, dynamic> queryMap = {
      'id': widget.changeTargetUserId.toString(),
      'key': 'password',
      'value': _controllerNewPassword.text.trim(),
      'check_old_password': widget.requireOldPassword ? 'true' : 'false',
      'old_value': _controllerOldPassword.text.trim(),
    };
    try {
      dynamic data = await widget.updatePassword(
        widget.appConfig,
        null,
        queryMap,
        MdlPagSvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      if (data == null) {
        throw Exception('Failed to update password');
      }
      return data;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      //return a Map
      Map<String, dynamic> result = {};
      result['error'] = explainException(e);

      if (result['error'].isEmpty) {
        String error = e.toString();
        if (error.toLowerCase().contains('old password is incorrect')) {
          result['error'] = 'Old password is incorrect';
        }
      }
      if (result['error'].isEmpty) {
        result['error'] = 'Failed to update password';
      }

      return result;
    } finally {
      setState(() {
        _updatingPassword = false;
      });
    }
  }

  bool showUpdatePasswordButton() {
    if (_controllerNewPassword.text.isEmpty) {
      return false;
    }
    if (_controllerConfirmPassword.text.isEmpty) {
      return false;
    }
    if (_controllerNewPassword.text != _controllerConfirmPassword.text) {
      return false;
    }
    if (_controllerNewPassword.text.isEmpty ||
        _controllerConfirmPassword.text.isEmpty) {
      return false;
    }
    if (widget.requireOldPassword) {
      if (_controllerOldPassword.text.isEmpty) {
        return false;
      }
      // if (_controllerNewPassword.text != _controllerOldPassword.text) {
      //   return false;
      // }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();

    _width = widget.width;
  }

  @override
  Widget build(BuildContext context) {
    // _height = widget.requireOldPassword ? 255 : 225;
    // if (_showUpdatePasswordButton) {
    //   _height += 20;
    // }
    if (widget.loggedInUser.isEmpty) {
      Timer(const Duration(milliseconds: 100), () {
        context.go('/login');
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          // height: _height,
          width: _width + 20,
          decoration: widget.showBorder
              ? BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).hintColor, width: 1),
                  borderRadius: BorderRadius.circular(5))
              : null,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 13),
          child: SizedBox(
            width: _width,
            // height: _height,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.titleWidget ?? Container(),
                if (widget.showUsername)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 5),
                    child: Text(
                      widget.loggedInUser.username ?? '',
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).hintColor.withAlpha(200)),
                    ),
                  ),
                widget.requireOldPassword
                    ? TextField(
                        controller: _controllerOldPassword,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Old Password',
                          hintText: 'Old Password',
                          labelStyle: inputLabelStyle,
                          hintStyle: TextStyle(
                            color: _errorTextOldPassword.isEmpty
                                ? Theme.of(context).hintColor
                                : _okToSubmitColor,
                          ),
                          // focusColor: Colors.red,
                          isDense: true,
                          // contentPadding: _padding,
                          // border: const OutlineInputBorder(
                          //   borderSide: BorderSide(
                          //     width: 1,
                          //   ),
                          //   borderRadius: BorderRadius.all(
                          //     Radius.circular(5),
                          //   ),
                          // ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).hintColor,
                              width: 0.5,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(5),
                            ),
                          ),
                          errorText: _errorTextOldPassword.isEmpty
                              ? null
                              : _errorTextOldPassword,
                          errorStyle: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _passwordUpdated = false;
                            _errorTextOldPassword = '';
                            _showUpdatePasswordButton =
                                showUpdatePasswordButton();
                          });
                        },
                      )
                    : Container(),
                verticalSpaceSmall,
                TextField(
                  controller: _controllerNewPassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    isDense: true,
                    // contentPadding: _padding,
                    labelText: 'New Password',
                    hintText: 'New Password',
                    hintStyle: TextStyle(
                      color: _errorTextNewPassword.isEmpty
                          ? Theme.of(context).hintColor
                          : _okToSubmitColor,
                    ),
                    labelStyle: inputLabelStyle,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).hintColor,
                        width: 0.5,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(5),
                      ),
                    ),

                    errorText: _errorTextNewPassword.isEmpty
                        ? null
                        : _errorTextNewPassword,
                    errorStyle: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _passwordUpdated = false;
                      _errorTextNewPassword = '';
                      _showUpdatePasswordButton = showUpdatePasswordButton();
                    });
                    if (value.length < widget.passwordLengthMin ||
                        value.length > 21) {
                      setState(() {
                        _errorTextNewPassword =
                            'Password must be between 6 and 21 characters';
                      });
                    }
                    //can't be all same
                    if (value.replaceAll(value[0], '').isEmpty) {
                      setState(() {
                        _errorTextNewPassword =
                            'Password cannot be all same characters';
                      });
                    }
                    if (value == _controllerOldPassword.text) {
                      setState(() {
                        _errorTextNewPassword =
                            'New password cannot be the same as old password';
                      });
                    }
                  },
                  // onSubmitted: (value) {
                  //   print('onSubmitted');
                  // },
                ),
                verticalSpaceSmall,
                TextField(
                  controller: _controllerConfirmPassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    // contentPadding: _padding,
                    isDense: true,
                    labelText: 'Confirm Password',
                    hintText: 'Confirm Password',
                    hintStyle: TextStyle(
                      color: _errorTextConfirmPassword.isEmpty
                          ? Theme.of(context).hintColor
                          : _okToSubmitColor,
                    ),
                    labelStyle: inputLabelStyle,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).hintColor,
                        width: 0.5,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(5),
                      ),
                    ),

                    errorText: _errorTextConfirmPassword.isEmpty
                        ? null
                        : _errorTextConfirmPassword,
                    errorStyle: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                  onChanged: (newValue) {
                    setState(() {
                      _passwordUpdated = false;
                      _errorTextConfirmPassword = '';
                      _showUpdatePasswordButton = showUpdatePasswordButton();
                      if (kDebugMode) {
                        print(_showUpdatePasswordButton);
                      }
                    });
                  },
                ),
                _passwordUpdated
                    ? Row(
                        children: [
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              'Change committed',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(),
                verticalSpaceSmall,
                if (_showUpdatePasswordButton)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _passwordUpdated = false;
                            _controllerOldPassword.clear();
                            _controllerNewPassword.clear();
                            _controllerConfirmPassword.clear();
                            _errorTextOldPassword = '';
                            _errorTextNewPassword = '';
                            _errorTextConfirmPassword = '';
                            _showUpdatePasswordButton =
                                showUpdatePasswordButton();
                          });
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ),
                      horizontalSpaceSmall,
                      WgtCommButton(
                        label: 'Update Password',
                        onPressed: () async {
                          dynamic result = await _updatePassword();
                          if (result['error'] == null) {
                            setState(() {
                              _passwordUpdated = true;
                              _controllerOldPassword.clear();
                              _controllerNewPassword.clear();
                              _controllerConfirmPassword.clear();
                              _errorTextOldPassword = '';
                              _errorTextNewPassword = '';
                              _errorTextConfirmPassword = '';
                              _showUpdatePasswordButton =
                                  showUpdatePasswordButton();
                            });
                          } else {
                            setState(() {
                              _errorTextOldPassword = result['error'];
                            });
                          }

                          await Future.delayed(
                              const Duration(milliseconds: 500));
                          // logout
                          secStorage.deleteAll();

                          Timer(const Duration(milliseconds: 100), () {
                            Provider.of<PagDataProvider>(context, listen: false)
                                .clearData();

                            MdlPagUser? user = Provider.of<PagUserProvider>(
                                    context,
                                    listen: false)
                                .currentUser;
                            user?.logout();
                            pagLogoutSso(context);
                            context.go('/login');
                          });
                        },
                      ),
                    ],
                  ),
                verticalSpaceSmall,
              ],
            ),
          ),
        ),
        Expanded(child: Container()),
      ],
    );
  }
}
