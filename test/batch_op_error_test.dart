@TestOn('browser')
library;

import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/comm_batch_op.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/comm/comm_tenant_auth.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/up_helper/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final config = MdlPagAppConfig(
    portalType: PagPortalType.pagConsole,
    lazyLoadScope: '',
    loadDashboard: false,
    userSvcEnv: 'dev',
    oreSvcEnv: 'dev',
    activePortalPagProjectScopeList: [],
  );
  final cases = [
    (
      200,
      jsonEncode({
        'error': {'message': 'Balance is invalid'},
      }),
      'Balance is invalid',
    ),
    (200, jsonEncode({'error': 'Operation refused'}), 'Operation refused'),
    (
      401,
      jsonEncode({
        'error': {'message': 'Please sign in again'},
      }),
      'Please sign in again',
    ),
    (401, '', 'Please sign in again'),
    (
      403,
      '<html>Forbidden</html>',
      'You are not authorized to perform this operation',
    ),
    (502, '<html>Gateway error</html>', 'HTTP 502'),
    (
      500,
      jsonEncode({
        'error': {'code': 'internal'},
      }),
      'HTTP 500',
    ),
  ];
  for (final (status, body, message) in cases) {
    test(
      'check and commit show a readable error for HTTP $status / $message',
      () async {
        await http.runWithClient(() async {
          for (final operation in [
            () => doBatchOp(config, {
              'op_name': 'PagPaymentOpType.postPayment',
            }, MdlPagSvcClaim()),
            () => doPagCheckOpList(config, null, MdlPagSvcClaim(), {}),
          ]) {
            Object? caught;
            try {
              await operation();
            } catch (error) {
              caught = error;
            }
            expect(caught, isNotNull);
            expect(getErrorText(caught), message);
          }
        }, () => MockClient((_) async => http.Response(body, status)));
      },
    );
  }
  test('global formatter still hides internal errors and OQG details', () {
    expect(getErrorText(Exception('internal error')), 'general error');
    expect(getErrorText(Exception('m:OQG internal error')), 'general error');
    expect(
      previousSystemDebtorErrorText(Exception('m:Please sign in again')),
      'Please sign in again',
    );
  });
}
