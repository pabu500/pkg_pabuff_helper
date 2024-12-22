import 'package:buff_helper/pag_helper/vendor_helper.dart';
import 'package:buff_helper/pag_helper/def/def_page_route.dart';

enum PagAppContextType {
  consoleHome,
  ems,
  evs,
  cm,
  ptw,
  fh,
  am,
  vm,
  bms,
  pq,
  es,
  ctLab,
}

enum PagAppRouteType {
  route,
  oaxHyperJump,
}

class MdlPagAppContext {
  String name;
  String label;
  String shortLabel;
  String route;
  PagAppContextType appContextType;
  PagAppRouteType? routeType;
  bool is3rdParty = false;
  PlatformVendor? platformVendor;
  VendorCredType? vendorCredType;
  List<Map<String, dynamic>>? menuRouteList;
  List<PagPageRoute>? routeList;
  PagPageRoute? appHomePageRoute;

  MdlPagAppContext({
    required this.name,
    required this.label,
    required this.shortLabel,
    required this.route,
    required this.appContextType,
    this.routeType,
    this.is3rdParty = false,
    this.platformVendor,
    this.vendorCredType,
    this.menuRouteList,
    this.routeList,
    this.appHomePageRoute,
  });
}
