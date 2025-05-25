// import 'dart:convert';
// import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
// import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
// import 'package:buff_helper/up_helper/up_helper.dart';
// import 'package:http/http.dart' as http;
// import 'package:pag_console/app_config.dart';
// import 'job_def.dart';

// Future<dynamic> doPostJob(
//   MdlPagUser loggedInUser,
//   PagJobTaskType jobType,
//   Map<String, String> requst,
//   List<Map<String, dynamic>> opList,
//   SvcClaim svcClaim,
// ) async {
//   svcClaim.svcName = PagSvcType.oresvc2.name;
//   svcClaim.endpoint = PagUrlBase.eptPostJob;

//   String svcToken = '';
//   // try {
//   //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
//   // } catch (err) {
//   //   throw Exception(err);
//   // }

//   final response = await http.post(
//     Uri.parse(PagUrlController(loggedInUser, pagAppConfig)
//         .getUrl(PagSvcType.oresvc2, PagUrlBase.eptPostJob)),
//     headers: <String, String>{
//       'Content-Type': 'application/json; charset=UTF-8',
//       'Authorization': 'Bearer $svcToken',
//     },
//     body: jsonEncode(SvcQuery(
//       svcClaim,
//       {
//         'job_task_type': getPagJobTaskTypeName(jobType),
//         'request': requst,
//         'op_list': opList,
//       },
//     ).toJson()),
//   );

//   if (response.statusCode == 200) {
//     // If the server did return a 200 OK response, parse the JSON.
//     final responseBody = jsonDecode(response.body);

//     if (responseBody['error'] != null) {
//       throw Exception(responseBody['error']);
//     }
//     return responseBody;
//   } else if (response.statusCode == 403) {
//     throw Exception("You are not authorized to perform this operation");
//   } else {
//     throw Exception(jsonDecode(response.body)['error']);
//   }
// }

// Future<dynamic> doGetJobTypeSubs(
//   MdlPagUser loggedInUser,
//   Map<String, dynamic> reqMap,
//   SvcClaim svcClaim,
// ) async {
//   svcClaim.svcName = PagSvcType.oresvc2.name;
//   svcClaim.endpoint = PagUrlBase.eptGetJobTypeSubs;

//   String svcToken = '';
//   // try {
//   //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
//   // } catch (err) {
//   //   throw Exception(err);
//   // }

//   // List<Map<String, dynamic>> meterList = [];
//   // for (var item in reqMap['meter_group_info']) {
//   //   meterList.add(item);
//   // }

//   try {
//     final response = await http.post(
//       Uri.parse(PagUrlController(loggedInUser, pagAppConfig)
//           .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Authorization': 'Bearer $svcToken',
//       },
//       body: jsonEncode(SvcQuery(svcClaim, reqMap).toJson()),
//     );

//     if (response.statusCode == 200) {
//       final responseBody = jsonDecode(response.body);
//       if (responseBody['info'] != null) {
//         return responseBody;
//       }
//       final jobTypeSubInfo = responseBody['subs'];
//       List<Map<String, dynamic>> jobTypeSubInfoList = [];
//       for (var item in jobTypeSubInfo) {
//         jobTypeSubInfoList.add({'item_index': item['job_type_id'], ...item});
//       }
//       return {'item_list': jobTypeSubInfoList};
//     } else {
//       throw Exception('Failed to get job type subs');
//     }
//   } catch (err) {
//     throw Exception(err);
//   }
// }

// Future<dynamic> doAddSub(
//   MdlPagUser loggedInUser,
//   Map<String, dynamic> reqMap,
//   SvcClaim svcClaim,
// ) async {
//   svcClaim.svcName = PagSvcType.oresvc2.name;
//   svcClaim.endpoint = PagUrlBase.eptAddJobTypeSub;

//   String svcToken = '';
//   // try {
//   //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
//   // } catch (err) {
//   //   throw Exception(err);
//   // }

//   // List<Map<String, dynamic>> meterList = [];
//   // for (var item in reqMap['meter_group_info']) {
//   //   meterList.add(item);
//   // }

//   try {
//     final response = await http.post(
//       Uri.parse(PagUrlController(loggedInUser, pagAppConfig)
//           .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Authorization': 'Bearer $svcToken',
//       },
//       body: jsonEncode(SvcQuery(svcClaim, reqMap).toJson()),
//     );

