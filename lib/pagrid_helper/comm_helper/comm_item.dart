import 'package:buff_helper/up_helper/up_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../app_helper/pagrid_app_config.dart';
import 'be_api_base.dart';

Future<dynamic> doCheckUnique(
    PaGridAppConfig appConfig, String field, String val, String table) async {
  try {
    //use query string instead of path
    UrlController urlController = UrlController(appConfig);

    final response = await http.get(
      Uri.parse(
          '${urlController.getUrl(SvcType.oresvc, UrlBase.eptOreCheckExists2)}?t=$table&field=$field&val=$val'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check unique.');
    }
  } catch (err) {
    return err.toString();
  }
}

Future<dynamic> doListItems(
  PaGridAppConfig appConfig,
  Map<String, dynamic> queryMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptListItems;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  UrlController urlController = UrlController(appConfig);

  final response = await http.post(
    Uri.parse(urlController.getUrl(SvcType.oresvc, UrlBase.eptListItems)),
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
        throw Exception("No meter record found");
      }
    }
    final itemListJson = responseBody['item_list'];
    final totalCount = responseBody['total_count'];
    final idSelectQuery = responseBody['id_select_query'];
    List<Map<String, dynamic>> itemList = [];
    if (itemListJson != null) {
      for (var item in itemListJson) {
        // if (item['can_cutoff'] != null) {
        //   item['can_cutoff'] = item['can_cutoff'] == '1';
        // }
        itemList.add(item);
      }
    }
    return {
      'item_list': itemList,
      'total_count': totalCount,
      'id_select_query': idSelectQuery,
      'query_map': queryMap,
    };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> getItemInfo(
  PaGridAppConfig appConfig,
  Map<String, String> queryMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetItemInfo;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  UrlController urlController = UrlController(appConfig);

  final response = await http.post(
    Uri.parse(urlController.getUrl(SvcType.oresvc, UrlBase.eptGetItemInfo)),
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
        throw Exception("No item record found");
      }
    }
    if (responseBody['item_info'] == null) {
      throw Exception("No item record found");
    }
    return responseBody['item_info'];
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> doCheckItemSnIwow(
  PaGridAppConfig appConfig,
  String meterName,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetItemSnIwow;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  UrlController urlController = UrlController(appConfig);

  final response = await http.post(
    Uri.parse(urlController.getUrl(SvcType.oresvc, UrlBase.eptGetItemSnIwow)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, {'item_name': meterName}).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);
    final info = responseBody['info'];
    if (info != null) {
      if (info.contains("Empty")) {
        throw Exception("No item record found");
      }
    }
    if (responseBody['item_sn'] == null) {
      throw Exception("No item record found");
    }
    return responseBody;
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}

Future<dynamic> pullItemLastReading(
  PaGridAppConfig appConfig,
  Map<String, String> queryMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptPullItemLastReading;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }

  UrlController urlController = UrlController(appConfig);
  try {
    final response = await http.post(
      Uri.parse(
          urlController.getUrl(SvcType.oresvc, UrlBase.eptPullItemLastReading)),
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
          throw Exception("No meter record found");
        }
      }
      if (responseBody['last_reading'] == null) {
        throw Exception("No item reading found");
      }
      return responseBody['last_reading'];
    } else if (response.statusCode == 403) {
      throw Exception("You are not authorized to perform this operation");
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  } catch (err) {
    rethrow;
  }
}

Future<dynamic> pullItemHistory(PaGridAppConfig appConfig,
    Map<String, dynamic> queryMap, SvcClaim svcClaim) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetTargetHistory;

  String svcToken = '';
  // try {
  //   svcToken = await svcGate(
  //     svcClaim, /*, user*/
  //   );
  // } catch (err) {
  //   throw Exception(err);
  // }

  UrlController urlController = UrlController(appConfig);

  final response = await http.post(
    Uri.parse(
        urlController.getUrl(SvcType.oresvc, UrlBase.eptGetTargetHistory)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, queryMap).toJson()),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response, parse the JSON.
    final responseBody = jsonDecode(response.body);
    if (queryMap['get_count_only'] != null) {
      return {
        'total_count': responseBody['total_count'],
      };
    }

    final info = responseBody['info'];
    if (info != null) {
      if (info.contains("Empty")) {
        // String durationText = getReadableDuration(duration);
        // throw Exception("empty history data between $startDate and $endDate");
        return {
          'history': [],
          'metas': {},
          'time_range': responseBody['time_range'],
        };
      }
    }
    final meterReadingHistoryJson = responseBody[queryMap['history_type']];
    final timeRange = responseBody['time_range'];
    final meterReadingHistory = meterReadingHistoryJson['history'];
    final meterReadingHistory2 = meterReadingHistoryJson['history2'];
    final meterReadingHistoryMeta = meterReadingHistoryJson['meta'];
    final meterReadingHistoryMetas = meterReadingHistoryJson['metas'];
    // final timeRange = meterReadingHistoryJson['time_range'];

    return {
      'history': meterReadingHistory ?? meterReadingHistory2,
      'metas': meterReadingHistoryMetas ?? {'total': meterReadingHistoryMeta},
      'time_range': timeRange,
    };
  } else if (response.statusCode == 403) {
    throw Exception("You are not authorized to perform this operation");
  } else {
    throw Exception(jsonDecode(response.body)['error']);
  }
}
