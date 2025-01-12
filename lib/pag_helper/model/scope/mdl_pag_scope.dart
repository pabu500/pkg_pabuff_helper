class MdlPagScope {
  String projectName;
  String projectId;
  String? siteGroupName;
  String? siteGroupId;
  String? siteName;
  String? siteId;
  String? buildingName;
  String? buildingId;
  String? locationGroupName;
  String? locationGroupId;

  MdlPagScope({
    required this.projectName,
    required this.projectId,
    this.siteGroupName,
    this.siteGroupId,
    this.siteName,
    this.siteId,
    this.buildingName,
    this.buildingId,
    this.locationGroupName,
    this.locationGroupId,
  });

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
      siteGroupName: json['site_group_name'],
      siteGroupId: json['site_group_id'],
      siteName: json['site_name'],
      siteId: json['site_id'],
      buildingName: json['building_name'],
      buildingId: json['building_id'],
      locationGroupName: json['location_group_name'],
      locationGroupId: json['location_group_id'],
    );
  }

  Map<String, dynamic> toScopeMap() {
    return {
      'project_name': projectName,
      'project_id': projectId,
      'site_group_name': siteGroupName,
      'site_group_id': siteGroupId,
      'site_name': siteName,
      'site_id': siteId,
      'building_name': buildingName,
      'building_id': buildingId,
      'location_group_name': locationGroupName,
      'location_group_id': locationGroupId,
    };
  }
}
