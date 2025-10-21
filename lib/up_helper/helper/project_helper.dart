import '../../pkg_buff_helper.dart';

enum ProjectScope {
  EVS2_PA,
  EVS2_NUS,
  EVS2_NUS_OLD,
  EVS2_SUTD,
  EVS2_NTU,
  EVS2_SMU,
  EVS2_SIT,
  EVS2_SUSS,
  EVS2_ZSP,
  NONE,
  SG_ALL,
  GLOBAL,
  EMS_SMRT,
  EMS_CW_NUS,
  MMC_GI_DE,
  // ZSP,
}

enum SiteScope {
  PA_ATP,
  NUS_PGPR,
  NUS_YNC,
  NUS_RVRC,
  NUS_UTOWN,
  NUS_VH,
  SUTD_CAMPUS,
  NTU_MR,
  NONE,
  SG_ALL,
  GLOBAL,
  SMRT_Clementi,
  SMRT_Dover,
  SMRT_Buona_Vista,
  SMRT_Commonwealth,
  SMRT_Queenstown,

  CW_NUS_KRC,
  CW_NUS_BTC,
  CW_NUS_UTOWN,

  GI_DE_DEMO,

  ZSP,
}

const evs2Projects = [
  ProjectScope.EVS2_NUS,
  ProjectScope.EVS2_SUTD,
  ProjectScope.EVS2_NTU,
  ProjectScope.EVS2_PA,
  ProjectScope.EVS2_ZSP,
  ProjectScope.SG_ALL,
  ProjectScope.NONE,
];
const emsProjects = [
  ProjectScope.EMS_SMRT,
  ProjectScope.EMS_CW_NUS,
  ProjectScope.NONE,
];

const evs2Sites = [
  SiteScope.NUS_PGPR,
  SiteScope.NUS_YNC,
  SiteScope.NUS_RVRC,
  SiteScope.NUS_UTOWN,
  SiteScope.NUS_VH,
  SiteScope.SUTD_CAMPUS,
  SiteScope.NTU_MR,
  SiteScope.SG_ALL,
  SiteScope.PA_ATP,
  SiteScope.ZSP,
  SiteScope.NONE,
];

const emsSites = [
  SiteScope.SMRT_Clementi,
  SiteScope.SMRT_Dover,
  SiteScope.SMRT_Buona_Vista,
  SiteScope.SMRT_Commonwealth,
  SiteScope.SMRT_Queenstown,
  SiteScope.SG_ALL,
  SiteScope.NONE,
];

const cwNusSites = [
  SiteScope.CW_NUS_KRC,
  SiteScope.CW_NUS_BTC,
  SiteScope.CW_NUS_UTOWN,
  SiteScope.SG_ALL,
  SiteScope.NONE,
];

ScopeProfile? getActiveScopeProfile(ProjectScope activePortalProjectScope) {
  for (var scopeProfile in scopeProfiles) {
    if ((scopeProfile['project_scope'] as ProjectScope) ==
        activePortalProjectScope) {
      return ScopeProfile.fromJson(scopeProfile);
    }
  }
  return null;
}

