import 'dart:io';

import 'package:buff_helper/pagrid_helper/comm_helper/be_api_base.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<AclSetting> getAclSetting(ProjectScope activePortalProjectScope) async {
  final response = await http.get(Uri.parse(
      UrlController(activePortalProjectScope)
          .getUrl(SvcType.usersvc, UrlBase.eptUsersvcGetAclSetting)));

  if (response.statusCode == 200) {
    return AclSetting.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load ACL Setting');
  }
}

Future<String> getAppToken(ProjectScope activePortalProjectScope) async {
  final response = await http.get(Uri.parse(
      UrlController(activePortalProjectScope)
          .getUrl(SvcType.usersvc, UrlBase.eptUsersvcGetAppToken)));

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['token'];
  } else {
    throw Exception('Failed to load App Token');
  }
}

Future<List<dynamic>> getPgk(ProjectScope activePortalProjectScope) async {
  final String appToken;
  try {
    appToken = await getAppToken(activePortalProjectScope);
  } catch (e) {
    throw Exception('Failed to load App Token');
  }

  final response = await http.post(
    Uri.parse(UrlController(activePortalProjectScope)
        .getUrl(SvcType.usersvc, UrlBase.eptUsersvcGetPgk)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{'token': appToken}),
  );

  if (response.statusCode == 200) {
    final responseBody = jsonDecode(response.body);
    final error = responseBody['error'];
    if (error != null) {
      throw Exception(error);
    }
    final pgks = responseBody['pgk'];
    return pgks;
  } else {
    throw Exception('Failed to load PGK');
  }
}

Future<Evs2User> doCreateUser(
    ProjectScope activePortalProjectScope, Map<Enum, String> formData) async {
  // String? token = await getToken();
  // print('token: $token');
  String scopeStr = 'none';

  if (formData[UserKey.projectScope] != null) {
    scopeStr = formData[UserKey.projectScope]!;
  }
  if (formData[UserKey.siteScope] != null) {
    scopeStr += ';${formData[UserKey.siteScope]!}';
  }

  try {
    final response = await http.post(
      Uri.parse(UrlController(activePortalProjectScope)
          .getUrl(SvcType.usersvc, UrlBase.eptUsersvcRegister)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        UserKey.fullname.name: formData[UserKey.fullname]!,
        UserKey.username.name: formData[UserKey.username]!,
        UserKey.password.name: formData[UserKey.password] ?? '',
        UserKey.email.name: formData[UserKey.email]!,
        UserKey.phone.name: formData[UserKey.phone]!,
        'dest_portal': formData[UserKey.destPortal] ?? DestPortal.evs2cp.name,
        'scope_str': scopeStr,
        UserKey.enabled.name: formData[UserKey.enabled] ?? 'false',
        UserKey.sendVerificationEmail.name:
            formData[UserKey.sendVerificationEmail] ?? 'false',
        UserKey.authProvider.name: formData[UserKey.authProvider] ?? '',
        UserKey.resetPasswordOnFirstLogin.name:
            formData[UserKey.resetPasswordOnFirstLogin] ?? 'true',
      }),
    );

    if (response.statusCode == 201) {
      // If the server did return a 201 CREATED response, parse the JSON.
      return Evs2User.fromJson(jsonDecode(response.body));
    } else {
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      throw Exception(responseBody['err']);
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doBatchCreateUsers(
    ProjectScope activePortalProjectScope,
    List<Map<String, dynamic>> userList,
    AclScope userScope,
    SvcClaim svcClaim) async {
  svcClaim.svcName = SvcType.usersvc.name;
  svcClaim.endpoint = UrlBase.eptUsersvcBatchReg;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(UrlController(activePortalProjectScope)
        .getUrl(SvcType.usersvc, UrlBase.eptUsersvcBatchReg)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, <String, dynamic>{
      'user_list': userList,
      'scope': userScope.name,
    }).toJson()),
  );

  if (response.statusCode == 200) {
    final responseBody = jsonDecode(response.body);
    final error = responseBody['error'];
    if (error != null) {
      throw Exception(error);
    }
    final resultList = responseBody['result'];
    List<Map<String, dynamic>> list = [];
    for (var item in resultList) {
      // Map<String, dynamic> listItem = {
      //   'meter_sn': item['meter_sn'],
      //   'username': item['username'],
      //   'password': item['password'],
      //   'checked': item['checked'],
      //   'status': item['status'],
      // };
      // if (item['error'] != null) {
      //   listItem['error'] = item['error'];
      // }
      // list.add(listItem);
      list.add(item);
    }
    return list;
  } else {
    throw Exception('Failed to create user.');
  }
}

