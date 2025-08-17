import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'vendor_helper.dart';
import 'model/mdl_pag_user.dart';
import 'def_helper/def_page_route.dart';

MdlPagAppContext appCtxConsoleHome = MdlPagAppContext(
  name: 'consoleHome',
  label: 'Console Home',
  shortLabel: 'Home',
  route: 'console_home_dashboard',
  appContextType: PagAppContextType.consoleHome,
  routeType: PagAppRouteType.route,
  // menuRouteList: [
  //   getMenueItem(PagPageRoute.consoleHomeDashboard),
  //   getMenueItem(PagPageRoute.consoleHomeUserService),
  //   getMenueItem(PagPageRoute.consoleHomeAcl),
  //   getMenueItem(PagPageRoute.consoleHomeSettings),
  // ],
  routeList: [
    PagPageRoute.consoleHomeDashboard,
    PagPageRoute.consoleHomeUserService,
    PagPageRoute.consoleHomeAcl,
    PagPageRoute.consoleHomeTaskManager,
    PagPageRoute.consoleHomeSettings,
  ],
);
MdlPagAppContext appCtxEms = MdlPagAppContext(
  name: 'ems',
  label: 'EMS',
  shortLabel: 'EMS',
  route: 'ems_dashboard',
  appContextType: PagAppContextType.ems,
  routeType: PagAppRouteType.route,
  // menuRouteList: [
  //   getMenueItem(PagPageRoute.emsDashboard),
  //   getMenueItem(PagPageRoute.meterManager),
  //   getMenueItem(PagPageRoute.tenantManager),
  //   // getMenueItem(PagPageRoute.tariffManager),
  //   getMenueItem(PagPageRoute.billingManager),
  //   // getMenueItem(PagPageRoute.emsTaskReportManager),
  // ],
  routeList: [
    PagPageRoute.emsDashboard,
    PagPageRoute.meterManager,
    PagPageRoute.meterGroupManager,
    PagPageRoute.tenantManager,
    PagPageRoute.tariffManager,
    PagPageRoute.billingManager,
    PagPageRoute.paymentManager,
    PagPageRoute.landlordManager,
    // PagPageRoute.emsTaskReportManager,
  ],
);
MdlPagAppContext appCtxEvs = MdlPagAppContext(
  name: 'evs',
  label: 'EVS',
  shortLabel: 'EVS',
  route: 'evs_dashboard',
  appContextType: PagAppContextType.evs,
  routeType: PagAppRouteType.route,
  // menuRouteList: [
  //   getMenueItem(PagPageRoute.evsDashboard),
  //   getMenueItem(PagPageRoute.meterManager),
  //   getMenueItem(PagPageRoute.creditTransaction),
  //   getMenueItem(PagPageRoute.evsTaskReportManager),
  // ],
  routeList: [
    PagPageRoute.evsDashboard,
    PagPageRoute.evsMeterManager,
    PagPageRoute.evsTenantManager,
    PagPageRoute.creditTransaction,
    PagPageRoute.evsTaskReportManager,
  ],
);
MdlPagAppContext appCtxPtw = MdlPagAppContext(
  name: 'ptw',
  label: 'PTW',
  shortLabel: 'PTW',
  route: 'ptw_dashboard',
  appContextType: PagAppContextType.ptw,
  routeType: PagAppRouteType.route,
  // menuRouteList: [
  //   getMenueItem(PagPageRoute.ptwDashboard),
  //   getMenueItem(PagPageRoute.lockManager),
  //   getMenueItem(PagPageRoute.ptwWorkSiteManager),
  //   getMenueItem(PagPageRoute.ptwApplicationManager),
  //   getMenueItem(PagPageRoute.ptwWorkOrderManager),
  //   getMenueItem(PagPageRoute.ptwTaskReportManager),
  // ],
  routeList: [
    PagPageRoute.ptwDashboard,
    PagPageRoute.lockManager,
    PagPageRoute.ptwWorkSiteManager,
    PagPageRoute.ptwApplicationManager,
    PagPageRoute.ptwWorkOrderManager,
    PagPageRoute.ptwTaskReportManager,
  ],
);
MdlPagAppContext appCtxVm = MdlPagAppContext(
  name: 'vm',
  label: 'Video Monioring',
  shortLabel: 'VM',
  route: 'vm_dashboard',
  appContextType: PagAppContextType.vm,
  routeType: PagAppRouteType.route,
  // menuRouteList: [
  //   getMenueItem(PagPageRoute.vmDashboard),
  //   getMenueItem(PagPageRoute.cameraManager),
  //   getMenueItem(PagPageRoute.vmEventManager),
  //   getMenueItem(PagPageRoute.vmTaskReportManager),
  // ],
  routeList: [
    PagPageRoute.vmDashboard,
    PagPageRoute.cameraManager,
    PagPageRoute.vmEventManager,
    PagPageRoute.vmTaskReportManager,
  ],
);
MdlPagAppContext appCtxBms = MdlPagAppContext(
  name: 'bms',
  label: 'BMS',
  shortLabel: 'BMS',
  route: 'bms',
  appContextType: PagAppContextType.bms,
  routeType: PagAppRouteType.route,
  // menuRouteList: [
  //   getMenueItem(PagPageRoute.bmsDashboard),
  // ],
  routeList: [
    PagPageRoute.bmsDashboard,
  ],
);
MdlPagAppContext appCtxFh = MdlPagAppContext(
  name: 'fh',
  label: 'Fleet Health',
  shortLabel: 'FH',
  route: 'fh_dashboard',
  appContextType: PagAppContextType.fh,
  routeType: PagAppRouteType.route,
  // menuRouteList: [
  //   getMenueItem(PagPageRoute.fhDashboard),
  //   getMenueItem(PagPageRoute.fhEventManager),
  //   getMenueItem(PagPageRoute.fhTaskReportManager),
  // ],
  routeList: [
    PagPageRoute.fhDashboard,
    PagPageRoute.fhEventManager,
    PagPageRoute.fhTaskReportManager,
  ],
);
MdlPagAppContext appCtxAm = MdlPagAppContext(
  name: 'am',
  label: 'Asset Management',
  shortLabel: 'AM',
  route: 'am_dashboard',
  appContextType: PagAppContextType.am,
  routeType: PagAppRouteType.route,
  // menuRouteList: [
  //   getMenueItem(PagPageRoute.amDashboard),
  //   getMenueItem(PagPageRoute.amDeviceManager),
  //   getMenueItem(PagPageRoute.amScopeManager),
  // ],
  routeList: [
    PagPageRoute.amDashboard,
    PagPageRoute.amDeviceManager,
    PagPageRoute.amScopeManager,
    PagPageRoute.amCommsManager,
  ],
);
MdlPagAppContext appCtxQq = MdlPagAppContext(
  name: 'pq',
  label: 'Power Quality',
  shortLabel: 'PQ',
  route: 'pq_dashboard',
  appContextType: PagAppContextType.pq,
  routeType: PagAppRouteType.route,
  // menuRouteList: [
  //   getMenueItem(PagPageRoute.pqDashboard),
  //   getMenueItem(PagPageRoute.pqInsights),
  //   getMenueItem(PagPageRoute.ctLab)
  // ],
  routeList: [
    PagPageRoute.pqDashboard,
    PagPageRoute.pqInsights,
    PagPageRoute.ctLab,
  ],
);
// final PagAppContext ctlab = PagAppContext(
//   name: 'ctlab',
//   label: 'CT Lab',
//   shortLabel: 'CT Lab',
//   route: 'ctlab',
//   is3rdParty: true,
//   platformVendor: PlatformVendor.ctlab,
//   vendorCredType: VendorCredType.access_token,
//   appContextType: PagAppContextType.ctLab,
//   routeType: PagAppRouteType.route,
//   menuRouteList: [
//     getMenueItem(PagPageRoute.ctLab),
//   ],
// );
MdlPagAppContext appCtxEs = MdlPagAppContext(
  name: 'es',
  label: 'Eelctrical Supervisory',
  shortLabel: 'ES',
  route: 'es_dashboard',
  appContextType: PagAppContextType.es,
  routeType: PagAppRouteType.route,
  // menuRouteList: [
  //   getMenueItem(PagPageRoute.esDashboard),
  //   getMenueItem(PagPageRoute.esInsights),
  // ],
  routeList: [
    PagPageRoute.esDashboard,
    PagPageRoute.esInsights,
  ],
);

