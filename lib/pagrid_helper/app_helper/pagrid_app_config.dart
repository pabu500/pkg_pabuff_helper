import '../../pkg_buff_helper.dart';

class PaGridAppConfig {
  late final bool loadDashboard;
  late final bool useDevOresvc;
  late final bool useDevUsersvc;
  late final DestPortal destPortal;
  late final ProjectScope activePortalProjectScope;

  PaGridAppConfig({
    required this.loadDashboard,
    required this.useDevOresvc,
    required this.useDevUsersvc,
    required this.destPortal,
    required this.activePortalProjectScope,
  });
}
