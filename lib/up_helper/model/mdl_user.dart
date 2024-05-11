import 'package:flutter/foundation.dart';

import '../enum/enum_acl.dart';
import '../helper/project_helper.dart';
import 'mdl_acl_permission.dart';
import 'mdl_acl_permission2.dart';

enum UserKey {
  none,
  fullname,
  username,
  email,
  emailVerified,
  identifier,
  phone,
  password,
  confirmPassword,
  destPortal,
  enabled,
  sendVerificationEmail,
  fcmRegToken,
  address,
  projectScope,
  siteScope,
  authProvider,
  resetPasswordOnFirstLogin,
}

enum AclRole {
  Administrator,
  EVS2_Reserved_1995,
  EVS2_Reserved_1996,
  EVS2_Reserved_1997,
  EVS2_Reserved_1998,
  EVS2_Reserved_1999,
  EVS2_Reserved_2000,
  EVS2_Owner,
  EVS2_Reserved_2002,
  EVS2_Reserved_2003,
  EVS2_Reserved_2004,
  EVS2_Admin_Root,
  EVS2_Reserved_2006,
  EVS2_Super_Admin,
  EVS2_Reserved_2008,
  EVS2_Reserved_2009,
  EVS2_Reserved_2010,
  EVS2_Admin,
  EVS2_Reserved_2012,
  EVS2_Ops_PA,
  EVS2_Reserved_2014,
  EVS2_Sub_Admin,
  EVS2_Reserved_2016,
  EVS2_Reserved_2017,
  EVS2_Ops1,
  EVS2_Ops2,
  EVS2_Ops_Site_NTU_MR,
  EVS2_Ops_Basic,
  Sl_NUS_Project_Host,
  EVS2_Reserved_2023,
  EVS2_Reserved_2024,
  EVS2_Basic_Meter_Consumer,
  EVS2_Reserved_2026,
  EVS2_Registered_User,
  EMS_Ops_Site_SMRT_Buona_Vista,
  EVS2_Basic_User,
}

enum DestPortal {
  evs2op,
  evs2cp,
  bmsup,
  emsop,
  emstp,
  none,
}

enum PushType {
  none,
  fcm, //firebase cloud messaging
  apns, //apple push notification service
  longPolling, //long polling
}

class Evs2User {
  int? id = 0;
  String? username = '';
  String? email = '';
  bool? emailVerified = false;
  String? fullName = '';
  String? password = '';
  String? phone = '';
  int? role = 0;
  bool? enabled = false;
  bool? prefDarkMode = false;
  bool? isLoggedin = false;
  Map<String, Permission>? rolePermMap;
  int? maxRank = 0;
  List<String>? roles;
  List<String>? permissions;
  List<Permission2>? permission2s;
  String? address;
  String? fcmRegToken;
  PushType? pushType;
  String? scopeStr;
  Map<String, String>? stripeEpts;
  String? destPortal;
  List<String>? scopes;
  List<ProjectScope>? projectScopes;
  List<SiteScope>? siteScopes;
  String? resetPasswordToken;
  AuthProvider? authProvider;
  Map<String, dynamic>? authInfo;

  Evs2User({
    this.id,
    this.username,
    this.email,
    this.emailVerified,
    this.password,
    this.fullName,
    this.phone,
    this.role,
    this.enabled,
    this.prefDarkMode,
    this.rolePermMap,
    this.maxRank = 0,
    this.roles,
    this.permissions,
    this.permission2s,
    this.address,
    this.fcmRegToken,
    this.pushType,
    this.scopeStr,
    this.stripeEpts,
    this.destPortal,
    this.scopes,
    this.projectScopes,
    this.siteScopes,
    this.resetPasswordToken,
    this.authProvider,
    this.authInfo,
  });

  void logout() {
    id = 0;
    username = '';
    email = '';
    emailVerified = false;
    fullName = '';
    password = '';
    phone = '';
    role = 0;
    enabled = false;
    prefDarkMode = false;
    rolePermMap = {};
    maxRank = 0;
    roles = [];
    permissions = [];
    permission2s = [];
    address = '';
    fcmRegToken = '';
    pushType = PushType.none;
    scopeStr = '';
    stripeEpts = {};
    destPortal = '';
    scopes = [];
    projectScopes = [];
    siteScopes = [];
    resetPasswordToken = '';
    authProvider = null;
    authInfo = {};
  }

