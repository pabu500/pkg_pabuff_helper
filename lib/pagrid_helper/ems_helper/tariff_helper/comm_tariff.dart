import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../app_helper/pagrid_app_config.dart';
import '../../comm_helper/be_api_base.dart';

Future<dynamic> doCreateTariffPackage(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptCreateTariffPackage;

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
      final responseBody = jsonDecode(response.body);

      return responseBody['result'];
    } else {
      throw Exception('Failed to create tariff package');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doUpdateTariffPackage(
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

Future<dynamic> doGetTariffPackageRateRows(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetRateRowList;

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

Future<dynamic> doUpdateTariffPackageRateRows(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptUpdatePackageRateRowList;

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
      throw Exception('Failed to update tariff package rate rows');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doAssignTenantsToTariffPackage(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptUpdateTariffPackageTenants;

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
      // If the server did return a 201 CREATED response, parse the JSON.
      final responseBody = jsonDecode(response.body);
      if (responseBody['error'] != null) {
        throw Exception(responseBody['error']);
      }
      final groupMap = responseBody['result'];
      return groupMap;
    } else {
      throw Exception('Failed to assign tenants to tariff package');
    }
  } catch (err) {
    throw Exception(err);
  }
}

Future<dynamic> doGetTariffPackageTenants(
  PaGridAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetTariffPackageTenants;

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
        // throw ItemNotFoundException('No tenants found');
        throw ItemNotFoundException('No tenants found');
      }
      final resultMap = responseBody['result'];
      final itemInfoListJson = resultMap['item_info_list'];
      List<Map<String, dynamic>> itemInfoList = [];
      for (var item in itemInfoListJson) {
        itemInfoList.add(item);
      }
      return {
        'item_group_id': resultMap['item_group_id'],
        'item_info_list': itemInfoList
      };
    } else {
      throw Exception('Failed to get tariff package tenants');
    }
  } catch (err) {
    rethrow;
  }
}
