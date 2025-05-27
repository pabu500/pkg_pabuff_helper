import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/ems/ems_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/mdl_svc_query.dart';

Future<dynamic> doPagCheckUnique(
    dynamic appConfig, String field, String val, String table) async {
  try {
    //use query string instead of path
    String url = PagUrlController(null, appConfig)
        .getUrl(PagSvcType.oresvc2, PagUrlBase.eptCheckItemExists);

    final response =
        await http.get(Uri.parse('$url?t=$table&field=$field&val=$val'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check unique.');
    }
  } catch (err) {
    // return err.toString();
    rethrow;
  }
}

Future<dynamic> fetchItemList(
  MdlPagUser? loggedInUser,
  MdlPagAppConfig pagAppConfig,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetItemList;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  if (kDebugMode) {
    print('fetching item list');
  }

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
      throw Exception('Failed to get stat');
    }

    var data = respJson['data'];
    if (data['item_list'] == null) {
      throw Exception('Failed to get item list');
    }

    final itemListJson = data['item_list'];
    final totalCount = data['count'];
    final listConfig = data['list_config'];
    final idSelectQuery = data['item_select_query'];
    List<Map<String, dynamic>> itemList = [];
    if (itemListJson != null) {
      for (var item in itemListJson) {
        // if (item['meter_usage_summary'] != null) {
        //   var meterUsageSummary = item['meter_usage_summary'];
        //   item['first_reading_timestamp'] =
        //       meterUsageSummary['first_reading_timestamp'];
        //   item['last_reading_timestamp'] =
        //       meterUsageSummary['last_reading_timestamp'];
        //   item['first_reading_value'] =
        //       meterUsageSummary['first_reading_value'];
        //   item['last_reading_value'] = meterUsageSummary['last_reading_value'];
        //   item['usage'] = meterUsageSummary['usage'];
        //   item['usage_color'] = Colors.green;
        // }
        populateListItemMeterUsage(item);
        populateListItemTenantUsage(item, queryMap['meter_type_list'] ?? []);
        itemList.add(item);
      }
    }
    int? count;
    if (totalCount is String) {
      count = int.tryParse(totalCount);
    } else {
      count = totalCount;
    }
    return {
      'item_list': itemList,
      'count': count,
      'list_config': listConfig,
      'item_select_query': idSelectQuery,
      'query_map': queryMap,
    };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> pullPagItemHistory(
    MdlPagUser loggedInUser,
    MdlPagAppConfig pagAppConfig,
    Map<String, dynamic> queryMap,
    MdlPagSvcClaim svcClaim) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetItemHistory;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(
  //     svcClaim, /*, user*/
  //   );
  // } catch (err) {
  //   throw Exception(err);
  // }

  PagUrlController urlController = PagUrlController(loggedInUser, pagAppConfig);

  final response = await http.post(
    Uri.parse(urlController.getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);
    var data = responseBody['data'];
    return data;
    if (queryMap['get_count_only'] == 'true') {
      if (data['total_count'] == null) {
        throw Exception('Failed to get total count');
      }
      return {
        'total_count': data['total_count'],
      };
    }

    final info = data['info'];
    if (info != null) {
      if (info.contains("Empty") || info.contains("found")) {
        // String durationText = getReadableDuration(duration);
        // throw Exception("empty history data between $startDate and $endDate");
        return {
          'history_list': [],
          'metas': {},
          'time_range': data['time_range'],
        };
      }
    }

    final meterReadingHistoryJson = data[queryMap['history_type']];
    final timeRange = data['time_range'];
    final historyList = data['history_list'];
    final meterReadingHistoryMeta = data['meta'];
    final multiMetaInfo = data['multi_meta_info'];

    return {
      'history_list': historyList,
      'meta_info': multiMetaInfo ?? {'total': meterReadingHistoryMeta},
      'time_range': timeRange,
    };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> getPagItemInfo(
  MdlPagUser? loggedInUser,
  MdlPagAppConfig pagAppConfig,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetItemInfo;

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
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);
    if (responseBody['error'] != null) {
      throw Exception(responseBody['error']);
    }
    final data = responseBody['data'];
    final info = data['info'];
    if (info != null) {
      if (info.contains("Empty")) {
        throw Exception("No item info found");
      }
    }
    if (data['item_info'] == null) {
      throw Exception("No item info found");
    }
    return data['item_info'];
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> doPagDelete(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptDeleteItem;

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

      return data;
    } else if (response.statusCode == 403) {
      throw Exception("You are not authorized to perform this operation");
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  } catch (err) {
    throw Exception(err);
  }
}
