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
}
