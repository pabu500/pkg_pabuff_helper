import 'package:buff_helper/pag_helper/def/def_page_route.dart';
import 'package:buff_helper/pag_helper/model/app/mdl_app_context_config.dart';
import 'package:buff_helper/pag_helper/model/app/mdl_page_config.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'scope/mdl_pag_site_group_profile.dart';
import 'scope/mdl_pag_site_profile.dart';

class MdlPagProjectProfile {
  int id;
  String name;
  String label;
  PagPortalProjectScope portalProjectScope;
  int timezone;
  String? currency = 'SGD';
  String? Function(String?)? validateEntityName;
  String? Function(String?)? validateMeterSn;
  bool? allowCustomAmount = false;
  List<PaymentModeSetting>? paymentSetting = [];
  Map<String, dynamic>? firebaseOptions;
  // Map<String, dynamic>? scopeInfo;
  String? assetFolder;
  double initialMapZoom = 10.0;
  Map<String, double>? mapCenter;
  bool isAllSites = false;
  // List<PagSiteProfile> siteProfileList;
  List<MdlPagSiteGroupProfile> siteGroupProfileList;
  List<MdlPagAppContextConfig> appContextConfigList;
  List<Map<String, dynamic>> deviceTypeInfoList;
  PagPageRoute homePageRoute;
  MdlListColController? siteGroupFilterColController;

  MdlPagProjectProfile({
    required this.id,
    required this.name,
    required this.label,
    required this.portalProjectScope,
    required this.timezone,
    required this.appContextConfigList,
    this.currency,
    this.validateEntityName,
    this.validateMeterSn,
    this.allowCustomAmount,
    this.paymentSetting,
    this.firebaseOptions,
    this.assetFolder,
    this.initialMapZoom = 10.0,
    // this.siteProfileList = const [],
    this.siteGroupProfileList = const [],
    this.mapCenter,
    this.isAllSites = false,
    this.homePageRoute = PagPageRoute.consoleHomeDashboard,
    this.deviceTypeInfoList = const [],
  });

  bool equals(MdlPagProjectProfile? projectProfile) {
    if (projectProfile == null) {
      return false;
    }
    return name == projectProfile.name;
  }

  get isEmpty => siteGroupProfileList.isEmpty;
  get isNotEmpty => siteGroupProfileList.isNotEmpty;

  MdlPagSiteProfile? getSiteProfile(String siteName) {
    // for (PagSiteProfile siteProfile in siteProfileList) {
    //   if (siteProfile.name == siteName) {
    //     return siteProfile;
    //   }
    // }
    for (MdlPagSiteGroupProfile siteGroupProfile in siteGroupProfileList) {
      for (MdlPagSiteProfile siteProfile in siteGroupProfile.siteProfileList) {
        if (siteProfile.name == siteName) {
          return siteProfile;
        }
      }
    }
    return null;
  }

  MdlPagSiteProfile? getDefaultSiteGroupProfile() {
    if (siteGroupProfileList.isEmpty) {
      return null;
    }
    if (siteGroupProfileList.length == 1) {
      return siteGroupProfileList.first.getDefaultSiteProfile();
    }
    return null;
  }

  List<MdlPagSiteProfile> getAllSiteProfileList() {
    List<MdlPagSiteProfile> siteProfileList = [];
    for (MdlPagSiteGroupProfile siteGroupProfile in siteGroupProfileList) {
      siteProfileList.addAll(siteGroupProfile.siteProfileList);
    }
    return siteProfileList;
  }

  int getSiteGroupCount() {
    return siteGroupProfileList.length;
  }

  int getTotalSiteCount() {
    int count = 0;
    for (MdlPagSiteGroupProfile siteGroupProfile in siteGroupProfileList) {
      count += siteGroupProfile.siteProfileList.length;
    }
    return count;
  }

  MdlPagSiteGroupProfile? getSiteGroupProfileById(String? siteGroupIdStr) {
    if (siteGroupIdStr == null) {
      return null;
    }
    for (MdlPagSiteGroupProfile siteGroupProfile in siteGroupProfileList) {
      if (siteGroupProfile.id.toString() == siteGroupIdStr) {
        return siteGroupProfile;
      }
    }
    return null;
  }