final scopeProfiles = [
  {
    'project_scope': ProjectScope.EVS2_PA,
    'project_sites': [
      SiteScope.PA_ATP,
    ],
    'timezone': 8,
    'currency': 'SGD',
    'validate_entity_sn': mmsSnValidator,
    'validate_entity_displayname': (displayname) {
      //8 digits, start with '1'
      RegExp exp1 = RegExp(r'^1\d{7}$');
      RegExp exp2 = RegExp(r'^2\d{7}$');
      RegExp exp3 = RegExp(r'^3\d{7}$');
      if (exp1.hasMatch(displayname) ||
          exp2.hasMatch(displayname) ||
          exp3.hasMatch(displayname)) {
        return null;
      } else {
        return 'Invalid displayname';
      }
    },
    'meter_phases': ['1p'],
  },
  {
    'project_scope': ProjectScope.MMC_GI_DE,
    'project_sites': [
      SiteScope.GI_DE_DEMO,
    ],
    'timezone': 8,
    'currency': 'SGD',
    'validate_entity_sn': mmsSnValidator,
    'validate_entity_displayname': (displayname) {
      //8 digits, start with '1'
      RegExp exp1 = RegExp(r'^1\d{7}$');
      RegExp exp2 = RegExp(r'^2\d{7}$');
      RegExp exp3 = RegExp(r'^3\d{7}$');
      if (exp1.hasMatch(displayname) ||
          exp2.hasMatch(displayname) ||
          exp3.hasMatch(displayname)) {
        return null;
      } else {
        return 'Invalid displayname';
      }
    },
    'meter_phases': ['1p'],
  },
  {
    'project_scope': ProjectScope.SG_ALL,
    'project_sites': [
      SiteScope.NUS_PGPR,
      SiteScope.NUS_YNC,
      SiteScope.NUS_RVRC,
      SiteScope.NUS_UTOWN,
      SiteScope.NUS_VH,
      SiteScope.SUTD_CAMPUS,
      SiteScope.NTU_MR,
    ],
    'timezone': 8,
    'currency': 'SGD',
    'validate_entity_sn': mmsSnValidator,
    'validate_entity_displayname': (displayname) {
      //8 digits, start with '1'
      RegExp exp1 = RegExp(r'^1\d{7}$');
      RegExp exp2 = RegExp(r'^2\d{7}$');
      RegExp exp3 = RegExp(r'^3\d{7}$');
      if (exp1.hasMatch(displayname) ||
          exp2.hasMatch(displayname) ||
          exp3.hasMatch(displayname)) {
        return null;
      } else {
        return 'Invalid displayname';
      }
    },
    'meter_phases': ['1p'],
  },
  {
    'project_scope': ProjectScope.EVS2_NUS,
    'project_sites': [
      SiteScope.NUS_PGPR,
      SiteScope.NUS_YNC,
      SiteScope.NUS_RVRC,
      SiteScope.NUS_UTOWN,
      SiteScope.NUS_VH,
    ],
    'timezone': 8,
    'currency': 'SGD',
    'validate_entity_displayname': (displayname) {
      //8 digits, start with '1'
      RegExp exp = RegExp(r'^1\d{7}$');
      if (exp.hasMatch(displayname)) {
        return null;
      } else {
        return 'Invalid displayname';
      }
    },
    'allow_custom_amount': true,
    'payment_mode_setting': {
      {
        'payment_mode': PaymentMode.stripe,
        'active': false,
        'show': false,
      },
      {
        'payment_mode': PaymentMode.netsQR,
        'active': false,
        'show': false,
        'pub_key': 'd877185d-af96-43a5-9f53-48a3c543c3d5',
      },
      {
        'payment_mode': PaymentMode.enets,
        'active': true,
        'show': true,
        'pub_key': '154eb31c-0f72-45bb-9249-84a1036fd1ca',
      },
    },
  },
  {
    'project_scope': ProjectScope.EVS2_SUTD,
    'project_sites': [SiteScope.SUTD_CAMPUS],
    'timezone': 8,
    'currency': 'SGD',
    'validate_meter_displayname': (displayname) {
      //8 digits, start with '2'
      RegExp exp = RegExp(r'^2\d{7}$');
      if (exp.hasMatch(displayname)) {
        return null;
      } else {
        return 'Invalid displayname';
      }
    },
    'payment_mode_setting': [
      {
        'payment_mode': PaymentMode.stripe,
        'active': false,
        'show': true,
      },
      {
        'payment_mode': PaymentMode.netsQR,
        'active': false,
        'show': true,
      },
      {
        'payment_mode': PaymentMode.enets,
        'active': true,
        'show': true,
      },
    ],
  },
  {
    'project_scope': ProjectScope.EVS2_NTU,
    'project_sites': [SiteScope.NTU_MR],
    'timezone': 8,
    'currency': 'SGD',
    'validate_entity_displayname': (displayname) {
      //8 digits, start with '3'
      RegExp exp = RegExp(r'^3\d{7}$');
      if (exp.hasMatch(displayname)) {
        return null;
      } else {
        return 'Invalid displayname';
      }
    },
    'payment_mode_setting': [
      {
        'payment_mode': PaymentMode.stripe,
        'active': true,
        'show': true,
        //'publishableKey':
        'pub_key':
            'pk_live_51MokvvAzcY0NKTCHoedkapOh9Tl9VEwT3Nz2bRn0vcGugAmFJBoOrH0GprHSj99GLhaDByJyciLVOmsoSiuHuY7F00N9f88BqB',
        'merchant_identifier': 'merchant.com.evs2.ntu',
        'pay_svc_host_url': 'https://p3.evs.com.sg'
      },
      {
        'payment_mode': PaymentMode.netsQR,
        'active': false,
        'show': true,
      },
      {
        'payment_mode': PaymentMode.enets,
        'active': false,
        'show': true,
      },
    ],
  },
  {
    'project_scope': ProjectScope.EMS_SMRT,
    'meter_type': ItemType.meter_3p,
    'project_sites': [
      SiteScope.SMRT_Clementi,
      SiteScope.SMRT_Dover,
      SiteScope.SMRT_Buona_Vista,
      SiteScope.SMRT_Commonwealth,
      SiteScope.SMRT_Queenstown,
    ],
    'timezone': 8,
    'currency': 'SGD',
    'validate_entity_displayname': (displayname) {
      //8 digits, start with '3'
      RegExp exp = RegExp(r'^3\d{7}$');
      if (exp.hasMatch(displayname)) {
        return null;
      } else {
        return 'Invalid displayname';
      }
    },
    'validate_entity_sn': (sn) {
      return null;
    },
  },
  {
    'project_scope': ProjectScope.EMS_CW_NUS,
    'meter_type': ItemType.meter_iwow,
    'project_sites': [
      {
        'key': SiteScope.CW_NUS_KRC,
        'name': 'KRC',
        'color': AppColors.contentColorCyan,
      },
      {
        'key': SiteScope.CW_NUS_BTC,
        'name': 'BTC',
        'color': AppColors.contentColorLightGrey,
      },
      {
        'key': SiteScope.CW_NUS_UTOWN,
        'name': 'UTown',
        'color': AppColors.contentColorLightTeal,
      },
    ],
    'timezone': 8,
    'currency': 'SGD',
    'validate_entity_displayname': (displayname) {
      //8 digits, start with '3'
      RegExp exp = RegExp(r'^3\d{7}$');
      if (exp.hasMatch(displayname)) {
        return null;
      } else {
        return 'Invalid displayname';
      }
    },
    'validate_entity_sn': (sn) {
      return null;
    },
    'meter_usage_factor': {
      MeterType.btu: 1 / 3.516, //1 / 3.5168528421,
      MeterType.electricity1p: 1,
      MeterType.electricity3p: 1,
      MeterType.gas: 1,
      MeterType.water: 1,
    },
    'firebase_options': {
      'apiKey': 'AIzaSyB5DxSfMVNZ2xI1hTOUP42GIEcvpGZ4nms',
      'authDomain': 'ems-cw-nus.firebaseapp.com',
      'projectId': 'ems-cw-nus',
      'storageBucket': 'ems-cw-nus.appspot.com',
      'messagingSenderId': '949621989494',
      'appId': '1:949621989494:web:2e67a89ce429494f043f57',
    },
  },
  {
    'project_scope': ProjectScope.EVS2_ZSP,
    'meter_type': ItemType.meter,
    'project_sites': [
      {
        'key': SiteScope.ZSP,
        'name': 'ZSP',
        'color': AppColors.contentColorCyan,
      },
    ],
    'timezone': 8,
    'currency': 'SGD',
  }
];

