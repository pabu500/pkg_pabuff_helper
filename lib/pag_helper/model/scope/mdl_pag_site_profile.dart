import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:flutter/foundation.dart';
import 'mdl_pag_building_profile.dart';

import 'mdl_pag_location_group_profile.dart';

class MdlPagSiteProfile {
  int id;
  String name;
  String label;
  double? latitude;
  double? longitude;
  int timezone;
  String? currency = 'SGD';
  double? mapZoom = 10;
  Map<String, dynamic> mapCenter;
  Map<String, dynamic> fhStat;
  List<MdlPagBuildingProfile> buildingProfileList;
  bool isAllBuildings;
  MdlListColController? buildingFilterColController;

  MdlPagSiteProfile({
    required this.id,
    required this.name,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.currency,
    this.mapZoom = 10,
    this.mapCenter = const {},
    this.fhStat = const {},
    this.buildingProfileList = const [],
    this.isAllBuildings = false,
  });

  bool equals(MdlPagSiteProfile? siteProfile) {
    if (siteProfile == null) {
      return false;
    }
    return id == siteProfile.id;
  }

  int getBuildingCount() {
    return buildingProfileList.length;
  }

  MdlPagBuildingProfile? getDefaultBuildingProfile() {
    if (buildingProfileList.isEmpty) {
      return null;
    }
    if (buildingProfileList.length == 1) {
      return buildingProfileList.first;
    }
    return null;
  }

  MdlPagBuildingProfile? getBuildingProfileById(String? buildingIdStr) {
    if (buildingIdStr == null) {
      return null;
    }
    for (var buildingProfile in buildingProfileList) {
      if (buildingProfile.id.toString() == buildingIdStr) {
        return buildingProfile;
      }
    }
    return null;
  }

  MdlPagBuildingProfile? getBuildingProfileByName(String? buildingName) {
    if (buildingName == null) {
      return null;
    }
    for (var buildingProfile in buildingProfileList) {
      if (buildingProfile.name == buildingName) {
        return buildingProfile;
      }
    }
    return null;
  }

  void bindFilterColController(MdlListColController? filterColController,
      {MdlPagBuildingProfile? defaultBuildingProfile,
      bool limitToDefault = false}) {
    if (filterColController == null) {
      return;
    }
    buildingFilterColController = filterColController;

    //populate valueList
    filterColController.valueList = [];
    if (defaultBuildingProfile != null && limitToDefault) {
      filterColController.valueList!.add({
        'value': defaultBuildingProfile.id.toString(),
        'label': defaultBuildingProfile.label,
      });
    } else {
      for (var buildingProfile in buildingProfileList) {
        filterColController.valueList!.add({
          'value': buildingProfile.id.toString(),
          'label': buildingProfile.label,
        });
      }
    }

    Map<String, dynamic>? defaultFilterValue;
    if (defaultBuildingProfile != null) {
      defaultFilterValue = {
        'value': defaultBuildingProfile.id.toString(),
        'label': defaultBuildingProfile.label,
      };
    }

    filterColController.resetFilter(defaultFilterValue: defaultFilterValue);

    buildingFilterColController?.filterWidgetController?.text =
        defaultFilterValue?['label'] ?? '';
  }

  List<MdlPagLocationGroupProfile> getAllLocationGroupProfileList() {
    List<MdlPagLocationGroupProfile> locationGroupProfileList = [];
    for (var buildingProfile in buildingProfileList) {
      locationGroupProfileList.addAll(buildingProfile.locationGroupProfileList);
    }
    return locationGroupProfileList;
  }

  List<MdlPagBuildingProfile> getBuildingProfileList() {
    return buildingProfileList;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'currency': currency,
      'map_zoom': mapZoom,
      'map_center': mapCenter,
      'fhStat': fhStat,
      'building_list':
          buildingProfileList.map((building) => building.toJson()).toList(),
    };
  }

  factory MdlPagSiteProfile.fromJson(Map<String, dynamic> json) {
    String? isWildcard = json['is_wildcard'];
    assert(isWildcard != null);
    bool isAllBuildings = isWildcard == 'true';

    Map<String, dynamic> itemInfo = json['item_info'] ?? {};
    assert(itemInfo.isNotEmpty);

    dynamic id = itemInfo['id'];
    if (id is String) {
      id = int.tryParse(id);
    }
    assert(id is int);

    dynamic lat = itemInfo['lat'];
    if (lat == null) {
      if (kDebugMode) {
        print('lat is null for site ${json['name']}');
      }
    }
    if (lat is String) {
      lat = double.tryParse(lat);
    }
    assert(lat is double);

    dynamic lng = itemInfo['lng'];
    if (lng == null) {
      if (kDebugMode) {
        print('lng is null for site ${itemInfo['name']}');
      }
    }
    if (lng is String) {
      lng = double.tryParse(lng);
    }
    assert(lng is double);

    Map<String, dynamic>? mapCenter = {
      'lat': lat,
      'lng': lng,
    };

    dynamic timezone = itemInfo['timezone'];
    if (timezone == null) {
      if (kDebugMode) {
        print('timezone is null for site ${itemInfo['name']}');
      }
    }
    if (timezone is String) {
      timezone = int.tryParse(timezone);
    }
    assert(timezone is int);

    List<MdlPagBuildingProfile> buildingList = [];
    if (json['building_list'] != null) {
      for (var buildingMap in json['building_list']) {
        Map<String, dynamic>? scopeInfo = buildingMap['scope_info'];
        assert(scopeInfo != null);
        MdlPagBuildingProfile building =
            MdlPagBuildingProfile.fromJson(scopeInfo!);
        buildingList.add(building);
      }
    }

    return MdlPagSiteProfile(
      id: id,
      name: itemInfo['name'],
      label: itemInfo['label'],
      latitude: lat,
      longitude: lng,
      timezone: timezone,
      currency: itemInfo['currency'],
      mapZoom: itemInfo['map_zoom'],
      mapCenter: mapCenter,
      buildingProfileList: buildingList,
      fhStat: itemInfo['fh_stat'] ?? {},
      isAllBuildings: isAllBuildings,
    );
  }
}
