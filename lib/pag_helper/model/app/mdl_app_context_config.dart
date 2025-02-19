import 'package:buff_helper/pag_helper/app_context_list.dart';
import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:buff_helper/pag_helper/def/scope_helper.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:flutter/foundation.dart';
import 'package:buff_helper/pag_helper/model/app/mdl_page_config.dart';

class MdlPagAppContextConfig {
  late final String appContextName;
  List<MdlPagPageConfig> pageConfigList;

  // list of scope that this app context is visible
  List<PagScopeType> visibleScopeList;
  // list of scope that context menu item is visible
  List<Map<String, dynamic>> ctxMenuVisibleScopeList;

  MdlPagAppContextConfig({
    required this.appContextName,
    this.pageConfigList = const [],
    this.visibleScopeList = PagScopeType.values,
    this.ctxMenuVisibleScopeList = const [],
  });

  //isEmpty
  bool get isEmpty => pageConfigList.isEmpty;

  factory MdlPagAppContextConfig.fromJson(Map<String, dynamic> json) {
    String appCtxName = json.keys.first;

    List<MdlPagPageConfig> pageConfigList = [];
    List<Map<String, dynamic>> ctxMenuVisibleScopeList = [];
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

      if (key == 'ctx_menu') {
        Map<String, dynamic> ctxMenu = appCtxConfig[key];
        for (String pageRouteKey in ctxMenu.keys) {
          try {
            PagPageRoute route = PagPageRoute.values.byName(pageRouteKey);
            Map<String, dynamic>? ctxMenuConfig = ctxMenu[route.name];
            if (ctxMenuConfig != null) {
              if (ctxMenuConfig['visible_at_scope'] != null) {
                List<String> scopeKeyList =
                    ctxMenuConfig['visible_at_scope'].split(',');
                List<PagScopeType> scopeList =
                    scopeKeyList.map((e) => PagScopeType.byKey(e)).toList();
                ctxMenuConfig['visible_at_scope'] = scopeList;
              }
            }
            ctxMenuVisibleScopeList.add({
              'route': route,
              'config': ctxMenuConfig,
            });
          } catch (e) {
            if (kDebugMode) {
              print('getPageConfig: $e');
            }
          }
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
      ctxMenuVisibleScopeList: ctxMenuVisibleScopeList,
    );
  }
}
