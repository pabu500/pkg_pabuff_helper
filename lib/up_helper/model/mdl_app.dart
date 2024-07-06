import 'mdl_acl_setting.dart';
import 'package:flutter/material.dart';

import 'mdl_scope_profile.dart';

enum PortalPage {
  userDashBoard,
  publicFront,
  userService,
  aclService,
  login,
  meterKiv,
  meterIssueCheck,
  meterService,
  meterGroupManager,
  sensorService,
  transactionService,
  creditService,
  creditTransactions,
  projectService,
  buildingService,
  levelService,
  levelDevices,
  equipmentService,
  alarmService,
  paymentSuccess,
  tenantManager,
  tariffManager,
  billingManager,
  jobManager,
  concManager,
}

//page titles
const dashboard = 'Dashboard';
const opsDashboard = 'Ops Dashboard';
const publicFront = 'Public Front';
const userService = 'User Service';
const aclService = 'ACL Service';
const listSearchUser = 'List/Search User';
const listRoles = 'List Roles';
const listPermissions = 'List Permissions';
const createNewAccount = 'Create New Account';
const configACL = 'Configure ACL';
const meterService = 'Meter Service';
const meterGroupManager = 'Meter Group Manager';
const sensorManager = 'Sensor Manager';
const sensorService = 'Sensor Service';
const meterManager = 'Meter Manager';
const siteManager = 'Site Manager';
const creditTransactions = 'Credit & Transactions';
const transactionService = 'Transaction Service';
const transactionHistory = 'Transaction History';
const topupHistory = 'Topup History';
const tariffHistory = 'Tariff History';
const creditService = 'Credit Service';
const topupCredit = 'Topup Credit';
const adjCredit = 'Adjust Credit';
const creditOps = 'Credit Ops';
const batchCrditOps = 'Batch Credit Ops';
const meterInfo = 'Meter Info';
const meterUsage = 'Usage';
const meterCpc = 'CPC';
const sensorInfo = 'Sensor Info';
const listSearchMeter = 'List/Search Meter';
const meterCommissioning = 'Commissioning';
const meterBatchUpdate = 'Batch Update';
const meterOps = 'Ops';
const meterKiv = 'Meter KIV';
const meterAlarm = 'Meter Alarm';
const paymentSuccess = 'Payment Success';
const login = 'Login';
const createUser = 'Create User';
const userProfile = 'User Profile';
const projectService = 'Project Service';
const buildingService = 'Building Service';
const buildingLevels = 'Building Levels';
const levelService = 'Level Service';
const levelDevices = 'Level Devices';
const equipmentService = 'Equipment Service';
const alarmService = 'Alarm Service';
const tenantManager = 'Tenant Manager';
const createTenant = 'Create Tenant';
const tenantInfo = 'Tenant Info';
const tariffManager = 'Tariff Manager';
const billingManager = 'Billing Manager';
const jobManager = 'Task/Report Manager';
const tariffInfo = 'Tariff Info';
const createTariffPackage = 'Create Tariff Package';
const meterGroupInfo = 'Meter Group Info';
const meterGroupUsage = 'Meter Group Usage';
const createMeterGroup = 'Create Meter Group';
const userOps = 'User Ops';
const tenantUserAssignment = 'Tenant User Assignment';
const meterIssueCheck = 'Issue Check';
const taskInfo = 'Task Info';
const billingRecordInfo = 'Billing View';
const listSearchBillingReord = 'List/Search Billing Record';
const createNewBill = 'Create New Bill';
const billRelease = 'Billing Ops';
const concManager = 'Concentrator Manager';
const createConc = 'Create Concentrator';
const concListSearch = 'List/Search Concentrator';

class AppModel extends ChangeNotifier {
  String? subDomain;
  // SharedPreferences prefs;
  ScopeProfile portalScopeProfile;
  String? appName;
  String? appVer;
  String? latestVer;
  String? oreVer;
  // int aa = 0;

  AppModel({
    required this.portalScopeProfile,
    // required this.prefs,
    this.subDomain,
    this.appName,
    this.appVer,
    this.latestVer,
  }) {
    // print('AppModel constructor');
    // _portalScopeProfile = portalScopeProfile;
  }

  // ScopeProfile? get portalScopeProfile => _portalScopeProfile;
  // set scopeProfile(ScopeProfile portalScopeProfile) {
  //   _portalScopeProfile = portalScopeProfile;
  //   notifyListeners();
  // }

  // set ax(int a) {
  //   aa = a;
  //   notifyListeners();
  // }

  PortalPage _pgCur = PortalPage.publicFront;
  PortalPage get curPage => _pgCur;

  set curPage(PortalPage curPage) {
    _pgCur = curPage;
    notifyListeners();
  }

  AclSetting? aclSetting;
  AclSetting? get acl => aclSetting;
  set acl(AclSetting? acl) {
    aclSetting = acl;
    notifyListeners();
  }

  List<dynamic> _pgks = [];
  List<dynamic> get pgks => _pgks;
  set pgks(List<dynamic> pgks) {
    _pgks = pgks;
    notifyListeners();
  }
}
