import 'package:buff_helper/pag_helper/pag_project_repo.dart';

class MdlPagAppConfig {
  late final bool loadDashboard;
  late final bool useDevOresvc;
  late final bool useDevUsersvc;
  late final List<PagPortalProjectScope> activePortalPagProjectScopeList;

  MdlPagAppConfig({
    required this.loadDashboard,
    required this.useDevOresvc,
    required this.useDevUsersvc,
    required this.activePortalPagProjectScopeList,
  });
}
