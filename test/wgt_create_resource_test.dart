import 'dart:async';
import 'dart:convert';

import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/wgt/app/platform/acl/wgt_create_resource.dart';
import 'package:buff_helper/pag_helper/wgt/scope/wgt_scope_setter.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/xt_ui/wdgt/dropdown/wgt_dropdown_selector.dart';
import 'package:buff_helper/xt_ui/wdgt/input/wgt_text_field2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

const _sectionLabel = 'ems.tenantManager.tenantSoA';
const _viewLabel = '$_sectionLabel.landlordOpsView';
const _typeHint = 'Select Resource Type';
const _contextHint = 'Select App Context';
const _routeHint = 'Select Page Route';
const _sectionHint = 'Select Page Section';
const _viewHint = 'Select Page Section View';

Finder _selector(String hint) => find.byWidgetPredicate(
  (widget) => widget is WgtDropdownSelector && widget.hint == hint,
);

WgtDropdownSelector _dropdown(WidgetTester tester, String hint) =>
    tester.widget(_selector(hint));

Future<void> _choose(WidgetTester tester, String hint, String value) async {
  final dropdown = _dropdown(tester, hint);
  expect(dropdown.items, contains(value));
  dropdown.onSelected(value);
  await tester.pump();
}

Future<void> _chooseSection(WidgetTester tester) async {
  await _choose(tester, _contextHint, 'ems');
  await _choose(tester, _routeHint, 'tenantManager');
  await _choose(tester, _sectionHint, 'tenantSoA');
}

WgtTextField _labelField(WidgetTester tester) => tester.widget(
  find.byWidgetPredicate(
    (widget) => widget is WgtTextField && widget.labelText == 'Label',
  ),
);

WgtCommButton _createButton(WidgetTester tester) => tester.widget(
  find.byWidgetPredicate(
    (widget) => widget is WgtCommButton && widget.label == 'Create Resource',
  ),
);

void _confirmProjectScope(WidgetTester tester) {
  tester.widget<WgtScopeSetter>(find.byType(WgtScopeSetter)).onScopeSet!(null);
}

class _Fixture {
  final uniquenessQueries = <Map<String, String>>[];
  final creates = <Map<String, dynamic>>[];
  FutureOr<http.Response> Function()? onCheck;

