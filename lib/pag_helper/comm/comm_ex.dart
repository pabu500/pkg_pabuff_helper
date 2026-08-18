import 'dart:convert';
import 'dart:io';

import 'package:buff_helper/pag_helper/comm/comm_helper.dart';
import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_svc_query.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../util/util.dart';

const int successCode = 200;
const int successCodeCreate = 201;

Future<dynamic> ex({
  required String endpoint,
  required String crudType,
  required String opStr,
  required MdlPagAppConfig appConfig,
  required Map<String, dynamic> queryMap,
  required MdlPagSvcClaim svcClaim,
}) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = endpoint;

  String svcToken = '';
  // try {
  //   svcToken = await aclGate(appConfig, svcClaim, queryMap);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final portalType = appConfig.portalType;
  queryMap['query_check_portal_type'] = portalType.name;

  try {
    final response = await http.post(
      Uri.parse(PagUrlController(null, appConfig)
          .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
    );

    int scode = successCode;
    if (crudType == 'create') {
      scode = successCodeCreate;
    }
    if (response.statusCode != scode) {
      if (response.statusCode == 403) {
        throw Exception("You are not authorized to perform this operation");
      }
      // throw Exception('Failed to $opStr');
    }

    return getResultFromResp(response.body,
        defualtErrorMsg: 'Failed to get response data for $opStr');
  } catch (e) {
    throw Exception('q:Failed to $opStr: $e');
  }
}

Future<dynamic> ex2({
  required String endpoint,
  required String crudType,
  required String opStr,
  required MdlPagAppConfig appConfig,
  required Map<String, dynamic> queryMap,
  required MdlPagSvcClaim2 svcClaim,
}) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = endpoint;

  String svcToken = '';
  try {
    svcToken = await aclGate(appConfig, svcClaim, queryMap);
  } catch (err) {
    throw Exception(err);
  }

  final portalType = appConfig.portalType;
  queryMap['query_check_portal_type'] = portalType.name;

  try {
    final response = await http.post(
      Uri.parse(PagUrlController(null, appConfig)
          .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(MdlPagSvcQuery2(svcClaim, queryMap).toJson()),
    );

    int scode = successCode;
    if (crudType == 'create') {
      scode = successCodeCreate;
    }
    if (response.statusCode != scode) {
      if (response.statusCode == 403) {
        throw Exception("You are not authorized to perform this operation");
      }
      // throw Exception('Failed to $opStr');
    }

    return getResultFromResp(response.body,
        defualtErrorMsg: 'Failed to get response data for $opStr');
  } catch (e) {
    throw Exception('q:Failed to $opStr: $e');
  }
}

Future<dynamic> aclGate(MdlPagAppConfig appConfig, MdlPagSvcClaim2 svcClaim,
    Map<String, dynamic> queryMap) async {
  const storage = FlutterSecureStorage();
  String? userToken = await storage.read(key: 'pag_user_token');
  if (userToken == null) {
    throw Exception("User is not logged in");
  }

  try {
    final response = await http.post(
      Uri.parse(PagUrlController(null, appConfig)
          .getUrl(PagSvcType.oresvc2, PagUrlBase.eptAclGate)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $userToken',
      },
      body: jsonEncode(MdlPagSvcQuery2(svcClaim, queryMap).toJson()),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final svcToken = responseBody['svc_token'];
      return svcToken;
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  } on SocketException {
    throw Exception("Unable to connect to authentication server");
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> svcGate(
    MdlPagAppConfig appConfig, MdlPagSvcClaim svcClaim) async {
  const storage = FlutterSecureStorage();
  String? userToken = await storage.read(key: 'evs2_user_token');
  if (userToken == null) {
    throw Exception("User is not logged in");
  }

  String svcToken = '';
  try {
    svcToken = await applySvcToken(appConfig, svcClaim);
    if (isJwtToken(svcToken)) return svcToken;
  } on SocketException {
    throw Exception("Unable to connect to authentication server");
  } catch (err) {
    throw Exception(err);
  }
  throw Exception(svcToken);
}

Future<dynamic> applySvcToken(
    MdlPagAppConfig appConfig, MdlPagSvcClaim svcClaim) async {
  const storage = FlutterSecureStorage();
  String? userToken = await storage.read(key: 'evs2_user_token');

  if (userToken == null) {
    throw Exception("User is not logged in");
  }

  final response = await http.post(
    Uri.parse(PagUrlController(null, appConfig)
        .getUrl(PagSvcType.usersvc2, PagUrlBase.eptUsersvcApplySvcToken)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $userToken',
    },
    body: jsonEncode(<String, dynamic>{
      'username': svcClaim.username ?? '',
      'svcName': svcClaim.svcName ?? '',
      'endpoint': svcClaim.endpoint ?? '',
      // 'scope': svcClaim.userScope ?? '',
      // 'res_id': svcClaim.resId ?? '',
      // 'res_name': svcClaim.resName ?? '',
      // 'res_label': svcClaim.resLabel ?? '',
      // 'operation': svcClaim.operation ?? ''
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
