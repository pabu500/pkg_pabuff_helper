import 'dart:async';

import 'package:buff_helper/pag_helper/comm/comm_user_service.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/comm/comm_sso.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  bool _hasLoggedIn = false;
  bool _failedLogin = false;
  String _errorTextLocal = '';
  String _errorTextSso = '';

  bool showMicrosoftButton = true;

  Future<MdlPagUser?> _login({
    String authProvider = 'local',
    String email = '',
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
          PagUserKey.username.name: _username,
          PagUserKey.password.name: _password,
          PagUserKey.email.name: email,
          PagUserKey.authProvider.name: authProvider,
          'portal_type_name': widget.appConfig.portalType.name,
          'portal_type_label': widget.appConfig.portalType.label,
        }),
      );

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

      if (_savePassword) {
        _saveToStorage();
      }

      return user;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      String message = e.toString();
      String errorText = 'login error';
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
      setState(() {
        _isLoggingIn = false;
      });
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
    String? accessToken;

    try {
      Map<String, dynamic> microsoftAuthInfo = {};

      final OAuthProvider authProvider = OAuthProvider('microsoft.com');

      authProvider.setCustomParameters({
        'tenant': '4c4e8b31-4a28-4d6a-ba59-49a718162e33',
      });

      // await Future.delayed(const Duration(seconds: 1));
      if (kDebugMode) {
        print('Microsoft login started');
      }

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(authProvider);

      if (kDebugMode) {
        // print('Microsoft login completed');
      }

      if (userCredential.credential != null) {
        accessToken = userCredential.credential!.accessToken;
        microsoftAuthInfo['accessToken'] = accessToken;
        // print('accessToken: ${userCredential.credential!.accessToken}');
      }

      final String? idToken =
          await FirebaseAuth.instance.currentUser!.getIdToken();

      // print('idToken: $idToken');

      if (idToken == null) {
        if (kDebugMode) {
          print(idToken ?? "No Id token");
        }
        throw Exception('INT:id token not found');
      } else {
        microsoftAuthInfo['credentialUid'] = userCredential.user!.uid;
        // print('credentialUid: ${userCredential.user!.uid}');

        Map<String, dynamic> result = await _validateAccessToken();
        if (result['error'] != null) {
          if (kDebugMode) {
            print('Microsoft login failed: ${result['error']}');
          }
          // setState(() {
          //   _errorTextSso = result['error'] ?? 'Microsoft login failed';
          // });
          throw Exception('INT:${result['error']}');
        } else {
          _login(authProvider: 'microsoft', email: result['email']).then(
            (user) {
              if (user != null) {
                widget.onLoggedIn?.call(user);
              }
            },
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Microsoft login failed: $e');
      }

      // clear login after failed login
      if (accessToken != null) {
        // print('Clearing login');
        FirebaseAuth.instance.signOut();
      }

      String error = e.toString();

      setState(() {
        if (error.contains('Exception: INT:')) {
          _errorTextSso = error.substring(15);
        } else {
          _errorTextSso = 'Microsoft login failed';
        }
      });
    }
  }

  Future<Map<String, dynamic>> _validateAccessToken() async {
    try {
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
      final IdTokenResult tokenResult =
          await firebaseAuth.currentUser!.getIdTokenResult();

      if (tokenResult.token == null) {
        // print('Token is null');
        return {'error': 'SSO token error'};
      } else {
        // UserSession.idToken = tokenResult.token;
        // UserSession.firebaseUid = firebaseAuth.currentUser!.uid;
        String email =
            decodeEmailAddress(FirebaseAuth.instance.currentUser!.email!);
        dynamic data = await pagVerifyEmailAddress(
          null,
          widget.appConfig,
          {
            'email': email,
            'auth_provider': 'microsoft',
          },
        );
        if (data == null) {
          // print('data is null');
          return {'error': 'email verification failed'};
        }
        dynamic verifyResult = data['verify_result'];
        if (verifyResult == null) {
          // print('verify_result is null');
          return {'error': 'failed to obtain verification result'};
        }
        String? isSsoEmailValid = verifyResult['is_sso_email_valid'];
        if (isSsoEmailValid == "true") {
          // print('Email is valid');
          verifyResult['email'] = email;
          return verifyResult;
        }

        return {'error': 'email is not valid'};
      }
    } catch (e) {
      String error = e.toString();
      // Token validation failed
      if (kDebugMode) {
        print('Token validation failed: $e');
      }
      if (error.toLowerCase().contains('auth provider mismatch')) {
        return {'error': 'auth provider mismatch'};
      }
      if (error.toLowerCase().contains('verify sso email address')) {
        return {'error': 'failed to verify sso email address'};
      }
      return {'error': 'token validation failed'};
    }
  }

  String decodeEmailAddress(String rawEmail) {
    List<String> emailList = rawEmail.split('#ext#');
    String email = emailList[0].replaceAll('_', '@');

    return email;
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
                    // _logginThen(user);
                    if (user != null) {
                      widget.onLoggedIn?.call(user);
                    }
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
