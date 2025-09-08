import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/mdl_svc_query.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Future<dynamic> getPortalStatus(
//     String appName, MdlPagAppConfig pagAppConfig) async {
//   String projectScope = pagAppConfig.activePortalPagProjectScopeList[0].name;

//   try {
//     String url =
//         '${PagUrlController(null, pagAppConfig).getUrl(PagSvcType.oresvc2, PagUrlBase.eptGetTargetPortalStatus)}/$appName/$projectScope';
//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final respJson = jsonDecode(response.body);
//       return respJson['status'] ?? '';
//     } else {
//       throw Exception('Failed to load status');
//     }
//   } catch (err) {
//     if (kDebugMode) {
//       print(err);
//     }
//     rethrow;
//   }
// }

Future<dynamic> getPortalTargetStatus(MdlPagAppConfig appConfig) async {
  String endpoint = PagUrlBase.eptGetPortalTargetStatus;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(
        PagUrlController(null, appConfig).getUrl(PagSvcType.oresvc2, endpoint)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(MdlPagSvcQuery(MdlPagSvcClaim(), {
      'portal_type': appConfig.portalType.value,
    }).toJson()),
  );

  if (response.statusCode == 200) {
    final responseBody = jsonDecode(response.body);
    if (responseBody['error'] != null) {
      // final error = responseBody['error'];
      // final code = error['code'] ?? 'unknown';
      // final message = error['message'] ?? '';
      // if (code == ApiCode.resultNotFound.code) {
      //   return <String, dynamic>{
      //     'info': 'not found',
      //     'message': message,
      //   };
      // }
      throw Exception(responseBody['error']);
    }
    final data = responseBody['data'];
    if (data == null) {
      throw Exception('Failed to get response data');
    }
    final result = data['result'];
    if (result == null) {
      throw Exception("No result found in the response");
    }
    String? resultKey = data['result_key'];
    if (resultKey == null && resultKey!.isEmpty) {
      throw Exception("Error: $resultKey");
    }
    if (result[resultKey] == null) {
      throw Exception("No data found in the response");
    }
    return result[resultKey];
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> getVersion2(
    String appName, MdlPagAppConfig pagAppConfig) async {
  String projectScope = pagAppConfig.activePortalPagProjectScopeList[0].name;

  try {
    String url =
        '${PagUrlController(null, pagAppConfig).getUrl(PagSvcType.oresvc2, PagUrlBase.eptGetVerion)}/$appName/$projectScope';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final respJson = jsonDecode(response.body);
      return respJson['version'] ?? '';
    } else {
      throw Exception('Failed to load version');
    }
  } catch (err) {
    if (kDebugMode) {
      print(err);
    }
    rethrow;
  }
}

Future<dynamic> getOreVersion2(
    MdlPagUser? loggedInUser, MdlPagAppConfig pagAppConfig) async {
  try {
    final response = await http.get(
      Uri.parse(PagUrlController(loggedInUser, pagAppConfig)
          .getUrl(PagSvcType.oresvc2, PagUrlBase.eptOreHello)),
    );

    if (response.statusCode == 200) {
      // final respJson = jsonDecode(response.body);
      String respJson = response.body;
      return respJson;
    } else {
      throw Exception('ORE handshake failed');
    }
  } catch (err) {
    return err.toString();
  }
}

Future<dynamic> getPagSysVar(
  MdlPagAppConfig appConfig,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetSysVar;
  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }
  final response = await http.post(
    Uri.parse(PagUrlController(null, appConfig)
        .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
  );

  try {
    if (response.statusCode == 200) {
      final respJson = jsonDecode(response.body);
      if (respJson['data'] == null) {
        throw Exception('No system variable found');
      }
      return respJson['data'];
    } else {
      throw Exception('Failed to load system variable');
    }
  } catch (err) {
    return err.toString();
  }
}

Future<dynamic> getOaxLink(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetOaxLink;

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

  try {
    if (response.statusCode == 200) {
      final respJson = jsonDecode(response.body);
      if (respJson['oax_link'] == null) {
        throw Exception('Failed to get oax link');
      }
      return respJson['oax_link'];
    } else {
      throw Exception('Failed to get oax link');
    }
  } catch (err) {
    // return err.toString();
    rethrow;
  }
}