Future<Evs2User> doUpdateProfile(
    ProjectScope activePortalProjectScope, Map<Enum, String> formData) async {
  // String? token = await getToken();
  // print('token: $token');

  final response = await http.post(
    Uri.parse(UrlController(activePortalProjectScope)
        .getUrl(SvcType.usersvc, UrlBase.eptUsersvcUpdateProfile)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      UserKey.fullname.name: formData[UserKey.fullname]!,
      UserKey.username.name: formData[UserKey.username]!,
      UserKey.password.name: formData[UserKey.password]!,
      UserKey.email.name: formData[UserKey.email]!,
      UserKey.phone.name: formData[UserKey.phone]!,
    }),
  );

  if (response.statusCode == 201) {
    // If the server did return a 201 CREATED response, parse the JSON.
    return Evs2User.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update user profile.');
  }
}

Future<dynamic> doUpdateKeyValue(ProjectScope activePortalProjectScope, int id,
    String key, String value, SvcClaim svcClaim,
    {String? oldVal, String? checkOldPassword}) async {
  svcClaim.svcName = SvcType.usersvc.name;
  svcClaim.endpoint = UrlBase.eptUsersvcUpdateKeyVal;

  String svcToken = '';
  try {
    svcToken =
        await svcGate(activePortalProjectScope, svcClaim /*, queryByUser*/);
  } catch (err) {
    throw Exception(err);
  }

  try {
    final response = await http.post(
      Uri.parse(UrlController(activePortalProjectScope)
          .getUrl(SvcType.usersvc, UrlBase.eptUsersvcUpdateKeyVal)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      // body: jsonEncode(<String, String>{
      //   'id': id.toString(),
      //   'key': key,
      //   'value': value,
      //   'old_value': oldVal ?? '',
      // }),
      body: jsonEncode(SvcQuery(svcClaim, <String, dynamic>{
        'id': id.toString(),
        'key': key,
        'value': value,
        'old_value': oldVal ?? '',
      }).toJson()),
    );

    if (response.statusCode == 200) {
      final resp = jsonDecode(response.body);
      if (resp['err'] != null) {
        throw Exception(resp.err);
      }
      Map<String, dynamic> result = {};
      result[key] = resp['userInfo'][key];
      return result;
    } else if (response.statusCode == 500) {
      Map<String, dynamic> result = {};
      result['error'] = jsonDecode(response.body)['err'];
      return result;
    } else {
      throw Exception('Failed to update user.');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<String> doUserCheckUnique(
    ProjectScope activePortalProjectScope, Enum field, String val,
    {String? table}) async {
  try {
    //for testing
    // await Future.delayed(const Duration(milliseconds: 500));

    final response = await http.get(
      Uri.parse(
          '${UrlController(activePortalProjectScope).getUrl(SvcType.usersvc, UrlBase.eptUsersvcCheckUnique)}/${field.name}/$val'),
      // headers: <String, String>{
      //   'Content-Type': 'application/json; charset=UTF-8',
      // },
      // body: jsonEncode(<String, String>{
      //   field: val,
      // }),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to check unique.');
    }
  } catch (err) {
    return err.toString();
  }
}

Future<Evs2User> doLogin(DestPortal destPortal,
    ProjectScope activePortalProjectScope, Map<Enum, String> formData) async {
  final response = await http.post(
    Uri.parse(UrlController(activePortalProjectScope)
        .getUrl(SvcType.usersvc, UrlBase.eptUsersvcLogin)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      UserKey.username.name: formData[UserKey.username] ?? '',
      UserKey.password.name: formData[UserKey.password] ?? '',
      UserKey.email.name: formData[UserKey.email]!,
      UserKey.authProvider.name: formData[UserKey.authProvider] ?? '',
      // UserKey.emailVerified.name: formData[UserKey.emailVerified]!,
      UserKey.destPortal.name: destPortal.name,
      // activePortalProjectScope == ProjectScope.EMS_CW_NUS ||
      //         activePortalProjectScope == ProjectScope.EMS_SMRT
      //     ? DestPortal.emsop.name
      //     : DestPortal.evs2op.name,
    }),
  );
  // final response = await http.post(
  //   Uri.parse(
  //       'http://evs2-alb-ifa-1424481483.ap-southeast-1.elb.amazonaws.com:8081/login'),
  //   headers: <String, String>{
  //     'Content-Type': 'application/json; charset=UTF-8',
  //   },
  //   body: jsonEncode(<String, String>{
  //     'username': 'P11005A',
  //     'password': '123',
  //   }),
  // );
  // print('usersvc comm: response:${response.body}');
  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    if (kDebugMode) {
      print('usersvc comm: getting token from response body');
    }
    String token = jsonDecode(response.body)['token'];
    // print('token: $token');
    const storage = FlutterSecureStorage();
    if (kDebugMode) {
      print('usersvc comm: writing token to secure storage');
    }
    try {
      await storage.write(key: 'evs2_user_token', value: token);
    } catch (err) {
      if (kDebugMode) {
        print('usersvc comm: error writing token to secure storage: $err');
      }
    }
    if (kDebugMode) {
      print('usersvc comm: getting user from token');
    }

    Evs2User user = Evs2User.fromJson2(jsonDecode(response.body));
    if (kDebugMode) {
      print(user);
    }
    if (user.scopes != null && user.scopes!.isNotEmpty) {
    } else {
      throw Exception('Mssing scope info');
    }
    return user;
  } else {
    if (kDebugMode) {
      print('usersvc comm: error: ${response.body}');
    }
    // int? userId = jsonDecode(response.body)['userId'];
    throw Exception(/*jsonDecode*/ (response.body) /*['err']*/);
  }
}

Future<bool> doCheckExists(
    ProjectScope activePortalProjectScope, Enum field, String val) async {
  //for testing
  // await Future.delayed(const Duration(milliseconds: 500));

  final response = await http.get(
    Uri.parse(
        '${UrlController(activePortalProjectScope).getUrl(SvcType.usersvc, UrlBase.eptUsersvcCheckExists)}/${field.name}/$val'),
    // headers: <String, String>{
    //   'Content-Type': 'application/json; charset=UTF-8',
    // },
    // body: jsonEncode(<String, String>{
    //   userKeys.email.name: formData[userKeys.email]!,
    // }),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    // User.fromJson(jsonDecode(response.body));
    if (response.body == 'yes') {
      return true;
    } else {
      return false;
    }
  } else {
    throw Exception(jsonDecode(response.body)['err']);
  }
}

Future<dynamic> doCheckKeyVal(
  ProjectScope activePortalProjectScope,
  int userId,
  String key,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.usersvc.name;
  svcClaim.endpoint = UrlBase.eptUsersvcGetUserKeyVal;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(UrlController(activePortalProjectScope)
        .getUrl(SvcType.usersvc, UrlBase.eptUsersvcGetUserKeyVal)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, <String, dynamic>{
      'id': userId.toString(),
      'key': key,
    }).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    // User.fromJson(jsonDecode(response.body));
    final responseBody = jsonDecode(response.body);
    if (responseBody['err'] != null) {
      throw Exception(responseBody['err']);
    }
    if (responseBody['info'] != null) {
      return responseBody['info'];
    }
    return responseBody;
  } else {
    throw Exception(jsonDecode(response.body)['err']);
  }
}

Future<bool> doForgotPassword(
    ProjectScope activePortalProjectScope, Map<Enum, String> formData) async {
  //for testing
  await Future.delayed(const Duration(milliseconds: 500));

  final response = await http.post(
    Uri.parse(UrlController(activePortalProjectScope)
        .getUrl(SvcType.usersvc, UrlBase.eptUsersvcForgotPassword)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      UserKey.email.name: formData[UserKey.email]!,
    }),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    return true;
    // User.fromJson(jsonDecode(response.body));
  } else {
    throw Exception(jsonDecode(response.body)['err']);
  }
}

