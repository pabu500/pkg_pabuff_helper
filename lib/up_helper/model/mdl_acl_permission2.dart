import '../enum/enum_acl.dart';

class Permission2 {
  AclScope scope;
  AclTarget target;
  AclOperation operation;

  Permission2({
    required this.scope,
    required this.target,
    required this.operation,
  });

  factory Permission2.fromJson(Map<String, dynamic> json) {
    return Permission2(
      // scope: AclScope.values.firstWhere((e) => e.name == json['scope']),
      // target: AclTarget.values.firstWhere((e) => e.name == json['target']),
      // operation: AclOperation.values.firstWhere((e) => e.name == json['operation']),
      scope: AclScope.values.byName(json['scope']),
      target: AclTarget.values.byName(json['target']),
      operation: AclOperation.values.byName(json['operation']),
    );
  }

  factory Permission2.fromString(String permissionStr) {
    List<String> permissionList = permissionStr.split(':');
    return Permission2(
      scope: AclScope.values.byName(permissionList[0]),
      target:
          AclTarget.values.byName(permissionList[1].replaceFirst('.', '_p_')),
      operation: AclOperation.values.byName(permissionList[2]),
    );
  }
}