  MdlPagSiteGroupProfile? getSiteGroupProfileByName(String? siteGroupName) {
    if (siteGroupName == null) {
      return null;
    }
    for (MdlPagSiteGroupProfile siteGroupProfile in siteGroupProfileList) {
      if (siteGroupProfile.name == siteGroupName) {
        return siteGroupProfile;
      }
    }
    return null;
  }

  void bindFilterColController(MdlListColController? filterColController,
      {MdlPagSiteGroupProfile? defaultSiteGroupProfile,
      bool limitToDefault = false}) {
    if (filterColController == null) {
      return;
    }
    siteGroupFilterColController = filterColController;

    //populate valueList
    filterColController.valueList = [];
    if (defaultSiteGroupProfile != null && limitToDefault) {
      filterColController.valueList!.add({
        'value': defaultSiteGroupProfile!.id.toString(),
        'label': defaultSiteGroupProfile.label,
      });
    } else {
      for (var siteGroupProfile in siteGroupProfileList) {
        filterColController.valueList!.add({
          'value': siteGroupProfile.id.toString(),
          'label': siteGroupProfile.label,
        });
      }
    }

    Map<String, dynamic>? defaultFilterValue;
    if (defaultSiteGroupProfile != null) {
      defaultFilterValue = {
        'value': defaultSiteGroupProfile.id.toString(),
        'label': defaultSiteGroupProfile.label,
      };
    }

    filterColController.resetFilter(defaultFilterValue: defaultFilterValue);

    siteGroupFilterColController?.filterWidgetController?.text =
        defaultFilterValue?['label'] ?? '';
  }

  bool hasAppInfo(String appContextName) {
    // default to true if appInfoList is empty
    if (appContextConfigList.isEmpty) {
      return true;
    }
    for (var appCtxConfig in appContextConfigList) {
      if (appCtxConfig.appContextName == appContextName) {
        return true;
      }
    }
    return false;
  }

  MdlPagPageConfig getPageConfig(String appContextName, String pageName) {
    if (kDebugMode) {
      print(
          'getPageConfig: looking for pageConfig: appCtx:$appContextName, pr:$pageName');
    }
    for (var appCtxConfig in appContextConfigList) {
      if (appCtxConfig.appContextName == appContextName) {
        for (var pageConfig in appCtxConfig.pageConfigList) {
          if (pageConfig.name == pageName) {
            return pageConfig;
          }
        }
      }
    }
    throw Exception('Page config not found');
  }

  // factory MdlPagProjectProfile.fromJson(Map<String, dynamic> json) {
  //   if (json['lat'] == null || json['lng'] == null) {
  //     throw Exception('lat or lng is null');
  //   }

  //   List<PaymentModeSetting> paymentSetting = [];
  //   if (json['payment_mode_setting'] != null) {
  //     json['payment_mode_setting'].forEach((v) {
  //       paymentSetting.add(PaymentModeSetting.fromJson(v));
  //     });
  //   }

  //   // List<PagSiteProfile> siteProfileList = [];
  //   // if (json['site_profile_list'] != null) {
  //   //   for (PagSiteProfile siteProfile in json['site_profile_list']) {
  //   //     siteProfileList.add(siteProfile);
  //   //   }
  //   // }
  //   List<MdlPagSiteGroupProfile> siteGroupProfileList = [];
  //   if (json['site_group_profile_list'] != null) {
  //     for (MdlPagSiteGroupProfile siteGroupProfile
  //         in json['site_group_profile_list']) {
  //       siteGroupProfileList.add(siteGroupProfile);
  //     }
  //   }
  //   if (json['meter_phases'] != null) {
  //     List<String> meterPhases = [];
  //     for (var phase in json['meter_phases']) {
  //       meterPhases.add(phase);
  //     }
  //   }

  //   Map<String, double>? mapCenter = {};
  //   if (json['map_center'] != null) {
  //     mapCenter = {
  //       'lat': json['map_center'][0],
  //       'lng': json['map_center'][1],
  //     };
  //   } else {
  //     mapCenter = {
  //       'lat': json['lat'],
  //       'lng': json['lng'],
  //     };
  //   }

