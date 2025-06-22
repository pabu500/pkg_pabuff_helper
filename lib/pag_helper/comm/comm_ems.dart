import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/mdl_svc_query.dart';
import 'package:buff_helper/util/date_time_util.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<dynamic> getUserTenantList(
  MdlPagAppConfig pagAppConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetUserTenantList;

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

  if (response.statusCode == 200) {
    final respJson = jsonDecode(response.body);
    if (respJson['error'] != null) {
      throw Exception(respJson['error']);
    }
    if (respJson['data'] == null) {
      throw Exception('Failed to get user tenant list');
    }

    var data = respJson['data'];
    if (data['user_tenant_list'] == null) {
      throw Exception('Failed to get user tenant list');
    }

    return data;

    // final itemListJson = data['user_tenant_list'];
    // List<Map<String, dynamic>> itemList = [];
    // if (itemListJson != null) {
    //   for (var item in itemListJson) {
    //     itemList.add(item);
    //   }
    // }
    // return {'user_tenant_list': itemList};
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> commitUserTenantList(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptSetUserTenantList;

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
    return respJson['data'];
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> getMeterConsolidatedUsageHistory(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, String> queryMap,
  Duration duration,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetMeterListConsolidatedUsageHistory;

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
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);
    final info = responseBody['info'];
    if (info != null) {
      if (info.contains("Empty")) {
        String durationText = getReadableDuration(duration);
        throw Exception("No record found in the last $durationText");
      }
    }
    // final historyListJson = responseBody[
    //     Evs2HistoryType.meter_list_consolidated_usage_history.name];
    // List<Map<String, dynamic>> meterListHistory = [];
    // for (var meterHistory in historyListJson) {
    //   String meterId = meterHistory['meter_id'];
    //   String meterIdType = meterHistory['meter_id_type'];
    //   String interval = meterHistory['interval'];
    //   List<Map<String, dynamic>> historyList = [];
    //   for (var item in meterHistory['meter_usage_history']) {
    //     historyList.add(item);
    //   }
    //   meterListHistory.add({
    //     'meter_id': meterId,
    //     'meter_id_type': meterIdType,
    //     'interval': interval,
    //     'history': historyList,
    //   });
    // }

    // return {
    //   Evs2HistoryType.meter_list_consolidated_usage_history.name:
    //       meterListHistory,
    // };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}