  factory Evs2User.fromJson(Map<String, dynamic> respJson) {
    try {
      Map<String, dynamic> userJson = respJson['userInfo'];

      Map<String, dynamic> rolePermProfile = userJson['role_perm_profile'];

      Map<String, dynamic>? _rolePermMap;
      _rolePermMap = rolePermProfile['role_perm_map'];

      return Evs2User(
        id: userJson['id'],
        username: userJson['username'],
        email: userJson['email'] ?? '',
        emailVerified: userJson['email_verified'] ?? false,
        // password: userJson['password'],
        fullName: userJson['fullname'] ?? '',
        phone: userJson['contact_number'] ?? '',
        // role: userJson['role'],
        enabled: userJson['enabled'],
        // prefDarkMode: userJson['prefDarkMode'],
        rolePermMap: _rolePermMap?.map(
          (key, value) => MapEntry(
            key,
            Permission.fromJson(value),
          ),
        ),
        address: userJson['address'] ?? '',
        fcmRegToken: userJson['fcm_reg_token'] ?? '',
        scopeStr: userJson['scope_str'] ?? '',
        // paySvcUrl: userJson['pay_svc_url'] ?? {},
        resetPasswordToken: userJson['reset_password_token'] ?? '',
      );
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return Evs2User();
    }
  }
  factory Evs2User.fromJson2(Map<String, dynamic> respJson) {
    try {
      Map<String, dynamic> userJson = respJson['userInfo'];
      List<String> roles = [...userJson['roles'].map((e) => e.toString())];
      List<String> permissions = [
        ...userJson['permissions'].map((e) => e.toString())
      ];

      List<Permission2> permission2s = [];
      for (String permStr in permissions) {
        permission2s.add(Permission2.fromString(permStr));
      }

      //split scopeStr into scopes list with ";" as delimiter
      String scopeStrDelimiter = ';';
      List<String> scopes = [];
      if (userJson['scope_str'] != null && userJson['scope_str'] != '') {
        scopes = [...userJson['scope_str'].split(scopeStrDelimiter)];
      }
      return Evs2User(
        id: userJson['id'],
        username: userJson['username'],
        email: userJson['email'] ?? '',
        emailVerified: userJson['email_verified'] ?? false,
        // password: userJson['password'],
        fullName: userJson['fullname'] ?? '',
        phone: userJson['contact_number'] ?? '',
        // role: userJson['role'],
        enabled: userJson['enabled'],
        // prefDarkMode: userJson['prefDarkMode'],
        maxRank: userJson['max_rank'],
        roles: roles,
        permissions: permissions,
        address: userJson['address'] ?? '',
        fcmRegToken: userJson['fcm_reg_token'] ?? '',
        scopeStr: userJson['scope_str'] ?? '',
        destPortal: userJson['dest_portal'] ?? '',
        scopes: scopes,
        permission2s: permission2s,
        resetPasswordToken: userJson['reset_password_token'] ?? '',
      );
    } catch (e) {
      if (kDebugMode) {
        print({'exception in User.fromJson2:$e'});
      }
      return Evs2User();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'email_verified': emailVerified,
      'password': password,
      'fullname': fullName,
      'contact_number': phone,
      'role': role,
      'enabled': enabled,
      'pref_dark_mode': prefDarkMode,
      'role_perm_profile': rolePermMap,
      'address': address,
      'fcm_reg_token': fcmRegToken,
      'scope_str': scopeStr,
      'dest_portal': destPortal,
      'auth_provider': 'local',
      'auth_info': {},
    };
  }

  Map<String, dynamic> toJson2() {
    return {
      'id': id,
      'username': username ?? '',
      'email': email ?? '',
      'email_verified': emailVerified ?? false,
      'password': password ?? '',
      'fullname': fullName ?? '',
      'contact_number': phone ?? '',
      'roles': roles ?? [],
      'max_rank': maxRank ?? 0,
      'enabled': enabled ?? false,
      // 'pref_dark_mode': prefDarkMode,
      'role_perm_profile': rolePermMap ?? {},
      'address': address ?? '',
      'fcm_reg_token': fcmRegToken ?? '',
      'scope_str': scopeStr ?? '',
      'dest_portal': destPortal ?? '',
      'reset_password_token': resetPasswordToken ?? '',
      'auth_provider': 'local',
      'auth_info': {},
    };
  }

  static List<dynamic> getKeyList() {
    return [
      'id',
      'username',
      'email',
      'email_verified',
      // 'password',
      'fullname',
      'contact_number',
      // 'role',
      'is_enabled',
    ];
  }

  List<dynamic> getValueStringList() {
    return [
      id.toString(),
      username,
      email,
      emailVerified.toString(),
      // password,
      fullName,
      phone,
      // role,
      enabled.toString(),
    ];
  }

  // bool checkPermission(AclScope scope, AclTarget target, AclOperation op) {
  //   for (var role in rolePermMap!.keys) {
  //     if (rolePermMap![role]!
  //         .checkPermission(scope.name, target.name, op.name)) {
  //       return true;
  //     }
  //   }
  //   return false;
  // }
  bool checkPermission2(AclScope scope, AclTarget target, AclOperation op) {
    return permissions!
        .contains('${scope.name}:${target.name}:${op.name}'.toLowerCase());
  }

