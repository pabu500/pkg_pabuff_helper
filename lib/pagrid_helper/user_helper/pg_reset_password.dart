import 'dart:async';

import 'package:buff_helper/pag_helper/comm/comm_user_service.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/wgt/user/wgt_update_password.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PgResetPassword extends StatefulWidget {
  const PgResetPassword({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    this.token,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser? loggedInUser;
  final String? token;

  @override
  State<PgResetPassword> createState() => _PgResetPasswordState();
}

class _PgResetPasswordState extends State<PgResetPassword> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _submitting = false;
  bool _passwordReset = false;
  String _errorText = '';

  final double _width = 360;

  bool get _isEmailReset => widget.token?.isNotEmpty ?? false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetForgottenPassword() async {
    final String password = _newPasswordController.text;
    final String confirmPassword = _confirmPasswordController.text;
    String? error;
    if (password.length < 6 || password.length > 21) {
      error = 'Password must be between 6 and 21 characters';
    } else if (password
        .split('')
        .every((character) => character == password[0])) {
      error = 'Password cannot use the same character throughout';
    } else if (password != confirmPassword) {
      error = 'Passwords do not match';
    }
    if (error != null) {
      setState(() => _errorText = error!);
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = '';
    });
    try {
      await doResetForgottenPassword(
        widget.appConfig,
        widget.token!,
        password,
      );
      if (!mounted) return;
      setState(() {
        _passwordReset = true;
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } catch (resetError) {
      if (!mounted) return;
      setState(() {
        _errorText = resetError.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEmailReset) {
      return _buildEmailReset(context);
    }
    return _buildLoggedInReset(context);
  }

  Widget _buildEmailReset(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 34),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
              ),
              verticalSpaceRegular,
              if (!_passwordReset) ...[
                TextField(
                  controller: _newPasswordController,
                  enabled: !_submitting,
                  autofocus: true,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_errorText.isNotEmpty) {
                      setState(() => _errorText = '');
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    border: OutlineInputBorder(),
                  ),
                ),
                verticalSpaceSmall,
                TextField(
                  controller: _confirmPasswordController,
                  enabled: !_submitting,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_submitting) {
                      _resetForgottenPassword();
                    }
                  },
                  onChanged: (_) {
                    if (_errorText.isNotEmpty) {
                      setState(() => _errorText = '');
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    border: const OutlineInputBorder(),
                    errorText: _errorText.isEmpty ? null : _errorText,
                  ),
                ),
                verticalSpaceRegular,
                WgtCommButton(
                  label: 'Reset password',
                  enabled: !_submitting,
                  inComm: _submitting,
                  onPressed: _resetForgottenPassword,
                ),
              ] else ...[
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                verticalSpaceSmall,
                const Text(
                  'Your password has been reset. You can now log in with your new password.',
                  textAlign: TextAlign.center,
                ),
              ],
              verticalSpaceMedium,
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(_passwordReset ? 'Go to login' : 'Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInReset(BuildContext context) {
    final MdlPagUser? loggedInUser = widget.loggedInUser;
    if (loggedInUser == null) {
      Timer(const Duration(milliseconds: 100), () {
        if (mounted) {
          context.go('/login');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(vertical: 21, horizontal: 34),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
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
                  loggedInUser: loggedInUser,
                  changeTargetUserId: loggedInUser.id!,
                  updatePassword: doUpdateUserKeyValue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
