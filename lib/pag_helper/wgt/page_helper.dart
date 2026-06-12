import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_building_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_profile.dart';
import 'package:buff_helper/pag_helper/wgt/scope/wgt_scope_selector3.dart';
import 'package:flutter/material.dart';

import '../model/mdl_pag_user.dart';

Widget getTitleWidgetNarrow(
  MdlPagUser? loggedInUser,
  MdlPagAppContext currentAppContext,
  bool isPhone,
  UniqueKey scopeSelectorKey,
  Function(
          MdlPagProjectProfile? pagProjectScope,
          MdlPagSiteGroupProfile? pagSiteGroupScope,
          MdlPagSiteProfile? pagSiteScope,
          MdlPagBuildingProfile? pagBuildingScope,
          MdlPagLocationGroupProfile? pagLocationGroupScope)
      onChange,
) {
  if (loggedInUser == null || loggedInUser.isEmpty) {
    return const SizedBox();
  }
  dev.log('buildTitleWidgetNarrow: ${currentAppContext.name}');

  return Transform.translate(
      offset: const Offset(-0, 0),
      child: Row(children: [
        getScopeSelector(loggedInUser, isPhone, scopeSelectorKey, onChange),
      ]));
}

Widget getScopeSelector(
  MdlPagUser loggedInUser,
  bool isPhone,
  UniqueKey scopeSelectorKey,
  Function(
          MdlPagProjectProfile? pagProjectScope,
          MdlPagSiteGroupProfile? pagSiteGroupScope,
          MdlPagSiteProfile? pagSiteScope,
          MdlPagBuildingProfile? pagBuildingScope,
          MdlPagLocationGroupProfile? pagLocationGroupScope)
      onChange,
) {
  assert(loggedInUser.userScope != null);
  return WgtPagScopeSelector3(
    key: scopeSelectorKey,
    iniScope: loggedInUser.selectedScope,
    projectList: loggedInUser.userScope!,
    isNarrow: isPhone,
    width: isPhone ? 230 : null,
    onChange: onChange,
  );
}
