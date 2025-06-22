import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_svc_query.dart';
import 'package:http/http.dart' as http;

Future<dynamic> pagUpdateBatchOpProgress(
    MdlPagAppConfig appConfig, MdlPagUser? loggedInUser, String op) async {
  try {
    final response = await http.get(
      Uri.parse(
          "${PagUrlController(loggedInUser, appConfig).getUrl(PagSvcType.oresvc2, PagUrlBase.eptPollingBatchOpProgress)}?op=$op"),
    );

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      var result = responseBody['result'];
      if (result != null) {
        if (result['updatedBatchList'] != null) {
          List<Map<String, dynamic>> updatedBatchList = [];
          for (var item in result['updatedBatchList']) {
            Map<String, dynamic> updatedBatchItem = item;
            if (item['error'] != null) {
              updatedBatchItem['error'] = item['error'];
            }
            if (item['progress_message'] != null) {
              updatedBatchItem['progress_message'] = item['progress_message'];
            } else {
              String status = item['status'];
              String prevStatus = item['prev_status'] ?? '';
              updatedBatchItem['status'] = status;
              updatedBatchItem['prev_status'] = prevStatus;
            }
            updatedBatchList.add(updatedBatchItem);
          }
          return updatedBatchList;
        } else {
          // throw Exception("No updatedBatchList in response");
          return [];
        }
      }
      var error = responseBody['error'];
      if (error != null) {
        throw Exception(error);
      }
    } else if (response.statusCode == 403) {
      throw Exception("You are not authorized to perform this operation");
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  } catch (err) {
    rethrow;
  }
}

Future<dynamic> getManualMeterList(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptMeterOpGetManualMeterList;

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
      if (respJson['data'] == null) {
        String? message = respJson['error']?['message'];
        if (message != null) {
          throw Exception(message);
        }
        throw Exception('Failed to get manual meter list');
      }
      return respJson;
    } else {
      throw Exception('Failed to get manual meter list');
    }
  } catch (err) {
    rethrow;
  }
}

Future<dynamic> submitManualReadingList(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptMeterOpSubmitManualReadingList;

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
      if (respJson['data'] == null) {
        String? message = respJson['error']?['message'];
        if (message != null) {
          throw Exception(message);
        }
        throw Exception('Failed to submit manual reading list');
      }
      return respJson;
    } else {
      throw Exception('Failed to submit manual reading list');
    }
  } catch (err) {
    rethrow;
  }
}

Future<dynamic> commitTenantMeterGroupList(
  MdlPagAppConfig appConfig,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptPagUpdateTenantMeterGroupList;

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
