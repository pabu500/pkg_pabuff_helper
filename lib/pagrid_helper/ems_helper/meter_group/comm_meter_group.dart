import 'package:buff_helper/pagrid_helper/app_helper/pagrid_app_config.dart';
import 'package:buff_helper/pagrid_helper/comm_helper/be_api_base.dart';
import 'package:buff_helper/pkg_buff_helper.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

Future<dynamic> doCreateMeterGroup(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptCreateMeterGroup;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  // List<Map<String, dynamic>> meterList = [];
  // for (var item in reqMap['meter_group_info']) {
  //   meterList.add(item);
  // }

  try {
    final response = await http.post(
      Uri.parse(
          UrlController(appConfig).getUrl(SvcType.oresvc, svcClaim.endpoint!)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(SvcQuery(svcClaim, reqMap).toJson()),
    );

    if (response.statusCode == 201) {
      // If the server did return a 201 CREATED response, parse the JSON.
      final responseBody = jsonDecode(response.body);
      if (responseBody['error'] != null) {
        throw Exception(responseBody['error']);
      }
      final groupMap = responseBody['result'];
      return groupMap;
    } else {
      throw Exception('Failed to create meter group');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doGetGroupMeters(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetGroupMeters;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  // List<Map<String, dynamic>> meterList = [];
  // for (var item in reqMap['meter_group_info']) {
  //   meterList.add(item);
  // }

  try {
    final response = await http.post(
      Uri.parse(
          UrlController(appConfig).getUrl(SvcType.oresvc, svcClaim.endpoint!)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(SvcQuery(svcClaim, reqMap).toJson()),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['info'] != null) {
        return responseBody;
      }
      final groupMeterListResp = responseBody['group_meter_list'];
      List<Map<String, dynamic>> groupMeterList = [];
      for (var item in groupMeterListResp) {
        groupMeterList.add({
          'item_index': item['meter_id'],
          'item_name': item['item_name'],
          'percentage': item['percentage'],
        });
      }
      return {'item_list': groupMeterList};
    } else {
      throw Exception('Failed to get group meters');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doGetMeterTenants(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetMeterTenants;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  // List<Map<String, dynamic>> meterList = [];
  // for (var item in reqMap['meter_group_info']) {
  //   meterList.add(item);
  // }

  try {
    final response = await http.post(
      Uri.parse(
          UrlController(appConfig).getUrl(SvcType.oresvc, svcClaim.endpoint!)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(SvcQuery(svcClaim, reqMap).toJson()),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final meterTenantList = responseBody['meter_tenants'];
      List<Map<String, dynamic>> meterTenantInfoList = [];
      for (var item in meterTenantList) {
        meterTenantInfoList.add(item);
      }
      return meterTenantInfoList;
    } else {
      throw Exception('Failed to get meter tenants');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doUpdateMeterGroup(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptUpdateGroupItems;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  // List<Map<String, dynamic>> meterList = [];
  // for (var item in reqMap['meter_group_info']) {
  //   meterList.add(item);
  // }

  try {
    final response = await http.post(
      Uri.parse(
          UrlController(appConfig).getUrl(SvcType.oresvc, svcClaim.endpoint!)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(SvcQuery(svcClaim, reqMap).toJson()),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final groupMap = responseBody['result'];
      if (groupMap['item_group_info'] == null) {
        throw Exception('Failed to update meter group');
      } else {
        return {'code': 0};
      }
    } else {
      throw Exception('Failed to update meter group');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doListMeterGroups(
  PaGridAppConfig appConfig,
  Map<String, dynamic> queryMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.usersvc.name;
  svcClaim.endpoint = UrlBase.eptListItems;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(
        UrlController(appConfig).getUrl(SvcType.usersvc, svcClaim.endpoint!)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, queryMap).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);
    final info = responseBody['info'];
    if (info != null) {
      if (info.contains("Empty")) {
        throw Exception("No item record found");
      }
    }
    final itemListJson = responseBody['item_list'];
    // // List<MeterGroup> itemList = [];
    // List<Map<String, dynamic>> itemList = [];
    // for (var item in itemListJson) {
    //   // Map<String, dynamic> tenantJson = {};
    //   // MeterGroup mg = MeterGroup.fromJson(item);
    //   // itemList.add(mg);
    //   itemList.add(item);
    // }
    // return userList;
    // final itemListJson = responseBody['user_list'];
    final totalCount = responseBody['total_count'];
    final idSelectQuery = responseBody['id_select_query'];
    // List<Map<String, dynamic>> itemList = [];
    // if (itemListJson != null) {
    //   for (var item in itemListJson) {
    //     itemList.add(item);
    //   }
    // }
    return {
      'item_list': itemListJson, //itemList,
      'total_count': totalCount,
      // 'meter_query_map': queryMap,
      'id_select_query': idSelectQuery ?? '',
      'query_map': queryMap,
    };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}
