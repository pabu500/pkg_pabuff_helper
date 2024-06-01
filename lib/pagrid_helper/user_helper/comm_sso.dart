// import 'dart:html';

import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import '../comm_helper/be_api_base.dart';

Future<dynamic> verifyEmailAddress(
    ProjectScope activePortalProjectScope, Map<String, dynamic> reqMap) async {
  final response = await http.post(
    Uri.parse(UrlController(activePortalProjectScope)
        .getUrl(SvcType.usersvc, UrlBase.eptUsersvcSsoVerifyEmailAddress)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(reqMap),
  );

  if (response.statusCode == 200) {
    final responseBody = jsonDecode(response.body);
    final error = responseBody['error'];
    if (error != null) {
      throw Exception(error);
    }
    return responseBody;
  } else {
    throw Exception('Failed to verify sso email address');
  }
}

Future<void> logoutSso(BuildContext context) async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    return;
  }
  try {
    auth.signOut();
    var logoutUrl =
        'https://login.microsoftonline.com/common/oauth2/logout?post_logout_redirect_uri=https://cwnustest.evs.com.sg';

    // Redirect the user to the logout URL
    // window.location.href = logoutUrl;
    launchUrl(Uri.parse(logoutUrl), webOnlyWindowName: '_self');
  } catch (e) {
    if (kDebugMode) {
      print('Error logging out: $e');
    }
  }
}