String? mmsSnValidator(value) {
  //12 digits, start with '202', all digits
  RegExp exp = RegExp(r'^202\d{9}$');
  if (exp.hasMatch(value)) {
    return null;
  } else {
    return 'Invalid sn';
  }
}

ScopeProfile? getActivePortalScopeProfile(ProjectScope activePortalProjectScope,
    List<Map<String, dynamic>> scopeProfiles) {
  for (var scopeProfile in scopeProfiles) {
    if (scopeProfile['project_scope'] == activePortalProjectScope) {
      return ScopeProfile.fromJson(scopeProfile);
    }
  }
  return null;
}

// get list of scopes and sort them into project and site scopes
// the scope strings must be in the format of
// "project_nus" or "site_nus_pgpr"
Map<String, dynamic> getSortedScope(List<String>? scopes) {
  if (scopes == null || scopes.isEmpty) {
    return {
      'project_scopes': [],
      'site_scopes': [],
    };
  }

  List<ProjectScope> projectScopes = [];
  List<SiteScope> siteScopes = [];

  for (var scope in scopes) {
    if (scope.toLowerCase().contains('global')) {
      projectScopes.add(ProjectScope.GLOBAL);
      siteScopes.add(SiteScope.GLOBAL);
      break;
    } else if (scope.toLowerCase().contains('sg_all')) {
      projectScopes.add(ProjectScope.SG_ALL);
      siteScopes.add(SiteScope.SG_ALL);
      break;
    }

    if (scope.contains('project_')) {
      projectScopes.add(getProjectScopeFromStr2(scope));
    } else if (scope.contains('site_')) {
      siteScopes.add(getSiteScopeFromStr2(scope));
    }
  }
  // if project scope is global or sg_all,
  // add all projects and sites
  // filter out NONE
  if (projectScopes.contains(ProjectScope.GLOBAL) ||
      projectScopes.contains(ProjectScope.SG_ALL)) {
    projectScopes = [];
    projectScopes.addAll(evs2Projects.where((e) =>
        e != ProjectScope.NONE &&
        e != ProjectScope.GLOBAL &&
        e != ProjectScope.SG_ALL));
    //sort alphabetically
    projectScopes.sort((a, b) => a.toString().compareTo(b.toString()));
    //add sg_all to the firt position
    projectScopes.insert(0, ProjectScope.SG_ALL);

    siteScopes = [];
    siteScopes.addAll(evs2Sites.where((e) =>
        e != SiteScope.NONE && e != SiteScope.GLOBAL && e != SiteScope.SG_ALL));
    //sort alphabetically
    siteScopes.sort((a, b) => a.toString().compareTo(b.toString()));
    //add sg_all to the firt position
    // siteScopes.insert(0, SiteScope.SG_ALL);
  }

  return {
    'project_scopes': projectScopes,
    'site_scopes': siteScopes,
  };
}

