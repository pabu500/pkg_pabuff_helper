import 'package:flutter/material.dart';

enum comm_tasks { login, register, forgotPassword }

enum AllowServiceEmail { yes, no }

String? getAllowServiceEmailValueStr(String? statusStr) {
  if ((statusStr ?? '').isEmpty) {
    return null;
  }
  AllowServiceEmail? status = getAllowServiceEmail(statusStr);

  return status.name;
}

AllowServiceEmail getAllowServiceEmail(String? statusStr) {
  if (statusStr == null || statusStr.isEmpty) {
    return AllowServiceEmail.no;
  }
  if (statusStr == '-') {
    return AllowServiceEmail.no;
  }
  switch (statusStr) {
    case 'yes':
      return AllowServiceEmail.yes;
    default:
      return AllowServiceEmail.no;
  }
}

String? errorFilter(String? err, comm_tasks task) {
  if (err == null) return null;

  if (err.length < 13) return err;

  String? _err;

  if (err.contains('retrieving user')) {
    _err = 'Error retriving user info';
    if (task == comm_tasks.login) _err = 'Invalid username or password';
  } else if (err.contains('Bad credentials')) {
    _err = 'Invalid username or password';
  } else if (err.contains('portal')) {
    _err = 'Incorrect portal';
  } else if (err.contains('scope')) {
    _err = 'Error getting scope info';
  } else {
    _err = 'Service Error';
  }

  return _err;
}

enum AuthProvider {
  local,
  google,
  facebook,
  apple,
  microsoft,
}

Map<String, dynamic> getAuthProviderTag(row, fieldKey) {
  if ((row['auth_provider'] ?? '').isEmpty) {
    return {};
  }
  if (row['auth_provider'] == '-') {
    return {};
  }
  String valueStr = row['auth_provider'].toString().toLowerCase();
  AuthProvider? status = AuthProvider.values.byName(valueStr);
  // if (status == AuthProvider.local) {
  //   return {};
  // }

  return {
    'tag': getAuthProviderTagStr(valueStr),
    'color': getAuthProviderColor(status.name),
    'tooltip': getAuthProviderMessage(status.name),
  };
}

String getAuthProviderTagStr(String? statusStr) {
  if (statusStr == null) {
    return 'N/A';
  }
  AuthProvider? status = AuthProvider.values.byName(statusStr);

  return authProviderInfo[status]!['tag'];
}

String getAuthProviderMessage(String? statusStr) {
  if (statusStr == null) {
    return 'N/A';
  }
  AuthProvider? status = AuthProvider.values.byName(statusStr);

  return authProviderInfo[status]!['tooltip'];
}

Color getAuthProviderColor(String? statusStr) {
  if (statusStr == null || statusStr.isEmpty) {
    return Colors.transparent;
  }
  AuthProvider? status = AuthProvider.values.byName(statusStr);

  return authProviderInfo[status]!['color'];
}

final Map<AuthProvider, dynamic> authProviderInfo = {
  AuthProvider.local: {
    'tag': 'local',
    'color': Colors.teal.withOpacity(0.7),
    'tooltip': 'Local User',
  },
  AuthProvider.microsoft: {
    'tag': 'MS',
    'color': Colors.orangeAccent.withOpacity(0.5),
    'tooltip': 'Microsoft SSO',
  },
  AuthProvider.google: {
    'tag': 'G',
    'color': Colors.purple.shade800.withOpacity(0.7),
    'tooltip': 'Google SSO',
  },
};