  //   PagPageRoute homePageRoute = PagPageRoute.consoleHomeDashboard;
  //   List<MdlPagAppContextConfig> appCtxConfigList = [];
  //   if (json['app_info_list'] != null) {
  //     for (Map<String, dynamic> appInfo in json['app_info_list']) {
  //       MdlPagAppContextConfig appCtxConfig =
  //           MdlPagAppContextConfig.fromJson(appInfo);
  //       appCtxConfigList.add(appCtxConfig);

  //       String homePageRouteStr = appInfo.values.first['home_page_route'] ?? '';
  //       if (homePageRouteStr.isNotEmpty) {
  //         try {
  //           PagPageRoute route = PagPageRoute.values.byName(homePageRouteStr);
  //           homePageRoute = route;
  //         } catch (e) {
  //           if (kDebugMode) {
  //             print('getPageConfig: $e');
  //           }
  //         }
  //       }
  //     }
  //   }

  //   List<Map<String, dynamic>> deviceTypeInfoList = [];
  //   if (json['device_type_info_list'] != null) {
  //     for (var deviceTypeInfo in json['device_type_info_list']) {
  //       deviceTypeInfoList.add(deviceTypeInfo);
  //     }
  //   }

  //   return MdlPagProjectProfile(
  //     portalProjectScope: json['portal_project_scope'],
  //     id: json['project_id'],
  //     name: json['name'],
  //     label: json['label'],
  //     timezone: json['timezone'],
  //     currency: json['currency'],
  //     validateEntityName: json['validate_entity_displayname'],
  //     validateMeterSn: json['validate_entity_sn'],
  //     allowCustomAmount: json['allow_custom_amount'] ?? false,
  //     paymentSetting: paymentSetting,
  //     firebaseOptions: json['firebase_options'] ?? {},
  //     assetFolder: json['asset_folder'],
  //     initialMapZoom: json['map_zoom'] ?? 10.0,
  //     mapCenter: mapCenter,
  //     // siteProfileList: siteProfileList,
  //     siteGroupProfileList: siteGroupProfileList,
  //     isAllSites: json['all_sites'] ?? false,
  //     appContextConfigList: appCtxConfigList,
  //     deviceTypeInfoList: deviceTypeInfoList,
  //     homePageRoute: homePageRoute,
  //   );
  // }

  PaymentModeSetting? getStripePaymentSetting() {
    for (var setting in paymentSetting!) {
      if (setting.paymentMode == PaymentMode.stripe) {
        return setting;
      }
    }
    return null;
  }