final List<MdlPagAppContext> appContextList = [
  appCtxConsoleHome,
  appCtxAm,
  appCtxFh,
  appCtxEms,
  appCtxEvs,
  appCtxPtw,
  appCtxVm,
  appCtxBms,
  appCtxQq,
  appCtxEs,
  // ctlab,
];

MdlPagAppContext getPageContext(PagPageRoute pageRoute) {
  for (var appContext in appContextList) {
    if (appContext.routeList!.any((route) => route == pageRoute)) {
      return appContext;
    }
  }
  return appCtxConsoleHome;
}

void routeGuard(BuildContext context, MdlPagUser? loggedInUser,
    {MdlPagAppContext? appContext, bool? goHome}) {
  if (loggedInUser == null) {
    return;
  }
  PagPageRoute pageRouteHome =
      loggedInUser.selectedScope.projectProfile!.homePageRoute;
  String homeRouteStr = getRoute(pageRouteHome);
  if (kDebugMode) {
    print('homeRouteStr: $homeRouteStr');
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (appContext != null) {
      if (!loggedInUser.selectedScope.projectProfile!
          .hasAppInfo(appContext.name)) {
        if (kDebugMode) {
          print('routeGuard: appContext ${appContext.name} not found');
        }
        context.go(pageRouteHome == PagPageRoute.none
            ? getRoute(PagPageRoute.techIssue)
            : homeRouteStr);
      }
    }
    if (goHome == true) {
      if (kDebugMode) {
        print('goHome: $homeRouteStr');
      }
      GoRouter.of(context).go(homeRouteStr);
    }
  });
}