  MockClient client() => MockClient((request) async {
    if (request.url.path.endsWith(PagUrlBase.eptGetResTypeInfoList)) {
      return _result('types', {
        'res_type_info_list': [
          for (final type in ['PageSectionView', 'PageSection', 'PagPageRoute'])
            {'label': type},
        ],
      });
    }
    if (request.url.path.endsWith(PagUrlBase.eptCheckItemExists)) {
      uniquenessQueries.add(request.url.queryParameters);
      return onCheck?.call() ?? http.Response('{"exists":"false"}', 200);
    }
    if (request.url.path.endsWith(PagUrlBase.eptCreateAclItem)) {
      creates.add(
        (jsonDecode(request.body) as Map)['request'] as Map<String, dynamic>,
      );
      return _result('resource', {'name': 'acl-res-test'}, status: 201);
    }
    fail('Unexpected request: ${request.method} ${request.url.path}');
  });

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1050);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final user = MdlPagUser(id: 1, username: 'tester')
      ..selectedScope = MdlPagScopeProfile(
        projectProfile: MdlPagProjectProfile(
          id: 1,
          name: 'cw_p2',
          label: 'CW',
          portalProjectScope: PagPortalProjectScope.values.first,
          timezone: 8,
          appContextConfigList: [],
          siteGroupProfileList: [],
        ),
      );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PagUserProvider()..setCurrentUser(user),
        child: MaterialApp(
          home: Scaffold(
            body: WgtCreateResource(
              loggedInUser: user,
              appConfig: MdlPagAppConfig(
                portalType: PagPortalType.pagConsole,
                lazyLoadScope: '',
                loadDashboard: false,
                userSvcEnv: 'dev',
                oreSvcEnv: 'dev',
                activePortalPagProjectScopeList: [],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

http.Response _result(String key, Object value, {int status = 200}) =>
    http.Response(
      jsonEncode({
        'data': {
          'result_key': key,
          'result': {key: value},
        },
      }),
      status,
    );

void main() {
  testWidgets('creates a registered page section view with its exact label', (
    tester,
  ) async {
    final fixture = _Fixture();
    await http.runWithClient(() async {
      await fixture.mount(tester);
      await _choose(tester, _typeHint, 'PageSectionView');
      expect(_labelField(tester).enabled, isFalse);
      expect(_dropdown(tester, _contextHint).items, ['ems']);
      await _choose(tester, _contextHint, 'ems');
      expect(_dropdown(tester, _routeHint).items, ['tenantManager']);
      await _choose(tester, _routeHint, 'tenantManager');
      expect(_dropdown(tester, _sectionHint).items, ['tenantSoA']);
      await _choose(tester, _sectionHint, 'tenantSoA');
      expect(_dropdown(tester, _viewHint).items, ['landlordOpsView']);
      expect(_labelField(tester).initialValue, isNull);
      expect(fixture.uniquenessQueries, isEmpty);
      expect(_createButton(tester).enabled, isFalse);

      await _choose(tester, _viewHint, 'landlordOpsView');
      await tester.pumpAndSettle();
      expect(_labelField(tester).initialValue, _viewLabel);
      expect(fixture.uniquenessQueries, [
        {'t': 'cw_p2.acl_res_cw_p2', 'field': 'label', 'val': _viewLabel},
      ]);
      expect(find.text('available'), findsOneWidget);
      expect(_createButton(tester).enabled, isFalse);
      _confirmProjectScope(tester);
      await tester.pump();
      expect(_createButton(tester).enabled, isTrue);
      await tester.tap(find.text('Create Resource'));
      await tester.pumpAndSettle();

      expect(
        fixture.creates.single,
        containsPair('res_type_label', 'PageSectionView'),
      );
      expect(fixture.creates.single, containsPair('label', _viewLabel));
      expect(fixture.creates.single, containsPair('is_project_scope', 'true'));
      expect(find.text('✓ Resource created'), findsOneWidget);
      expect(_labelField(tester).initialValue, isNull);
      expect(_selector(_viewHint), findsNothing);
    }, fixture.client);
  });

  testWidgets(
    'blocks duplicate view labels and discards checks from earlier selections',
    (tester) async {
      final fixture = _Fixture();
      final staleCheck = Completer<http.Response>();
      fixture.onCheck = () => staleCheck.future;
      await http.runWithClient(() async {
        await fixture.mount(tester);
        await _choose(tester, _typeHint, 'PageSectionView');
        await _chooseSection(tester);
        await _choose(tester, _viewHint, 'landlordOpsView');
        expect(fixture.uniquenessQueries, [
          {'t': 'cw_p2.acl_res_cw_p2', 'field': 'label', 'val': _viewLabel},
        ]);
        _confirmProjectScope(tester);
        await tester.pump();
        expect(_createButton(tester).enabled, isFalse);

        await _choose(tester, _typeHint, 'PageSection');
        expect(_selector(_viewHint), findsNothing);
        expect(_labelField(tester).initialValue, isNull);
        staleCheck.complete(http.Response('{"exists":"false"}', 200));
        await tester.pumpAndSettle();
        expect(find.text('available'), findsNothing);
        expect(_createButton(tester).enabled, isFalse);

        fixture.onCheck = () => http.Response('{"exists":"false"}', 200);
        await _chooseSection(tester);
        await tester.pumpAndSettle();
        expect(_selector(_viewHint), findsNothing);
        expect(_labelField(tester).initialValue, _sectionLabel);
        expect(_createButton(tester).enabled, isTrue);

        fixture.onCheck = () => http.Response('{"exists":"true"}', 200);
        await _choose(tester, _typeHint, 'PageSectionView');
        await _chooseSection(tester);
        await _choose(tester, _viewHint, 'landlordOpsView');
        await tester.pumpAndSettle();
        expect(find.text('taken'), findsOneWidget);
        expect(_createButton(tester).enabled, isFalse);
        expect(fixture.creates, isEmpty);
      }, fixture.client);
    },
  );
}
