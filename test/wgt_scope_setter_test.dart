import 'dart:convert';

import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_building_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_profile.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';
import 'package:buff_helper/pag_helper/wgt/scope/wgt_scope_setter.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_input_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

final config = MdlPagAppConfig(
  portalType: PagPortalType.pagConsole,
  lazyLoadScope: '',
  loadDashboard: false,
  userSvcEnv: 'dev',
  oreSvcEnv: 'dev',
  activePortalPagProjectScopeList: [],
);

class ScopeFixture {
  final location = MdlPagLocation(id: 5, name: 'location', label: 'Location 1');
  late final locationGroup = MdlPagLocationGroupProfile(
    id: 4,
    name: 'group',
    label: 'Group 1',
    latitude: 0,
    longitude: 0,
    locationList: [location],
  );
  late final building = MdlPagBuildingProfile(
    id: 3,
    name: 'building',
    label: 'Building 1',
    locationGroupProfileList: [locationGroup],
  );
  late final site = MdlPagSiteProfile(
    id: 2,
    name: 'site',
    label: 'Site 1',
    latitude: 0,
    longitude: 0,
    timezone: 8,
    buildingProfileList: [building],
  );
  late final siteGroup = MdlPagSiteGroupProfile(
    id: 1,
    name: 'sites',
    label: 'Sites',
    siteProfileList: [site],
  );
  dynamic committed;
  int fetches = 0;

  Future<void> show(
    WidgetTester tester, {
    bool? autoCascade,
    Map<String, dynamic>? savedScope,
  }) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final user = MdlPagUser(id: 1, username: 'tester');
    user.selectedScope = MdlPagScopeProfile(
      projectProfile: MdlPagProjectProfile(
        id: 1,
        name: 'cw_p2',
        label: 'CW',
        portalProjectScope: PagPortalProjectScope.values.first,
        timezone: 8,
        appContextConfigList: [],
        siteGroupProfileList: [siteGroup],
      ),
    );
    final provider = PagUserProvider()..setCurrentUser(user);
    // Omit the parameter in the default case to exercise the public default.
    final setter = autoCascade != null
        ? WgtScopeSetter(
            appConfig: config,
            width: 600,
            forItemKind: PagItemKind.tariff,
            autoCascadeScopeFilter: autoCascade,
            itemScopeMap: savedScope,
            onScopeSet: (scope) => committed = scope,
          )
        : WgtScopeSetter(
            appConfig: config,
            width: 600,
            forItemKind: PagItemKind.tariff,
            itemScopeMap: savedScope,
            onScopeSet: (scope) => committed = scope,
          );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(body: Center(child: setter)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit));
    await tester.pumpAndSettle();
  }

  MockClient client() => MockClient((request) async {
    fetches++;
    return http.Response(
      jsonEncode({
        'data': {
          'scope_info_list': [
            {'id': '5', 'name': 'location', 'label': 'Location 1'},
          ],
        },
      }),
      200,
    );
  });
}

DropdownButton<T> dropdown<T>(WidgetTester tester) =>
    tester.widget<DropdownButton<T>>(find.byType(DropdownButton<T>));

Future<void> select<T>(WidgetTester tester, T value) async {
  dropdown<T>(tester).onChanged!(value);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'disabling cascading leaves children unselected and commits site scope',
    (tester) async {
      final fixture = ScopeFixture();
      await fixture.show(tester, autoCascade: false);
      await select(tester, fixture.siteGroup);
      expect(dropdown<MdlPagSiteProfile>(tester).value, isNull);
      expect(
        dropdown<MdlPagSiteProfile>(tester).items!.single.value,
        fixture.site,
      );
      await select(tester, fixture.site);
      expect(dropdown<MdlPagBuildingProfile>(tester).value, isNull);
      expect(
        dropdown<MdlPagBuildingProfile>(tester).items!.single.value,
        fixture.building,
      );
      expect(dropdown<MdlPagLocationGroupProfile>(tester).value, isNull);
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(fixture.committed, same(fixture.site));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'disabling cascading leaves location groups and fetched locations unselected',
    (tester) async {
      final fixture = ScopeFixture();
      await http.runWithClient(() async {
        await fixture.show(tester, autoCascade: false);
        await select(tester, fixture.siteGroup);
        await select(tester, fixture.site);
        await select(tester, fixture.building);
        expect(dropdown<MdlPagLocationGroupProfile>(tester).value, isNull);
        await select(tester, fixture.locationGroup);
        final locationInput = tester.widget<WgtInputDropdown>(
          find.byType(WgtInputDropdown),
        );
        expect(locationInput.initialValue, isNull);
        expect(locationInput.items.single['value'], '5');
        expect(fixture.fetches, 1);
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();
        expect(fixture.committed, same(fixture.locationGroup));
        expect(tester.takeException(), isNull);
      }, fixture.client);
    },
  );

  for (final autoCascade in <bool?>[null, true]) {
    testWidgets(
      autoCascade == null
          ? 'default cascades through sole children including fetched locations'
          : 'explicit true cascades through sole children including fetched locations',
      (tester) async {
        final fixture = ScopeFixture();
        await http.runWithClient(() async {
          await fixture.show(tester, autoCascade: autoCascade);
          await select(tester, fixture.siteGroup);
          expect(dropdown<MdlPagSiteProfile>(tester).value, fixture.site);
          expect(
            dropdown<MdlPagBuildingProfile>(tester).value,
            fixture.building,
          );
          expect(
            dropdown<MdlPagLocationGroupProfile>(tester).value,
            fixture.locationGroup,
          );
          final locationInput = tester.widget<WgtInputDropdown>(
            find.byType(WgtInputDropdown),
          );
          expect(locationInput.initialValue!['value'], '5');
          expect(fixture.fetches, 1);
          await tester.tap(find.byIcon(Icons.check));
          await tester.pumpAndSettle();
          expect(fixture.committed, fixture.location);
          expect(tester.takeException(), isNull);
        }, fixture.client);
      },
    );
  }

  testWidgets('default preserves an existing saved scope', (tester) async {
    final fixture = ScopeFixture();
    await fixture.show(
      tester,
      savedScope: {
        'site_group_name': 'sites',
        'site_name': 'site',
        'building_name': 'building',
        'location_group_name': 'group',
        'location_name': 'location',
      },
    );
    expect(dropdown<MdlPagSiteProfile>(tester).value, fixture.site);
    expect(dropdown<MdlPagBuildingProfile>(tester).value, fixture.building);
    expect(
      dropdown<MdlPagLocationGroupProfile>(tester).value,
      fixture.locationGroup,
    );
    final locationInput = tester.widget<WgtInputDropdown>(
      find.byType(WgtInputDropdown),
    );
    expect(locationInput.initialValue!['value'], '5');
    expect(tester.takeException(), isNull);
  });
}
