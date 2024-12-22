enum PagPortalProjectScope {
  none,
  PA,
  NUS,
  NTU,
  SUTD,
  SMRT,
  MBFC,
  ZSP,
  GI_DE,
  PA_EMS,
  SUNSEAP,
  SG_ALL,
  GLOBAL,
  CW_P2,
  CW_P2_PLQ,
  CW_P2_AMIS,
}

// enum PagSiteScope {
//   pa,
//   pgpr,
//   utown,
//   rvrc,
//   ync,
//   sutd,
//   mr,
//   zsp,
//   mbfc,
//   tuasave5,
//   bedok,
// }

final portalProjectProfileRepo = [
  {
    'project_scope': PagPortalProjectScope.PA,
    // 'label': 'PA',
    // 'project_sites': [
    //   PagSiteScope.pa,
    //   PagSiteScope.pgpr,
    //   PagSiteScope.utown,
    //   PagSiteScope.rvrc,
    //   PagSiteScope.ync,
    //   PagSiteScope.sutd,
    //   PagSiteScope.mr,
    //   PagSiteScope.zsp,
    //   PagSiteScope.mbfc,
    // ],
    // 'timezone': 8,
    // 'currency': 'SGD',
    // 'asset_folder': 'assets/images/project/pa',
    // 'map_zoom': 11.6,
    // 'map_center': [1.2777317, 103.800769],
    'firebase_options': {
      'apiKey': 'AIzaSyCI_Of8pl7hG1-cCxfOP3E-LQ9iBF3Dc6Y',
      'authDomain': 'pag-pa.firebaseapp.com',
      'projectId': 'pag-pa',
      'storageBucket': 'pag-pa.appspot.com',
      'appId': '1:559367262112:web:bdced3f7085f0025c75ec5',
      'messagingSenderId': '559367262112',
      'measurementId': 'G-KWBCXHSFM5',
    },
  },
  {
    'project_scope': PagPortalProjectScope.GI_DE,
    // 'label': 'GI-DE',
    // 'project_sites': [
    //   PagSiteScope.zsp,
    //   PagSiteScope.mbfc,
    //   PagSiteScope.bedok,
    //   PagSiteScope.tuasave5,
    // ],
    // 'timezone': 8,
    // 'currency': 'SGD',
    // 'asset_folder': 'assets/images/project/gi_de',
    // 'map_zoom': 11.6,
    // 'map_center': [1.3521, 103.8198],
    'firebase_options': {
      'apiKey': 'AIzaSyCI_Of8pl7hG1-cCxfOP3E-LQ9iBF3Dc6Y',
      'authDomain': 'pag-pa.firebaseapp.com',
      'projectId': 'pag-pa',
      'storageBucket': 'pag-pa.appspot.com',
      'appId': '1:559367262112:web:bdced3f7085f0025c75ec5',
      'messagingSenderId': '559367262112',
      'measurementId': 'G-KWBCXHSFM5',
    },
  },
  {
    'project_scope': PagPortalProjectScope.PA_EMS,
    // 'label': 'GI-DE',
    // 'project_sites': [
    //   PagSiteScope.zsp,
    //   PagSiteScope.mbfc,
    //   PagSiteScope.bedok,
    //   PagSiteScope.tuasave5,
    // ],
    // 'timezone': 8,
    // 'currency': 'SGD',
    // 'asset_folder': 'assets/images/project/gi_de',
    // 'map_zoom': 11.6,
    // 'map_center': [1.3521, 103.8198],
    'firebase_options': {
      'apiKey': 'AIzaSyCI_Of8pl7hG1-cCxfOP3E-LQ9iBF3Dc6Y',
      'authDomain': 'pag-pa.firebaseapp.com',
      'projectId': 'pag-pa',
      'storageBucket': 'pag-pa.appspot.com',
      'appId': '1:559367262112:web:bdced3f7085f0025c75ec5',
      'messagingSenderId': '559367262112',
      'measurementId': 'G-KWBCXHSFM5',
    },
  }
];

// final siteProfileRepo = [
//   {
//     'site_scope': PagSiteScope.zsp,
//     'label': 'ZSP',
//     'name': 'ZSP',
//     'address': 'ZSP',
//     'lat': 1.327038,
//     'lng': 103.846408,
//     'timezone': 8,
//     'currency': 'SGD',
//     'map_zoom': 11.6,
//   },
//   {
//     'site_scope': PagSiteScope.mbfc,
//     'label': 'MBFC',
//     'name': 'MBFC',
//     'address': 'MBFC',
//     'lat': 1.2797,
//     'lng': 103.8544,
//     'timezone': 8,
//     'currency': 'SGD',
//     'map_zoom': 11.6,
//   }
// ];

Map<String, dynamic>? getPortalProjectScopeProfile(
    PagPortalProjectScope activePortalPagProjectScope) {
  for (var portalProjectScopeProfile in portalProjectProfileRepo) {
    if (portalProjectScopeProfile['project_scope'] ==
        activePortalPagProjectScope) {
      return portalProjectScopeProfile;
    }
  }
  return null;
}

// PagSiteProfile? getSiteProfile(PagSiteScope siteScope) {
//   for (var siteProfile in siteProfileRepo) {
//     if (siteProfile['site_scope'] == siteScope) {
//       return PagSiteProfile.fromJson(siteProfile);
//     }
//   }
//   return null;
// }
