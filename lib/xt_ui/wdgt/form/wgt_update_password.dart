import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import '../list/get_commit_button.dart';

// import 'comm_user_service.dart';

class WgtUpdatePassword extends StatefulWidget {
  const WgtUpdatePassword({
    super.key,
    required this.requestByUsername,
    required this.userId,
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

  final Widget? titleWidget;
  final String requestByUsername;
  final int userId;
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
  _WgtUpdatePasswordState createState() => _WgtUpdatePasswordState();
}

class _WgtUpdatePasswordState extends State<WgtUpdatePassword> {
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

  final Color _okToSubmitColor = Colors.amber.shade900.withOpacity(0.95);

  Future<dynamic> _updatePassword() async {
    setState(() {
      _updatingPassword = true;
      _errorText = '';
    });
    try {
      Map<String, dynamic> result = await widget.updatePassword(
        widget.userId,
        'password',
        _controllerNewPassword.text.trim(),
        checkOldPassword: widget.requireOldPassword ? 'true' : 'false',
        oldVal: _controllerOldPassword.text.trim(),
        SvcClaim(
          username: widget.requestByUsername,
          scope: widget.aclScopeStr,
          target: getAclTargetStr(AclTarget.evs2user_p_profile),
          operation: AclOperation.update.name,
        ),
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
    return Column(
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.titleWidget ?? Container(),
                widget.showUsername
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 5),
                        child: Text(
                          widget.requestByUsername,
                          style: TextStyle(
                              fontSize: 18,
                              color:
                                  Theme.of(context).hintColor.withOpacity(0.8)),
                        ),
                      )
                    : Container(),
                widget.requireOldPassword
                    ? TextField(
                        controller: _controllerOldPassword,
                        obscureText: true,
                        decoration: InputDecoration(
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
                          labelText: 'Old Password',
                          hintText: 'Old Password',
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
                    labelText: 'New Password',
                    hintText: 'New Password',
                    hintStyle: TextStyle(
                      color: _errorTextNewPassword.isEmpty
                          ? Theme.of(context).hintColor
                          : _okToSubmitColor,
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
                    labelText: 'Confirm Password',
                    hintText: 'Confirm Password',
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
                      getCommitButton(() async {
                        Map<String, dynamic> result = await _updatePassword();
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
                        // return result;
                      }, text: 'Update Password'),
                      // TextButton(
                      //   onPressed: () async {
                      //     Map<String, dynamic> result = await _updatePassword();
                      //     if (result['error'] == null) {
                      //       setState(() {
                      //         _passwordUpdated = true;
                      //         _controllerOldPassword.clear();
                      //         _controllerNewPassword.clear();
                      //         _controllerConfirmPassword.clear();
                      //         _errorTextOldPassword = '';
                      //         _errorTextNewPassword = '';
                      //         _errorTextConfirmPassword = '';
                      //         _showUpdatePasswordButton =
                      //             showUpdatePasswordButton();
                      //       });
                      //     } else {
                      //       setState(() {
                      //         _errorTextOldPassword = result['error'];
                      //       });
                      //     }
                      //     // return result;
                      //   },
                      //   child: Text(
                      //     'Update Password',
                      //     style: TextStyle(
                      //       fontWeight: FontWeight.w500,
                      //       color: commitColor,
                      //     ),
                      //   ),
                      // ),
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
