import 'package:buff_helper/pag_helper/pag_project_repo.dart';

const double defaultLat = 1.3521;
const double defaultLng = 103.8198;

// setting here is used to hard limit the scope of the portal
// when deploying to different environment.
// actual limit within the hard limit will be determined by ACL

// this is the list of active portal project scope
// that the deployed portal will support
const List<PagPortalProjectScope> activePortalPagProjectScopeList = [
  PagPortalProjectScope.GI_DE,
  // PagPortalProjectScope.PA_EMS,
  PagPortalProjectScope.ZSP,
  PagPortalProjectScope.MBFC,
  PagPortalProjectScope.SUNSEAP,
  PagPortalProjectScope.CW_P2,
];