ProjectScope getProjectScopeFromStr2(String scopeStr) {
  for (ProjectScope projectScope in ProjectScope.values) {
    if (scopeStr.toLowerCase().contains(projectScope.name.toLowerCase())) {
      return projectScope;
    }
  }
  return ProjectScope.NONE;
}

SiteScope getSiteScopeFromStr2(String scopeStr) {
  for (SiteScope siteScope in SiteScope.values) {
    // if (scopeStr.toLowerCase().contains(siteScope.name.toLowerCase())) {
    if (scopeStr.toLowerCase() == 'site_${siteScope.name.toLowerCase()}') {
      // if (scopeStr.toLowerCase() == siteScope.name.toLowerCase()) {
      return siteScope;
    } else if (scopeStr.toLowerCase() == siteScope.name.toLowerCase()) {
      return siteScope;
    }
  }
  return SiteScope.NONE;
}

List<SiteScope> getProjectSites(
    ProjectScope? projectScope, List<Map<String, dynamic>> scopeProfiles) {
  if (projectScope == null) return [];
  for (var scopeProfile in scopeProfiles) {
    if (scopeProfile['project_scope'] == projectScope) {
      List<SiteScope> projectSites = [];
      if (scopeProfile['project_sites'] != null) {
        for (var site in scopeProfile['project_sites']) {
          if (site is SiteScope) {
            projectSites.add(site);
          } else {
            projectSites.add(site['key']);
          }
        }
      }
      return projectSites;
    }
  }
  return [];
}

double getProjectMeterUsageFactor(ProjectScope? projectScope,
    List<Map<String, dynamic>> scopeProfiles, MeterType? meterType) {
  if (projectScope == null) return 1.0;
  if (meterType == null) return 1.0;
  for (var scopeProfile in scopeProfiles) {
    if (scopeProfile['project_scope'] == projectScope) {
      if (scopeProfile['meter_usage_factor'] != null) {
        if (scopeProfile['meter_usage_factor'][meterType] != null) {
          return scopeProfile['meter_usage_factor'][meterType] as double;
        }
      }
    }
  }
  return 1.0;
}

String getProjectScopeStrFromScopeStr(String scopeStr) {
  if (scopeStr.contains('nus')) {
    return 'evs2_nus';
  }
  if (scopeStr.contains('ntu')) {
    return 'evs2_ntu';
  }
  if (scopeStr.contains('sutd')) {
    return 'evs2_sutd';
  }
  if (scopeStr.contains('pa')) {
    return 'evs2_pa';
  }
  if (scopeStr.contains('zsp')) {
    return 'zsp';
  }
  return 'none';
}

