import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/mdl_svc_query.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future<dynamic> doPagCreateScope(
  MdlPagUser loggedInUser,
  MdlPagAppConfig appConfig,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptCreateScope;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  try {
    final response = await http.post(
      Uri.parse(PagUrlController(loggedInUser, appConfig)
          .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
    );

    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);

      if (responseBody['info'] != null) {
        throw Exception(responseBody['info']);
      }
      if (responseBody['error'] != null) {
        throw Exception(responseBody['error']);
      }
      final data = responseBody['data'];
      if (data == null) {
        throw Exception("No data found in the response");
      }
      final result = data['result'];
      if (result == null) {
        throw Exception("No result found in the response");
      }
      String? resultKey = data['result_key'];
      if (resultKey == null && resultKey!.isEmpty) {
        throw Exception("Error: $resultKey");
      }
      return result[resultKey];
    } else {
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      throw Exception(responseBody['error']);
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> getUserRoleScopeList(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetUserRoleScopeList;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }
  try {
    final response = await http.post(
      Uri.parse(PagUrlController(loggedInUser, appConfig)
          .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
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
      if (respJson['data'] == null) {
        throw Exception('Failed to get user role list');
      }

      var data = respJson['data'];
      if (data['user_role_scope_list'] == null) {
        throw Exception('Failed to get user role scope list');
      }

      final scopeListJson = data['user_role_scope_list'];

      List<Map<String, dynamic>> scopeInfoList = [];
      if (scopeListJson != null) {
        for (var item in scopeListJson) {
          scopeInfoList.add(item);
        }
      }

      return {
        'user_role_scope_list': scopeInfoList,
      };
    } else if (response.statusCode == 403) {
      throw Exception("You are not authorized to perform this operation");
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  } catch (e) {
    if (kDebugMode) {
      print('getUserRoleScopeList error: $e');
    }
    rethrow;
  }
}

Future<dynamic> getScopeChildrenList(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetScopeChildrenList;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(PagUrlController(loggedInUser, appConfig)
        .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
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
    if (respJson['data'] == null) {
      throw Exception('Failed to get location list');
    }

    var data = respJson['data'];
    if (data['scope_info_list'] == null) {
      throw Exception('Failed to get scope info list');
    }

    final scopeInfoListJson = data['scope_info_list'];

    List<Map<String, dynamic>> scopeInfoList = [];
    if (scopeInfoListJson != null) {
      for (var item in scopeInfoListJson) {
        scopeInfoList.add(item);
      }
    }

    return {
      'scope_info_list': scopeInfoList,
    };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> getLocationGroupLocationList(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetLocationGroupLocationList;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(PagUrlController(loggedInUser, appConfig)
        .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
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
    if (respJson['data'] == null) {
      throw Exception('Failed to get location list');
    }

    var data = respJson['data'];
    if (data['location_group_location_list'] == null) {
      throw Exception('Failed to get location list');
    }

    final locationListJson = data['location_group_location_list'];

    List<Map<String, dynamic>> locationInfoList = [];
    if (locationListJson != null) {
      for (var item in locationListJson) {
        locationInfoList.add(item);
      }
    }

    return {
      'location_group_location_list': locationInfoList,
    };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}
