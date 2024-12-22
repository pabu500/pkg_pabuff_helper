import 'package:buff_helper/pag_helper/model/acl/mdl_pag_operation.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_role.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_target.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_building_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_profile.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/vendor_helper.dart';
import 'package:buff_helper/pag_helper/def/def_tree.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';

import 'scope/mdl_pag_scope2.dart';

enum PagUserKey {
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
  allowServiceEmail,
}

class MdlPagUser {
  int? id = 0;
  String? username = '';
  String? email = '';
  bool? emailVerified = false;
  String? fullName = '';
  String? password = '';
  String? phone = '';
  // int? role = 0;
  bool? enabled = false;
  bool? prefDarkMode = false;
  bool? isLoggedin = false;
  List<Map<String, dynamic>>? venderCredList;

  List<MdlPagRole> roleList;
  List<MdlPagProjectProfile>? userScope;
  String? resetPasswordToken;
  AuthProvider? authProvider;
  Map<String, dynamic>? authInfo;
  List<Map<String, dynamic>>? tenantList;

  // MdlPagProjectProfile? selectedProjectProfile;
  // MdlPagSiteGroupProfile? selectedSiteGroupProfile;
  // MdlPagSiteProfile? selectedSiteProfile;
  // MdlPagBuildingProfile? selectedBuildingProfile;
  // MdlPagLocationGroupProfile? selectedLocationGroupProfile;
  MdlPagScope2 selectedScope;

  MdlPagUser({
    this.id,
    this.username,
    this.email,
    this.emailVerified,
    this.password,
    this.fullName,
    this.phone,
    // this.role,
    this.enabled,
    this.prefDarkMode,
    this.resetPasswordToken,
    this.authProvider,
    this.authInfo,
    this.roleList = const [],
    this.tenantList,
    this.venderCredList,
    this.userScope = const [],
    required this.selectedScope,
  });

  void logout() {
    id = 0;
    username = '';
    email = '';
    emailVerified = false;
    fullName = '';
    password = '';
    phone = '';
    // role = 0;
    enabled = false;
    prefDarkMode = false;
    resetPasswordToken = '';
    authProvider = null;
    authInfo = {};
    tenantList = [];
    venderCredList = [];
    userScope = [];
    selectedScope.clear();
  }

  get isEmpty => {username ?? ''}.isEmpty;

  bool hasScopeForPagProject(List<PagPortalProjectScope> projectScopeList) {
    if (userScope == null) {
      return false;
    }
    List<Map<String, bool>> userScopeList = [];
    for (PagPortalProjectScope projectScope in projectScopeList) {
      for (MdlPagProjectProfile projectProfile in userScope!) {
        if (projectProfile.name.toUpperCase() ==
            projectScope.name.toUpperCase()) {
          if (kDebugMode) {
            print('add matched projectProfile.name: ${projectProfile.name}');
          }
          userScopeList.add({projectProfile.name: true});
          break;
        }
      }
    }
    // return false;
    return projectScopeList.length >= userScopeList.length;
  }

  void updateVendorCred(
      PlatformVendor pv, VendorCredType credType, String cred) {
    venderCredList ??= [];
    for (Map<String, dynamic> credMap in venderCredList!) {
      if (credMap['vendor'] == pv && credMap['cred_type'] == credType) {
        credMap['cred'] = cred;
        return;
      }
    }
    venderCredList!.add({
      'vendor': pv,
      'cred_type': credType,
      'cred': cred,
    });
  }

  String getVendorCred(PlatformVendor pv, VendorCredType credType) {
    if (venderCredList == null) {
      return '';
    }
    for (Map<String, dynamic> credMap in venderCredList!) {
      if (credMap['vendor'] == pv && credMap['cred_type'] == credType) {
        return credMap['cred'];
      }
    }
    return '';
  }

  // int getSelectedProjectTimeZone() {
  //   assert(selectedProjectProfile != null);

  //   return selectedProjectProfile!.timezone;
  // }

  PagPortalProjectScope getProjectScope({int index = 0}) {
    if (userScope == null) {
      return PagPortalProjectScope.none;
    }
    if (index >= userScope!.length) {
      return PagPortalProjectScope.none;
    }
    String projectName = userScope![index].name;
    return PagPortalProjectScope.values.byName(projectName.toUpperCase());
  }