String? getSiteDisplayString(SiteScope? site) {
  if (site == null) return null;
  switch (site) {
    case SiteScope.PA_ATP:
      return 'ATP';
    case SiteScope.NUS_PGPR:
      return 'PGPR';
    case SiteScope.NUS_YNC:
      return 'YNC';
    case SiteScope.NUS_RVRC:
      return 'RVRC';
    case SiteScope.NUS_UTOWN:
      return 'UTown';
    case SiteScope.NUS_VH:
      return 'VH';
    case SiteScope.SUTD_CAMPUS:
      return 'SUTD';
    case SiteScope.NTU_MR:
      return 'MR';
    case SiteScope.SMRT_Clementi:
      return 'Clementi';
    case SiteScope.SMRT_Dover:
      return 'Dover';
    case SiteScope.SMRT_Buona_Vista:
      return 'Buona Vista';
    case SiteScope.SMRT_Commonwealth:
      return 'Commonwealth';
    case SiteScope.SMRT_Queenstown:
      return 'Queenstown';
    case SiteScope.CW_NUS_KRC:
      return 'KRC';
    case SiteScope.CW_NUS_BTC:
      return 'BTC';
    case SiteScope.CW_NUS_UTOWN:
      return 'UTown';
    case SiteScope.ZSP:
      return 'ZSP';
    default:
      return 'NONE';
  }
}

SiteScope? getSiteScopeFromStr(String? scopeStr) {
  if (scopeStr == null || scopeStr.isEmpty) return null;

  String scopeStrLower = scopeStr.toLowerCase();
  if (scopeStrLower.contains('site_')) {
    scopeStrLower = scopeStrLower.replaceAll('site_', '');
  }
  switch (scopeStrLower.toUpperCase()) {
    case 'PA_ATP':
      return SiteScope.PA_ATP;
    case 'NUS_PGPR':
      return SiteScope.NUS_PGPR;
    case 'NUS_YNC':
      return SiteScope.NUS_YNC;
    case 'NUS_RVRC':
      return SiteScope.NUS_RVRC;
    case 'NUS_UTOWN':
      return SiteScope.NUS_UTOWN;
    case 'NUS_VH':
      return SiteScope.NUS_VH;
    case 'SUTD_CAMPUS':
      return SiteScope.SUTD_CAMPUS;
    case 'NTU_MR':
      return SiteScope.NTU_MR;
    case 'SMRT_Clementi':
      return SiteScope.SMRT_Clementi;
    case 'SMRT_Dover':
      return SiteScope.SMRT_Dover;
    case 'SMRT_Buona_Vista':
      return SiteScope.SMRT_Buona_Vista;
    case 'SMRT_Commonwealth':
      return SiteScope.SMRT_Commonwealth;
    case 'SMRT_Queenstown':
      return SiteScope.SMRT_Queenstown;
    case 'CW_NUS_KRC':
      return SiteScope.CW_NUS_KRC;
    case 'CW_NUS_BTC':
      return SiteScope.CW_NUS_BTC;
    case 'CW_NUS_UTOWN':
      return SiteScope.CW_NUS_UTOWN;
    default:
      return SiteScope.NONE;
  }
}

String getProjectDisplayString(ProjectScope project) {
  switch (project) {
    case ProjectScope.EVS2_PA:
      return 'PA';
    case ProjectScope.EVS2_NUS:
    case ProjectScope.EVS2_NUS_OLD:
      return 'NUS';
    case ProjectScope.EVS2_NTU:
      return 'NTU';
    case ProjectScope.EVS2_SUTD:
      return 'SUTD';
    case ProjectScope.EVS2_SMU:
      return 'SMU';
    case ProjectScope.EVS2_SIT:
      return 'SIT';
    case ProjectScope.EVS2_SUSS:
      return 'SUSS';
    case ProjectScope.NONE:
      return 'NONE';
    case ProjectScope.SG_ALL:
      return 'SG_ALL';
    case ProjectScope.GLOBAL:
      return 'GLOBAL';
    case ProjectScope.EMS_SMRT:
      return 'EMS_SMRT';
    case ProjectScope.EMS_CW_NUS:
      return 'EMS_CW_NUS';
    case ProjectScope.MMC_GI_DE:
      return 'MC_GI_DE';
    case ProjectScope.EVS2_ZSP:
      return 'ZSP';
  }
}

