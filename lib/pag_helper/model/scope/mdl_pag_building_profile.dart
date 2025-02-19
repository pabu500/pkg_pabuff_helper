import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:flutter/foundation.dart';
import '../../def/project_helper.dart';
import '../fleet_health/mdl_pag_fleet_health.dart';
import 'mdl_pag_location_group_profile.dart';

class MdlPagBuildingProfile {
  int id;
  String name;
  String label;
  List<MdlPagLocationGroupProfile> locationGroupProfileList;
  bool isAllLocationGroups;
  MdlListColController? locationGroupFilterColController;
  double? latitude;
  double? longitude;
  MdlPagFleetHealth? fleetHealth;

  MdlPagBuildingProfile({
    required this.id,
    required this.name,
    required this.label,
    this.locationGroupProfileList = const [],
    this.isAllLocationGroups = false,
    this.latitude,
    this.longitude,
    this.fleetHealth,
  });

  bool equals(MdlPagBuildingProfile? buildingProfile) {
    if (buildingProfile == null) {
      return false;
    }
    return id == buildingProfile.id;
  }

  int getLocationGroupCount() {
    return locationGroupProfileList.length;
  }

  MdlPagLocationGroupProfile? getDefaultLocationGroupProfile() {
    if (locationGroupProfileList.isEmpty) {
      return null;
    }
    if (locationGroupProfileList.length == 1) {
      return locationGroupProfileList.first;
    }
    return null;
  }

  MdlPagLocationGroupProfile? getLocationGroupProfileById(
      String? locationGroupIdStr) {
    if (locationGroupIdStr == null) {
      return null;
    }
    for (var locationGroupProfile in locationGroupProfileList) {
      if (locationGroupProfile.id.toString() == locationGroupIdStr) {
        return locationGroupProfile;
      }
    }
    return null;
  }

  MdlPagLocationGroupProfile? getLocationGroupProfileByName(String? name) {
    if (name == null) {
      return null;
    }
    for (var locationGroupProfile in locationGroupProfileList) {
      if (locationGroupProfile.name == name) {
        return locationGroupProfile;
      }
    }
    return null;
  }

  void bindFilterColController(MdlListColController? filterColController,
      {MdlPagLocationGroupProfile? defaultLocationGroupProfile,
      bool limitToDefault = false}) {
    if (filterColController == null) {
      return;
    }
    locationGroupFilterColController = filterColController;

    //populate valueList
    filterColController.valueList = [];
    if (defaultLocationGroupProfile != null && limitToDefault) {
      filterColController.valueList!.add({
        'value': defaultLocationGroupProfile.id.toString(),
        'label': defaultLocationGroupProfile.label,
      });
    } else {
      for (var locationGroupProfile in locationGroupProfileList) {
        filterColController.valueList!.add({
          'value': locationGroupProfile.id.toString(),
          'label': locationGroupProfile.label,
        });
      }
    }

    Map<String, dynamic>? defaultFilterValue;
    if (defaultLocationGroupProfile != null) {
      defaultFilterValue = {
        'value': defaultLocationGroupProfile.id.toString(),
        'label': defaultLocationGroupProfile.label,
      };
    }

    filterColController.resetFilter(defaultFilterValue: defaultFilterValue);

    locationGroupFilterColController?.filterWidgetController?.text =
        defaultFilterValue?['label'] ?? '';
  }

  factory MdlPagBuildingProfile.fromJson(Map<String, dynamic> json) {
    String? isWildcard = json['is_wildcard'];
    assert(isWildcard != null);
    bool isAllLocationGroups = isWildcard == 'true';

    Map<String, dynamic> itemInfo = json['item_info'] ?? {};
    assert(itemInfo.isNotEmpty);

    String? name = itemInfo['name'];
    assert(name != null);
    String label = itemInfo['label'] ?? '';
    // assert(label != null);

    dynamic id = itemInfo['id'];
    if (id is String) {
      id = int.tryParse(id);
    }
    assert(id is int);

    List<MdlPagLocationGroupProfile> locationGroupProfileList = [];
    if (json['location_group_list'] != null) {
      for (var locationGroupMap in json['location_group_list']) {
        Map<String, dynamic>? scopeInfo = locationGroupMap['scope_info'];
        assert(scopeInfo != null);
        MdlPagLocationGroupProfile locationGroup =
            MdlPagLocationGroupProfile.fromJson(scopeInfo!);
        locationGroupProfileList.add(locationGroup);
      }
      locationGroupProfileList.sort((a, b) => a.name.compareTo(b.name));
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

    return MdlPagBuildingProfile(
      id: id,
      name: name!,
      label: label,
      locationGroupProfileList: locationGroupProfileList,
      isAllLocationGroups: isAllLocationGroups,
      latitude: lat ?? defaultLat,
      longitude: lng ?? defaultLng,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'label': label,
    };
  }
}
