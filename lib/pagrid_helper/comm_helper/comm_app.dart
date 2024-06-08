import 'dart:convert';

import 'package:buff_helper/pagrid_helper/comm_helper/be_api_base.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:http/http.dart' as http;

import '../app_helper/pagrid_app_config.dart';

Future<dynamic> getVersion(PaGridAppConfig appConfig, String appName) async {
  String projectScope = appConfig.activePortalProjectScope.name;
  if (projectScope == 'SG_ALL') {
    // projectScope = 'EVS2_NUS';
  }
  try {
    final response = await http.get(
      Uri.parse(
          '${UrlController(appConfig).getUrl(SvcType.oresvc, UrlBase.eptGetVerion)}/$appName/$projectScope'),
    );

    if (response.statusCode == 200) {
      final respJson = jsonDecode(response.body);
      return respJson['version'] ?? '';
    } else {
      throw Exception('Failed to load version');
    }
  } catch (err) {
    return err.toString();
  }
}

Future<dynamic> getOreVersion(PaGridAppConfig appConfig) async {
  try {
    final response = await http.get(
      Uri.parse(
          UrlController(appConfig).getUrl(SvcType.oresvc, UrlBase.eptOreHello)),
    );

    if (response.statusCode == 200) {
      // final respJson = jsonDecode(response.body);
      String respJson = response.body;
      return respJson;
    } else {
      throw Exception('ORE handshake failed');
    }
  } catch (err) {
    return err.toString();
  }
}

Future<dynamic> getSysVar(
  PaGridAppConfig appConfig,
  Map<String, dynamic> queryMap,
  SvcClaim svcClaim,
) async {
  svcClaim.svcName = SvcType.oresvc.name;
  svcClaim.endpoint = UrlBase.eptGetSysVar;
  String svcToken = '';
  // try {
  //   svcToken = await svcGate(svcClaim /*, queryByUser*/);
  // } catch (err) {
  //   throw Exception(err);
  // }
  final response = await http.post(
    Uri.parse(
        UrlController(appConfig).getUrl(SvcType.oresvc, UrlBase.eptGetSysVar)),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $svcToken',
    },
    body: jsonEncode(SvcQuery(svcClaim, queryMap).toJson()),
  );

  try {
    if (response.statusCode == 200) {
      final respJson = jsonDecode(response.body);
      if (respJson['value'] == null) {
        throw Exception('No system variable found');
      }
      return respJson['value'];
    } else {
      throw Exception('Failed to load system variable');
    }
  } catch (err) {
    return err.toString();
  }
}
