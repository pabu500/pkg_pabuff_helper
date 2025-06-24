import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:flutter/foundation.dart';
import '../../def_helper/project_helper.dart';
import '../fleet_health/mdl_pag_fleet_health.dart';
import 'mdl_pag_building_profile.dart';

import 'mdl_pag_site_profile.dart';

class MdlPagSiteGroupProfile {
  int id;
  String name;
  String label;
  bool isAllSites;
  MdlListColController? siteFilterColController;
  double? latitude;
  double? longitude;
  MdlPagFleetHealth? fleetHealth;

  List<MdlPagSiteProfile> siteProfileList;

  MdlPagSiteGroupProfile({
    required this.id,
    required this.name,
    required this.label,
    required this.siteProfileList,
    this.isAllSites = false,
    this.latitude,
    this.longitude,
    this.fleetHealth,
  });

  get isEmpty => siteProfileList.isEmpty;
  get isNotEmpty => siteProfileList.isNotEmpty;

  bool equals(MdlPagSiteGroupProfile? siteProfile) {
    if (siteProfile == null) {
      return false;
    }
    return id == siteProfile.id;
  }

  int getSiteCount() {
    return siteProfileList.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'label': label,
    };
  }

  int getSiteProfileCount() {
    return siteProfileList.length;
  }

  MdlPagSiteProfile? getDefaultSiteProfile() {
    if (siteProfileList.isEmpty) {
      return null;
    }
    if (siteProfileList.length == 1) {
      return siteProfileList.first;
    }
    return null;
  }

  List<MdlPagBuildingProfile> getAllBuildingProfileList() {
    List<MdlPagBuildingProfile> buildingProfileList = [];
    for (var siteProfile in siteProfileList) {
      buildingProfileList.addAll(siteProfile.buildingProfileList);
    }
    return buildingProfileList;
  }

  MdlPagSiteProfile? getSiteProfileById(String? siteIdStr) {
    if (siteIdStr == null) {
      return null;
    }
    for (var siteProfile in siteProfileList) {
      if (siteProfile.id.toString() == siteIdStr) {
        return siteProfile;
      }
    }
    return null;
  }

  MdlPagSiteProfile? getSiteProfileByName(String? siteName) {
    if (siteName == null) {
      return null;
    }
    for (var siteProfile in siteProfileList) {
      if (siteProfile.name == siteName) {
        return siteProfile;
      }
    }
    return null;
  }

  void bindFilterColController(MdlListColController? filterColController,
      {MdlPagSiteProfile? defaultSiteProfile, bool limitToDefault = false}) {
    if (filterColController == null) {
      return;
    }
    siteFilterColController = filterColController;

    //populate valueList
    filterColController.valueList = [];
    if (defaultSiteProfile != null && limitToDefault) {
      filterColController.valueList!.add({
        'value': defaultSiteProfile.id.toString(),
        'label': defaultSiteProfile.label,
      });
    } else {
      for (var siteProfile in siteProfileList) {
        filterColController.valueList!.add({
          'value': siteProfile.id.toString(),
          'label': siteProfile.label,
        });
      }
    }

    Map<String, dynamic>? defaultFilterValue;
    if (defaultSiteProfile != null) {
      defaultFilterValue = {
        'value': defaultSiteProfile.id.toString(),
        'label': defaultSiteProfile.label,
      };
    }

    filterColController.resetFilter(defaultFilterValue: defaultFilterValue);

    siteFilterColController?.filterWidgetController?.text =
        defaultFilterValue?['label'] ?? '';
  }

  factory MdlPagSiteGroupProfile.fromJson(Map<String, dynamic> json) {
    String? isWildcard = json['is_wildcard'];
    assert(isWildcard != null);
    bool isAllSites = isWildcard == 'true';

    Map<String, dynamic> itemInfo = json['item_info'] ?? {};
    assert(itemInfo.isNotEmpty);

    dynamic id = itemInfo['id'];
    if (id is String) {
      id = int.tryParse(id);
    }
    assert(id is int);

    List<MdlPagSiteProfile> siteProfileListX = [];
    if (itemInfo['site_list'] != null) {
      for (var siteProfileMap in itemInfo['site_list']) {
        Map<String, dynamic>? scopeInfo = siteProfileMap['scope_info'];
        assert(scopeInfo != null);
        try {
          MdlPagSiteProfile siteProfile =
              MdlPagSiteProfile.fromJson(scopeInfo!);
          siteProfileListX.add(siteProfile);
        } catch (e) {
          if (kDebugMode) {
            print('fromJson site_list $e');
          }
          rethrow;
        }
        siteProfileListX.sort((a, b) => a.name.compareTo(b.name));
      }
    }

    dynamic lat = itemInfo['lat'];
    if (lat == null) {
      if (kDebugMode) {
        // print('lat is null for site ${json['name']}');
      }
    }
    if (lat is String) {
      lat = double.tryParse(lat);
    }
    // assert(lat is double);

    dynamic lng = itemInfo['lng'];
    if (lng == null) {
      if (kDebugMode) {
        // print('lng is null for site ${itemInfo['name']}');
      }
    }
    if (lng is String) {
      lng = double.tryParse(lng);
    }
    // assert(lng is double);

    Map<String, dynamic>? mapCenter = {
      'lat': lat,
      'lng': lng,
    };

    return MdlPagSiteGroupProfile(
      id: id,
      name: itemInfo['name'],
      label: itemInfo['label'],
      isAllSites: isAllSites,
      siteProfileList: siteProfileListX,
      latitude: lat ?? defaultLat,
      longitude: lng ?? defaultLng,
    );
  }
}