  List<PagPortalProjectScope> getProjectScopeList() {
    List<PagPortalProjectScope> projectScopes = [];
    if (userScope == null) {
      return projectScopes;
    }
    for (MdlPagProjectProfile projectProfileList in userScope!) {
      String projectName = projectProfileList.name;
      try {
        PagPortalProjectScope projectScope =
            PagPortalProjectScope.values.byName(projectName.toUpperCase());
        projectScopes.add(projectScope);
      } catch (e) {
        if (kDebugMode) {
          print({'exception in User.getProjectScopeList:$e'});
        }
      }
    }
    return projectScopes;
  }

  // PagTreePartType getSelectedScopeTreePartType() {
  //   if (selectedLocationGroupProfile != null) {
  //     return PagTreePartType.locationGroup;
  //   }
  //   if (selectedBuildingProfile != null) {
  //     return PagTreePartType.building;
  //   }
  //   if (selectedSiteProfile != null) {
  //     return PagTreePartType.site;
  //   }
  //   if (selectedSiteGroupProfile != null) {
  //     return PagTreePartType.siteGroup;
  //   }
  //   return PagTreePartType.project;
  // }

  // dynamic getSelectedScopeProfile() {
  //   if (selectedLocationGroupProfile != null) {
  //     return selectedLocationGroupProfile;
  //   }
  //   if (selectedBuildingProfile != null) {
  //     return selectedBuildingProfile;
  //   }
  //   if (selectedSiteProfile != null) {
  //     return selectedSiteProfile;
  //   }
  //   if (selectedSiteGroupProfile != null) {
  //     return selectedSiteGroupProfile;
  //   }
  //   return selectedProjectProfile;
  // }

  List<MdlPagProjectProfile> getProjectProfileList() {
    List<MdlPagProjectProfile> projectProfiles = [];
    if (userScope == null) {
      return projectProfiles;
    }
    for (MdlPagProjectProfile projectProfile in userScope!) {
      projectProfiles.add(projectProfile);
    }
    return projectProfiles;
  }

  List<MdlPagSiteProfile> getProjectSiteProfileList(
      MdlPagProjectProfile projectProfile) {
    List<MdlPagSiteProfile> siteProfileList = [];
    if (userScope == null) {
      return [];
    }
    for (MdlPagProjectProfile userProjectProfile in userScope!) {
      if (userProjectProfile.name == projectProfile.name) {
        for (MdlPagSiteGroupProfile siteProfile
            in projectProfile.siteGroupProfileList) {
          for (MdlPagSiteProfile site in siteProfile.siteProfileList) {
            siteProfileList.add(site);
          }
        }
      }
    }
    return siteProfileList;
  }

  void updateSelectedScopeByName(String projectName, String siteGroupName,
      String siteName, String buildingName, String locationGroupName) {
    selectedScope.updateScopeByName(userScope!, projectName, siteGroupName,
        siteName, buildingName, locationGroupName);
  }

  void updateSelectedScopeByName2(
      PagTreePartType scopeType, String profileName) {
    selectedScope.updateScopeByName2(userScope!, scopeType, profileName);
  }

  bool hasPermission(
      MdlPagScope scope, MdlPagTarget target, MdlPagOperation operation) {
    if (roleList.isEmpty) {
      return false;
    }
    // for (MdlPagRole role in roleList) {
    //   if (role.hasPermission(permission)) {
    //     return true;
    //   }
    // }
    // return false;
    return true;
  }

