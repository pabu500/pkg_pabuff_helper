import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/def/def_role.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_role.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_svc_query.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pagrid_helper/comm_helper/local_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<MdlPagUser> doLoginPag(
  MdlPagAppConfig appConfig,
  Map<String, String> formData,
) async {
  String url = PagUrlController(null, appConfig)
      .getUrl(PagSvcType.usersvc2, PagUrlBase.eptUsersvcLogin);
  final response = await http.post(
    Uri.parse(url),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      PagUserKey.username.name: formData[PagUserKey.username.name] ?? '',
      PagUserKey.password.name: formData[PagUserKey.password.name] ?? '',
      // PagUserKey.email.name: formData[PagUserKey.email]!,
      // PagUserKey.authProvider.name: formData[PagUserKey.authProvider] ?? '',
      // PagUserKey.destPortal.name: 'pag_console',
      'portal_type_name': formData['portal_type_name'] ?? '',
      'portal_type_label': formData['portal_type_label'] ?? '',
    }),
  );

  if (response.statusCode == 200) {
    if (kDebugMode) {
      print('usersvc comm: getting token from response body');
    }
    String token = jsonDecode(response.body)['token'];

    if (kDebugMode) {
      print('usersvc comm: writing token to secure storage');
    }
    try {
      await storage.write(key: 'pag_user_token', value: token);
    } catch (err) {
      if (kDebugMode) {
        print('usersvc comm: error writing token to secure storage: $err');
      }
    }
    if (kDebugMode) {
      print('usersvc comm: getting user from token');
    }

    MdlPagUser user = MdlPagUser.fromJson2(jsonDecode(response.body));

    // if (user.userScope == null) {
    //   throw Exception('failed to get user scope');
    // }

    // if (!user.hasScopeForPagProject(activePortalPagProjectScopeList)) {
    //   throw Exception('no access to this project portal');
    // }

    // dynamic scopePref = readFromSharedPref('scope_pref');
    // if (kDebugMode) {
    //   print('scopePref: $scopePref');
    // }
    // Map<String, dynamic> scopePrefMap = json.decode(scopePref ?? '{}');
    // String selectedProjectName = scopePrefMap['selected_project_name'] ?? '';
    // String selectedSiteGroupName =
    //     scopePrefMap['selected_site_group_name'] ?? '';
    // String selectedSiteName = scopePrefMap['selected_site_name'] ?? '';
    // String selectedBuildingName = scopePrefMap['selected_building_name'] ?? '';
    // String selectedLocationGroupName =
    //     scopePrefMap['selected_location_group_name'] ?? '';

    // user.updateSelectedScopeByName(
    //   selectedProjectName,
    //   selectedSiteGroupName,
    //   selectedSiteName,
    //   selectedBuildingName,
    //   selectedLocationGroupName,
    // );

    return user;
  } else {
    if (kDebugMode) {
      print('usersvc comm: error: ${response.body}');
    }
    throw Exception(/*jsonDecode*/ (response.body) /*['err']*/);
  }
}

Future<MdlPagUser> doCreateUser(
  MdlPagUser loggedInUser,
  MdlPagAppConfig appConfig,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  try {
    final response = await http.post(
      Uri.parse(PagUrlController(loggedInUser, appConfig)
          .getUrl(PagSvcType.usersvc2, PagUrlBase.eptUsersvcRegister)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ',
      },
      body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
    );

    if (response.statusCode == 201) {
      // If the server did return a 201 CREATED response, parse the JSON.
      return MdlPagUser.fromJson2(jsonDecode(response.body));
    } else {
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      throw Exception(responseBody['err']);
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doGetUserRoleList(
  MdlPagUser loggedInUser,
  MdlPagAppConfig appConfig,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetUserRoleList;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(PagUrlController(loggedInUser, appConfig)
        .getUrl(PagSvcType.usersvc2, svcClaim.endpoint!)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer ',
    },
    body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
  );

  if (response.statusCode == 200) {
    final respJson = jsonDecode(response.body);
    if (respJson['error'] != null) {
      throw Exception(respJson['error']);
    }
    if (respJson['data'] == null) {
      throw Exception('Failed to get user role list');
    }

    var data = respJson['data'];
    if (data['user_role_list'] == null) {
      throw Exception('Failed to get user role list');
    }

    final itemListJson = data['user_role_list'];
    List<MdlPagRole> roleList = [];
    if (itemListJson != null) {
      for (var item in itemListJson) {
        // String portalTypeStr = item['portal_type'];
        // PagPortalType portalType = PagPortalType.byLabel(portalTypeStr);
        // if (portalType == PagPortalType.none) {
        //   throw Exception('Invalid portal type: $portalTypeStr');
        // }
        // item['portal_type'] = portalType.name;
        MdlPagRole role = MdlPagRole.fromJson(item);
        roleList.add(role);
      }
    }
    return {
      'user_role_list': roleList,
    };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> doGetVisibleRoleList(
  MdlPagUser loggedInUser,
  MdlPagAppConfig appConfig,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetVisibleRoleList;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(PagUrlController(loggedInUser, appConfig)
        .getUrl(PagSvcType.usersvc2, svcClaim.endpoint!)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer ',
    },
    body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
  );

  if (response.statusCode == 200) {
    final respJson = jsonDecode(response.body);
    if (respJson['error'] != null) {
      throw Exception(respJson['error']);
    }
    if (respJson['data'] == null) {
      throw Exception('Failed to get visible role list');
    }

    var data = respJson['data'];
    if (data['visible_role_list'] == null) {
      throw Exception('Failed to get visible role list');
    }

    final itemListJson = data['visible_role_list'];
    List<Map<String, dynamic>> itemList = [];
    if (itemListJson != null) {
      for (var item in itemListJson) {
        String portalTypeStr = item['portal_type'];
        PagPortalType portalType = PagPortalType.byLabel(portalTypeStr);
        if (portalType == PagPortalType.none) {
          throw Exception('Invalid portal type: $portalTypeStr');
        }
        item['portal_type_name'] = portalType.name;
        item['portal_type_label'] = portalType.label;
        itemList.add(item);
      }
    }
    return {
      'visible_role_list': itemList,
    };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> commitUserRoleList(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.usersvc2.name;
  svcClaim.endpoint = PagUrlBase.eptSetUserRoleList;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(PagUrlController(loggedInUser, appConfig)
        .getUrl(PagSvcType.usersvc2, svcClaim.endpoint!)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
  );

  if (response.statusCode == 200) {
    final respJson = jsonDecode(response.body);
    if (respJson['error'] != null) {
      throw Exception(respJson['error']);
    }
    return respJson['data'];
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> doUpdateUserKeyValue(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.usersvc2.name;
  svcClaim.endpoint = PagUrlBase.eptUsersvcUpdateKeyVal;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(appConfig, svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  try {
    final response = await http.post(
      Uri.parse(PagUrlController(loggedInUser, appConfig)
          .getUrl(PagSvcType.usersvc2, svcClaim.endpoint!)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
      // body: jsonEncode(MdlPagSvcQuery(svcClaim, <String, dynamic>{
      //   'id': id.toString(),
      //   'key': key,
      //   'value': value,
      //   'old_value': oldVal ?? '',
      // }).toJson()),
    );

    if (response.statusCode == 200) {
      String key = queryMap['key'];

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

Future<dynamic> doCheckKeyVal(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.usersvc2.name;
  svcClaim.endpoint = PagUrlBase.eptUsersvcGetUserKeyVal;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(PagUrlController(loggedInUser, appConfig)
        .getUrl(PagSvcType.usersvc2, svcClaim.endpoint!)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
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
