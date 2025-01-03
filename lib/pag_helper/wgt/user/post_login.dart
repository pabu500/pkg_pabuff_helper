import 'dart:convert';

import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pagrid_helper/comm_helper/local_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:buff_helper/pag_helper/comm/comm_scope.dart';
import 'package:provider/provider.dart';

import '../../def/project_helper.dart';
import '../../vendor/ct_lab/comm_ct_lab.dart';

Future<void> doPostLogin(
  MdlPagAppConfig appConfig,
  BuildContext context,
  MdlPagUser loggedInUser, {
  required String taskName,
  bool loadVendorCredential = true,
  PagPageRoute? prCur,
}) async {
  if (kDebugMode) {
    print('doPostLogin');
  }

  try {
    var result = await getUserRoleScopeList(
      appConfig,
      loggedInUser,
      {
        'portal_type_name': appConfig.portalType.name,
        'portal_type_label': appConfig.portalType.label,
        'user_id': loggedInUser.id.toString(),
        'user_role_list': loggedInUser.roleList.map((e) => e.toJson()).toList(),
        'task_name': taskName,
        'lazy_load_scope': appConfig.lazyLoadScope,
      },
      MdlPagSvcClaim(
        userId: loggedInUser.id,
        username: loggedInUser.username,
        scope: '',
        target: '',
        operation: '',
      ),
    );
    if (result['user_role_scope_list'] != null) {
      loggedInUser.populateRoleScope(result['user_role_scope_list'], appConfig);
    }
  } catch (e) {
    if (kDebugMode) {
      print('doPostLogin error: $e');
    }
    rethrow;
  }

  if (loggedInUser.userScope == null) {
    throw Exception('failed to get user scope');
  }

  if (!loggedInUser.hasScopeForPagProject(activePortalPagProjectScopeList)) {
    throw Exception('no access to this project portal');
  }

  Map<String, dynamic> rolePrefMap = json.decode(
    readFromSharedPref('role_pref') ?? '{}',
  );
  String selectedRoleName = rolePrefMap['selected_role_name'] ?? '';

  // only update scope when selectedRoleName is not empty
  if (selectedRoleName.isNotEmpty) {
    loggedInUser.updateSelectedRoleByName(selectedRoleName);

    dynamic scopePref = readFromSharedPref('scope_pref');
    if (kDebugMode) {
      print('scopePref: $scopePref');
    }
    Map<String, dynamic> scopePrefMap = json.decode(scopePref ?? '{}');
    String selectedProjectName = scopePrefMap['selected_project_name'] ?? '';
    String selectedSiteGroupName =
        scopePrefMap['selected_site_group_name'] ?? '';
    String selectedSiteName = scopePrefMap['selected_site_name'] ?? '';
    String selectedBuildingName = scopePrefMap['selected_building_name'] ?? '';
    String selectedLocationGroupName =
        scopePrefMap['selected_location_group_name'] ?? '';

    loggedInUser.updateSelectedScopeByName(
      selectedProjectName,
      selectedSiteGroupName,
      selectedSiteName,
      selectedBuildingName,
      selectedLocationGroupName,
    );
  }

  if (loadVendorCredential) {
    await doLoadVendorCredential(appConfig, loggedInUser);
  }

  if (context.mounted) {
    Provider.of<PagUserProvider>(context, listen: false)
        .setCurrentUser(loggedInUser);
  }
}
