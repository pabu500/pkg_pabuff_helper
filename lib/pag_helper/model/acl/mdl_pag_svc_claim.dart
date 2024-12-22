class MdlPagSvcClaim {
  String? username = '';
  int? userId = 0;
  String? svcName = '';
  String? endpoint = '';
  String? scope = '';
  String? target = '';
  String? operation = '';

  MdlPagSvcClaim(
      {this.username,
      this.userId,
      this.svcName,
      this.endpoint,
      this.scope,
      this.target,
      this.operation});

  factory MdlPagSvcClaim.fromJson(Map<String, dynamic> json) {
    return MdlPagSvcClaim(
      username: json['username'],
      userId: json['user_id'],
      svcName: json['svc_name'],
      endpoint: json['endpoint'],
      scope: json['scope'],
      target: json['target'],
      operation: json['operation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'user_id': userId,
      'svcName': svcName,
      'endpoint': endpoint,
      'scope': scope,
      'target': target,
      'operation': operation,
    };
  }
}
