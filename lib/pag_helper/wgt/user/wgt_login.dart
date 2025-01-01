import 'package:buff_helper/pag_helper/comm/comm_user_service.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../wgt/wgt_comm_button.dart';

class WgtLogin extends StatefulWidget {
  const WgtLogin({
    super.key,
    required this.appConfig,
    required this.onPostLogin,
    this.postLoginThen,
  });

  final MdlPagAppConfig appConfig;
  final Function(MdlPagUser loggedInUser) onPostLogin;
  final Function(MdlPagUser)? postLoginThen;

  @override
  State<WgtLogin> createState() => _WgtLoginState();
}

class _WgtLoginState extends State<WgtLogin> {
  String _username = '';
  String _password = '';
  bool _savePassword = true;

  final String keyLocalAuthEnabled = "keyLocalAuthEnabled";

  bool _isLoggingIn = false;
  bool _hasLoggedIn = false;
  bool _failedLogin = false;
  String _errorTextLocal = '';
  String _errorTextSso = '';

  Future<MdlPagUser?> _login() async {
    if (_isLoggingIn) {
      return null;
    }
    setState(() {
      _isLoggingIn = true;
      _failedLogin = false;
      _errorTextLocal = '';
    });

    try {
      MdlPagUser user = await doLoginPag(
        widget.appConfig,
        Map.of({
          PagUserKey.username.name: _username,
          PagUserKey.password.name: _password,
          PagUserKey.email.name: '',
          'portal_type_name': widget.appConfig.portalType.name,
          'portal_type_label': widget.appConfig.portalType.label,
        }),
      );

      // moved to comm_user_service.dart
      // if (!user.hasScopeForPagProject(activePortalPagProjectScopeList)) {
      //   setState(() {
      //     _errorTextLocal = 'no access to this project portal';
      //   });
      //   // return null;
      //   throw Exception('no access to this project portal');
      // }

      if (_savePassword) {
        _saveToStorage();
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      String message = e.toString();
      if (message.toLowerCase().contains('bad credentials')) {
        setState(() {
          _errorTextLocal = 'invalid username or password';
        });
      } else if (message.toLowerCase().contains('xmlhttprequest error')) {
        setState(() {
          _errorTextLocal = 'service connection error';
        });
      } else if (message.toLowerCase().contains('oqg')) {
        setState(() {
          _errorTextLocal = 'service error';
        });
      } else if (message.toLowerCase().contains('failed to get user scope')) {
        setState(() {
          _errorTextLocal = 'failed to get user scope';
        });
      } else if (message
          .toLowerCase()
          .contains('no access to this project portal')) {
        setState(() {
          _errorTextLocal = 'no access to this project portal';
        });
      } else {
        setState(() {
          _errorTextLocal = 'login failed';
        });
      }
      setState(() {
        _failedLogin = true;
        _isLoggingIn = false;
      });
    } finally {
      setState(() {
        _isLoggingIn = false;
      });
    }
    return null;
  }

  _saveToStorage() async {
    if (_savePassword) {
      // reset fingerprint auth values. Only for demo purpose
      await storage.write(key: keyLocalAuthEnabled, value: "false");

      await storage.write(
          key: PagUserKey.identifier.toString(), value: _username);
      await storage.write(
          key: PagUserKey.password.toString(), value: _password);

      // check if biometric auth is supported
      // if (await localAuth.canCheckBiometrics) {
      //   // Ask for enable biometric auth
      //   showModalBottomSheet<void>(
      //     context: context,
      //     builder: (BuildContext context) {
      //       return EnableLocalAuthModalBottomSheet(action: _onEnableLocalAuth);
      //     },
      //   );
      // }
    }
  }

  _logginThen(MdlPagUser? user) async {
    if (user == null) {
      return;
    }
    try {
      await widget.onPostLogin(user).then((value) {
        if (mounted) {
          widget.postLoginThen?.call(user);
          // Provider.of<PagUserProvider>(context, listen: false).iniUser(user);
          // Provider.of<PagAppProvider>(context, listen: false)
          //     .iniPageRoute(PagPageRoute.consoleHomeDashboard);

          // context.go(getRoute(PagPageRoute.splash));
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('loginThen: $e');
      }
      setState(() {
        _errorTextLocal = 'user scope error';
      });
    } finally {
      setState(() {
        _failedLogin = true;
        _isLoggingIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('WgtLogin.build()');
    }
    bool enabled = !_isLoggingIn &&
        _username.isNotEmpty &&
        _password.isNotEmpty &&
        _errorTextLocal.isEmpty;
    if (kDebugMode) {
      print('login button enabled: $enabled');
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 355,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              verticalSpaceSmall,
              const Text('Login'),
              verticalSpaceSmall,
              WgtTextField(
                enabled: !_isLoggingIn,
                appConfig: widget.appConfig,
                hintText: 'Username',
                showClearButton: false,
                onChanged: (value) {
                  setState(() {
                    _errorTextLocal = '';
                    _username = value;
                  });
                },
              ),
              WgtTextField(
                enabled: !_isLoggingIn,
                appConfig: widget.appConfig,
                hintText: 'Password',
                obscureText: true,
                showClearButton: false,
                onChanged: (value) {
                  setState(() {
                    _errorTextLocal = '';
                    _password = value;
                  });
                },
                onEditingComplete: () async {
                  // onEditingComplete is called twice.
                  // causing awkward behavior.
                  // This is a workaround
                  if (_hasLoggedIn) {
                    return;
                  }
                  // onEditingComplete is called repeatedly
                  // when failed login, causing awkward behavior.
                  // This is a workaround
                  if (_failedLogin) {
                    return;
                  }
                  if (_username.isEmpty || _password.length < 3) {
                    return;
                  }

                  if (kDebugMode) {
                    print('onEditingComplete');
                  }

                  await _login().then((user) {
                    _logginThen(user);
                  });
                },
                suffix: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: Text(
                      'Forget Password?',
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 13.5),
                    ),
                  ),
                  onTap: () => context.go('/forgot_Password'),
                ),
              ),
              verticalSpaceSmall,
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  const Text('Save Password'),
                  Checkbox(
                    checkColor: Theme.of(context).colorScheme.onSurface,
                    value: _savePassword,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _savePassword = newValue!;
                      });
                    },
                  ),
                ],
              ),
              verticalSpaceRegular,
              WgtCommButton(
                label: 'Login',
                enabled: enabled,
                inComm: _isLoggingIn,
                onPressed: () async {
                  if (kDebugMode) {
                    print('Login button pressed');
                  }
                  await _login().then((user) async {
                    _logginThen(user);
                  });
                },
              ),
              // verticalSpaceTiny,
              if (_errorTextLocal.isNotEmpty)
                getErrorTextPrompt(
                  context: context,
                  errorText: _errorTextLocal,
                  // textColor: Theme.of(context).colorScheme.error,
                  // borderColor: Theme.of(context).colorScheme.error,
                  bgColor:
                      Theme.of(context).colorScheme.onSurface.withAlpha(130),
                ),
              verticalSpaceRegular,
            ],
          ),
        ),
      ],
    );
  }
}
