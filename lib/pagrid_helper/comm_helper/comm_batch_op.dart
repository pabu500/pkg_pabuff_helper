import 'dart:convert';

import 'package:buff_helper/pagrid_helper/app_helper/pagrid_app_config.dart';
import 'package:buff_helper/up_helper/up_helper.dart';
import 'package:buff_helper/util/date_time_util.dart';
import 'package:http/http.dart' as http;

import 'be_api_base.dart';

Future<dynamic> doOpSingleKeyValUpdate(
  PaGridAppConfig appConfig,
  ItemType itemType,
  ItemIdType? itemIdType,
  String opName,
  String targetFields,
  List<Map<String, dynamic>> opList,
  DateTime? scheduledTime,
  String projectScope,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptDoOpUpdateSingleKeyVal;

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
      Uri.parse(
          UrlController(appConfig).getUrl(SvcType.oresvc, svcClaim.endpoint!)),
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
  PaGridAppConfig appConfig,
  ItemType itemType,
  ItemIdType? itemIdType,
  String opName,
  String targetFields,
  List<Map<String, dynamic>> opList,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptDoOpUpdateMultiKeyVal;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }
  try {
    final response = await http.post(
      Uri.parse(
          UrlController(appConfig).getUrl(SvcType.oresvc, svcClaim.endpoint!)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(SvcQuery(svcClaim, <String, dynamic>{
        'item_type': itemType.name,
        'item_id_type': itemIdType != null ? itemIdType.name : '',
        'op_name': opName,
        'op_list': opList,
      }).toJson()),
    );

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response, parse the JSON.
      final responseBody = jsonDecode(response.body);
      final error = responseBody['error'];
      if (error != null) {
        throw Exception(error);
      }
      // throw Exception('test error');
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

Future<dynamic> updateBatchOpProgress(
    PaGridAppConfig appConfig, String op) async {
  // await Future.delayed(const Duration(seconds: 1));
  try {
    // if (!context.mounted) {
    //   return;
    // }
    final response = await http.get(
      Uri.parse(
          "${UrlController(appConfig).getUrl(SvcType.oresvc, UrlBase.eptPollingBatchOpProgress)}?op=$op"),
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
    throw Exception(err);
  }
}