  factory MdlPagUser.fromJson2(Map<String, dynamic> respJson) {
    try {
      Map<String, dynamic> userJson = respJson['userInfo'];

      //role and scope
      List<Map<String, dynamic>> userRoleScopeList = [];
      List<MdlPagRole> roleList = [];
      if (userJson['user_role_scope_list'] != null) {
        userRoleScopeList = [...userJson['user_role_scope_list']];
      }
      List<MdlPagProjectProfile> projectProfileList = [];
      for (Map<String, dynamic> userRoleScope in userRoleScopeList) {
        String roleIdStr = userRoleScope['id'];
        int roleId = int.tryParse(roleIdStr) ?? -1;

        String roleName = userRoleScope['name'];
        String? roleLabel = userRoleScope['label'];
        String roleRankStr = userRoleScope['rank'];
        int roleRank = int.tryParse(roleRankStr) ?? -1;

        MdlPagRole role = MdlPagRole(
          id: roleId,
          name: roleName,
          label: roleLabel,
          rank: roleRank,
        );
        roleList.add(role);

        List<Map<String, dynamic>> projectRoleScopeConfigList = [];
        if (userRoleScope['project_role_scope_config_list'] != null) {
          projectRoleScopeConfigList = [
            ...userRoleScope['project_role_scope_config_list']
          ];
          for (Map<String, dynamic> projectRoleScope
              in projectRoleScopeConfigList) {
            if (projectRoleScope['role_scope'] == null) {
              if (kDebugMode) {
                print('projectRoleScope[role_scope] is null');
              }
              continue;
            }

            try {
              MdlPagProjectProfile? projectProfile =
                  MdlPagProjectProfile.fromJson2(projectRoleScope);
              projectProfileList.add(projectProfile);
            } catch (e) {
              if (kDebugMode) {
                print({'exception in User.fromJson -> project fromJson2:$e'});
              }
            }
          }
        }
      }

      MdlPagProjectProfile? selectedProjectProfile = projectProfileList[0];
      assert(selectedProjectProfile.isNotEmpty);
      MdlPagSiteGroupProfile? selectSiteGroupProfile;
      if (selectedProjectProfile.getSiteGroupCount() == 1) {
        selectSiteGroupProfile = selectedProjectProfile.siteGroupProfileList[0];
        assert(selectSiteGroupProfile.isNotEmpty);
      }
      MdlPagSiteProfile? selectedSiteProfile;
      if (selectSiteGroupProfile != null) {
        if (selectSiteGroupProfile.getSiteProfileCount() == 1) {
          selectedSiteProfile = selectSiteGroupProfile.siteProfileList[0];
        }
      }
      MdlPagBuildingProfile? selectedBuildingProfile;
      if (selectedSiteProfile != null) {
        if (selectedSiteProfile.getBuildingCount() == 1) {
          selectedBuildingProfile = selectedSiteProfile.buildingProfileList[0];
        }
      }
      MdlPagLocationGroupProfile? selectedLocationGroupProfile;
      if (selectedBuildingProfile != null) {
        if (selectedBuildingProfile.getLocationGroupCount() == 1) {
          selectedLocationGroupProfile =
              selectedBuildingProfile.locationGroupProfileList[0];
        }
      }

      MdlPagScope2 selectedScope = MdlPagScope2(
        projectProfile: selectedProjectProfile,
        siteGroupProfile: selectSiteGroupProfile,
        siteProfile: selectedSiteProfile,
        buildingProfile: selectedBuildingProfile,
        locationGroupProfile: selectedLocationGroupProfile,
      );

      List<Map<String, dynamic>> tenantList = [];
      String authProviderStr = userJson['auth_provider'] ?? 'local';
      AuthProvider? authProvider = AuthProvider.values.byName(authProviderStr);

      return MdlPagUser(
        id: userJson['id'],
        username: userJson['username'],
        email: userJson['email'] ?? '',
        emailVerified: userJson['email_verified'] ?? false,
        fullName: userJson['fullname'] ?? '',
        phone: userJson['contact_number'] ?? '',
        enabled: userJson['enabled'],
        resetPasswordToken: userJson['reset_password_token'] ?? '',
        userScope: projectProfileList,
        // selectedProjectProfile: selectedProjectProfile,
        // selectedSiteGroupProfile: selectSiteGroupProfile,
        // selectedSiteProfile: selectedSiteProfile,
        selectedScope: selectedScope,
        roleList: roleList,
        tenantList: tenantList,
        authProvider: authProvider,
        venderCredList: [
          {
            'vendor': PlatformVendor.ctlab,
            'cred_type': VendorCredType.access_token,
            'cred': userJson['ctlab_access_token'] ?? '',
          }
        ],
      );
    } catch (e) {
      if (kDebugMode) {
        print({'exception in User.fromJson:$e'});
      }
      return MdlPagUser(selectedScope: MdlPagScope2());
    }
  }
}
