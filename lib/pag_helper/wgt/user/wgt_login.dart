import 'dart:async';

import 'dart:developer' as dev;
import 'package:buff_helper/pag_helper/comm/comm_user_service.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:go_router/go_router.dart';
import '../../wgt/wgt_comm_button.dart';

class WgtLogin extends StatefulWidget {
  const WgtLogin({
    super.key,
    required this.appConfig,
    this.onLoggedIn,
    // required this.onPostLogin,
    // this.postLoginThen,
  });

  final MdlPagAppConfig appConfig;
  final Function(MdlPagUser loggedInUser)? onLoggedIn;
  // final Function(MdlPagUser loggedInUser) onPostLogin;
  // final Function(MdlPagUser)? postLoginThen;

  @override
  State<WgtLogin> createState() => _WgtLoginState();
}

class _WgtLoginState extends State<WgtLogin> {
  String _username = '';
  String _password = '';
  bool _savePassword = true;

  final String keyLocalAuthEnabled = "keyLocalAuthEnabled";

  bool _isLoggingIn = false;
  bool _isSigningInWithMicrosoft = false;
  bool _hasLoggedIn = false;
  bool _failedLogin = false;
  String _errorTextLocal = '';
  String _errorTextSso = '';

  bool showMicrosoftButton = true;

