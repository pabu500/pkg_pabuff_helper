class AclSetting {
  List<String> scopes;
  List<String> targets;
  List<String> operations;

  AclSetting(
      {required this.scopes, required this.targets, required this.operations});

  factory AclSetting.fromJson(Map<String, dynamic> json) {
    return AclSetting(
      scopes: List<String>.from(json['scopes'] as List<dynamic>),
      targets: List<String>.from(json['targets'] as List<dynamic>),
      operations: List<String>.from(json['operations'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scopes': scopes,
      'targets': targets,
      'operations': operations,
    };
  }
}
