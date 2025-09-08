import 'dart:developer' as dev;
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_error_text_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/input/wgt_text_field2.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';
import 'package:flutter/material.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';

import '../../comm/comm_user_service.dart';

class WgtOpResetPassword extends StatefulWidget {
  const WgtOpResetPassword({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.targetUserIndexStr,
    required this.targetUsername,
    required this.targetUserAuthProvider,
    // required this.height,
    this.onPasswordReset,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final String targetUserIndexStr;
  final String targetUsername;
  final String targetUserAuthProvider;
  // final double height;
  final Function? onPasswordReset;

  @override
  State<WgtOpResetPassword> createState() => _WgtOpResetPasswordState();
}

class _WgtOpResetPasswordState extends State<WgtOpResetPassword> {
  String _errorText = '';
  String _resultText = '';
  String? _validateResult;
  bool _isValidated = false;
  bool _isResetting = false;
  bool _isReset = false;

  String _iniPassword = '';

  Future<void> _opResetTargetUserPassword() async {
    if (_isResetting || _isReset) return;
    _isResetting = true;
    _resultText = '';
    _errorText = '';

    Map<String, dynamic> queryMap = {
      'target_user_index': widget.targetUserIndexStr,
      'target_username': widget.targetUsername,
      'initial_password': _iniPassword,
    };

    try {
      final result = await doResetUserPassword(
          widget.appConfig,
          queryMap,
          MdlPagSvcClaim(
            userId: widget.loggedInUser.id,
            username: widget.loggedInUser.username,
            scope: '',
            target: '',
            operation: '',
          ));
      if ((result['message'] ?? '').contains(' successfully')) {
        _resultText = 'Password reset successfully';
        widget.onPasswordReset?.call();
      }
    } catch (e) {
      _errorText = 'Failed to reset password';
      dev.log('Error resetting user password: $e');
    } finally {
      _isResetting = false;
      _isReset = true;
      setState(() {});
    }
  }

  String? validateIniPassword(String value) {
    // minimum 3 char
    if (value.length < 3) {
      return 'Initial password must be at least 3 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.targetUsername.isEmpty) {
      return Container();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      width: 395,
      // height: 135,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reset Password for '),
              Text(
                widget.targetUsername,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            ],
          ),
          verticalSpaceTiny,
          WgtTextField(
            appConfig: widget.appConfig,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
              labelText: 'Initial Password',
              labelStyle: TextStyle(color: Theme.of(context).hintColor),
              border: const OutlineInputBorder(
                borderSide: BorderSide(),
              ),
              errorText: _validateResult,
              errorStyle: const TextStyle(fontSize: 13),
            ),
            validator: validateIniPassword,
            onChanged: (value) {
              setState(() {
                _iniPassword = value;
              });
            },
            onValidate: (String? result) {
              setState(() {
                if (result == null) {
                  _isValidated = true;
                  _validateResult = null;
                } else {
                  _isValidated = false;
                  _validateResult = result;
                }
              });
            },
          ),
          verticalSpaceSmall,
          if (widget.targetUserAuthProvider != 'local')
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  'Password reset not supported for auth provider: ${widget.targetUserAuthProvider}'),
            ),
          if (widget.targetUserAuthProvider == 'local')
            WgtCommButton(
              enabled: !_isResetting && !_isReset && _isValidated,
              label: 'Reset Password',
              onPressed: () async {
                await _opResetTargetUserPassword();
              },
            ),
          verticalSpaceTiny,
          if (_resultText.isNotEmpty)
            Text(
              _resultText,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          if (_errorText.isNotEmpty)
            getErrorTextPrompt(context: context, errorText: _errorText),
        ],
      ),
    );
  }
}