  Future<MdlPagUser?> _login({
    String authProvider = 'local',
    String email = '',
    String? firebaseIdToken,
    String? microsoftIdToken,
  }) async {
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
          PagUserKey.username.name: authProvider == 'local' ? _username : '',
          PagUserKey.password.name: authProvider == 'local' ? _password : '',
          PagUserKey.email.name: email,
          PagUserKey.authProvider.name: authProvider,
          // 'portal_type_name': widget.appConfig.portalType.name,
          // 'portal_type_label': widget.appConfig.portalType.label,
          'portal_type': widget.appConfig.portalType.value,
          if (firebaseIdToken != null) 'firebase_id_token': firebaseIdToken,
          if (microsoftIdToken != null) 'microsoft_id_token': microsoftIdToken,
        }),
      );

      if (user.resetPasswordToken == 'flag_reset') {
        dev.log('Password reset required. Not saving password.');
        _savePassword = false;
      }

      // user.flatReset
      // if (user.resetPasswordToken == 'flag_reset') {
      //   Timer(const Duration(milliseconds: 100), () {
      //     Provider.of<PagUserProvider>(
      //       context,
      //       listen: false,
      //     ).setCurrentUser(user);
      //     context.go('/reset_password');
      //   });
      // }

      // moved to comm_user_service.dart
      // if (!user.hasScopeForPagProject(activePortalPagProjectScopeList)) {
      //   setState(() {
      //     _errorTextLocal = 'no access to this project portal';
      //   });
      //   // return null;
      //   throw Exception('no access to this project portal');
      // }

      if (_savePassword && authProvider == 'local') {
        _saveToStorage();
      }

      return user;
    } catch (e) {
      if (!mounted) return null;
      if (kDebugMode) {
        print(e);
      }
      String message = e.toString();
      String errorText = authProvider == 'microsoft'
          ? 'Microsoft sign-in failed. Please try again.'
          : 'login error';
      if (message.toLowerCase().contains('auth provider mismatch')) {
        errorText = 'auth provider mismatch';
      }
      if (message.toLowerCase().contains('bad credentials')) {
        errorText = 'invalid username or password';
      } else if (message.toLowerCase().contains('xmlhttprequest error')) {
        errorText = 'service connection error';
      } else if (message.toLowerCase().contains('oqg')) {
        errorText = 'service error';
      } else if (message.toLowerCase().contains('failed to get user scope')) {
        errorText = 'failed to get user scope';
      } else if (message.toLowerCase().contains('auth/get_login_token')) {
        errorText = 'auth service error';
      } else if (message.contains('did not return a login token')) {
        errorText = 'Sign-in service did not return a session. Please try again.';
      } else if (message
          .toLowerCase()
          .contains('no access to this project portal')) {
        errorText = 'no access to this project portal';
      }
      setState(() {
        if (authProvider == 'microsoft') {
          _errorTextSso = errorText;
        } else {
          _errorTextLocal = errorText;
        }
        _failedLogin = true;
        _isLoggingIn = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
    return null;
  }

  _saveToStorage() async {
    if (_savePassword) {
      // reset fingerprint auth values. Only for demo purpose
      await secStorage.write(key: keyLocalAuthEnabled, value: "false");

      await secStorage.write(
          key: PagUserKey.identifier.toString(), value: _username);
      await secStorage.write(
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

  // _logginThen(MdlPagUser? user) async {
  //   if (user == null) {
  //     return;
  //   }
  //   try {
  //     await widget.onPostLogin(user).then((value) {
  //       if (mounted) {
  //         widget.postLoginThen?.call(user);
  //         // Provider.of<PagUserProvider>(context, listen: false).iniUser(user);
  //         // Provider.of<PagAppProvider>(context, listen: false)
  //         //     .iniPageRoute(PagPageRoute.consoleHomeDashboard);

  //         // context.go(getRoute(PagPageRoute.splash));
  //       }
  //     });
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('loginThen: $e');
  //     }
  //     setState(() {
  //       _errorTextLocal = 'user scope error';
  //     });
  //   } finally {
  //     setState(() {
  //       _failedLogin = true;
  //       _isLoggingIn = false;
  //     });
  //   }
  // }
  void loginWithMicrosoft(BuildContext context) async {
    if (_isSigningInWithMicrosoft || _isLoggingIn) return;
    setState(() {
      _isSigningInWithMicrosoft = true;
      _errorTextSso = '';
    });
    final auth = FirebaseAuth.instance;
    try {
      final provider = OAuthProvider('microsoft.com');
      provider.setCustomParameters({
        'tenant': '4c4e8b31-4a28-4d6a-ba59-49a718162e33',
      });
      provider.addScope('email');
      final credential = await auth.signInWithPopup(provider);
      final firebaseIdToken = await credential.user?.getIdToken();
      final oauthCredential = credential.credential;
      final microsoftIdToken = oauthCredential is OAuthCredential
          ? oauthCredential.idToken
          : null;
      if (firebaseIdToken == null || microsoftIdToken == null) {
        throw StateError('SSO identity token missing');
      }
      if (!mounted) {
        await auth.signOut();
        return;
      }
      // Identity and email are verified by usersvc2. The email-only preflight
      // cannot authenticate a user and is no longer part of login.
      final user = await _login(
        authProvider: 'microsoft',
        firebaseIdToken: firebaseIdToken,
        microsoftIdToken: microsoftIdToken,
      );
      if (user == null) {
        await auth.signOut();
      } else if (mounted) {
        widget.onLoggedIn?.call(user);
      }
    } catch (_) {
      // Provider exceptions may contain credentials; never print them.
      try {
        await auth.signOut();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _errorTextSso = 'Microsoft sign-in failed. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSigningInWithMicrosoft = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    dev.log('WgtLogin.build()');

    bool enabled = !_isLoggingIn &&
        !_isSigningInWithMicrosoft &&
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
                enabled: !_isLoggingIn &&
                    !_hasLoggedIn /*&& _errorTextLocal != 'Login failed'*/,
                appConfig: widget.appConfig,
                hintText: 'Password',
                obscureText: true,
                showClearButton: false,
                unfocusOnEditingComplete: true,
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
                  if (_isLoggingIn || _hasLoggedIn) {
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

                  dev.log('login:onEditingComplete');

                  // await _login().then((user) {
                  //   // _logginThen(user);
                  //   if (user != null) {
                  //     widget.onLoggedIn?.call(user);
                  //   } else {
                  //     dev.log('login:onEditingComplete failed');
                  //     _errorTextLocal = 'Login failed';
                  //     setState(() {});
                  //   }
                  // });
                  final user = await _login();
                  if (user != null) {
                    widget.onLoggedIn?.call(user);
                  } else {
                    dev.log('login:onEditingComplete failed');
                    _errorTextLocal = 'Login failed';
                    setState(() {});
                  }
                },
                suffix: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 13.5),
                    ),
                  ),
                  onTap: () => context.go('/forgot_password'),
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
                    // _logginThen(user);
                    if (user != null) {
                      widget.onLoggedIn?.call(user);
                    }
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
                  bgColor: Theme.of(context).colorScheme.onPrimary,
                ),
              verticalSpaceSmall,
              if (showMicrosoftButton)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).hintColor.withAlpha(89),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 13),
                  child: SignInButton(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    Buttons.Microsoft,
                    onPressed: () {
                      loginWithMicrosoft(context);
                    },
                  ),
                ),
              if (_errorTextSso.isNotEmpty)
                getErrorTextPrompt(context: context, errorText: _errorTextSso),
              if (showMicrosoftButton) verticalSpaceRegular,
            ],
          ),
        ),
      ],
    );
  }
}
