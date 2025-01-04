import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:flutter/foundation.dart';
import '../fleet_health/mdl_pag_fleet_health.dart';
import 'mdl_pag_location.dart';

class MdlPagLocationGroupProfile {
  int id;
  String name;
  String label;
  double? latitude;
  double? longitude;
  // int timezone;
  // String? currency = 'SGD';
  double? mapZoom = 10;
  Map<String, dynamic> mapCenter;
  MdlPagFleetHealth? fleetHealth;
  List<MdlPagLocation> locationList;
  bool isAllLocations;
  MdlListColController? filterColController;

  MdlPagLocationGroupProfile({
    required this.id,
    required this.name,
    required this.label,
    required this.latitude,
    required this.longitude,
    // required this.timezone,
    // this.currency,
    this.mapZoom = 10,
    this.mapCenter = const {},
    this.fleetHealth,
    this.locationList = const [],
    this.isAllLocations = false,
  });

  bool equals(MdlPagLocationGroupProfile? siteProfile) {
    if (siteProfile == null) {
      return false;
    }
    return id == siteProfile.id;
  }

  MdlPagLocation? getLocationByLabel(String? label) {
    if (label == null) {
      return null;
    }
    for (var location in locationList) {
      if (location.label == label) {
        return location;
      }
    }
    return null;
  }

  MdlPagLocation? getLocationById(String? locationIdStr) {
    if (locationIdStr == null) {
      return null;
    }
    for (var location in locationList) {
      if (location.id.toString() == locationIdStr) {
        return location;
      }
    }
    return null;
  }

  MdlPagLocation? getLocationByName(String? name) {
    if (name == null) {
      return null;
    }
    for (var location in locationList) {
      if (location.name == name) {
        return location;
      }
    }
    return null;
  }

  void bindFilterColController(MdlListColController? filterColController) {
    if (filterColController == null) {
      return;
    }
    this.filterColController = filterColController;

    //populate valueList
    for (var location in locationList) {
      filterColController.valueList = [];
      filterColController.valueList!.add({
        'value': location.id.toString(),
        'label': location.label,
      });
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
      // 'timezone': timezone,
      // 'currency': currency,
      'map_zoom': mapZoom,
      'map_center': mapCenter,
      'fh_stat': fleetHealth,
      'location_list':
          locationList.map((location) => location.toJson()).toList(),
    };
  }

  factory MdlPagLocationGroupProfile.fromJson(Map<String, dynamic> json) {
    String? isWildcard = json['is_wildcard'];
    assert(isWildcard != null);
    bool isAllLocations = isWildcard == 'true';

    Map<String, dynamic> itemInfo = json['item_info'] ?? {};
    assert(itemInfo.isNotEmpty);

    dynamic id = itemInfo['id'];
    if (id is String) {
      id = int.tryParse(id);
    }
    assert(id is int);

    String? name = itemInfo['name'];
    assert(name != null);
    String label = itemInfo['label'] ?? '';
    // assert(label != null);

    dynamic lat = itemInfo['lat'];
    if (lat == null) {
      if (kDebugMode) {
        // print('lat is null for location group ${itemInfo['lat']}');
      }
    }
    if (lat is String) {
      lat = double.tryParse(lat);
    }
    // assert(lat is double);

    dynamic lng = itemInfo['lng'];
    if (lng == null) {
      if (kDebugMode) {
        // print('lng is null for location group ${itemInfo['lng']}');
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

    List<MdlPagLocation> locationList = [];
    if (json['location_list'] != null) {
      locationList = (json['location_list'] as List)
          .map((lg) => MdlPagLocation.fromJson(lg))
          .toList();
    }

    return MdlPagLocationGroupProfile(
      id: id,
      name: name!,
      label: label,
      latitude: lat,
      longitude: lng,
      // currency: json['currency'],
      mapZoom: itemInfo['map_zoom'],
      mapCenter: mapCenter,
      locationList: locationList,
      // fleetHealth: itemInfo['fh_stat'] ?? {},
      isAllLocations: isAllLocations,
    );
  }
}
