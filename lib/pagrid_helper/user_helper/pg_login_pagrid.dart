import 'dart:async';
import 'dart:convert';

import 'package:buff_helper/pagrid_helper/pagrid_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

class LoginPagePagrid extends StatefulWidget {
  const LoginPagePagrid({
    super.key,
    required this.destPortal,
    required this.appConfig,
    required this.onAssignUserToProvider,
  });

  final DestPortal destPortal;
  final PaGridAppConfig appConfig;
  final Function onAssignUserToProvider;

  @override
  _LoginPagePagridState createState() => _LoginPagePagridState();
}

class _LoginPagePagridState extends State<LoginPagePagrid> {
  final GlobalKey _keyMainButton = GlobalKey();
  String _errorText = '';
  bool _wait = false;
  bool _savePassword = true;
  // bool _remberMe = false;
  bool _credExpired = false;
  // int _userId = -1;
  Evs2User? _loggedInUser;

  bool _useOpsDashboard = false;

  xt_util_FormCorrdinator formCoordinator = xt_util_FormCorrdinator();

  // Create storage
  final _storage = const FlutterSecureStorage();
  // final String keyUsername = "keyUsername";
  final String keyIdentifier = UserKey.identifier.toString();
  final String keyPassword = UserKey.password.toString();
  final String keyLocalAuthEnabled = "keyLocalAuthEnabled";

  var localAuth = LocalAuthentication();

  final StreamController<Map<Enum, String>> _dataStreamController =
      StreamController<Map<Enum, String>>();

  // Read values
  Future<void> _readFromStorage() async {
    //for testing
    // await Future.delayed(const Duration(milliseconds: 1000));

    String isLocalAuthEnabled =
        await _storage.read(key: keyLocalAuthEnabled) ?? "false";

    if ("true" == isLocalAuthEnabled) {
      bool didAuthenticate = await localAuth.authenticate(
          localizedReason: 'Please authenticate to sign in');

      if (didAuthenticate) {
        // _usernameController.text = await _storage.read(key: keyUsername) ?? '';
        // _passwordController.text = await _storage.read(key: keyPassword) ?? '';
      }
    } else {
      // _usernameController.text = await _storage.read(key: keyUsername) ?? '';
      // _passwordController.text = await _storage.read(key: keyPassword) ?? '';
      formCoordinator.formData[UserKey.identifier] =
          await _storage.read(key: keyIdentifier) ?? '';
      formCoordinator.formData[UserKey.password] =
          await _storage.read(key: keyPassword) ?? '';
    }
    _dataStreamController.add(formCoordinator.formData);
  }

