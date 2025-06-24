import 'dart:async';

import 'package:buff_helper/pag_helper/def_helper/scope_helper.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/fleet_health/mdl_pag_fleet_health.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_building_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_profile.dart';
import 'package:buff_helper/up_helper/model/mdl_svc_claim.dart';
import 'package:flutter/foundation.dart';
import 'package:buff_helper/pag_helper/def_helper/def_page_route.dart';

import '../../comm/comm_es.dart';
import '../../comm/comm_fh.dart';

class PagDataProvider extends ChangeNotifier {
  String _fhStatTimeStr = "";
  Map<String, dynamic> _fhStat = {};
  Timer? _fetchFhStatTimer;

  String _scadaDataTimeStr = "";
  Map<String, dynamic> _scadaData = {};
  MdlPagLocation? _selectedLocation;

  String get fhStatTimeStr => _fhStatTimeStr;
  Map<String, dynamic> get fhStat => _fhStat;

  String get scadaDataTimeStr => _scadaDataTimeStr;
  Map<String, dynamic> get scadaData => _scadaData;

  bool isLoading = false;

  DateTime lastScopeListUpdateTime = DateTime.now();
  PagScopeType latestScopeType = PagScopeType.none;

  bool isScopeUpdated = false;

  void onUpdateScope() {
    isScopeUpdated = true;
    clearData();
  }

  void clearData() {
    _fhStatTimeStr = "";
    _fhStat = {};
    _scadaDataTimeStr = "";
    _scadaData = {};
    _selectedLocation = null;
    isLoading = false;
    lastScopeListUpdateTime = DateTime.now();
    latestScopeType = PagScopeType.none;
  }

  //setter for timer
  void setFetchFhStatTimer(Timer? timer) {
    _fetchFhStatTimer = timer;
  }

  void cancelFetchFhStatTimer() {
    _fetchFhStatTimer?.cancel();
  }

