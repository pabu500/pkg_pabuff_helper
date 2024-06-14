import 'package:buff_helper/pagrid_helper/app_helper/pagrid_app_config.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../comm_helper/be_api_base.dart';

Future<dynamic> doCreateTenant(
  PaGridAppConfig appConfig,
  Map<String, String> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptCreateTenant;

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
      body: jsonEncode(SvcQuery(svcClaim, reqMap).toJson()),
    );

    if (response.statusCode == 201) {
      // If the server did return a 201 CREATED response, parse the JSON.
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create tenant');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doUpdateTenantMeterGroups(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptUpdateTenantMeterGroups;

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
      if (responseBody['error'] != null) {
        throw Exception(responseBody['error']);
      }
      final groupMap = responseBody['result'];
      if (groupMap['item_group_info'] == null) {
        throw Exception('Failed to update tenant meter groups');
      } else {
        return {'code': 0};
      }
    } else {
      throw Exception('Failed to update tenant meter groups');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doGetTenantMeterGroups(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetTenantMeterGroups;

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
      if (responseBody['error'] != null) {
        throw Exception(responseBody['error']);
      }
      if (responseBody['info'] != null) {
        return responseBody;
      }
      final tenantMeterGroupInfo = responseBody['tenant_meter_group_list'];
      List<Map<String, dynamic>> tenantMeterGroupInfoList = [];
      for (var item in tenantMeterGroupInfo) {
        tenantMeterGroupInfoList.add({
          'item_index': item['group_id'],
          'item_name': item['group_name'],
          'item_label': item['group_label'],
        });
      }
      return {'item_list': tenantMeterGroupInfoList};
    } else {
      throw Exception('Failed to get tenant meter groups');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doGetTenantMap(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetTenantMap;

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
      final tenantMap = responseBody['tenant_map'];

      return tenantMap;
    } else {
      throw Exception('Failed to get tenant meter groups');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> checkMainTenant(
  PaGridAppConfig appConfig,
  Map<String, String> queryMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptCheckMainTenant;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  UrlController urlController = UrlController(appConfig);

  final response = await http.post(
    Uri.parse(urlController.getUrl(SvcType.oresvc, svcClaim.endpoint!)),
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
    if (responseBody['error'] != null) {
      throw Exception(responseBody['error']);
    }
    return responseBody['item_info'];
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> doGetUserTenantList(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetUserTenantList;

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
      final itemInfoListJson = responseBody['item_info_list'];
      List<Map<String, dynamic>> itemInfoList = [];
      for (var item in itemInfoListJson) {
        itemInfoList.add({'item_index': item['id'], ...item});
      }
      return {
        'item_group_id': responseBody['item_group_id'],
        'item_list': itemInfoList
      };
    } else {
      throw Exception('Failed to get rate rows');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doUpdateUserTenantList(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptUpdateUserTenantList;

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
      if (groupMap['item_info_list'] == null) {
        throw Exception('Failed to update tariff package rate rows');
      } else {
        for (var item in groupMap['item_info_list']) {
          if (item['error'] != null) {
            return {'code': -1, 'error': item['error']};
          }
        }
        return {'code': 0};
      }
    } else {
      throw Exception('Failed to update user tenant list');
    }
  } catch (err) {
    throw Exception(err);
  }
}
