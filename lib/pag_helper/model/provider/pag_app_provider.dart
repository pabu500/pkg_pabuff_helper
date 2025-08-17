import 'package:flutter/foundation.dart';
import 'package:buff_helper/pag_helper/def_helper/def_page_route.dart';

class PagAppProvider extends ChangeNotifier {
  String? appName;
  String? appVer;
  String? latestVer;
  String? oreVer;

  // PagAppContextType appCtxCur = PagAppContextType.consoleHome;
  PagPageRoute prCur = PagPageRoute.projectPublicFront;

  // PagAppContextType? _currentAppContext;
  // String? _currentRoute;

  PagAppProvider({
    this.appName,
    this.appVer,
    this.latestVer,
  });

  // PagPageRoute get prCur => _srCur;
  // set prCur(PagPageRoute curServiceRoute) {
  //   _srCur = curServiceRoute;
  //   // will trigger setstate in the widget
  //   // notifyListeners();
  // }

  // //getter
  // String? get currentRoute => _currentRoute;
  // //setter
  // set currentRoute(String? currentRoute) {
  //   _currentRoute = currentRoute;
  //   notifyListeners();
  // }

  // PagAppContextType? get currentAppContext => _currentAppContext;

  // set currentAppContext(PagAppContextType? currentAppContext) {
  //   _currentAppContext = currentAppContext;
  //   notifyListeners();
  // }

  // void initAppContext(PagAppContextType appContextType) {
  //   appCtxCur = appContextType;
  // }

  void iniPageRoute(PagPageRoute curPageRoute) {
    prCur = curPageRoute;
  }
}
