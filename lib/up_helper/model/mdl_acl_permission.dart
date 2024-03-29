import 'mdl_acl_target_ops.dart';

//scope target ops
class Permission {
  Map<String, TargetOps> permissions;

  Permission({required this.permissions});

  factory Permission.fromJson(Map<String, dynamic> json) {
    Map<String, TargetOps> permissions = {};
    json.forEach((key, value) {
      permissions[key] = TargetOps.fromJson(value);
    });

    return Permission(permissions: permissions);
  }

  Map<String, dynamic> toJson() {
    return permissions;
  }

  bool checkPermission(String xScope, String xTarget, String xOp) {
    if (permissions.containsKey(xScope)) {
      TargetOps targetOps = permissions[xScope]!;
      if (targetOps.targetOps.containsKey(xTarget)) {
        List<String> ops = targetOps.targetOps[xTarget]!;
        if (ops.contains(xOp)) {
          return true;
        }
      }
    }

    return false;
  }
}