//     if (response.statusCode == 200) {
//       // If the server did return a 201 CREATED response, parse the JSON.
//       final responseBody = jsonDecode(response.body);
//       if (responseBody['error'] != null) {
//         throw Exception(responseBody['error']);
//       }
//       final code = responseBody['code'];
//       return {'code': code};
//     } else {
//       throw Exception('Failed to add job type sub');
//     }
//   } catch (err) {
//     throw Exception(err);
//   }
// }

// Future<dynamic> doRemoveSub(
//   MdlPagUser loggedInUser,
//   Map<String, dynamic> reqMap,
//   SvcClaim svcClaim,
// ) async {
//   svcClaim.svcName = PagSvcType.oresvc2.name;
//   svcClaim.endpoint = PagUrlBase.eptDeleteJobTypeSub;

//   String svcToken = '';
//   // try {
//   //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
//   // } catch (err) {
//   //   throw Exception(err);
//   // }

//   // List<Map<String, dynamic>> meterList = [];
//   // for (var item in reqMap['meter_group_info']) {
//   //   meterList.add(item);
//   // }

//   try {
//     final response = await http.post(
//       Uri.parse(PagUrlController(loggedInUser, pagAppConfig)
//           .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Authorization': 'Bearer $svcToken',
//       },
//       body: jsonEncode(SvcQuery(svcClaim, reqMap).toJson()),
//     );

//     if (response.statusCode == 200) {
//       final responseBody = jsonDecode(response.body);
//       if (responseBody['error'] != null) {
//         throw Exception(responseBody['error']);
//       }
//       final code = responseBody['code'];
//       return {'code': code};
//     } else {
//       throw Exception('Failed to delete job type sub');
//     }
//   } catch (err) {
//     throw Exception(err);
//   }
// }

// Future<dynamic> getLastJobLastTriggerTime(
//   MdlPagUser loggedInUser,
//   Map<String, dynamic> reqMap,
//   SvcClaim svcClaim,
// ) async {
//   svcClaim.svcName = PagSvcType.oresvc2.name;
//   svcClaim.endpoint = PagUrlBase.getLastManualTrigger;

//   String svcToken = '';
//   // try {
//   //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
//   // } catch (err) {
//   //   throw Exception(err);
//   // }

//   // List<Map<String, dynamic>> meterList = [];
//   // for (var item in reqMap['meter_group_info']) {
//   //   meterList.add(item);
//   // }

//   try {
//     final response = await http.post(
//       Uri.parse(PagUrlController(loggedInUser, pagAppConfig)
//           .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Authorization': 'Bearer $svcToken',
//       },
//       body: jsonEncode(SvcQuery(svcClaim, reqMap).toJson()),
//     );

//     if (response.statusCode == 200) {
//       final responseBody = jsonDecode(response.body);
//       if (responseBody['info'] != null) {
//         return responseBody;
//       }
//       if (responseBody['error'] != null) {
//         throw Exception(responseBody['error']);
//       }
//       final result = responseBody['result'];
//       return result;
//     } else {
//       throw Exception('Failed to get job last trigger info');
//     }
//   } catch (err) {
//     throw Exception(err);
//   }
// }

// Future<dynamic> doUpdateLastManualTriggerTime(
//   MdlPagUser loggedInUser,
//   Map<String, dynamic> reqMap,
//   SvcClaim svcClaim,
// ) async {
//   svcClaim.svcName = PagSvcType.oresvc2.name;
//   svcClaim.endpoint = PagUrlBase.eptUpdateLastManualTrigger;

//   String svcToken = '';
//   // try {
//   //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
//   // } catch (err) {
//   //   throw Exception(err);
//   // }

//   // List<Map<String, dynamic>> meterList = [];
//   // for (var item in reqMap['meter_group_info']) {
//   //   meterList.add(item);
//   // }

//   try {
//     final response = await http.post(
//       Uri.parse(PagUrlController(loggedInUser, pagAppConfig)
//           .getUrl(PagSvcType.oresvc2, svcClaim.endpoint!)),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Authorization': 'Bearer $svcToken',
//       },
//       body: jsonEncode(SvcQuery(svcClaim, reqMap).toJson()),
//     );

//     if (response.statusCode == 200) {
//       final responseBody = jsonDecode(response.body);
//       if (responseBody['info'] != null) {
//         return responseBody;
//       }
//       if (responseBody['error'] != null) {
//         throw Exception(responseBody['error']);
//       }
//       final result = responseBody['result'];
//       return result;
//     } else {
//       throw Exception('Failed to get job last trigger info');
//     }
//   } catch (err) {
//     throw Exception(err);
//   }
// }
