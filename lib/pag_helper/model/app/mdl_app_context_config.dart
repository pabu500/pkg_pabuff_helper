import 'package:buff_helper/pag_helper/app_context_list.dart';
import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:buff_helper/pag_helper/def/scope_helper.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:flutter/foundation.dart';
import 'package:buff_helper/pag_helper/model/app/mdl_page_config.dart';

class MdlPagAppContextConfig {
  late final String appContextName;
  List<MdlPagPageConfig> pageConfigList;
  List<PagScopeType> visibleScopeList;

  MdlPagAppContextConfig({
    required this.appContextName,
    this.pageConfigList = const [],
    this.visibleScopeList = PagScopeType.values,
  });

  //isEmpty
  bool get isEmpty => pageConfigList.isEmpty;

  factory MdlPagAppContextConfig.fromJson(Map<String, dynamic> json) {
    String appCtxName = json.keys.first;

    List<MdlPagPageConfig> pageConfigList = [];
    List<PagScopeType> scopeList = PagScopeType.values;
    Map<String, dynamic> appCtxConfig = json[appCtxName];
    for (String key in appCtxConfig.keys) {
      // these keys is not a page config
      if (key == 'home_page_route') {
        continue;
      }
      if (key == 'app_home_page_route') {
        String pr = appCtxConfig[key];
        try {
          PagPageRoute route = PagPageRoute.values.byName(pr);
          for (MdlPagAppContext appCtx in appContextList) {
            if (appCtx.routeList!.contains(route)) {
              appCtx.appHomePageRoute = route;
              break;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('getPageConfig: $e');
          }
        }

        continue;
      }

      if (key == 'visible_at_scope') {
        String scopeListStr = appCtxConfig[key];
        if (scopeListStr.isEmpty || scopeListStr == 'all') {
          // scopeList = PagScopeType.values;
        } else {
          List<String> scopeKeyList = scopeListStr.split(',');
          scopeList = scopeKeyList.map((e) => PagScopeType.byKey(e)).toList();
        }
        continue;
      }

      String page = key;

      Map<String, dynamic> pageConfig = appCtxConfig[page];
      pageConfigList.add(MdlPagPageConfig.fromJson({
        'name': page,
        ...pageConfig,
      }));
    }

    return MdlPagAppContextConfig(
      appContextName: appCtxName,
      pageConfigList: pageConfigList,
      visibleScopeList: scopeList,
    );
  }
}
