import 'mdl_svc_claim.dart';
// import 'dart:convert';

class SvcQuery {
  SvcClaim svcClaimDto;
  // Map<String, String> request;
  // List<Map<String, dynamic>>? request2;
  dynamic request;

  // SvcQuery({required this.svcClaimDto, required this.request});
  SvcQuery(this.svcClaimDto, this.request);

  Map<String, dynamic> toJson() {
    return {
      'svcClaimDto': svcClaimDto.toJson(),
      'request': request is Map<String, dynamic>
          ? request
          : request is List<Map<String, dynamic>>
              ? request
              : request is List<String>
                  ? request
                  : request
    };
  }
}
