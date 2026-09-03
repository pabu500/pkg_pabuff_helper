import 'package:buff_helper/pag_helper/def_helper/def_page_route.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/def_helper/enum_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';

import '../model/mdl_pag_app_context.dart';

import '../../up_helper/enum/enum_acl.dart';
import '../comm/comm_ex.dart';
import '../comm/pag_be_api_base.dart';
import '../model/acl/mdl_pag_svc_claim.dart';
import '../model/mdl_pag_app_config.dart';
import '../model/mdl_pag_app_context.dart';
import '../model/mdl_pag_user.dart';

enum PagPortalType {
  pagConsole('pag-console', 'Ops Console', 'op', Colors.teal),
  pagConsoleApp('pag-console-app', 'Ops Console App', 'opapp', Colors.blue),
  pagCmApp('pag-cm-app', 'Ops CM App', 'cmapp', Colors.indigo),
  pagEmsTp('pag-ems-tp', 'EMS Tenant Portal', 'tp', Colors.purple),
  pagEvsCp('pag-evs-cp', 'EVS Consume Portal', 'cp', Colors.orange),
  none('none', 'None', 'none', Colors.grey),
  ;

  const PagPortalType(
    this.value,
    this.label,
    this.tag,
    this.color,
  );

  final String value;
  final String label;
  final String tag;
  final Color color;

  static PagPortalType byValue(String? value) =>
      enumByValue<PagPortalType>(
        value,
        values,
        (e) => e.value,
      ) ??
      none;
}

enum PagRoleType {
  sysAdmin('sys_admin', 'System Admin', 'sysadmin', Colors.red),
  admin('admin', 'Admin', 'admin', Colors.redAccent),
  subAdmin('sub_admin', 'Sub Admin', 'subadmin', Colors.yellow),
  ops('ops', 'Ops', 'ops', Colors.teal),
  siteOps('site_ops', 'Site Ops', 'siteops', Colors.orange),
  billingOps('billing_ops', 'Billing Ops', 'billingops', Colors.indigo),
  tenant('tenant', 'EMS Tenant', 'tenant', Colors.purple),
  consumer('consumer', 'EVS Consumer', 'consumer', Colors.green),
  unknown('unknown', 'Unknown', 'unknown', Colors.grey),
  ;

  const PagRoleType(
    this.value,
    this.label,
    this.tag,
    this.color,
  );

  final String value;
  final String label;
  final String tag;
  final Color color;

  static PagRoleType byValue(String? value) =>
      enumByValue<PagRoleType>(
        value,
        values,
        (e) => e.value,
      ) ??
      unknown;
}

String? validateRoleTag(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'required';
  }

  // Allowed:
  // 2-8 chars
  // alphanumeric, underscore, dash
  final validCharacters = RegExp(
    r"""^[a-zA-Z0-9\-_]{2,8}$""",
  );

  if (!validCharacters.hasMatch(value)) {
    return 'must be 2-8 characters and can only contain letters, numbers, hyphens, and underscores';
  }

  return null;
}

String? Function(String) getRoleValidator(String key,
    {bool isValueRequired = true}) {
  switch (key) {
    case 'label':
      return getValidator(validateItemLabel, isValueRequired);
    case 'tag':
      return getValidator(validateRoleTag, isValueRequired);

    default:
      dev.log('No validator found for user key: $key');
      return (String? value) {
        return null;
      };
  }
}

String? getResNameByItemType(dynamic itemType) {
  if (itemType is Enum) {
    dev.log('getResNameByItemType: itemType is an Enum: $itemType');
    return itemType.name;
  }
  dev.log('getResNameByItemType: itemType is not an Enum: $itemType');
  return null;
}

String? getResNameByPageRouteSection(
    MdlPagAppContext appContext, PagPageRoute pageRoute, String pageSection) {
  return '${appContext.name}.${pageRoute.name}.$pageSection';
}

Future<dynamic> checkAcl(
  MdlPagAppConfig appConfig,
  MdlPagAppContext appContext,
  MdlPagUser loggedInUser,
  PagPageRoute pageRoute,
  String pageSection,
  AclOperation operation,
) async {
  try {
    final aclResult = await ex2(
      endpoint: PagUrlBase.eptCheckAcl,
      crudType: 'read',
      opStr: 'check acl',
      appConfig: appConfig,
      queryMap: {},
      svcClaim: MdlPagSvcClaim2(
        userId: loggedInUser.id,
        username: loggedInUser.username,
        roleId: loggedInUser.selectedRole?.id,
        roleName: loggedInUser.selectedRole?.name,
        roleLabel: loggedInUser.selectedRole?.label,
        userScope: loggedInUser.selectedScope.toScopeMap(),
        resName:
            getResNameByPageRouteSection(appContext, pageRoute, pageSection),
        operation: operation.name,
      ),
    );
    if ('denied' == aclResult['result']) {
      aclResult['result'] = 'access denied';
    }
    return aclResult;
  } catch (e) {
    dev.log('checkAcl error: $e');
    return {
      'result': 'error',
      'message': e.toString(),
    };
  }
}
