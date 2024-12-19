import '../../pkg_buff_helper.dart';

enum PagProjectScope {
  EVS2_PA,

  EVS2_NUS,
  EVS2_SUTD,
  EVS2_NTU,

  NONE,
  SG_ALL,
  GLOBAL,

  EMS_SMRT,
  EMS_CW_NUS,

  PAG_GI_DE,
}

enum PagSiteScope {
  PA_ATP,

  NUS_PGPR,
  NUS_YNC,
  NUS_RVRC,
  NUS_UTOWN,

  SUTD_CAMPUS,

  NTU_MR,

  SMRT_Clementi,
  SMRT_Dover,
  SMRT_Buona_Vista,
  SMRT_Commonwealth,
  SMRT_Queenstown,

  CW_NUS_KRC,
  CW_NUS_BTC,
  CW_NUS_UTOWN,

  GI_DE_DEMO,
}

final projectProfileRepo = [
  {
    'project_scope': PagProjectScope.PAG_GI_DE,
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
    'project_scope': PagProjectScope.EVS2_PA,
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
    'firebase_options': {
      'apiKey': 'AIzaSyCI_Of8pl7hG1-cCxfOP3E-LQ9iBF3Dc6Y',
      'authDomain': 'pag-pa.firebaseapp.com',
      'projectId': 'pag-pa',
      'storageBucket': 'pag-pa.appspot.com',
      'appId': '1:559367262112:web:bdced3f7085f0025c75ec5',
      'messagingSenderId': '559367262112',
      'measurementId': 'G-KWBCXHSFM5',
    },
    'payment_mode_setting': {
      {
        'payment_mode': PaymentMode.stripe,
        'active': false,
        'show': true,
      },
      {
        'payment_mode': PaymentMode.netsQR,
        'active': false,
        'show': true,
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
    'project_scope': PagProjectScope.SG_ALL,
    'project_sites': [
      SiteScope.NUS_PGPR,
      SiteScope.NUS_YNC,
      SiteScope.NUS_RVRC,
      SiteScope.NUS_UTOWN,
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
    'project_scope': PagProjectScope.EVS2_NUS,
    'project_sites': [
      SiteScope.NUS_PGPR,
      SiteScope.NUS_YNC,
      SiteScope.NUS_RVRC,
      SiteScope.NUS_UTOWN,
    ],
    'timezone': 8,
    'currency': 'SGD',
    'validate_entity_displayname': (displayname) {
      //8 digits, start with '1'
      return nusSnValidator(displayname);
    },
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
    'project_scope': PagProjectScope.EVS2_SUTD,
    'project_sites': [SiteScope.SUTD_CAMPUS],
    'timezone': 8,
    'currency': 'SGD',
    'validate_entity_displayname': (displayname) {
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
    'project_scope': PagProjectScope.EVS2_NTU,
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
    'project_scope': PagProjectScope.EMS_SMRT,
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
    'project_scope': PagProjectScope.EMS_CW_NUS,
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
  }
];

ScopeProfile? getScopeProfile(PagProjectScope activePortalPagProjectScope) {
  for (var scopeProfile in projectProfileRepo) {
    if (scopeProfile['project_scope'] == activePortalPagProjectScope) {
      return ScopeProfile.fromJson(scopeProfile);
    }
  }
  return null;
}

ScopeProfile? getUserScopeProfile(Evs2User user) {
  String scopeStr = user.scopeStr ?? '';
  if (scopeStr.isEmpty) {
    return null;
  }
  String projectScopeStr = getProjectScopeStrFromScopeStr(scopeStr);
  if (projectScopeStr.isEmpty) {
    return null;
  }
  for (var scopeProfile in projectProfileRepo) {
    if ((scopeProfile['project_scope'] as ProjectScope).name.toLowerCase() ==
        projectScopeStr.toLowerCase()) {
      return ScopeProfile.fromJson(scopeProfile);
    }
  }
  return null;
}

ScopeProfile? getUserScopeProfilePag(Evs2User user) {
  String scopeStr = user.scopeStr ?? '';
  if (scopeStr.isEmpty) {
    return null;
  }
  String projectScopeStr = getProjectScopeStrFromScopeStr(scopeStr);
  if (projectScopeStr.isEmpty) {
    return null;
  }
  for (var scopeProfile in projectProfileRepo) {
    if ((scopeProfile['project_scope'] as PagProjectScope).name.toLowerCase() ==
        projectScopeStr.toLowerCase()) {
      return ScopeProfile.fromJson(scopeProfile);
    }
  }
  return null;
}

Map<String, dynamic> getPayProfile(Evs2User user) {
  String scopeStr = user.scopeStr ?? '';
  if (scopeStr.isEmpty) {
    return {};
  }
  String projectScopeStr = getProjectScopeStrFromScopeStr(scopeStr);
  if (projectScopeStr.isEmpty) {
    return {};
  }
  Map<String, dynamic> payProfile = {};

  for (var projectProfile in projectProfileRepo) {
    if (projectProfile['project_scope'] == projectScopeStr) {
      payProfile =
          projectProfile['payment_mode_setting'] as Map<String, dynamic>;
      break;
    }
  }

  return payProfile;
}

Map<String, dynamic> getProjctPaymentModes(String scopeStr) {
  Map<String, dynamic> paymentModes = {};

  late Map<String, dynamic> paymentProfile;

  for (var projectProfile in projectProfileRepo) {
    if (projectProfile['project_scope'] == scopeStr) {
      paymentProfile =
          projectProfile['payment_mode_setting'] as Map<String, dynamic>;
      break;
    }
  }

  for (var key in paymentProfile.keys) {
    paymentModes[key] = {
      'active': paymentProfile[key]['active'],
      'show': paymentProfile[key]['show']
    };
  }

  return paymentModes;
}

Function getDisplaynameValidator(String scopeStr) {
  Map<String, dynamic>? cp;

  for (var projectProfile in projectProfileRepo) {
    PagProjectScope projectScope =
        projectProfile['project_scope'] as PagProjectScope;
    if (projectScope.name == scopeStr) {
      cp = projectProfile;
      break;
    }
  }
  if (cp == null) {
    return (displayname) {
      return 'Invalid displayname';
    };
  }

  Function validator = cp['validate_entity_displayname'];
  return validator;
}

String? mmsSnValidator(value) {
  //12 digits, start with '202', all digits
  RegExp exp = RegExp(r'^202\d{9}$');
  if (exp.hasMatch(value)) {
    return null;
  } else {
    return 'Invalid sn';
  }
}

String? nusSnValidator(String displayname) {
  RegExp exp = RegExp(r'^1\d{7}$');
  int displaynameInt = int.parse(displayname);
  if (exp.hasMatch(displayname)) {
    return isRVRC(displayname);
    //check if the meter is under YNC, if yes, return invalid displayname
    // if ((displaynameInt >= 10002801 && displaynameInt <= 10003925) ||
    //     [10003963, 10003982, 10003985, 10009999].contains(displaynameInt)) {
    //   return 'Invalid displayname';
    // }
    // return null;
  } else {
    return 'Invalid displayname';
  }
}

List<int> rvrc24List = [
  10010001,
  10010002,
  10010003,
  10010004,
  10010005,
  10010006,
  10010007,
  10010008,
  10010009,
  10010010,
  10010011,
  10010012,
  10010013,
  10010014,
  10010015,
  10010016,
  10010017,
  10010018,
  10010019,
  10010020,
  10010021,
  10010022,
  10010023,
  10010024
];

String? isRVRC(String displayname) {
  int displaynameInt = int.parse(displayname);
  if (((displaynameInt < 10013020 &&
          displaynameInt != 10010016 &&
          !rvrc24List.contains(displaynameInt)) ||
      displaynameInt > 10013376)) {
    return 'Invalid displayname';
  }
  return null;
}