  bool hasPermmision2(AclScope scope, AclTarget target, AclOperation op) {
    if (permission2s == null) {
      return false;
    }
    // return permission2s!.contains(Permission2.fromString('$scope:${target.name}:$op'));

    return permission2s!.any((element) =>
        element.scope == scope &&
        element.target == target &&
        element.operation == op);

    // for (Permission2 perm2 in permission2s!) {
    //   if (kDebugMode) {
    //     print({
    //       'perm2.scope:${perm2.scope} perm2.scope == $scope:${perm2.scope == scope}',
    //       'perm2.target:${perm2.target} perm2.target == $target:${perm2.target == target}',
    //       'perm2.operation:${perm2.operation} perm2.operation == $op:${perm2.operation == op}',
    //     });
    //   }
    //   if (perm2.scope == scope &&
    //       perm2.target == target &&
    //       perm2.operation == op) {
    //     return true;
    //   }
    // }
    // return false;
  }

  bool hasPermmision3(
      AclScope scope, List<AclTarget> targets, List<AclOperation> ops,
      {bool matchAll = true}) {
    if (permission2s == null) {
      return false;
    }
    if (matchAll) {
      for (AclTarget target in targets) {
        for (AclOperation op in ops) {
          if (!hasPermmision2(scope, target, op)) {
            return false;
          }
        }
      }
      return true;
    } else {
      for (AclTarget target in targets) {
        for (AclOperation op in ops) {
          if (hasPermmision2(scope, target, op)) {
            return true;
          }
        }
      }
      return false;
    }
  }

  bool showFullDashboard() {
    return isFullOpsAndUp();
  }

  bool isSubAdminAndUp() {
    return isAdminAndUp() || hasRole2(AclRole.EVS2_Sub_Admin);
  }

  bool isFullOpsAndUp() {
    return isSubAdminAndUp() || hasRole2(AclRole.EVS2_Ops_PA);
  }

  bool isAdminAndUp() {
    return hasRole2(AclRole.EVS2_Owner) ||
        hasRole2(AclRole.Administrator) ||
        hasRole2(AclRole.EVS2_Admin_Root) ||
        hasRole2(AclRole.EVS2_Super_Admin) ||
        hasRole2(AclRole.EVS2_Admin);
  }
  // bool hasRole(AclRole role) {
  //   return rolePermMap!.containsKey(role.name);
  // }

  bool hasRole2(AclRole role) {
    //roles is a list of [{name: EVS2_Admin, rank: 55}]

    //"{name: EVS2_Ops_Basic, rank: 1}"
    List<String> rolesStrList = roles!.map((e) => e.toString()).toList();
    List<Map<String, dynamic>> rolesMap = [];
    for (String roleStr in rolesStrList) {
      String roleStrTrimmed =
          roleStr.replaceAll('{', '').replaceAll('}', '').replaceAll(' ', '');
      List<String> roleStrList = roleStrTrimmed.split(',');
      rolesMap.add({
        'name': roleStrList[0].split(':')[1].trim(),
        'rank': int.tryParse(roleStrList[1].split(':')[1].trim()),
      });
    }

    // bool hasRole = roles!.any((element) => element == role.name);
    bool hasRole = rolesMap.any((element) => element['name'] == role.name);
    // print('hasRole2: $hasRole - ${role.name}');
    return hasRole;
  }

  // in the list of user roles,
  // find the role that has one or all of the roleStrs
  bool hasRoleStr(List<String> roleStrs, {bool matchAll = false}) {
    if (roles == null) return false;
    if (matchAll) {
      for (String role in roles!) {
        int strsFound = 0;
        for (String roleStr in roleStrs) {
          if (!role.contains(roleStr)) {
            break;
          }
          strsFound++;
        }
        if (strsFound == roleStrs.length) {
          return true;
        }
      }
      return false;
    } else {
      for (String role in roles!) {
        for (String roleStr in roleStrs) {
          if (role.contains(roleStr)) {
            return true;
          }
        }
      }
      return false;
    }
  }

  bool useOpsDashboard() {
    return isAdminAndUp() || hasRole2(AclRole.EVS2_Ops_Basic);
  }

  bool canSeeOpsDrawer() {
    return isAdminAndUp() || hasRole2(AclRole.EVS2_Ops_Basic);
  }

  DestPortal getDestPortal() {
    switch (destPortal) {
      case 'evs2op':
        return DestPortal.evs2op;
      case 'evs2cp':
        return DestPortal.evs2cp;
      case 'bmsup':
        return DestPortal.bmsup;
      case 'emsop':
        return DestPortal.emsop;
      case 'emstp':
        return DestPortal.emstp;
      default:
        return DestPortal.none;
    }
  }

  bool isEmpty() {
    return username == '' || username == null;
  }
}