ItemType getProjectMeterType(ProjectScope project) {
  switch (project) {
    case ProjectScope.EVS2_PA:
      return ItemType.meter;
    case ProjectScope.EVS2_NUS:
    case ProjectScope.EVS2_NUS_OLD:
      return ItemType.meter;
    case ProjectScope.EVS2_NTU:
      return ItemType.meter;
    case ProjectScope.EVS2_SUTD:
      return ItemType.meter;
    case ProjectScope.EVS2_SMU:
      return ItemType.meter;
    case ProjectScope.EVS2_SIT:
      return ItemType.meter;
    case ProjectScope.EVS2_SUSS:
      return ItemType.meter;
    case ProjectScope.NONE:
      return ItemType.meter;
    case ProjectScope.SG_ALL:
      return ItemType.meter;
    case ProjectScope.GLOBAL:
      return ItemType.meter;
    case ProjectScope.EMS_SMRT:
      return ItemType.meter_3p;
    case ProjectScope.EMS_CW_NUS:
      return ItemType.meter_iwow;
    case ProjectScope.MMC_GI_DE:
      return ItemType.meter;
    case ProjectScope.EVS2_ZSP:
      return ItemType.meter;
  }
}

AclScope getAclProjectScope(ProjectScope? evs2project) {
  switch (evs2project) {
    case ProjectScope.EVS2_PA:
      return AclScope.project_evs2_pa;
    case ProjectScope.SG_ALL:
      return AclScope.global;
    case ProjectScope.EVS2_NUS:
    case ProjectScope.EVS2_NUS_OLD:
      return AclScope.project_evs2_nus;
    case ProjectScope.EVS2_SUTD:
      return AclScope.project_evs2_sutd;
    case ProjectScope.EVS2_NTU:
      return AclScope.project_evs2_ntu;
    case ProjectScope.EMS_SMRT:
      return AclScope.project_ems_smrt;
    case ProjectScope.EMS_CW_NUS:
      return AclScope.project_ems_cw_nus;
    case ProjectScope.EVS2_ZSP:
      return AclScope.project_evs2_zsp;
    default:
      return AclScope.self;
  }
}

AclScope getAclSiteScope(SiteScope? siteScope) {
  switch (siteScope) {
    case SiteScope.PA_ATP:
      return AclScope.site_pa_atp;
    case SiteScope.NUS_PGPR:
      return AclScope.site_nus_pgpr;
    case SiteScope.NUS_YNC:
      return AclScope.site_nus_ync;
    case SiteScope.NUS_RVRC:
      return AclScope.site_nus_rvrc;
    case SiteScope.NUS_UTOWN:
      return AclScope.site_nus_utown;
    case SiteScope.NUS_VH:
      return AclScope.site_nus_vh;
    case SiteScope.SUTD_CAMPUS:
      return AclScope.site_sutd_campus;
    case SiteScope.NTU_MR:
      return AclScope.site_ntu_mr;
    case SiteScope.SMRT_Clementi:
      return AclScope.site_smrt_clementi;
    case SiteScope.SMRT_Dover:
      return AclScope.site_smrt_dover;
    case SiteScope.SMRT_Buona_Vista:
      return AclScope.site_smrt_buona_vista;
    case SiteScope.SMRT_Commonwealth:
      return AclScope.site_smrt_commonwealth;
    case SiteScope.SMRT_Queenstown:
      return AclScope.site_smrt_queenstown;
    default:
      return AclScope.self;
  }
}

final the24 = [
  '10010001',
  '10010002',
  '10010003',
  '10010004',
  '10010005',
  '10010006',
  '10010007',
  '10010008',
  '10010009',
  '10010010',
  '10010011',
  '10010012',
  '10010013',
  '10010014',
  '10010015',
  // '10010016',
  '10010017',
  '10010018',
  '10010019',
  '10010020',
  '10010021',
  '10010022',
  '10010023',
  '10010024',
];

bool isRVRC24(String displayname) {
  //if 10010001 to 10010024, yes,
  if (the24.contains(displayname)) {
    return true;
  } else {
    return false;
  }
}

bool is2401EVS1(String displayname) {
  //if 10100034 to 10101302, yes,
  int? displaynameInt = int.tryParse(displayname);
  if (displaynameInt == null) {
    return false;
  }
  if (displaynameInt >= 10100034 && displaynameInt <= 10101302) {
    return true;
  } else {
    return false;
  }
}

//CAPT
bool is2402EVS1(String displayname) {
  //if 10100034 to 10101302, yes,
  int? displaynameInt = int.tryParse(displayname);
  if (displaynameInt == null) {
    return false;
  }
  if (displaynameInt >= 10100500 && displaynameInt <= 10100694) {
    return true;
  } else {
    return false;
  }
}
