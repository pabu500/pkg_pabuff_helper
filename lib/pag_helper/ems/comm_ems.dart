import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../comm/pag_be_api_base.dart';
import '../model/acl/mdl_pag_svc_claim.dart';
import '../model/mdl_svc_query.dart';

Future<dynamic> doCreateTariffPackage(
  MdlPagAppConfig appConfig,
  Map<String, dynamic> reqMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptCreateTariffPackage;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  try {
    final response = await http.post(
      Uri.parse(PagUrlController(null, appConfig)
          .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(MdlPagSvcQuery(svcClaim, reqMap).toJson()),
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
  MdlPagAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptUpdateTenantMeterGroups;

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
      Uri.parse(PagUrlController(null, appConfig)
          .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
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
  MdlPagAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetRateRowList;

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
      Uri.parse(PagUrlController(null, appConfig)
          .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
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
  MdlPagAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptUpdatePackageRateRowList;

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
      Uri.parse(PagUrlController(null, appConfig)
          .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
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
  MdlPagAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptUpdateTariffPackageTenants;

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
      Uri.parse(PagUrlController(null, appConfig)
          .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
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
  MdlPagAppConfig appConfig,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetTariffPackageTenants;

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
      Uri.parse(PagUrlController(null, appConfig)
          .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
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
