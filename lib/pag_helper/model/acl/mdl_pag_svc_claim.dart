class MdlPagSvcClaim {
  int? userId = 0;
  String? username = '';

  int? roleId = 0;
  String? roleName = '';
  String? roleLabel = '';

  String? svcName = '';
  String? endpoint = '';
  String? scope = '';
  String? target = '';
  String? operation = '';
  int? selectedRoleId = 0;

  MdlPagSvcClaim(
      {this.userId,
      this.username,
      this.roleId,
      this.roleName,
      this.roleLabel,
      this.selectedRoleId,
      this.svcName,
      this.endpoint,
      this.scope,
      this.target,
      this.operation});

  factory MdlPagSvcClaim.fromJson(Map<String, dynamic> json) {
    return MdlPagSvcClaim(
      userId: json['user_id'],
      username: json['username'],
      roleId: json['role_id'],
      roleName: json['role_name'],
      roleLabel: json['role_label'],
      selectedRoleId: json['selected_role_id'],
      svcName: json['svc_name'],
      endpoint: json['endpoint'],
      scope: json['scope'],
      target: json['target'],
      operation: json['operation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'role_id': roleId,
      'role_name': roleName,
      'role_label': roleLabel,
      'selected_role_id': selectedRoleId,
      'svc_name': svcName,
      'endpoint': endpoint,
      'scope': scope,
      'target': target,
      'operation': operation,
    };
  }
}