  _saveToStorage(String username) async {
    if (_savePassword) {
      // reset fingerprint auth values. Only for demo purpose
      await _storage.write(key: keyLocalAuthEnabled, value: "false");

      // Write values
      // await _storage.write(key: keyUsername, value: _usernameController.text);
      // await _storage.write(key: keyPassword, value: _passwordController.text);
      await _storage.write(
          key: keyIdentifier,
          value: username); //formCoordinator.formData[userKeys.identifier]);
      await _storage.write(
          key: keyPassword, value: formCoordinator.formData[UserKey.password]);

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

  /// Method associated to UI Button in modalBottomSheet.
  /// It enables local_auth and saves data into storage
  _onEnableLocalAuth() async {
    // Save
    await _storage.write(key: keyLocalAuthEnabled, value: "true");

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          "Fingerprint authentication enabled.\nClose the app and restart it again"),
    ));
  }

  Future<void> _onLogin({String? authProvider, String? email}) async {
    Function? updateMainBtnError =
        formCoordinator.fieldUpdateErrors[btnKey.mainbutton];

    if (authProvider != null && email != null) {
      formCoordinator.formData[UserKey.authProvider] = authProvider;
      formCoordinator.formData[UserKey.email] = email;
    } else {
      formCoordinator.formData[UserKey.authProvider] = 'local';
      if (!formCoordinator.precheckAll()) return;

      setState(() {
        _errorText = '';
        if (updateMainBtnError != null) {
          updateMainBtnError(_errorText);
        }
      });

      String? idtext = formCoordinator.formData[UserKey.identifier];
      //determine if it is username or email
      if (idtext != null) {
        if (validateUsername(idtext) == null) {
          formCoordinator.formData[UserKey.username] = idtext;
          formCoordinator.formData[UserKey.email] = '';
        } else if (validateEmail(idtext) == null) {
          formCoordinator.formData[UserKey.email] = idtext;
          formCoordinator.formData[UserKey.username] = '';
        } else {
          formCoordinator.fieldUpdateErrors[UserKey.identifier]!(
              // 'Invalid username or email'
              'Invalid username');
          return;
        }
      }

      formCoordinator.toggleDisabledAll(true);

      formCoordinator.saveAll();
    }

    Function? toggleWait = formCoordinator.toggleWait[btnKey.mainbutton];
    setState(() {
      _wait = true;
    });
    if (toggleWait != null) {
      toggleWait(_wait);
    }

    Evs2User? user;
    try {
      user = await doLogin(
          widget.destPortal, widget.appConfig, formCoordinator.formData);
      _loggedInUser = user;
    } catch (err) {
      String errMsg = err.toString();
      Map<String, dynamic> errMap =
          jsonDecode(errMsg.replaceFirst('Exception:', '').trim());

      setState(() {
        _wait = false;
        _errorText = errorFilter(errMap['err'].toString(), comm_tasks.login) ??
            'Service Error';
      });
      if (toggleWait != null) {
        toggleWait(_wait);
      }
      formCoordinator.toggleDisabledAll(false);

      if (updateMainBtnError != null) {
        updateMainBtnError(_errorText);
      }
      if (errMap['err'].toString().contains('credentials have expired')) {
        if (kDebugMode) {
          print('creditials have expired');
          setState(() {
            _credExpired = true;
            // _userId = errMap['userId'];
          });
        }
      }
      return;
    } finally {
      if (user != null) {
        if (_savePassword) {
          _saveToStorage(user.username!);
        }

        widget.onAssignUserToProvider(user);
      } else {
        setState(() {
          _errorText ?? 'Service Error';
        });
      }
      setState(() {
        _wait = false;
      });
      if (toggleWait != null) {
        toggleWait(_wait);
      }
    }
  }

  void loginWithMicrosoft(BuildContext context) async {
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
        print('Microsoft login completed');
      }

      if (userCredential.credential != null) {
        microsoftAuthInfo['accessToken'] =
            userCredential.credential!.accessToken;
      }

      final String? idToken =
          await FirebaseAuth.instance.currentUser!.getIdToken();

      if (idToken != null) {
        microsoftAuthInfo['credentialUid'] = userCredential.user!.uid;
        Map<String, dynamic> result = await validateAccessToken();
        if (result['error'] != null) {
          if (kDebugMode) {
            print('Microsoft login failed: ${result['error']}');
          }
        } else {
          _onLogin(authProvider: 'microsoft', email: result['email']);
        }
      } else {
        if (kDebugMode) {
          print(idToken ?? "No Id token");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Microsoft login failed: $e');
      }
      // Handle login failure
    }
  }

  Future<Map<String, dynamic>> validateAccessToken() async {
    try {
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
      final IdTokenResult tokenResult =
          await firebaseAuth.currentUser!.getIdTokenResult();

      if (tokenResult.token != null) {
        // UserSession.idToken = tokenResult.token;
        // UserSession.firebaseUid = firebaseAuth.currentUser!.uid;
        String email =
            decodeEmailAddress(FirebaseAuth.instance.currentUser!.email!);
        Map<String, dynamic> result = await verifyEmailAddress(
            widget.appConfig, {'email': email, 'auth_provider': 'microsoft'});
        if (result['is_sso_email_valid'] == true) {
          result['email'] = email;
          return result;
        }
        if (result['is_sso_email_valid'] != null) {
          setState(() {
            _errorText = 'Email is not valid';
          });
          return {'error': 'Email is not valid'};
        }
      }
      return {'error': 'Token validation failed'};
    } catch (e) {
      // Token validation failed
      if (kDebugMode) {
        print('Token validation failed: $e');
      }
      return {'error': 'Token validation failed'};
    }
  }

  // Future<void> verifyEmailAddress() async {
  //   try {
  //     String email =
  //         decodeEmailAddress(FirebaseAuth.instance.currentUser!.email!);
  //     // Define the URL of your Spring Boot backend
  //     const String url =
  //         'http://localhost:7222/verifyToken'; // Adjust the URL as needed

  //     // Define the headers for the HTTP request
  //     final Map<String, String> headers = {
  //       'Content-Type': 'application/json', // Content type of the request body
  //     };

  //     if (kDebugMode) {
  //       print(email);
  //     }
  //     // Define the body of the HTTP request (in JSON format)
  //     final Map<String, dynamic> body = {
  //       'email': email, // Pass the ID token as a parameter
  //     };

  //     // Send the HTTP POST request to your Spring Boot backend
  //     final http.Response response = await http.post(
  //       Uri.parse(url),
  //       headers: headers,
  //       body: jsonEncode(body), // Encode the body as JSON
  //     );

  //     // Check if the request was successful (status code 200)
  //     if (response.statusCode == 200) {
  //       final jsonResponse = jsonDecode(response.body);

  //       setState(() {
  //         //isLoggedIn = jsonResponse['verified'] as bool;
  //         UserSession.isLoggedIn = jsonResponse['verified'];

  //         html.document.title = 'Sign Out';

  //         if (UserSession.isLoggedIn) {
  //           listenFirebaseUser();
  //           Navigator.pushReplacementNamed(context, '/signout');
  //         }
  //       });
  //     } else {
  //       if (kDebugMode) {
  //         print(
  //             'Failed to send ID token to Spring Boot: ${response.statusCode}');
  //       }
  //       // Handle the error response from the server if needed
  //     }
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error sending ID token to Spring Boot: $e');
  //     }
  //     // Handle any exceptions that occur during the request
  //   }
  // }

  String decodeEmailAddress(String rawEmail) {
    List<String> emailList = rawEmail.split('#ext#');
    String email = emailList[0].replaceAll('_', '@');

    return email;
  }

  @override
  void initState() {
    super.initState();
    _readFromStorage();
  }

  @override
  void dispose() {
    _dataStreamController.close();
    super.dispose();
    // _usernameController.dispose();
    // _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //   final _formKey = new GlobalKey<FormState>();
    //   FormProvider _formProvider = Provider.of<FormProvider>(context);
    // UserProvider _userProvider = Provider.of<UserProvider>(context);

    //will lose all the data in the form when the page is rebuilt
    //better define outside the build method
    //xt_util_FormCorrdinator formCoordinator = xt_util_FormCorrdinator();

    // String? idtext;
    int tabIndex = 0;

    // _readFromStorage();

    return Scaffold(
      appBar: AppBar(
        // automaticallyImplyLeading: false,
        title: Container(),
        // const Align(alignment: Alignment.center, child: Text('Login')),
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: screenWidthPercentage(context, percentage: 0.7, max: 500),
              child: StreamBuilder<Map<Enum, String>>(
                stream: _dataStreamController.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Align(
                      alignment: Alignment.center,
                      child: xtWait(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  } else if (snapshot.data!.length < 2) {
                    return Align(
                      alignment: Alignment.center,
                      child: xtWait(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(top: 13),
                      child: _credExpired && _loggedInUser != null
                          ? WgtUpdatePassword(
                              appConfig: widget
                                  .appConfig, //widget.appConfig, //appConfig,
                              titleWidget: const Column(
                                children: [
                                  xtInfoBox(
                                      text: 'Your password has expired',
                                      iconTextSpace: 3,
                                      icon: Icon(
                                        Icons.info,
                                        color: Colors.orange,
                                      )),
                                  // verticalSpaceTiny,
                                  Text('Please update your password'),
                                  verticalSpaceSmall,
                                ],
                              ),
                              loggedInUser: _loggedInUser!,
                              // requestByUsername:formCoordinator.formData[UserKey.username]!,
                              // userId: _userId,
                              updatePassword: doUpdateKeyValue,
                            )
                          : AuthenticationLayout(
                              title: 'Welcome',
                              subtitle:
                                  // 'Please enter your username or email and password to log in',
                                  'Please enter your username and password to log in',
                              // mainButtonTitle: 'LOG IN',
                              // onMainButtonTapped: Provider.of<User>(context).doLogin,
                              form: FocusTraversalGroup(
                                policy: OrderedTraversalPolicy(),
                                child: Column(
                                  children: [
                                    xtTextField(
                                      appConfig: widget.appConfig,
                                      order: tabIndex++,
                                      tfKey: UserKey.identifier,
                                      maxLength: maxEmailLength,
                                      formCoordinator: formCoordinator,
                                      initialText: formCoordinator
                                          .formData[UserKey.identifier],
                                      decoration: xtBuildInputDecoration(
                                        prefixIcon: const Icon(Icons.person),
                                        // hintText: 'Useranem or Email',
                                        hintText: 'Username',
                                      ),
                                      doValidate: (text) {
                                        if (text.isEmpty) {
                                          // return 'Please enter your username or email';
                                          return 'Please enter your username';
                                        }
                                        return null;
                                      },
                                    ),
                                    // TextField(
                                    xtTextField(
                                      appConfig: widget.appConfig,
                                      order: tabIndex++,
                                      tfKey: UserKey.password,
                                      maxLength: maxPasswordLength,
                                      formCoordinator: formCoordinator,
                                      initialText: formCoordinator
                                          .formData[UserKey.password],
                                      obscureText: true,
                                      decoration: xtBuildInputDecoration(
                                        prefixIcon: const Icon(Icons.password),
                                        hintText: 'Password',
                                      ),
                                      doValidate: (text) {
                                        if (text.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        return null;
                                      },
                                      onEditingComplete: () async {
                                        await _onLogin();
                                      },
                                    ),
                                    verticalSpaceSmall,
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: SizedBox(
                                        width: 169,
                                        height: 34,
                                        child: CheckboxListTile(
                                          value: _savePassword,
                                          onChanged: (bool? newValue) {
                                            setState(() {
                                              _savePassword = newValue!;
                                            });
                                          },
                                          title: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text("Remember me",
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .hintColor,
                                                  ))),
                                          activeColor:
                                              Theme.of(context).hintColor,
                                          contentPadding:
                                              const EdgeInsets.all(0),
                                        ),
                                      ),
                                    ),
                                    verticalSpaceRegular,
                                    xtButton(
                                      key: _keyMainButton,
                                      xtKey: btnKey.mainbutton,
                                      formCoordinator: formCoordinator,
                                      text: 'LOG IN',
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      onPressed: () async {
                                        await _onLogin();
                                      },
                                    ),
                                    verticalSpaceRegular,
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: InkWell(
                                            //GestureDetector(
                                            onTap: () =>
                                                context.go('/forgot_Password'),
                                            child: xtText.body(
                                              'Forget Password?',
                                            )),
                                      ),
                                    ),
                                    if (widget.appConfig
                                                .activePortalProjectScope ==
                                            ProjectScope.EMS_CW_NUS &&
                                        widget.destPortal == DestPortal.emsop)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 13),
                                        child: SignInButton(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 20),
                                          Buttons.Microsoft,
                                          onPressed: () {
                                            loginWithMicrosoft(context);
                                          },
                                        ),
                                      ),
                                    if (_errorText.isNotEmpty)
                                      getErrorTextPrompt(
                                          context: context,
                                          errorText: _errorText)
                                  ],
                                ),
                              ),
                            ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
