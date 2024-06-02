import 'dart:convert';
import 'package:buff_helper/pagrid_helper/pagrid_helper.dart';
import 'package:buff_helper/up_helper/up_helper.dart';
import 'package:http/http.dart' as http;

import '../comm_helper/be_api_base.dart';

Future<dynamic> doPostJob(
  ProjectScope activePortalProjectScope,
  JobTaskType jobType,
  Map<String, String> requst,
  List<Map<String, dynamic>> opList,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptPostJob;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(UrlController(activePortalProjectScope)
        .getUrl(SvcType.oresvc, UrlBase.eptPostJob)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(
      svcClaim,
      {
        'job_task_type': getJobTaskTypeName(jobType),
        'request': requst,
        'op_list': opList,
      },
    ).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);

    if (responseBody['error'] != null) {
      throw Exception(responseBody['error']);
    }
    return responseBody;
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}