Future<dynamic> doUpdateUsers(ProjectScope activePortalProjectScope,
    List<Map<String, dynamic>> modifiedUsers, SvcClaim svcClaim) async {
  svcClaim.svcName = SvcType.usersvc.name;
  svcClaim.endpoint = UrlBase.eptUsersvcUpdateUsers;

  String svcToken = '';
  try {
    svcToken =
        await svcGate(activePortalProjectScope, svcClaim /*, queryByUser*/);
  } catch (err) {
    throw Exception(err);
  }

  // for (var element in modifiedUsers) {
  //   element['updated_timestamp'] = getSgNow().toString();
  // }

  final response = await http.post(
    Uri.parse(UrlController(activePortalProjectScope)
        .getUrl(SvcType.usersvc, UrlBase.eptUsersvcUpdateUsers)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, modifiedUsers).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);
    final error = responseBody['error'];
    if (error != null) {
      throw Exception(error);
    }
    return responseBody;
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

// Future<dynamic> doUpdatePassword(
//     int userId, String password, SvcClaim svcClaim) async {
//   svcClaim.svcName = SvcType.usersvc.name;
//   svcClaim.endpoint = URLController.eptUpdateUserPassword
//       .replaceFirst(URLController.usersvcURL, '');

//   String svcToken = '';
//   try {
//     svcToken = await svcGate(svcClaim /*, queryByUser*/);
//   } catch (err) {
//     throw Exception(err);
//   }

//   final response = await http.post(
//     Uri.parse(URLController.eptUpdateUserPassword),
//     headers: <String, String>{
//       'Content-Type': 'application/json; charset=UTF-8',
//       'Authorization': 'Bearer $svcToken',
//     },
//     body: jsonEncode(SvcQuery(svcClaim, {
//       'user_id': userId,
//       'password': password,
//     }).toJson()),
//   );

//   if (response.statusCode == 200) {
//     // If the server did return a 200 OK response, parse the JSON.
//     final responseBody = jsonDecode(response.body);
//     final error = responseBody['error'];
//     if (error != null) {
//       throw Exception(error);
//     }
//     return responseBody;
//   } else if (response.statusCode == 403) {
//     throw Exception("You are not authorized to perform this operation");
//   } else {
//     throw Exception(jsonDecode(response.body)['error']);
//   }
// }

Future<dynamic> applySvcToken(
    ProjectScope activePortalProjectScope, SvcClaim svcClaim) async {
  const _storage = FlutterSecureStorage();
  String? userToken = await _storage.read(key: 'evs2_user_token');

  if (userToken == null) {
    throw Exception("User is not logged in");
  }

  //for testing
  // await Future.delayed(const Duration(milliseconds: 500));

  final response = await http.post(
    Uri.parse(UrlController(activePortalProjectScope)
        .getUrl(SvcType.usersvc, UrlBase.eptUsersvcApplySvcToken)),
    // Uri.http(URLController.usersvcAuthority, URLController.pathApplySvcToken),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $userToken',
    },
    body: jsonEncode(<String, String>{
      'username': svcClaim.username ?? '',
      'svcName': svcClaim.svcName ?? '',
      'endpoint': svcClaim.endpoint ?? '',
      'scope': svcClaim.scope ?? '',
      'target': svcClaim.target ?? '',
      'operation': svcClaim.operation ?? ''
    }),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);
    final svcToken = responseBody['svc_token'];
    return svcToken;
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> svcGate(ProjectScope activePortalProjectScope,
    SvcClaim svcClaim /*, User user*/) async {
  const storage = FlutterSecureStorage();
  String? userToken = await storage.read(key: 'evs2_user_token');
  if (userToken == null) {
    throw Exception("User is not logged in");
  }

  String svcToken = '';
  try {
    svcToken = await applySvcToken(activePortalProjectScope, svcClaim);
    if (isJwtToken(svcToken)) return svcToken;
  } on SocketException {
    throw Exception("Unable to connect to authentication server");
  } catch (err) {
    throw Exception(err);
  }
  throw Exception(svcToken);
}

Future<dynamic> updateBatchUserOpProgress(
    ProjectScope activePortalProjectScope, String op) async {
  // await Future.delayed(const Duration(seconds: 1));
  try {
    // if (!context.mounted) {
    //   return;
    // }
    final response = await http.get(
      Uri.parse(
          "${UrlController(activePortalProjectScope).getUrl(SvcType.usersvc, UrlBase.eptUsersvcPollingUserBatchOpProgress)}?op=$op"),
    );

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      var result = responseBody['result'];
      if (result != null) {
        if (result['updatedBatchList'] != null) {
          List<Map<String, dynamic>> updatedBatchList = [];
          for (var item in result['updatedBatchList']) {
            Map<String, dynamic> updatedBatchItem = {
              'meter_sn': item['meter_sn'],
              'username': item['username'],
              'password': item['password'],
              'checked': item['checked'],
            };
            if (item['error'] != null) {
              updatedBatchItem['error'] = {'status': item['error']};
            }

            String status = item['status'];
            String prevStatus = item['prev_status'] ?? '';

            if (item['checked']) {
              if (prevStatus.isNotEmpty) {
                status = 'step 2: $status';
              }
            }
            updatedBatchItem['status'] = status;
            updatedBatchItem['prev_status'] = prevStatus;

            updatedBatchList.add(updatedBatchItem);
          }
          return updatedBatchList;
        }
      }
      var error = responseBody['error'];
      if (error != null) {
        throw Exception(error);
      }
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doGetUserTenant(
  ProjectScope activePortalProjectScope,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetUserTenant;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  // List<Map<String, dynamic>> meterList = [];
  // for (var item in reqMap['meter_group_info']) {
  //   meterList.add(item);
  // }

  try {
    final response = await http.post(
      Uri.parse(UrlController(activePortalProjectScope)
          .getUrl(SvcType.oresvc, UrlBase.eptGetUserTenant)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(SvcQuery(svcClaim, reqMap).toJson()),
    );

    if (response.statusCode == 200) {
      // If the server did return a 201 CREATED response, parse the JSON.
      final responseBody = jsonDecode(response.body);
      if (responseBody['error'] != null) {
        throw Exception(responseBody['error']);
      }
      final groupMap = responseBody;
      return groupMap;
    } else {
      throw Exception('Failed to get user tenant');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doSetUserTenant(
  ProjectScope activePortalProjectScope,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptSetUserTenant;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  // List<Map<String, dynamic>> meterList = [];
  // for (var item in reqMap['meter_group_info']) {
  //   meterList.add(item);
  // }

  try {
    final response = await http.post(
      Uri.parse(UrlController(activePortalProjectScope)
          .getUrl(SvcType.oresvc, UrlBase.eptSetUserTenant)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(SvcQuery(svcClaim, reqMap).toJson()),
    );

    if (response.statusCode == 200) {
      // If the server did return a 201 CREATED response, parse the JSON.
      final responseBody = jsonDecode(response.body);
      if (responseBody['error'] != null) {
        throw Exception(responseBody['error']);
      }
      final groupMap = responseBody;
      return groupMap;
    } else {
      throw Exception('Failed to get user tenant');
    }
  } catch (err) {
    throw Exception(err);
  }
}
