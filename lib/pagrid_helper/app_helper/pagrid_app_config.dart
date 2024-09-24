import '../../pkg_buff_helper.dart';
import '../project_helper/project_setting.dart';

class PaGridAppConfig {
  late final bool loadDashboard;
  late final bool useDevOresvc;
  late final bool useDevUsersvc;
  late final DestPortal destPortal;
  late final ProjectScope activePortalProjectScope;
  late final PagProjectScope activePortalPagProjectScope;
  late final bool includeTestItems;

  PaGridAppConfig({
    required this.loadDashboard,
    required this.useDevOresvc,
    required this.useDevUsersvc,
    required this.destPortal,
    required this.activePortalProjectScope,
    required this.activePortalPagProjectScope,
    this.includeTestItems = false,
  });
}
