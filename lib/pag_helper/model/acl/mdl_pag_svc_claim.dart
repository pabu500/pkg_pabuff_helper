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
      target: json['res'],
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
      'res': target,
      'operation': operation,
    };
  }
}

class MdlPagSvcClaim2 {
  int? userId;
  String? username = '';

  int? roleId;
  String? roleName = '';
  String? roleLabel = '';

  Map<String, dynamic>? userScope;

  // int? resId;
  // String? resName = '';
  // String? resLabel = '';

  // String? operation = '';
  List<Map<String, dynamic>>? permRequestList;

  String? svcName = '';
  String? endpoint = '';

  MdlPagSvcClaim2({
    this.userId,
    this.username,
    this.roleId,
    this.roleName,
    this.roleLabel,
    // this.resName,
    // this.resLabel,
    this.svcName,
    this.endpoint,
    this.userScope,
    // this.resId,
    // this.operation,
    this.permRequestList,
  });

  factory MdlPagSvcClaim2.fromJson(Map<String, dynamic> json) {
    return MdlPagSvcClaim2(
      userId: json['user_id'],
      username: json['username'],
      roleId: json['role_id'],
      roleName: json['role_name'],
      roleLabel: json['role_label'],
      // resName: json['res_name'],
      // resLabel: json['res_label'],
      svcName: json['svc_name'],
      endpoint: json['endpoint'],
      userScope: json['user_scope'],
      // resId: json['res_id'],
      // operation: json['operation'],
      permRequestList: (json['perm_request_list'] as List<dynamic>?)
          ?.map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    // final encodedPermRequestList = permRequestList?.map((permRequest) {
    //   final encodedPermRequest = Map<String, dynamic>.from(permRequest);
    //   final operation = encodedPermRequest['operation'];
    //   if (operation is Enum) {
    //     encodedPermRequest['operation'] = operation.name;
    //   }
    //   return encodedPermRequest;
    // }).toList();

    return {
      'user_id': userId,
      'username': username,
      'role_id': roleId,
      'role_name': roleName,
      'role_label': roleLabel,
      // 'res_name': resName,
      // 'res_label': resLabel,
      'svc_name': svcName,
      'endpoint': endpoint,
      'user_scope': userScope,
      // 'res_id': resId,
      // 'operation': operation,
      'perm_request_list': permRequestList,
    };
  }
}
