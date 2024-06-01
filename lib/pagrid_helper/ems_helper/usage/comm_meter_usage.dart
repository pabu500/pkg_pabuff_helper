import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../comm_helper/be_api_base.dart';

Future<dynamic> queryMeterUsageSummary(
  ProjectScope activePortalProjectScope,
  Map<String, String> queryMap,
  Duration duration,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetMeterListUsageSummary;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  UrlController urlController = UrlController(activePortalProjectScope);

  final response = await http.post(
    Uri.parse(urlController.getUrl(
        SvcType.oresvc, UrlBase.eptGetMeterListUsageSummary)),
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
    final summaryListJson =
        responseBody[Evs2HistoryType.meter_list_usage_summary.name];
    final totalCount = responseBody['total_count'];
    List<Map<String, dynamic>> summaryList = [];
    for (var item in summaryListJson) {
      if ((item['commissioned_timestamp'] ?? '').isNotEmpty) {
        DateTime commissionedTimestamp =
            DateTime.parse(item['commissioned_timestamp']);

        DateTime? firstReadingTime =
            DateTime.tryParse(item['first_reading_time']);
        bool useCommissionedDatetime =
            item['use_commissioned_datetime'] ?? false;
        if (useCommissionedDatetime) {
          item['first_reading_time_color'] =
              getOpLifecycleStatusColor('normal');
          item['first_reading_time_tooltip'] =
              'using commssion date: ${item['commissioned_timestamp']}';
        } else {
          if (firstReadingTime != null) {
            if (firstReadingTime.isBefore(commissionedTimestamp)) {
              item['first_reading_time_color'] =
                  getOpLifecycleStatusColor('cip');
              item['first_reading_time_tooltip'] =
                  'before commssion date: ${item['commissioned_timestamp']}';
            }
          }
        }
        DateTime? lastReadingTime =
            DateTime.tryParse(item['last_reading_time']);
        if (lastReadingTime != null) {
          if (lastReadingTime.isBefore(commissionedTimestamp)) {
            item['last_reading_time_color'] = getOpLifecycleStatusColor('cip');
            item['last_reading_time_tooltip'] =
                'before commssion: ${item['commissioned_timestamp']}';
          }
        }
      }
      summaryList.add(item);
    }

    return {
      Evs2HistoryType.meter_list_usage_summary.name: summaryList,
      'total_count': totalCount,
    };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> queryMeterConsolidatedUsageHistory(
  ProjectScope activePortalProjectScope,
  Map<String, String> queryMap,
  Duration duration,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetMeterListConsolidatedUsageHistory;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  UrlController urlController = UrlController(activePortalProjectScope);

  final response = await http.post(
    Uri.parse(urlController.getUrl(
        SvcType.oresvc, UrlBase.eptGetMeterListConsolidatedUsageHistory)),
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
    final historyListJson = responseBody[
        Evs2HistoryType.meter_list_consolidated_usage_history.name];
    List<Map<String, dynamic>> meterListHistory = [];
    for (var meterHistory in historyListJson) {
      String meterId = meterHistory['meter_id'];
      String meterIdType = meterHistory['meter_id_type'];
      String interval = meterHistory['interval'];
      List<Map<String, dynamic>> historyList = [];
      for (var item in meterHistory['meter_usage_history']) {
        historyList.add(item);
      }
      meterListHistory.add({
        'meter_id': meterId,
        'meter_id_type': meterIdType,
        'interval': interval,
        'history': historyList,
      });
    }

    return {
      Evs2HistoryType.meter_list_consolidated_usage_history.name:
          meterListHistory,
    };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}
