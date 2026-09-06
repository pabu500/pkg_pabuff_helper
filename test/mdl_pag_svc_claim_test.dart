import 'dart:convert';

import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/up_helper/enum/enum_acl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MdlPagSvcClaim2 serializes a caller-built permission request', () {
    final claim = MdlPagSvcClaim2(
      permRequestList: [
        {
          'res_label': 'ems.meter.list',
          'operation': AclOperation.read.name,
        },
      ],
    );

    final encoded =
        jsonDecode(jsonEncode(claim.toJson())) as Map<String, dynamic>;
    final permissions = encoded['perm_request_list'] as List<dynamic>;
    final permission = permissions.first as Map<String, dynamic>;

    expect(permission, {
      'res_label': 'ems.meter.list',
      'operation': 'read',
    });
  });
}
