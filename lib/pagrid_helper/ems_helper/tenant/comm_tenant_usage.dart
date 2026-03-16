import 'package:buff_helper/pkg_buff_helper.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../app_helper/pagrid_app_config.dart';
import '../../comm_helper/be_api_base.dart';

Future<dynamic> queryTenantUsageSummary(
  PaGridAppConfig appConfig,
  Map<String, String> queryMap,
  Duration duration,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetTenantListUsageSummary;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(
        UrlController(appConfig).getUrl(SvcType.oresvc, svcClaim.endpoint!)),
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
        String durationText = getReadableDuration(duration);
        throw Exception("No record found in the last $durationText");
      }
    }
    if (responseBody['error'] != null) {
      throw Exception(responseBody['error']);
    }
    final summaryJsonList =
        responseBody[Evs2HistoryType.tenant_list_usage_summary.name];

    List<Map<String, dynamic>> summaryList = [];
    for (var item in summaryJsonList) {
      summaryList.add(item);
    }

    return {
      Evs2HistoryType.tenant_list_usage_summary.name: summaryList,
    };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}
