import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_page_route.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final appContext = MdlPagAppContext(
    name: 'ems',
    label: 'EMS',
    shortLabel: 'EMS',
    route: 'ems_dashboard',
    appContextType: PagAppContextType.ems,
  );

  test('builds the resource label for a page route enum value', () {
    expect(
      getResNameByPageRoute(appContext, PagPageRoute.meterManager),
      'ems.meterManager',
    );
  });

  test('keeps page section resource labels below their page route', () {
    expect(
      getResNameByPageRouteSection(
        appContext,
        PagPageRoute.meterManager,
        PageSection.meterList,
      ),
      'ems.meterManager.meterList',
    );
  });

  test('uses the exact full and landlord Ops SoA resource labels', () {
    expect(
      getResNameByPageRouteSection(
        appContext,
        PagPageRoute.tenantManager,
        PageSection.tenantSoA,
      ),
      'ems.tenantManager.tenantSoA',
    );
    expect(
      getResNameByPageRouteSection(
        appContext,
        PagPageRoute.tenantManager,
        PageSection.tenantSoA,
        view: PageSectionView.landlordOpsView,
      ),
      'ems.tenantManager.tenantSoA.landlordOpsView',
    );
  });

  group('Tenant Manager SoA access', () {
    const full = 'ems.tenantManager.tenantSoA';
    const restricted = '$full.landlordOpsView';
    const fullRead = {
      'res_label': full,
      'operation': 'read',
      'result': 'granted',
    };
    const restrictedRead = {
      'res_label': restricted,
      'operation': 'read',
      'result': 'granted',
    };
    const restrictedList = {
      'res_label': restricted,
      'operation': 'list',
      'result': 'granted',
    };

    TenantSoaAccess resolve(List<dynamic> results) => resolveTenantSoaAccess(
      results,
      fullLabel: full,
      landlordOpsLabel: restricted,
    );

    test('opens the restricted tab with both restricted grants', () {
      expect(
        resolve([restrictedRead, restrictedList]),
        TenantSoaAccess.landlordOps,
      );
    });

    test('keeps full access when the full resource is granted', () {
      expect(resolve([fullRead]), TenantSoaAccess.full);
      expect(
        resolve([restrictedRead, restrictedList, fullRead]),
        TenantSoaAccess.full,
      );
    });

    test('hides SoA when neither complete grant is present', () {
      expect(resolve([]), TenantSoaAccess.none);
      expect(resolve([restrictedRead]), TenantSoaAccess.none);
      expect(resolve([restrictedList]), TenantSoaAccess.none);
      expect(
        resolve([
          restrictedRead,
          {...restrictedList, 'res_label': full},
        ]),
        TenantSoaAccess.none,
      );
    });

    test('does not accept contradictory or malformed grants', () {
      expect(
        resolve([
          null,
          restrictedRead,
          restrictedList,
          {...restrictedList, 'result': 'denied'},
          {...fullRead, 'result': true},
        ]),
        TenantSoaAccess.none,
      );
    });
  });
}
