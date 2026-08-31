import 'package:buff_helper/pag_helper/comm/comm_user_service.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PgForgotPassword extends StatefulWidget {
  const PgForgotPassword({
    super.key,
    this.appConfig,
    this.supportEmail = '',
  });

  final MdlPagAppConfig? appConfig;
  final String supportEmail;

  @override
  State<PgForgotPassword> createState() => _PgForgotPasswordState();
}

class _PgForgotPasswordState extends State<PgForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;
  String _errorText = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    final String? validationError = validateEmail(email);
    if (validationError != null) {
      setState(() {
        _errorText = validationError;
      });
      return;
    }
    if (widget.appConfig == null) {
      setState(() {
        _errorText = 'Password reset is not available';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = '';
    });
    try {
      final String resetUrl = Uri.base.resolve('/reset_password').toString();
      await doRequestPasswordReset(widget.appConfig!, email, resetUrl);
      if (!mounted) return;
      setState(() {
        _submitted = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).hintColor,
                ),
              ),
              verticalSpaceSmall,
              if (!_submitted && widget.appConfig != null) ...[
                const Text(
                  'Enter the email address for your local account. We will send you a link to reset your password.',
                  textAlign: TextAlign.center,
                ),
                verticalSpaceRegular,
                TextField(
                  controller: _emailController,
                  enabled: !_submitting,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_submitting) {
                      _submit();
                    }
                  },
                  onChanged: (_) {
                    if (_errorText.isNotEmpty) {
                      setState(() => _errorText = '');
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    errorText: _errorText.isEmpty ? null : _errorText,
                  ),
                ),
                verticalSpaceRegular,
                WgtCommButton(
                  label: 'Send reset link',
                  enabled: !_submitting,
                  inComm: _submitting,
                  onPressed: _submit,
                ),
              ] else if (_submitted) ...[
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                verticalSpaceSmall,
                const Text(
                  'If the address belongs to a local account, a password reset link has been sent. Please check your inbox and spam folder.',
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text(
                  widget.supportEmail.isEmpty
                      ? 'Please contact your administrator for assistance.'
                      : 'Please email ${widget.supportEmail} for assistance.',
                  textAlign: TextAlign.center,
                ),
              ],
              verticalSpaceMedium,
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
