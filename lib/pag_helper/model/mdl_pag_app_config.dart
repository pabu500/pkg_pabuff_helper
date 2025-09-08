import 'package:buff_helper/pag_helper/def_helper/def_role.dart';
import 'package:buff_helper/pag_helper/pag_project_repo.dart';

class MdlPagAppConfig {
  late final PagPortalType portalType;
  late final String lazyLoadScope;
  late final bool loadDashboard;
  // late final bool useDevOresvc;
  late final String userSvcEnv;
  // late final String ppmsvcEnv;
  late final String oreSvcEnv;
  // late final bool useDevUsersvc;
  late final List<PagPortalProjectScope> activePortalPagProjectScopeList;

  MdlPagAppConfig({
    required this.portalType,
    required this.lazyLoadScope,
    required this.loadDashboard,
    // required this.useDevOresvc,
    required this.userSvcEnv,
    // required this.ppmsvcEnv,
    required this.oreSvcEnv,
    // required this.useDevUsersvc,
    required this.activePortalPagProjectScopeList,
  });
}
