import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/vendor_helper.dart';
import 'package:buff_helper/up_helper/model/mdl_svc_claim.dart';
import 'package:flutter/foundation.dart';
import 'package:buff_helper/pag_helper/def/def_page_route.dart';

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
