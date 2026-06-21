import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/comm_helper.dart';
import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_svc_query.dart';
import 'package:http/http.dart' as http;

const int successCode = 200;
const int successCodeCreate = 201;

Future<dynamic> ex({
  required String endpoint,
  required String crudType,
  required String opStr,
  required MdlPagAppConfig appConfig,
  required Map<String, dynamic> queryMap,
  required MdlPagSvcClaim svcClaim,
}) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = endpoint;

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
      body: jsonEncode(MdlPagSvcQuery(svcClaim, queryMap).toJson()),
    );

    int scode = successCode;
    if (crudType == 'create') {
      scode = successCodeCreate;
    }
    if (response.statusCode != scode) {
      if (response.statusCode == 403) {
        throw Exception("You are not authorized to perform this operation");
      }
      // throw Exception('Failed to $opStr');
    }

    return getResultFromResp(response.body,
        defualtErrorMsg: 'Failed to get response data for $opStr');
  } catch (e) {
    throw Exception('q:Failed to $opStr: $e');
  }
}
