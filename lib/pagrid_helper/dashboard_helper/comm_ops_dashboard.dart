import 'dart:convert';

import 'package:buff_helper/pagrid_helper/pagrid_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:http/http.dart' as http;

import '../comm_helper/be_api_base.dart';

Future<dynamic> getMmsStatus(
    PaGridAppConfig appConfig, SvcClaim svcClaim) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetMmsSatus;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(
  //     svcClaim, /*, user*/
  //   );
  // } catch (err) {
  //   throw Exception(err);
  // }

  try {
    final response = await http.post(
      Uri.parse(UrlController(appConfig)
          .getUrl(SvcType.oresvc, UrlBase.eptGetMmsSatus)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(SvcQuery(svcClaim, <String, String>{}).toJson()),
    );
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response, parse the JSON.
      final responseBody = jsonDecode(response.body);
      final info = responseBody['info'];
      if (info != null) {
        throw Exception(info);
      }
      final error = responseBody['error'];
      if (error != null) {
        throw Exception(error);
      }
      final mmsStatus = responseBody['mms_status'];
      return mmsStatus;
    } else if (response.statusCode == 403) {
      throw Exception("You are not authorized to perform this operation");
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  } catch (err) {
    String explainedMessage = explainException(err);
    if (explainedMessage.isEmpty) {
      throw Exception(err);
    } else {
      throw Exception('ore_$explainedMessage');
    }
  }
}

Future<dynamic> getActiveMeterCount(
    PaGridAppConfig appConfig, SvcClaim svcClaim) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetActiveMeterCount;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(
  //     svcClaim, /*, user*/
  //   );
  // } catch (err) {
  //   throw Exception(err);
  // }

  try {
    final response = await http.post(
      Uri.parse(UrlController(appConfig)
          .getUrl(SvcType.oresvc, UrlBase.eptGetActiveMeterCount)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(SvcQuery(svcClaim, <String, String>{}).toJson()),
    );
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response, parse the JSON.
      final responseBody = jsonDecode(response.body);
      final info = responseBody['info'];
      if (info != null) {
        throw Exception(info);
      }
      final error = responseBody['error'];
      if (error != null) {
        throw Exception(error);
      }
      final activeMeterCount = responseBody['active_meter_count'];
      return activeMeterCount;
    } else if (response.statusCode == 403) {
      throw Exception("You are not authorized to perform this operation");
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  } catch (err) {
    String explainedMessage = explainException(err);
    if (explainedMessage.isEmpty) {
      throw Exception(err);
    } else {
      throw Exception('ore_$explainedMessage');
    }
  }
}

Future<dynamic> pullActiveMeterCountHistory(
    PaGridAppConfig appConfig, SvcClaim svcClaim) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetActiveMeterCountHistory;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(
  //     svcClaim, /*, user*/
  //   );
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(UrlController(appConfig)
        .getUrl(SvcType.oresvc, UrlBase.eptGetActiveMeterCountHistory)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, <String, String>{
      'days': '14',
    }).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);
    final info = responseBody['info'];
    if (info != null) {
      if (info.contains("Empty")) {
        String durationText = getReadableDuration(const Duration(days: 14));
        throw Exception("No history data found in the last $durationText");
      }
    }
    final meterReadingHistoryJson =
        responseBody[Evs2HistoryType.active_meter_count_history.name];
    List<Map<String, String>> meterReadingHistory = [];
    for (var meterReading in meterReadingHistoryJson) {
      meterReadingHistory.add({
        'timestamp': meterReading['timestamp'],
        'count': meterReading['count'].toString(),
      });
    }
    return meterReadingHistory;
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> getRecentUsage(
  PaGridAppConfig appConfig,
  DestPortal destPortal,
  Map<String, dynamic> queryMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetActiveKwhConsumption;
  if (destPortal == DestPortal.emstp) {
    svcClaim.endpoint = UrlBase.eptTenantGetActiveUsage;
  }

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(
  //     svcClaim, /*, user*/
  //   );
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
      // body: jsonEncode(SvcQuery(svcClaim, <String, String>{
      //   'project_scope': projectScope == null ? '' : projectScope.name,
      //   'site_scope': siteScope == null ? '' : siteScope.name,
      // }).toJson()),
      body: jsonEncode(SvcQuery(svcClaim, queryMap).toJson()),
    );
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response, parse the JSON.
      final responseBody = jsonDecode(response.body);
      final info = responseBody['info'];
      if (info != null) {
        throw Exception(info);
      }
      final error = responseBody['error'];
      if (error != null) {
        throw Exception(error);
      }
      final kwhConsumption = responseBody['active_usage'];
      return kwhConsumption;
    } else if (response.statusCode == 403) {
      throw Exception("You are not authorized to perform this operation");
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  } catch (err) {
    // String explainedMessage = explainException(err);
    // if (explainedMessage.isEmpty) {
    //   throw Exception(err);
    // } else {
    //   throw Exception('ore_$explainedMessage');
    // }
    rethrow;
  }
}

Future<dynamic> pullActiveUsageHistory(
  PaGridAppConfig appConfig,
  SvcClaim svcClaim,
  ProjectScope? projectScope,
  SiteScope? siteScope,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetAcitveUsageHistory;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(
  //     svcClaim, /*, user*/
  //   );
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(UrlController(appConfig)
        .getUrl(SvcType.oresvc, UrlBase.eptGetAcitveUsageHistory)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, <String, String>{
      'days': '14',
      'project_scope': projectScope == null ? '' : projectScope.name,
      'site_scope': siteScope == null ? '' : siteScope.name,
    }).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);
    final info = responseBody['info'];
    if (info != null) {
      if (info.contains("Empty")) {
        String durationText = getReadableDuration(const Duration(days: 14));
        throw Exception("No history data found in the last $durationText");
      }
    }
    final meterReadingHistoryJson =
        responseBody[Evs2HistoryType.active_kwh_consumption_history.name];
    List<Map<String, dynamic>> meterReadingHistory = [];
    for (var meterReading in meterReadingHistoryJson) {
      double kwh = double.parse(meterReading['total_kwh']);
      bool errorData = kwh < 0 || kwh > /*200*/ 2000;
      meterReadingHistory.add({
        'timestamp': meterReading['timestamp'],
        'total_kwh': errorData ? '0' : meterReading['total_kwh'].toString(),
        'error_data': errorData ? kwh.toString() : '',
      });
    }
    return meterReadingHistory;
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> getRecentTopupTotal(
  PaGridAppConfig appConfig,
  SvcClaim svcClaim,
  ProjectScope? projectScope,
  SiteScope? siteScope,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetRecentTotalTopup;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(
  //     svcClaim, /*, user*/
  //   );
  // } catch (err) {
  //   throw Exception(err);
  // }

  try {
    final response = await http.post(
      Uri.parse(UrlController(appConfig)
          .getUrl(SvcType.oresvc, UrlBase.eptGetRecentTotalTopup)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(SvcQuery(svcClaim, <String, String>{
        'project_scope': projectScope == null ? '' : projectScope.name,
        'site_scope': siteScope == null ? '' : siteScope.name,
      }).toJson()),
    );
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response, parse the JSON.
      final responseBody = jsonDecode(response.body);
      final info = responseBody['info'];
      if (info != null) {
        throw Exception(info);
      }
      final error = responseBody['error'];
      if (error != null) {
        throw Exception(error);
      }
      final totalTopup = responseBody['total_topup'];
      return totalTopup;
    } else if (response.statusCode == 403) {
      throw Exception("You are not authorized to perform this operation");
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  } catch (err) {
    String explainedMessage = explainException(err);
    if (explainedMessage.isEmpty) {
      throw Exception(err);
    } else {
      throw Exception('ore_$explainedMessage');
    }
  }
}

Future<dynamic> pullTotalTopupHistory(
  PaGridAppConfig appConfig,
  SvcClaim svcClaim,
  ProjectScope? projectScope,
  SiteScope? siteScope,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetTotalTopupHistory;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(
  //     svcClaim, /*, user*/
  //   );
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(UrlController(appConfig)
        .getUrl(SvcType.oresvc, UrlBase.eptGetTotalTopupHistory)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, <String, String>{
      'days': '14',
      'project_scope': projectScope == null ? '' : projectScope.name,
      'site_scope': siteScope == null ? '' : siteScope.name,
    }).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);
    final info = responseBody['info'];
    if (info != null) {
      if (info.contains("Empty")) {
        String durationText = getReadableDuration(const Duration(days: 14));
        throw Exception("No history data found in the last $durationText");
      }
    }
    final meterReadingHistoryJson =
        responseBody[Evs2HistoryType.total_topup_history.name];
    if (meterReadingHistoryJson == null) {
      throw Exception("No history data");
    }
    List<Map<String, dynamic>> meterReadingHistory = [];
    for (var meterReading in meterReadingHistoryJson) {
      // double kwh = double.parse(meterReading['topup_total']);
      // bool errorData = kwh < 0 || kwh > 100;
      bool errorData = false;
      meterReadingHistory.add({
        'timestamp': meterReading['timestamp'],
        'total_topup': errorData ? '0' : meterReading['total_topup'].toString(),
        // 'error_data': errorData ? kwh.toString() : '',
      });
    }
    return meterReadingHistory;
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> getRecentCommDataUsage(
    PaGridAppConfig appConfig, SvcClaim svcClaim) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptCommDataGetRecentComsumption;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(
  //     svcClaim, /*, user*/
  //   );
  // } catch (err) {
  //   throw Exception(err);
  // }

  try {
    final response = await http.post(
      Uri.parse(UrlController(appConfig)
          .getUrl(SvcType.oresvc, UrlBase.eptCommDataGetRecentComsumption)),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $svcToken',
      },
      body: jsonEncode(SvcQuery(svcClaim, <String, String>{}).toJson()),
    );
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response, parse the JSON.
      final responseBody = jsonDecode(response.body);
      final info = responseBody['info'];
      if (info != null) {
        throw Exception(info);
      }
      final error = responseBody['error'];
      if (error != null) {
        throw Exception(error);
      }
      final commDataConsumption = responseBody['total_data'];
      return commDataConsumption;
    } else if (response.statusCode == 403) {
      throw Exception("You are not authorized to perform this operation");
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  } catch (err) {
    String explainedMessage = explainException(err);
    if (explainedMessage.isEmpty) {
      throw Exception(err);
    } else {
      throw Exception('ore_$explainedMessage');
    }
  }
}

Future<dynamic> pullKwhUsageByBuilding(
  PaGridAppConfig appConfig,
  Map<String, dynamic> queryMap,
  SvcClaim svcClaim,
) async {
  /*User queryByUser*/

  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetTopKwhUsageByBuilding;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(
  //     svcClaim, /*, user*/
  //   );
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(UrlController(appConfig)
        .getUrl(SvcType.oresvc, UrlBase.eptGetTopKwhUsageByBuilding)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    // body: jsonEncode(SvcQuery(svcClaim, <String, String>{
    //   'tops': '10',
    // }).toJson()),
    body: jsonEncode(SvcQuery(svcClaim, queryMap).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);
    final info = responseBody['info'];
    if (info != null) {
      if (info.contains("Empty")) {
        String durationText = getReadableDuration(const Duration(days: 14));
        throw Exception("No history data found in the last $durationText");
      }
    }
    final meterReadingHistoryJson = responseBody['top_usage_by_building'];
    List<Map<String, dynamic>> topBuildings = [];
    for (var buidlingUsage in meterReadingHistoryJson) {
      double valTotal = buidlingUsage['val_total'];
      bool errorData = valTotal < 0 || valTotal > 1000000000;
      topBuildings.add({
        'item_id_col_name': buidlingUsage['item_id_col_name'],
        'val_total': errorData ? 0.0 : buidlingUsage['val_total'],
        'building_id': buidlingUsage['building_id'],
        'building': buidlingUsage['building'],
        'block': buidlingUsage['block'],
        'top_meters': buidlingUsage['top_meter_usage'],
        'error_data': errorData ? valTotal.toString() : '',
      });
    }
    return topBuildings;
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> pullMonthToDateCommDataUsageStat(
    PaGridAppConfig appConfig, SvcClaim svcClaim) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptCommDataGetMonthToDateUsageTotal;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(
  //     svcClaim, /*, user*/
  //   );
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(UrlController(appConfig)
        .getUrl(SvcType.oresvc, UrlBase.eptCommDataGetMonthToDateUsageTotal)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, <String, String>{
      'tops': '10',
    }).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);
    final info = responseBody['info'];
    if (info != null) {
      if (info.contains("Empty")) {
        String durationText = getReadableDuration(const Duration(days: 14));
        throw Exception("No history data found in the last $durationText");
      }
    }
    final mtdUsage = responseBody['month_to_date_usage'];
    List<Map<String, dynamic>> activeMeters = [];
    List<Map<String, dynamic>> inactiveMeters = [];
    for (var meter in mtdUsage['active_meters']) {
      activeMeters.add({
        'active': true,
        'meter_sn': meter['meter_sn'],
        'data_bal': meter['data_bal'],
        'data_bal_ini': meter['data_bal_ini'],
        'concentrator_id': meter['concentrator_id'],
        'building_id': meter['building_id'] ?? '',
        'building': meter['building'] ?? '',
        'block': meter['block'] ?? '',
        'level': meter['level'] ?? '',
      });
    }
    for (var meter in mtdUsage['inactive_meters']) {
      inactiveMeters.add({
        'active': false,
        'meter_sn': meter['meter_sn'],
        'data_bal': meter['data_bal'],
        'data_bal_ini': meter['data_bal_ini'],
        'concentrator_id': meter['concentrator_id'],
        'building_id': meter['building_id'] ?? '',
        'building': meter['building'] ?? '',
        'block': meter['block'] ?? '',
        'level': meter['level'] ?? '',
      });
    }
    final usageRateProfile = mtdUsage['usage_rate_profile'];
    List<Map<String, dynamic>> usageRateProfileList = [];
    for (var usageRate in usageRateProfile['profile']) {
      usageRateProfileList.add({
        'min': usageRate['min'],
        'max': usageRate['max'],
        'count': usageRate['count'],
      });
    }
    Map<String, dynamic> mtdUsageMap = {
      'total_usage': mtdUsage['total_usage'],
      'total_package_ini': mtdUsage['total_package_ini'],
      'total_meter_count': mtdUsage['total_meter_count'],
      'active_meters': activeMeters,
      'inactive_meters': inactiveMeters,
      'usage_rate_profile': usageRateProfileList,
    };
    return mtdUsageMap;
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> getRecentUsageHistory(
  PaGridAppConfig appConfig,
  Map<String, dynamic> queryMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetAllUsageHistory;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(
  //     svcClaim, /*, user*/
  //   );
  // } catch (err) {
  //   throw Exception(err);
  // }

  final response = await http.post(
    Uri.parse(UrlController(appConfig)
        .getUrl(SvcType.oresvc, UrlBase.eptGetAllUsageHistory)),
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
        String durationText = getReadableDuration(const Duration(days: 14));
        throw Exception("No history data found in the last $durationText");
      }
    }
    final allUsageHistoryJson = responseBody['all_usage_history'];
    // List<Map<String, dynamic>> allUsageHistory = [];
    // for (var preiodUsage in allUsageHistoryJson) {
    //   allUsageHistory.add({
    //     'from_timestamp': preiodUsage['from_timestamp'],
    //     'to_timestamp': preiodUsage['to_timestamp'],
    //     'usage': preiodUsage['usage'],
    //   });
    // }
    return allUsageHistoryJson;
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}