  factory MdlPagProjectProfile.fromJson2(Map<String, dynamic> json) {
    String projectIdStr = json['project_id'];
    int projectId = int.tryParse(projectIdStr) ?? -1;
    assert(projectId != -1);
    String projectName = json['project_name'];
    assert(projectName.isNotEmpty);
    String projectLabel = json['project_label'];
    assert(projectLabel.isNotEmpty);

    late PagPortalProjectScope portalProjectScope;
    try {
      portalProjectScope =
          PagPortalProjectScope.values.byName(projectName.toUpperCase());
    } catch (e) {
      if (kDebugMode) {
        print({'exception in User.fromJson:$e'});
      }
    }

    String projectTimezoneStr = json['project_timezone'];
    int projectTimezone = int.tryParse(projectTimezoneStr) ?? -1;
    assert(projectTimezone != -1);

    String projectCurrency = json['project_currency'] ?? 'MISSING';
    assert(projectCurrency != 'MISSING');

    String projectLatStr = json['project_lat'];
    double projectLat = double.tryParse(projectLatStr) ?? -1.0;
    assert(projectLat > 0);
    String projectLngStr = json['project_lng'];
    double projectLng = double.tryParse(projectLngStr) ?? -1.0;
    assert(projectLng > 0);

    Map<String, double> mapCenter = {
      'lat': projectLat,
      'lng': projectLng,
    };

    String projectMapZoomStr = json['project_map_zoom'];
    double projectMapZoom = double.tryParse(projectMapZoomStr) ?? -1;
    assert(projectMapZoom != -1);

    String projectAssetFolder = json['project_asset_folder'] ?? 'MISSING';
    assert(projectAssetFolder != 'MISSING');

    Map<String, dynamic> roleScope = json['role_scope'];

    bool isAllSites = (roleScope['is_all_sites'] ?? 'false') == 'true';

    // scope list arranged by a list of site groups
    List<Map<String, dynamic>> scopeList = [];
    if (roleScope['scope_list'] != null) {
      scopeList = [...roleScope['scope_list']];
    }
    List<MdlPagSiteGroupProfile> siteGroupProfileList = [];
    for (Map<String, dynamic> siteGroup in scopeList) {
      assert(siteGroup['scope_info'] != null);
      Map<String, dynamic> siteGroupScopeInfo = siteGroup['scope_info'];
      assert(siteGroupScopeInfo['item_info'] != null);
      Map<String, dynamic> siteGroupInfo = siteGroupScopeInfo['item_info'];

      List<Map<String, dynamic>> siteList = [];
      if (siteGroupScopeInfo['site_list'] != null) {
        siteList = [...siteGroupScopeInfo['site_list']];
      }
      siteGroupInfo['site_list'] = siteList;

      MdlPagSiteGroupProfile siteGroupProfile =
          MdlPagSiteGroupProfile.fromJson(siteGroupScopeInfo);
      siteGroupProfileList.add(siteGroupProfile);
    }

    Map<String, dynamic> configInfo = {};
    if (json['config_info'] != null) {
      configInfo = json['config_info'];
    }
    List<Map<String, dynamic>> appInfoList = [];
    List<Map<String, dynamic>> deviceTypeInfoList = [];
    if (configInfo.isNotEmpty) {
      if (configInfo['device'] != null) {
        if (configInfo['app'] != null) {
          for (var appInfo in configInfo['app']) {
            appInfoList.add(appInfo);
          }
        }
        for (var deviceTypeInfo in configInfo['device']) {
          deviceTypeInfoList.add(deviceTypeInfo);
        }
      }
    }

    List<MdlPagAppContextConfig> appCtxConfigList = [];
    PagPageRoute homePageRoute = PagPageRoute.consoleHomeDashboard;
    if (appInfoList.isNotEmpty) {
      for (var appInfo in appInfoList) {
        MdlPagAppContextConfig appCtxConfig =
            MdlPagAppContextConfig.fromJson(appInfo);
        appCtxConfigList.add(appCtxConfig);

        String homePageRouteStr = appInfo.values.first['home_page_route'] ?? '';
        if (homePageRouteStr.isNotEmpty) {
          try {
            PagPageRoute route = PagPageRoute.values.byName(homePageRouteStr);
            homePageRoute = route;
          } catch (e) {
            if (kDebugMode) {
              print('getPageConfig: $e');
            }
          }
        }
      }
    }

    List<PaymentModeSetting> paymentSetting = [];
    if (json['payment_mode_setting'] != null) {
      json['payment_mode_setting'].forEach((v) {
        paymentSetting.add(PaymentModeSetting.fromJson(v));
      });
    }
    if (json['meter_phases'] != null) {
      List<String> meterPhases = [];
      for (var phase in json['meter_phases']) {
        meterPhases.add(phase);
      }
    }

    return MdlPagProjectProfile(
      portalProjectScope: portalProjectScope,
      id: projectId,
      name: projectName,
      label: projectLabel,
      timezone: projectTimezone,
      currency: projectCurrency,
      validateEntityName: json['validate_entity_displayname'],
      validateMeterSn: json['validate_entity_sn'],
      allowCustomAmount: json['allow_custom_amount'] ?? false,
      paymentSetting: paymentSetting,
      firebaseOptions: json['firebase_options'] ?? {},
      assetFolder: projectAssetFolder,
      initialMapZoom: projectMapZoom,
      mapCenter: mapCenter,
      siteGroupProfileList: siteGroupProfileList,
      isAllSites: isAllSites,
      appContextConfigList: appCtxConfigList,
      deviceTypeInfoList: deviceTypeInfoList,
      homePageRoute: homePageRoute,
    );
  }
}
