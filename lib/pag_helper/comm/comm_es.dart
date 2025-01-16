import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/mdl_svc_query.dart';
import 'package:http/http.dart' as http;

Future<dynamic> getScadaDataPointDef(
  MdlPagAppConfig pagAppConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptSacadaGetDataPointDef;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(PagUrlController(loggedInUser, pagAppConfig)
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
        throw Exception('Failed to get scada data point def');
      }
      return respJson;
    } else {
      throw Exception('Failed to get scada data point def');
    }
  } catch (err) {
    // return err.toString();
    rethrow;
  }
}

Future<dynamic> getScadaInfo(
  MdlPagAppConfig pagAppConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptScadaInfo;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(PagUrlController(loggedInUser, pagAppConfig)
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
        throw Exception('Failed to get sld info');
      }
      return respJson;
    } else {
      throw Exception('Failed to get sld info');
    }
  } catch (err) {
    // return err.toString();
    rethrow;
  }
}

Future<dynamic> getScadaData(
  MdlPagAppConfig pagAppConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptSacadaGetData;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(PagUrlController(loggedInUser, pagAppConfig)
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
        throw Exception('Failed to get scada data');
      }
      return respJson;
    } else {
      throw Exception('Failed to get scada data');
    }
  } catch (err) {
    // return err.toString();
    rethrow;
  }
}
