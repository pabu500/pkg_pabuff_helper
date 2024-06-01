import 'package:buff_helper/pagrid_helper/pagrid_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  ForgotPassword({super.key, required this.activePortalProjectScope});

  final ProjectScope activePortalProjectScope;

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  GlobalKey _keyMainButton = GlobalKey();
  String? _errorText;
  bool _wait = false;
  bool _email_sent_success = false;

  xt_util_FormCorrdinator formCoordinator = xt_util_FormCorrdinator();

  double _width = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Center(
        child: SizedBox(
          width: screenWidthPercentage(context, percentage: 0.7, max: _width),
          child: AuthenticationLayout(
            title: 'Forgot your password?',
            subtitle:
                'Enter the email address accosiated with your account. We will send you an email with a link to reset your password.',
            // mainButtonTitle: 'Continue',
            form: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: [
                  xtTextField(
                    activePortalProjectScope: widget.activePortalProjectScope,
                    tfKey: UserKey.email,
                    maxLength: maxEmailLength,
                    formCoordinator: formCoordinator,
                    decoration: xtBuildInputDecoration(
                      prefixIcon: const Icon(Icons.email),
                      hintText: 'Email',
                      // keyboardType: TextInputType.emailAddress,
                    ),
                    doValidate: validateEmail,
                  ),
                  verticalSpaceRegular,
                  xtButton(
                    key: _keyMainButton,
                    xtKey: btnKey.mainbutton,
                    formCoordinator: formCoordinator,
                    text: 'Continue',
                    onPressed: () async {
                      // bool stage = false;
                      if (!formCoordinator.precheckAll()) {
                        return;
                      }

                      Function? updateMainBtnError =
                          formCoordinator.fieldUpdateErrors[btnKey.mainbutton];
                      setState(() {
                        _errorText = null;
                        if (updateMainBtnError != null) {
                          updateMainBtnError(_errorText);
                        }
                      });

                      formCoordinator.toggleDisabledAll(true);

                      formCoordinator.saveAll();

                      Function? toggleWait =
                          formCoordinator.toggleWait[btnKey.mainbutton];

                      setState(() {
                        _wait = true;
                      });
                      if (toggleWait != null) {
                        toggleWait(_wait);
                      }

                      bool? emailExists;
                      try {
                        emailExists = await doCheckExists(
                            widget.activePortalProjectScope,
                            UserKey.email,
                            formCoordinator.formData[UserKey.email]!);
                      } catch (err) {
                        setState(() {
                          _wait = false;
                          _errorText = _errorText = errorFilter(
                              err.toString(), comm_tasks.forgotPassword);
                        });
                        if (toggleWait != null) {
                          toggleWait(_wait);
                        }
                        formCoordinator.toggleDisabledAll(false);
                        if (updateMainBtnError != null) {
                          updateMainBtnError(_errorText);
                        }
                        return;
                      }

                      setState(() {
                        _wait = false;
                      });
                      if (toggleWait != null) {
                        toggleWait(_wait);
                      }
                      if (emailExists == null) {
                        setState(() {
                          _errorText = 'Service Error';
                        });
                        formCoordinator.toggleDisabledAll(false);
                        if (updateMainBtnError != null) {
                          updateMainBtnError(_errorText);
                        }
                        return;
                      }

                      if (!emailExists) {
                        setState(() {
                          _errorText = 'Email not found';
                        });
                        formCoordinator.toggleDisabledAll(false);
                        if (updateMainBtnError != null) {
                          updateMainBtnError(_errorText);
                        }
                        return;
                      }

                      setState(() {
                        _errorText = null;
                        _wait = true;
                      });
                      if (toggleWait != null) {
                        toggleWait(_wait);
                      }
                      // formCoordinator.toggleDisabledAll(false);
                      bool? email_sent_success;
                      email_sent_success = await doForgotPassword(
                              widget.activePortalProjectScope,
                              formCoordinator.formData)
                          .catchError((err) {
                        setState(() {
                          _wait = false;
                          _errorText = err.toString();
                          if (_errorText != null) {
                            _errorText =
                                _errorText!.replaceAll('Exception: ', '');
                          }
                        });
                        if (toggleWait != null) {
                          toggleWait(_wait);
                        }
                        if (updateMainBtnError != null) {
                          updateMainBtnError(_errorText);
                        }
                        return Future(() => false);
                      });

                      setState(() {
                        _wait = false;
                      });
                      if (toggleWait != null) {
                        toggleWait(_wait);
                      }
                      if (_email_sent_success == null) {
                        setState(() {
                          _errorText = 'Service Error';
                        });
                        formCoordinator.toggleDisabledAll(false);
                        if (updateMainBtnError != null) {
                          updateMainBtnError(_errorText);
                        }
                        return;
                      } else {
                        setState(() {
                          _email_sent_success = email_sent_success!;
                        });
                      }
                    },
                  ),
                  // if (_email_sent_success && _errorText == null)
                  const Padding(padding: EdgeInsets.only(top: 13)),
                  xtInfoBox(
                    width: screenWidthPercentage(context,
                        percentage: 0.7, max: 0.75 * _width),
                    boarderColor: xtLightGreen2,
                    text:
                        'An email has been sent to ${formCoordinator.formData[UserKey.email] ?? 'you'} with a link to reset your password.',
                    textColor: Colors.white,
                    icon: const Icon(
                      Icons.check_circle,
                      color: xtLightGreen2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
