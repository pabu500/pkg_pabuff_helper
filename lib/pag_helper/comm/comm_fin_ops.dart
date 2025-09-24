import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_svc_query.dart';
import 'package:http/http.dart' as http;

Future<dynamic> doFinPostPayment(
  MdlPagAppConfig appConfig,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptBatchOpFinPostPayment;

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
    final error = responseBody['error'];
    if (error != null) {
      throw Exception(error);
    }
    final data = responseBody['data'];
    if (data == null) {
      throw Exception('Failed to get response data');
    }
    final result = data['result'];
    if (result == null) {
      throw Exception("No result found in the response");
    }
    String? resultKey = data['result_key'];
    if (resultKey == null && resultKey!.isEmpty) {
      throw Exception("Error: $resultKey");
    }
    if (result[resultKey] == null) {
      throw Exception("No data found in the response");
    }
    return result[resultKey];
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> matchPayment(
  MdlPagAppConfig appConfig,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptFinMatchPayment;

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
    if (responseBody['error'] != null) {
      final error = responseBody['error'];
      final code = error['code'] ?? 'unknown';
      final message = error['message'] ?? '';
      if (code == ApiCode.resultNotFound.code) {
        return <String, dynamic>{
          'info': 'not found',
          'message': message,
        };
      }
      throw Exception(responseBody['error']);
    }
    final data = responseBody['data'];
    if (data == null) {
      throw Exception('Failed to get response data');
    }
    final result = data['result'];
    if (result == null) {
      throw Exception("No result found in the response");
    }
    String? resultKey = data['result_key'];
    if (resultKey == null && resultKey!.isEmpty) {
      throw Exception("Error: $resultKey");
    }
    if (result[resultKey] == null) {
      throw Exception("No data found in the response");
    }
    return result[resultKey];
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> updatePaymentLcStatus(
  MdlPagAppConfig appConfig,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptUpdateItemLcStatus;

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
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);

    if (responseBody['info'] != null) {
      throw Exception(responseBody['info']);
    }
    if (responseBody['error'] != null) {
      throw Exception(responseBody['error']);
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

Future<dynamic> fetchPaymentMatchOpInfo(
  MdlPagAppConfig appConfig,
  Map<String, dynamic> queryMap,
  MdlPagSvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetPaymentMatchOpInfo;

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
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);

    if (responseBody['info'] != null) {
      throw Exception(responseBody['info']);
    }
    if (responseBody['error'] != null) {
      throw Exception(responseBody['error']);
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
