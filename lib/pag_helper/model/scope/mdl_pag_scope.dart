import 'package:buff_helper/pag_helper/def/scope_helper.dart';

class MdlPagScope {
  String projectName;
  String projectId;
  String? projectLabel;
  String? siteGroupName;
  String? siteGroupId;
  String? siteGroupLabel;
  String? siteName;
  String? siteId;
  String? siteLabel;
  String? buildingName;
  String? buildingId;
  String? buildingLabel;
  String? locationGroupName;
  String? locationGroupId;
  String? locationGroupLabel;

  MdlPagScope({
    required this.projectName,
    required this.projectId,
    this.projectLabel,
    this.siteGroupName,
    this.siteGroupId,
    this.siteGroupLabel,
    this.siteName,
    this.siteId,
    this.siteLabel,
    this.buildingName,
    this.buildingId,
    this.buildingLabel,
    this.locationGroupName,
    this.locationGroupId,
    this.locationGroupLabel,
  });

  String getLeafScopeLabel() {
    if (locationGroupLabel != null) {
      return locationGroupLabel!;
    }
    if (buildingLabel != null) {
      return buildingLabel!;
    }
    if (siteLabel != null) {
      return siteLabel!;
    }
    if (siteGroupLabel != null) {
      return siteGroupLabel!;
    }
    if (projectLabel != null) {
      return projectLabel!;
    }
    return projectName;
  }

  PagScopeType getScopeType() {
    if (locationGroupId != null) {
      return PagScopeType.locationGroup;
    }
    if (buildingId != null) {
      return PagScopeType.building;
    }
    if (siteId != null) {
      return PagScopeType.site;
    }
    if (siteGroupId != null) {
      return PagScopeType.siteGroup;
    }

    return PagScopeType.project;
  }

  factory MdlPagScope.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      throw Exception('Empty json');
    }
    if (json['project_name'] == null) {
      throw Exception('Project name not found');
    }
    if (json['project_id'] == null) {
      throw Exception('Project id not found');
    }
    return MdlPagScope(
      projectName: json['project_name'],
      projectId: json['project_id'],
      projectLabel: json['project_label'],
      siteGroupName: json['site_group_name'],
      siteGroupId: json['site_group_id'],
      siteGroupLabel: json['site_group_label'],
      siteName: json['site_name'],
      siteId: json['site_id'],
      siteLabel: json['site_label'],
      buildingName: json['building_name'],
      buildingId: json['building_id'],
      buildingLabel: json['building_label'],
      locationGroupName: json['location_group_name'],
      locationGroupId: json['location_group_id'],
      locationGroupLabel: json['location_group_label'],
    );
  }

  Map<String, dynamic> toScopeMap() {
    return {
      'project_name': projectName,
      'project_id': projectId,
      'project_label': projectLabel,
      'site_group_name': siteGroupName,
      'site_group_id': siteGroupId,
      'site_group_label': siteGroupLabel,
      'site_name': siteName,
      'site_id': siteId,
      'site_label': siteLabel,
      'building_name': buildingName,
      'building_id': buildingId,
      'building_label': buildingLabel,
      'location_group_name': locationGroupName,
      'location_group_id': locationGroupId,
      'location_group_label': locationGroupLabel,
    };
  }
}
