import 'package:buff_helper/pkg_buff_helper.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../comm_helper/be_api_base.dart';

Future<dynamic> getBill(
  ProjectScope activePortalProjectScope,
  Map<String, String> queryMap,
  // Duration duration,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetBill;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(UrlController(activePortalProjectScope)
        .getUrl(SvcType.oresvc, UrlBase.eptGetBill)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, queryMap).toJson()),
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

Future<dynamic> genBill(
  ProjectScope activePortalProjectScope,
  Map<String, dynamic> queryMap,
  // Duration duration,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGenerateBillingRec;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(UrlController(activePortalProjectScope)
        .getUrl(SvcType.oresvc, UrlBase.eptGenerateBillingRec)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, queryMap).toJson()),
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
    return responseBody['result'];
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> checkTpInfo(
  ProjectScope activePortalProjectScope,
  Map<String, String> queryMap,
  // Duration duration,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptCheckTpInfo;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(UrlController(activePortalProjectScope)
        .getUrl(SvcType.oresvc, UrlBase.eptCheckTpInfo)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, queryMap).toJson()),
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

Future<dynamic> doGetReleaseCandidate(
  ProjectScope activePortalProjectScope,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetReleaseCandidate;

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
      Uri.parse(UrlController(activePortalProjectScope)
          .getUrl(SvcType.oresvc, UrlBase.eptGetReleaseCandidate)),
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

Future<dynamic> doReleaseBills(
  ProjectScope activePortalProjectScope,
  Map<String, dynamic> reqMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptReleaseBills;

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
      Uri.parse(UrlController(activePortalProjectScope)
          .getUrl(SvcType.oresvc, UrlBase.eptReleaseBills)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(SvcQuery(svcClaim, reqMap).toJson()),
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