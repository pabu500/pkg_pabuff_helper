import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/vendor_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:buff_helper/pkg_buff_helper.dart';

import '../../model/acl/mdl_pag_svc_claim.dart';
import '../../model/mdl_svc_query.dart';

Future<dynamic> doLoadVendorCredential(
    MdlPagAppConfig appConfig, MdlPagUser loggedInUser) async {
  //get ct_lab access token
  var result = {};
  try {
    result = await getCtLabAccessToken(
      appConfig,
      loggedInUser,
      {
        'user_id': loggedInUser.id.toString(),
      },
      MdlPagSvcClaim(
        userId: loggedInUser.id,
        username: loggedInUser.username,
        scope: '',
        operation: '',
        target: '',
      ),
    );

    if (result['access_token'] == null) {
      throw Exception('Failed to get access token');
    }

    String accessToken = result['access_token'];
    loggedInUser.updateVendorCred(
      PlatformVendor.ctlab,
      VendorCredType.access_token,
      accessToken,
    );
    result['status'] = 'Go';
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
    // rethrow;
  }
}

Future<dynamic> getCtLabAccessToken(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptCtLabGetAccessToken;

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
      if (respJson['access_token'] == null) {
        throw Exception('Failed to get access token');
      }
      return respJson;
    } else {
      throw Exception('Failed to get access token');
    }
  } catch (err) {
    if (kDebugMode) {
      print(err);
    }
    rethrow;
  }
}

Future<dynamic> getTrending(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptCtLabGetTrending;

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
      if (respJson['trending'] == null) {
        throw Exception('Failed to get trending');
      }
      return respJson;
    } else {
      throw Exception('Failed to get trending');
    }
  } catch (err) {
    // return err.toString();
    rethrow;
  }
}

Future<dynamic> getEventList(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptCtLabGetEventList;

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
      if (respJson['event_list'] == null) {
        throw Exception('Failed to get event list');
      }
      return respJson;
    } else {
      throw Exception('Failed to get event list');
    }
  } catch (err) {
    // return err.toString();
    rethrow;
  }
}
