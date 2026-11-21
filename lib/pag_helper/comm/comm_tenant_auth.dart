import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../model/acl/mdl_pag_svc_claim.dart';
import '../model/mdl_pag_app_config.dart';
import '../model/mdl_pag_user.dart';
import '../model/mdl_svc_query.dart';
import 'comm_helper.dart';
import 'pag_be_api_base.dart';

class SessionExpiredException implements Exception {
  const SessionExpiredException({this.handled = false});
  final bool handled;
  @override
  String toString() => 'm:Your session has expired. Please sign in again.';
}

Map<String, dynamic> loginTokenClaims(String? token) {
  try {
    final parts = token?.split('.');
    if (parts == null || parts.length != 3) {
      throw const SessionExpiredException();
    }
    return Map<String, dynamic>.from(
      jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
          as Map,
    );
  } catch (_) {
    throw const SessionExpiredException();
  }
}

/// Checks the credential selected for this request. Renewal is owned by the console.
Future<Map<String, String>> tenantOperationHeaders(
  MdlPagSvcClaim claim, {
  MdlPagUser? user,
}) async {
  await user?.ensureLoginSession?.call();
  if (user?.resetPasswordToken == 'flag_reset') {
    throw const SessionExpiredException();
  }
  final token = user != null
      ? user.loginToken
      : await const FlutterSecureStorage().read(key: 'pag_user_token');
  if (token == null || token.trim().isEmpty) {
    throw const SessionExpiredException();
  }
  final payload = loginTokenClaims(token);
  if (payload['sub'] is! String || (payload['sub'] as String).isEmpty) {
    throw const SessionExpiredException();
  }
  final username = user?.username ?? claim.username ?? payload['sub'];
  if (payload['sub'] != username) throw const SessionExpiredException();
  if (user != null) {
    claim.username = user.username;
    claim.userId = user.id;
    claim.roleId = user.selectedRole?.id;
  } else {
    claim.username = username as String?;
  }
  claim.userId ??= 0;
  return {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $token',
  };
}

/// A guard rejection ends the session without replaying the operation.
Future<http.Response> sendTenantOperation(
  MdlPagSvcClaim claim,
  MdlPagUser? user,
  Future<http.Response> Function(Map<String, String> headers) send,
) async {
  final headers = await tenantOperationHeaders(claim, user: user);
  // Keep the session handler for requests still in flight when logout clears it.
  final onExpired = user?.onSessionExpired;
  final response = await send(headers);
  if (_isTenantGuardRejection(response)) {
    await onExpired?.call();
    throw SessionExpiredException(handled: onExpired != null);
  }
  return response;
}

bool _isTenantGuardRejection(http.Response response) {
  if (response.statusCode != 401) return false;
  try {
    final body = jsonDecode(response.body);
    return body is Map &&
        body['error'] is Map &&
        body['error']['message'] == 'Please sign in again';
  } catch (_) {
    return false;
  }
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
  final response = await sendTenantOperation(
    claim,
    user,
    (headers) => http.post(
      Uri.parse(
        PagUrlController(user, appConfig).getUrl(PagSvcType.oresvc2, endpoint),
      ),
      headers: headers,
      body: jsonEncode(MdlPagSvcQuery(claim, query).toJson()),
    ),
  );
  return Map<String, dynamic>.from(getResultFromResp(response.body) as Map);
}

/// Keep conversion errors readable without changing shared transport exceptions.
String previousSystemDebtorErrorText(Object? error) {
  if (error is Map) {
    return previousSystemDebtorErrorText(error['message'] ?? error['error']);
  }
  final text = (error is StateError ? error.message : error?.toString() ?? '')
      .trim()
      .replaceFirst(RegExp(r'^(?:(?:Exception:|Bad state:|m:|q:)\s*)+'), '')
      .trim();
  return text.isEmpty ? 'Conversion failed' : text;
}

Future<Map<String, dynamic>> convertPreviousSystemDebtor(
  MdlPagAppConfig appConfig,
  MdlPagUser user,
  Map<String, dynamic> query,
) async {
  const endpoint = '/ems/tenant/convert_previous_system_debtor';
  final claim = MdlPagSvcClaim(
    svcName: PagSvcType.oresvc2.name,
    endpoint: endpoint,
  );
  final response = await sendTenantOperation(
    claim,
    user,
    (headers) => http.post(
      Uri.parse(
        PagUrlController(user, appConfig).getUrl(PagSvcType.oresvc2, endpoint),
      ),
      headers: headers,
      body: jsonEncode(MdlPagSvcQuery(claim, query).toJson()),
    ),
  );
  final result = Map<String, dynamic>.from(
    getResultFromResp(response.body) as Map,
  );
  return Map<String, dynamic>.from(
    result['previous_system_debtor'] as Map? ?? result,
  );
}

Future<Map<String, dynamic>> reopenTenant(
  MdlPagAppConfig appConfig,
  MdlPagUser user,
  Map<String, dynamic> query,
) async {
  const endpoint = '/ems/tenant/reopen_tenant';
  final claim = MdlPagSvcClaim(
    svcName: PagSvcType.oresvc2.name,
    endpoint: endpoint,
  );
  final response = await sendTenantOperation(
    claim,
    user,
    (headers) => http.post(
      Uri.parse(
        PagUrlController(user, appConfig).getUrl(PagSvcType.oresvc2, endpoint),
      ),
      headers: headers,
      body: jsonEncode(MdlPagSvcQuery(claim, query).toJson()),
    ),
  );
  return Map<String, dynamic>.from(getResultFromResp(response.body) as Map);
}
