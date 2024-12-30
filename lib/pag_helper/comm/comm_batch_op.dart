import 'dart:convert';

import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/mdl_svc_query.dart';
import 'package:buff_helper/up_helper/up_helper.dart';
import 'package:buff_helper/util/date_time_util.dart';
import 'package:http/http.dart' as http;
import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';

Future<dynamic> doOpSingleKeyValUpdate(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  ItemType itemType,
  ItemIdType? itemIdType,
  String opName,
  String targetFields,
  List<Map<String, dynamic>> opList,
  DateTime? scheduledTime,
  String projectScope,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptDoOpUpdateSingleKeyVal;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  String timeStr = '';
  if (scheduledTime != null) {
    timeStr = getDateTimeStrFromDateTime(scheduledTime);
  }
  try {
    final response = await http.post(
      Uri.parse(PagUrlController(loggedInUser, appConfig)
          .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(SvcQuery(svcClaim, <String, dynamic>{
        'op_name': opName,
        'item_type': itemType.name,
        'item_id_type': itemIdType != null ? itemIdType.name : '',
        'key_name': targetFields,
        'op_list': opList,
        'scheduled_time': timeStr,
        'project_scope': projectScope,
      }).toJson()),
    );

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response, parse the JSON.
      final responseBody = jsonDecode(response.body);
      final error = responseBody['error'];
      if (error != null) {
        throw Exception(error);
      }
      dynamic resultList = responseBody['list_op_result'];
      List<Map<String, dynamic>> listOped = [];
      for (Map<String, dynamic> item in resultList) {
        Map<String, dynamic> listItem = item;
        if (item['error'] != null) {
          listItem['error'] = item['error'];
        }
        listOped.add(listItem);
      }
      return listOped;
    } else if (response.statusCode == 403) {
      throw Exception("You are not authorized to perform this operation");
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doOpMultiKeyValUpdate(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptDoOpUpdateMultiKeyVal;

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
      // If the server did return a 200 OK response, parse the JSON.
      final responseBody = jsonDecode(response.body);
      final error = responseBody['error'];
      if (error != null) {
        throw Exception(error);
      }
      // throw Exception('test error');
      final data = responseBody['data'];
      if (data == null) {
        throw Exception('Failed to get response data');
      }
      dynamic resultList = data['op_result_list'];
      List<Map<String, dynamic>> listOped = [];
      for (Map<String, dynamic> item in resultList) {
        Map<String, dynamic> listItem = item;
        if (item['error'] != null) {
          listItem['error'] = item['error'];
        }
        listOped.add(listItem);
      }
      return listOped;
    } else if (response.statusCode == 403) {
      throw Exception("You are not authorized to perform this operation");
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<Map<String, dynamic>> pagUpdateBatchOpProgress(
    MdlPagAppConfig appConfig, MdlPagUser? loggedInUser, String opName) async {
  try {
    final response = await http.get(
      Uri.parse(
          "${PagUrlController(loggedInUser, appConfig).getUrl(PagSvcType.oresvc2, PagUrlBase.eptPollingBatchOpProgress)}?op=$opName"),
    );

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);

      var error = responseBody['error'];
      if (error != null) {
        throw Exception(error);
      }

      var result = responseBody['result'];
      if (result != null) {
        if (result['error'] != null) {
          throw Exception(result['error']);
        }

        if (result['updated_batch_list'] != null) {
          List<Map<String, dynamic>> updatedBatchList = [];
          for (var item in result['updated_batch_list']) {
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
          result['updated_batch_list'] = updatedBatchList;
        }
      }
      return result;
    } else if (response.statusCode == 403) {
      throw Exception("You are not authorized to perform this operation");
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  } catch (err) {
    rethrow;
  }
}
