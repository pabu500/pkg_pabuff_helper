import 'package:buff_helper/pag_helper/def/def_tree.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/wgt/tree/wgt_tree_element.dart';

import '../../def/def_scope.dart';
import 'mdl_pag_site_group_profile.dart';
import 'mdl_pag_building_profile.dart';
import 'mdl_pag_location_group_profile.dart';
import 'mdl_pag_site_profile.dart';

class MdlPagScope2 {
  MdlPagProjectProfile? projectProfile;
  MdlPagSiteGroupProfile? siteGroupProfile;
  MdlPagSiteProfile? siteProfile;
  MdlPagBuildingProfile? buildingProfile;
  MdlPagLocationGroupProfile? locationGroupProfile;

  MdlPagScope2({
    this.projectProfile,
    this.siteGroupProfile,
    this.siteProfile,
    this.buildingProfile,
    this.locationGroupProfile,
  });

  factory MdlPagScope2.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      throw Exception('Empty json');
    }
    MdlPagProjectProfile projectProfile = MdlPagProjectProfile.fromJson2(json);
    MdlPagSiteGroupProfile? siteGroupProfile;
    if (json['site_group_profile'] != null) {
      siteGroupProfile =
          MdlPagSiteGroupProfile.fromJson(json['site_group_profile']);
    }
    MdlPagSiteProfile? siteProfile;
    if (json['site_profile'] != null) {
      siteProfile = MdlPagSiteProfile.fromJson(json['site_profile']);
    }
    MdlPagBuildingProfile? buildingProfile;
    if (json['building_profile'] != null) {
      buildingProfile =
          MdlPagBuildingProfile.fromJson(json['building_profile']);
    }
    MdlPagLocationGroupProfile? locationGroupProfile;
    if (json['location_group_profile'] != null) {
      locationGroupProfile =
          MdlPagLocationGroupProfile.fromJson(json['location_group_profile']);
    }
    return MdlPagScope2(
      projectProfile: projectProfile,
      siteGroupProfile: siteGroupProfile,
      siteProfile: siteProfile,
      buildingProfile: buildingProfile,
      locationGroupProfile: locationGroupProfile,
    );
  }

  Map<String, dynamic> toScopeMap() {
    return {
      'project_id': projectProfile?.id.toString(),
      'project_name': projectProfile?.name,
      'site_group_id': siteGroupProfile?.id.toString(),
      'site_group_name': siteGroupProfile?.name,
      'site_id': siteProfile?.id.toString(),
      'site_name': siteProfile?.name,
      'building_id': buildingProfile?.id.toString(),
      'building_name': buildingProfile?.name,
      'location_group_id': locationGroupProfile?.id.toString(),
      'location_group_name': locationGroupProfile?.name,
    };
  }

  //is empty getter
  bool get isEmpty {
    return projectProfile == null &&
        siteGroupProfile == null &&
        siteProfile == null &&
        buildingProfile == null &&
        locationGroupProfile == null;
  }

  void clear() {
    projectProfile = null;
    siteGroupProfile = null;
    siteProfile = null;
    buildingProfile = null;
    locationGroupProfile = null;
  }

  String getEffectScopeStr() {
    String effectiveScopeStr = projectProfile!.label;
    if (siteGroupProfile != null) {
      effectiveScopeStr += ' - ${siteGroupProfile!.label}';
    }
    if (siteProfile != null) {
      effectiveScopeStr += ' - ${siteProfile!.label}';
    }
    if (buildingProfile != null) {
      effectiveScopeStr += ' - ${buildingProfile!.label}';
    }
    if (locationGroupProfile != null) {
      effectiveScopeStr += ' - ${locationGroupProfile!.label}';
    }
    return effectiveScopeStr;
  }

  int getProjectTtimezone() {
    assert(projectProfile != null);
    return projectProfile!.timezone;
  }

  PagScopeType getScopeType() {
    if (locationGroupProfile != null) {
      return PagScopeType.locationGroup;
    } else if (buildingProfile != null) {
      return PagScopeType.building;
    } else if (siteProfile != null) {
      return PagScopeType.site;
    } else if (siteGroupProfile != null) {
      return PagScopeType.siteGroup;
    } else {
      return PagScopeType.project;
    }
  }

  PagTreePartType getScopeTreePartType() {
    if (locationGroupProfile != null) {
      return PagTreePartType.locationGroup;
    } else if (buildingProfile != null) {
      return PagTreePartType.building;
    } else if (siteProfile != null) {
      return PagTreePartType.site;
    } else if (siteGroupProfile != null) {
      return PagTreePartType.siteGroup;
    } else {
      return PagTreePartType.project;
    }
  }

  dynamic getScopeProfile() {
    if (locationGroupProfile != null) {
      return locationGroupProfile;
    } else if (buildingProfile != null) {
      return buildingProfile;
    } else if (siteProfile != null) {
      return siteProfile;
    } else if (siteGroupProfile != null) {
      return siteGroupProfile;
    } else {
      return projectProfile;
    }
  }

  List<dynamic> getScopeProfileList() {
    List<dynamic> scopeList = <dynamic>[];
    if (locationGroupProfile != null) {
      scopeList.addAll(locationGroupProfile!.locationList);
    } else if (buildingProfile != null) {
      scopeList.addAll(buildingProfile!.locationGroupProfileList);
    } else if (siteProfile != null) {
      scopeList.addAll(siteProfile!.buildingProfileList);
    } else if (siteGroupProfile != null) {
      scopeList.addAll(siteGroupProfile!.siteProfileList);
    } else {
      scopeList.addAll(projectProfile!.siteGroupProfileList);
    }
    return scopeList;
  }

  bool isSelectedNode(PagTreeNode node) {
    dynamic selectedScopeProfile = getScopeProfile();
    if (selectedScopeProfile == null) {
      return false;
    }
    if (selectedScopeProfile is MdlPagProjectProfile) {
      return node.treePartType == PagTreePartType.project &&
          node.name == selectedScopeProfile.name;
    }
    if (selectedScopeProfile is MdlPagSiteGroupProfile) {
      return node.treePartType == PagTreePartType.siteGroup &&
          node.name == selectedScopeProfile.name;
    }
    if (selectedScopeProfile is MdlPagSiteProfile) {
      return node.treePartType == PagTreePartType.site &&
          node.name == selectedScopeProfile.name;
    }
    if (selectedScopeProfile is MdlPagBuildingProfile) {
      return node.treePartType == PagTreePartType.building &&
          node.name == selectedScopeProfile.name;
    }
    if (selectedScopeProfile is MdlPagLocationGroupProfile) {
      return node.treePartType == PagTreePartType.locationGroup &&
          node.name == selectedScopeProfile.name;
    }
    return false;
  }

  void updateScopeByName(
      List<MdlPagProjectProfile> userScope,
      String projectName,
      String siteGroupName,
      String siteName,
      String buildingName,
      String locationGroupName) {
    for (MdlPagProjectProfile projectProfile in userScope) {
      if (projectProfile.name == projectName) {
        this.projectProfile = projectProfile;
        if (siteGroupName.isEmpty) {
          siteGroupProfile = null;
          siteProfile = null;
          buildingProfile = null;
          locationGroupProfile = null;
          break;
        }
        for (MdlPagSiteGroupProfile siteGroupProfile
            in projectProfile.siteGroupProfileList) {
          if (siteGroupProfile.name == siteGroupName) {
            siteGroupProfile = siteGroupProfile;
            if (siteName.isEmpty) {
              siteProfile = null;
              buildingProfile = null;
              break;
            }
            for (MdlPagSiteProfile siteProfile
                in siteGroupProfile.siteProfileList) {
              if (siteProfile.name == siteName) {
                siteProfile = siteProfile;
                if (buildingName.isEmpty) {
                  buildingProfile = null;
                  break;
                }
                for (MdlPagBuildingProfile buildingProfile
                    in siteProfile.buildingProfileList) {
                  if (buildingProfile.name == buildingName) {
                    buildingProfile = buildingProfile;
                    if (locationGroupName.isEmpty) {
                      locationGroupProfile = null;
                      break;
                    }
                    for (MdlPagLocationGroupProfile locationGroupProfile
                        in buildingProfile.locationGroupProfileList) {
                      if (locationGroupProfile.name == locationGroupName) {
                        locationGroupProfile = locationGroupProfile;
                        break;
                      }
                    }
                    break;
                  }
                }
                break;
              }
            }
            break;
          }
        }
        break;
      }
    }
    if (projectProfile == null) {
      throw Exception('Project not found');
    }
  }

  void updateScopeByName2(List<MdlPagProjectProfile> userScope,
      PagTreePartType scopeType, String profileName) {
    switch (scopeType) {
      case PagTreePartType.project:
        for (MdlPagProjectProfile projectProfile in userScope!) {
          if (projectProfile.name == profileName) {
            this.projectProfile = projectProfile;
            siteGroupProfile = null;
            siteProfile = null;
            buildingProfile = null;
            locationGroupProfile = null;
            break;
          }
        }
        break;
      case PagTreePartType.siteGroup:
        for (MdlPagSiteGroupProfile siteGroupProfile
            in projectProfile!.siteGroupProfileList) {
          if (siteGroupProfile.name == profileName) {
            this.siteGroupProfile = siteGroupProfile;
            siteProfile = null;
            buildingProfile = null;
            locationGroupProfile = null;
            break;
          }
        }
        break;
      case PagTreePartType.site:
        for (MdlPagSiteGroupProfile siteGroupProfile
            in projectProfile!.siteGroupProfileList) {
          for (MdlPagSiteProfile siteProfile
              in siteGroupProfile.siteProfileList) {
            if (siteProfile.name == profileName) {
              this.siteGroupProfile = siteGroupProfile;
              this.siteProfile = siteProfile;
              buildingProfile = null;
              locationGroupProfile = null;
              break;
            }
          }
        }
        break;
      case PagTreePartType.building:
        for (MdlPagSiteGroupProfile siteGroupProfile
            in projectProfile!.siteGroupProfileList) {
          for (MdlPagSiteProfile siteProfile
              in siteGroupProfile.siteProfileList) {
            for (MdlPagBuildingProfile buildingProfile
                in siteProfile.buildingProfileList) {
              if (buildingProfile.name == profileName) {
                this.siteGroupProfile = siteGroupProfile;
                this.siteProfile = siteProfile;
                this.buildingProfile = buildingProfile;
                locationGroupProfile = null;
                break;
              }
            }
          }
        }
        break;
      case PagTreePartType.locationGroup:
        for (MdlPagSiteGroupProfile siteGroupProfile
            in projectProfile!.siteGroupProfileList) {
          for (MdlPagSiteProfile siteProfile
              in siteGroupProfile.siteProfileList) {
            for (MdlPagBuildingProfile buildingProfile
                in siteProfile.buildingProfileList) {
              for (MdlPagLocationGroupProfile locationGroupProfile
                  in buildingProfile.locationGroupProfileList) {
                if (locationGroupProfile.name == profileName) {
                  this.siteGroupProfile = siteGroupProfile;
                  this.siteProfile = siteProfile;
                  this.buildingProfile = buildingProfile;
                  this.locationGroupProfile = locationGroupProfile;
                  break;
                }
              }
            }
          }
        }
        break;
      default:
        break;
    }
  }

  dynamic getRoot() {
    if (projectProfile?.getSiteGroupCount() == 1) {
      MdlPagSiteGroupProfile siteGroupProfile =
          projectProfile!.siteGroupProfileList[0];
      if (siteGroupProfile.getSiteCount() == 1) {
        MdlPagSiteProfile siteProfile = siteGroupProfile.siteProfileList[0];
        if (siteProfile.getBuildingCount() == 1) {
          MdlPagBuildingProfile buildingProfile =
              siteProfile.buildingProfileList[0];
          if (buildingProfile.getLocationGroupCount() == 1) {
            return buildingProfile.locationGroupProfileList[0];
          }
          return buildingProfile;
        }
        return siteProfile;
      }
      return siteGroupProfile;
    }
    return projectProfile;
  }

  PagTreePartType getRootTreePartType() {
    if (projectProfile?.getSiteGroupCount() == 1) {
      MdlPagSiteGroupProfile siteGroupProfile =
          projectProfile!.siteGroupProfileList[0];
      if (siteGroupProfile.getSiteCount() == 1) {
        MdlPagSiteProfile siteProfile = siteGroupProfile.siteProfileList[0];
        if (siteProfile.getBuildingCount() == 1) {
          MdlPagBuildingProfile buildingProfile =
              siteProfile.buildingProfileList[0];
          if (buildingProfile.getLocationGroupCount() == 1) {
            return PagTreePartType.locationGroup;
          }
          return PagTreePartType.building;
        }
        return PagTreePartType.site;
      }
      return PagTreePartType.siteGroup;
    }
    return PagTreePartType.project;
  }

  void goRoot() {
    siteGroupProfile = null;
    siteProfile = null;
    buildingProfile = null;
    locationGroupProfile = null;
    if (projectProfile?.getSiteGroupCount() == 1) {
      siteGroupProfile = projectProfile!.siteGroupProfileList[0];
      if (siteGroupProfile!.getSiteCount() == 1) {
        siteProfile = siteGroupProfile!.siteProfileList[0];
        if (siteProfile!.getBuildingCount() == 1) {
          buildingProfile = siteProfile!.buildingProfileList[0];
          if (buildingProfile!.getLocationGroupCount() == 1) {
            locationGroupProfile = buildingProfile!.locationGroupProfileList[0];
          } else {
            buildingProfile = buildingProfile;
          }
        } else {
          siteProfile = siteProfile;
        }
      } else {
        siteGroupProfile = siteGroupProfile;
      }
    } else {
      projectProfile = projectProfile;
    }
  }
}
