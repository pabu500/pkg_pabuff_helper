import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:http/http.dart' as http;
import 'package:buff_helper/pkg_buff_helper.dart';

Future<dynamic> getFhStat(
  MdlPagAppConfig appConfig,
  MdlPagUser? loggedInUser,
  Map<String, dynamic> queryMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = PagSvcType.oresvc2.name;
  svcClaim.endpoint = PagUrlBase.eptGetFhStat;

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
    body: jsonEncode(SvcQuery(svcClaim, queryMap).toJson()),
  );

  try {
    if (response.statusCode == 200) {
      final respJson = jsonDecode(response.body);
      if (respJson['data'] == null) {
        throw Exception('Failed to get fh stat');
      }
      return respJson;
    } else {
      throw Exception('Failed to get fh stat');
    }
  } catch (err) {
    // return err.toString();
    rethrow;
  }
}
