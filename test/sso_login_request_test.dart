@TestOn('browser')
library;

import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/comm_user_service.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
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

  test('Microsoft login sends both identity tokens to usersvc2', () async {
    var calls = 0;
    await http.runWithClient(() async {
      await expectLater(
        doLoginPag(config, {
          'authProvider': 'microsoft',
          'portal_type': PagPortalType.pagConsole.value,
          'firebase_id_token': 'firebase-identity',
          'microsoft_id_token': 'microsoft-identity',
        }),
        throwsException,
      );
    }, () => MockClient((request) async {
      calls++;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(request.url.path, endsWith('/login'));
      expect(body['authProvider'], 'microsoft');
      expect(body['username'], '');
      expect(body['password'], '');
      expect(body['firebase_id_token'], 'firebase-identity');
      expect(body['microsoft_id_token'], 'microsoft-identity');
      // Reject after inspecting the request, avoiding storage or real services.
      return http.Response('{"error":"Microsoft sign-in could not be verified"}', 401);
    }));
    expect(calls, 1);
  });
}
