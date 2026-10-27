import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../model/acl/mdl_pag_svc_claim.dart';
import '../model/mdl_pag_app_config.dart';
import '../model/mdl_pag_user.dart';
import '../model/mdl_svc_query.dart';
import 'comm_helper.dart';
import 'pag_be_api_base.dart';

const defaultProjectConsoleDisabledMessage =
    'Console access for this project is currently disabled. Please contact your System Admin.';

class PagConsoleSettingsException implements Exception {
  const PagConsoleSettingsException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}

class PagProjectConsoleSetting {
  const PagProjectConsoleSetting({
    required this.projectId,
    required this.projectName,
    required this.projectLabel,
    required this.enabled,
    required this.revision,
    this.disabledMessage = defaultProjectConsoleDisabledMessage,
    this.lifecycleStatus,
  });

  factory PagProjectConsoleSetting.fromJson(Map<String, dynamic> json) {
    final enabled = json['enable_project_console'];
    if (enabled is! bool ||
        json['project_name'] is! String ||
        (json['disabled_message'] != null &&
            json['disabled_message'] is! String)) {
      throw const FormatException('Invalid project settings response');
    }
    return PagProjectConsoleSetting(
      projectId: _integer(json['project_id'], minimum: 1),
      projectName: json['project_name'] as String,
      projectLabel: json['project_label'] as String? ?? '',
      enabled: enabled,
      revision: _integer(json['revision']),
      disabledMessage:
          json['disabled_message'] as String? ??
          defaultProjectConsoleDisabledMessage,
      lifecycleStatus: json['lc_status'] as String?,
    );
  }

  final int projectId;
  final String projectName;
  final String projectLabel;
  final String? lifecycleStatus;
  final bool enabled;
  final int revision;
  final String disabledMessage;

  PagProjectConsoleSetting copyWith({
    bool? enabled,
    int? revision,
    String? disabledMessage,
  }) => PagProjectConsoleSetting(
    projectId: projectId,
    projectName: projectName,
    projectLabel: projectLabel,
    lifecycleStatus: lifecycleStatus,
    enabled: enabled ?? this.enabled,
    revision: revision ?? this.revision,
    disabledMessage: disabledMessage ?? this.disabledMessage,
  );
}

Future<List<PagProjectConsoleSetting>> getConsoleProjectSettings({
  required MdlPagAppConfig appConfig,
  required MdlPagUser user,
}) async {
  final result = await _request(appConfig, user, '/console/get_settings', {
    'section': 'platform',
  });
  if (result is! List) {
    throw const FormatException('Invalid project settings response');
  }
  return result
      .map(
        (row) => PagProjectConsoleSetting.fromJson(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<PagProjectConsoleSetting> updateConsoleProjectSetting({
  required MdlPagAppConfig appConfig,
  required MdlPagUser user,
  required PagProjectConsoleSetting setting,
  required bool enabled,
  String? disabledMessage,
}) async {
  final message = (disabledMessage ?? setting.disabledMessage).trim();
  if (message.isEmpty ||
      message.runes.length > 500 ||
      message.contains('\u0000')) {
    throw const PagConsoleSettingsException(
      'Enter a message between 1 and 500 characters.',
    );
  }
  final result = await _request(appConfig, user, '/console/update_settings', {
    'project_id': setting.projectId,
    'section': 'platform',
    'expected_revision': setting.revision,
    'settings_value': {
      'schema_version': 1,
      'enable_project_console': enabled,
      'disabled_message': message,
    },
  });
  if (result is! Map ||
      _integer(result['project_id'], minimum: 1) != setting.projectId ||
      result['enable_project_console'] is! bool ||
      result['enable_project_console'] != enabled ||
      result['disabled_message'] != message ||
      _integer(result['revision']) != setting.revision + 1) {
    throw const FormatException('Invalid saved project settings response');
  }
  return setting.copyWith(
    enabled: result['enable_project_console'] as bool,
    revision: _integer(result['revision']),
    disabledMessage: result['disabled_message'] as String,
  );
}

Future<dynamic> _request(
  MdlPagAppConfig appConfig,
  MdlPagUser user,
  String endpoint,
  Map<String, dynamic> query,
) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'pag_user_token');
  if (token == null || token.isEmpty) {
    throw const PagConsoleSettingsException(
      'Please sign in again',
      statusCode: 401,
    );
  }
  final claim = MdlPagSvcClaim(
    userId: user.id,
    username: user.username,
    roleId: user.selectedRole?.id,
    svcName: PagSvcType.oresvc2.name,
    endpoint: endpoint,
  );
  final http.Response response;
  try {
    response = await http.post(
      Uri.parse(
        PagUrlController(null, appConfig).getUrl(PagSvcType.oresvc2, endpoint),
      ),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(MdlPagSvcQuery(claim, query).toJson()),
    );
  } on http.ClientException {
    throw const PagConsoleSettingsException(
      'Cannot connect to console settings. Please try again.',
    );
  }
  if (response.statusCode != 200) {
    var message = 'Unable to load or save console settings. Please try again.';
    try {
      final body = jsonDecode(response.body);
      final error = body is Map ? body['error'] : null;
      if (error is Map && error['message'] is String) {
        message = error['message'] as String;
      }
    } on FormatException {
      // Proxies may return a non-JSON error page.
    }
    throw PagConsoleSettingsException(message, statusCode: response.statusCode);
  }
  return getResultFromResp(response.body);
}

int _integer(Object? value, {int minimum = 0}) {
  final text = value?.toString() ?? '';
  final parsed = RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(text)
      ? int.tryParse(text)
      : null;
  if (parsed == null || parsed < minimum) {
    throw const FormatException('Invalid project settings number');
  }
  return parsed;
}
