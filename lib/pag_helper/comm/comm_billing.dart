import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_svc_query.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../model/mdl_pag_app_config.dart';

Future<dynamic> getUsageFactor(MdlPagAppConfig appConfig,
    Map<String, String> queryMap, MdlPagSvcClaim svcClaim) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetUsageFactor;

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
    final responseBody = jsonDecode(response.body);

    if (responseBody['info'] != null) {
      throw Exception(responseBody['info']);
    }
    if (responseBody['error'] != null) {
      throw Exception(responseBody['error']);
    }
    return {'usage_factor_list': responseBody['usage_factor_list']};
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> getBill(MdlPagAppConfig appConfig, Map<String, String> queryMap,
    MdlPagSvcClaim svcClaim) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetBill;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(PagUrlController(null, appConfig)
        .getUrl(PagSvcType.oresvc2, PagUrlBase.eptGetBill)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);

    if (responseBody['info'] != null) {
      throw Exception(responseBody['info']);
    }
    if (responseBody['error'] != null) {
      throw Exception(responseBody['error']);
    }
    return {'result': responseBody['result']};
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> genPagBill(MdlPagAppConfig appConfig,
    Map<String, dynamic> queryMap, MdlPagSvcClaim svcClaim) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGenBill;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(PagUrlController(null, appConfig)
        .getUrl(PagSvcType.oresvc2, PagUrlBase.eptGenBill)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);

    if (responseBody['info'] != null) {
      throw Exception(responseBody['info']);
    }
    if (responseBody['error'] != null) {
      final message = responseBody['error']['message'];
      dev.log('Error message: $message');
      throw Exception(message);
    }
    final data = responseBody['data'];
    if (data == null) {
      throw Exception("No data found in the response");
    }
    final result = data['result'];
    if (result == null) {
      throw Exception("No result found in the response");
    }
    String? resultKey = data['result_key'];
    if (resultKey == null && resultKey!.isEmpty) {
      throw Exception("Error: $resultKey");
    }
    return result[resultKey];
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> checkPagTpInfo(MdlPagAppConfig appConfig,
    Map<String, String> queryMap, MdlPagSvcClaim svcClaim) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptCheckTpRateInfo;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(PagUrlController(null, appConfig)
        .getUrl(PagSvcType.oresvc2, PagUrlBase.eptCheckTpRateInfo)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);

    if (responseBody['info'] != null) {
      throw ItemNotFoundException('error');
    }
    if (responseBody['error'] != null) {
      throw Exception(responseBody['error']);
    }
    return {
      'result': responseBody['tariff_package_rate'],
    };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> doGetReleaseCandidate(MdlPagAppConfig appConfig,
    Map<String, dynamic> reqMap, MdlPagSvcClaim svcClaim) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetReleaseCandidate;

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
          .getUrl(PagSvcType.oresvc2, PagUrlBase.eptGetReleaseCandidate)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(MdlPagSvcQuery(svcClaim, reqMap).toJson()),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['info'] != null) {
        // throw ItemNotFoundException('No tenants found');
        throw ItemNotFoundException('No items found');
      }
      final resultMap = responseBody['result'];
      final itemInfoListJson = resultMap['item_info_list'];
      List<Map<String, dynamic>> itemInfoList = [];
      for (var item in itemInfoListJson) {
        itemInfoList.add(item);
      }
      return {
        // 'item_group_id': resultMap['item_group_id'],
        'item_info_list': itemInfoList
      };
    } else {
      throw Exception('Failed to get release candidate');
    }
  } catch (err) {
    rethrow;
  }
}

Future<dynamic> doBatchOpBill(MdlPagAppConfig appConfig,
    Map<String, dynamic> reqMap, MdlPagSvcClaim svcClaim) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptBatchOpBill;

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
          .getUrl(PagSvcType.oresvc2, PagUrlBase.eptBatchOpBill)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(MdlPagSvcQuery(svcClaim, reqMap).toJson()),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['info'] != null) {
        throw ItemNotFoundException('No items found');
      }
      final resultMap = responseBody['result'];
      final itemInfoListJson = responseBody['item_info_list'];
      List<Map<String, dynamic>> itemInfoList = [];
      for (var item in itemInfoListJson) {
        itemInfoList.add(item);
      }
      return {
        // 'item_group_id': resultMap['item_group_id'],
        'result': resultMap,
        'item_info_list': itemInfoList
      };
    } else {
      throw Exception('Failed to release bills');
    }
  } catch (err) {
    rethrow;
  }
}

Future<dynamic> doBlast(MdlPagAppConfig appConfig, Map<String, dynamic> reqMap,
    MdlPagSvcClaim svcClaim) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptBlastBillingNotification;

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
      body: jsonEncode(MdlPagSvcQuery(svcClaim, reqMap).toJson()),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['error'] != null) {
        throw Exception(responseBody['error']);
      }

      return responseBody;
    } else {
      throw Exception('Failed to release bills');
    }
  } catch (err) {
    rethrow;
  }
}
