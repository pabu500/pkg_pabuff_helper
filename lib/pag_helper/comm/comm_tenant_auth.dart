import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../model/acl/mdl_pag_svc_claim.dart';
import '../model/mdl_pag_app_config.dart';
import '../model/mdl_pag_user.dart';
import '../model/mdl_svc_query.dart';
import 'comm_helper.dart';
import 'pag_be_api_base.dart';

/// The server verifies the signature and binds the token subject to the claim.
Future<Map<String, String>> tenantOperationHeaders(
  MdlPagSvcClaim claim, {
  MdlPagUser? user,
}) async {
  if (user?.resetPasswordToken == 'flag_reset') {
    throw Exception('Please sign in again');
  }
  final token =
      user?.loginToken ??
      await const FlutterSecureStorage().read(key: 'pag_user_token');
  if (token == null || token.trim().isEmpty) {
    throw Exception('Please sign in again');
  }
  if (user != null) {
    claim.username = user.username;
    claim.userId = user.id;
    claim.roleId = user.selectedRole?.id;
  } else if (claim.username == null || claim.username!.isEmpty) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Please sign in again');
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    claim.username = payload['sub'] as String?;
  }
  claim.userId ??= 0;
  return {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $token',
  };
}

Future<Map<String, dynamic>> getTenantLcTransitionCheck(
  MdlPagAppConfig appConfig,
  MdlPagUser user,
  Map<String, dynamic> query,
) async {
  const endpoint = '/ems/tenant/get_tenant_lc_transition_check';
  final claim = MdlPagSvcClaim(
    svcName: PagSvcType.oresvc2.name,
    endpoint: endpoint,
  );
  final headers = await tenantOperationHeaders(claim, user: user);
  final response = await http.post(
    Uri.parse(
      PagUrlController(user, appConfig).getUrl(PagSvcType.oresvc2, endpoint),
    ),
    headers: headers,
    body: jsonEncode(MdlPagSvcQuery(claim, query).toJson()),
  );
  return Map<String, dynamic>.from(getResultFromResp(response.body) as Map);
}
