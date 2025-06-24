import 'package:flutter/foundation.dart';
import 'package:buff_helper/pag_helper/def_helper/def_page_route.dart';

class PagAppProvider extends ChangeNotifier {
  String? appName;
  String? appVer;
  String? latestVer;
  String? oreVer;
  PagPageRoute prCur = PagPageRoute.projectPublicFront;

  String? _currentRoute;

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

  //getter
  String? get currentRoute => _currentRoute;
  //setter
  set currentRoute(String? currentRoute) {
    _currentRoute = currentRoute;
    notifyListeners();
  }

  void iniPageRoute(PagPageRoute curPageRoute) {
    prCur = curPageRoute;
  }
}