  MdlPagLocation? get selectedLocation => _selectedLocation;
  void setSelectedLocation(MdlPagLocation? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  String getFetchedTimeStr(PagPageRoute pageRoute) {
    String timeStr = "";
    switch (pageRoute) {
      case PagPageRoute.consoleHomeDashboard:
        timeStr = _fhStatTimeStr;
        break;
      case PagPageRoute.esInsights:
        timeStr = _scadaDataTimeStr;
        break;
      default:
        break;
    }
    //get time only
    timeStr = timeStr.contains(' ') ? timeStr.split(' ')[1] : '-';
    return timeStr;
  }

  Future<void> fetchAppCtxData(
      MdlPagAppConfig pagAppConfig,
      MdlPagUser? loggedInUser,
      PagPageRoute pageRoute,
      DateTime? refreshTriggerTime) async {
    isLoading = true;

    switch (pageRoute) {
      case PagPageRoute.consoleHomeDashboard:
        await fetchFhStat(pagAppConfig, loggedInUser, refreshTriggerTime);
        break;
      case PagPageRoute.esInsights:
        if (_selectedLocation == null) {
          return;
        }
        Map<String, dynamic> queryMap = {
          'scope': loggedInUser!.selectedScope.toScopeMap(),
        };

        // not for scope, but for the acutal request
        if (_selectedLocation != null) {
          queryMap['location_id'] = _selectedLocation!.id.toString();
          queryMap['location_name'] = _selectedLocation!.name;
        }

        await fetchScadaData(pagAppConfig, loggedInUser, queryMap);
        break;
      default:
        break;
    }
    isLoading = false;
  }

  // Fetch data and notify listeners
  Future<void> fetchFhStat(MdlPagAppConfig pagAppConfig,
      MdlPagUser? loggedInUser, DateTime? refreshTriggerTime) async {
    // Simulate a network call with a delay
    // await Future.delayed(const Duration(seconds: 1));
    if (loggedInUser == null) {
      if (kDebugMode) {
        print("fetchFhStat: loggedInUser is null");
      }
      return;
    }

    try {
      Map<String, dynamic> reqMap = {
        'scope': loggedInUser.selectedScope.toScopeMap(),
      };

      var result = await getFhStat(
        pagAppConfig,
        loggedInUser,
        reqMap,
        SvcClaim(
          userId: loggedInUser.id,
          username: loggedInUser.username,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      if (result['data'] == null) {
        throw Exception('Failed to get stat');
      }

      var data = result['data'];

      if (data['stat_timestamp'] == null) {
        throw Exception('Failed to get stat');
      }

      _fhStatTimeStr = data['stat_timestamp'];

      if (data['fh_stat'] == null) {
        throw Exception('Failed to get stat');
      }
      _fhStat = data['fh_stat'];

      // add something new (e.g. now time) to the data
      // to force the listeners to rebuild
      // _fhStat['stat_timestamp'] = DateTime.now().toIso8601String();
      if (refreshTriggerTime != null) {
        if (kDebugMode) {
          print('refreshTriggerTime: ${refreshTriggerTime.toIso8601String()}');
        }
        _fhStat['refresh_trigger_time'] = refreshTriggerTime.toIso8601String();
      }
      _fhStat['refresh_trigger_time'] = DateTime.now().toIso8601String();

      notifyListeners(); // Notify any listeners that data has changed
    } catch (e) {
      _fhStatTimeStr = "-";
      if (kDebugMode) {
        print("Failed to fetch fh data: $e");
      }
      notifyListeners();
      return;
    }
  }

  Future<void> fetchScadaData(
    MdlPagAppConfig pagAppConfig,
    MdlPagUser? loggedInUser,
    Map<String, dynamic> queryMap,
  ) async {
    try {
      var result = await getScadaData(
        pagAppConfig,
        loggedInUser,
        queryMap,
        MdlPagSvcClaim(
          userId: loggedInUser!.id,
          username: loggedInUser.username,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      if (result['data'] == null) {
        throw Exception('Failed to get stat');
      }

      var data = result['data'];

      if (data['scada_data'] == null) {
        throw Exception('Failed to get SCADA data');
      }

      _scadaDataTimeStr = data['fetch_timestamp'];

      _scadaData = data['scada_data'];

      notifyListeners(); // Notify any listeners that data has changed
    } catch (e) {
      _scadaDataTimeStr = "-";
      if (kDebugMode) {
        print("Failed to fetch scada data: $e");
      }
      notifyListeners();
      return;
    }
  }

  // return true if the scope list is updated
  bool updateScopeListFleetHealth(
    PagScopeType scopeType,
    Map<String, dynamic> fhStat,
    List<dynamic> scopeProfileList,
  ) {
    if (fhStat.isEmpty) {
      return false;
    }

    if (scopeType == latestScopeType) {
      if (DateTime.now().difference(lastScopeListUpdateTime).inSeconds < 1) {
        if (kDebugMode) {
          print(
              'updateScopeListFleetHealth: less than 1 seconds, scopeType: $scopeType, $lastScopeListUpdateTime');
        }
        return false;
      }
    }

    lastScopeListUpdateTime = DateTime.now();
    latestScopeType = scopeType;

    for (var fleetHealth in fhStat['fleet_health_list']) {
      String itemName = fleetHealth['name'];
      String itemId = fleetHealth['id'];
      //plug fh stat to scope profile list
      for (var scopeProfile in scopeProfileList) {
        if (scopeProfile is MdlPagSiteGroupProfile) {
          if (scopeProfile.id.toString() == itemId) {
            scopeProfile.fleetHealth = MdlPagFleetHealth.fromJson(fleetHealth);
            break;
          }
        } else if (scopeProfile is MdlPagSiteProfile) {
          if (scopeProfile.id.toString() == itemId) {
            scopeProfile.fleetHealth = MdlPagFleetHealth.fromJson(fleetHealth);
            break;
          }
        } else if (scopeProfile is MdlPagBuildingProfile) {
          if (scopeProfile.id.toString() == itemId) {
            scopeProfile.fleetHealth = MdlPagFleetHealth.fromJson(fleetHealth);
            break;
          }
        } else if (scopeProfile is MdlPagLocationGroupProfile) {
          if (scopeProfile.id.toString() == itemId) {
            scopeProfile.fleetHealth = MdlPagFleetHealth.fromJson(fleetHealth);
            break;
          }
        }
      }
    }

    return true;
  }
}
