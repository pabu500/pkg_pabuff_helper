import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';

class MdlPagSvcQuery {
  MdlPagSvcClaim svcClaimDto;
  dynamic request;

  MdlPagSvcQuery(this.svcClaimDto, this.request);

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
