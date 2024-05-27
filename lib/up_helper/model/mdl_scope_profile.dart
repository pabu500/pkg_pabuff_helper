import '../up_helper.dart';

class ScopeProfile /*extends ChangeNotifier*/ {
  ProjectScope projectScope;
  List<SiteScope> projectSites = [];
  List<Map<String, dynamic>> projectSitesMap = [];
  int timezone;
  String? currency = 'SGD';
  String? Function(String?)? validateEntityName;
  String? Function(String?)? validateMeterSn;
  bool? allowCustomAmount = false;
  List<PaymentModeSetting>? paymentSetting = [];
  List<String> meterPhases = ['1p', '3p'];
  ItemType? meterType;

  ProjectScope? _selectedProjectScope;
  SiteScope? _selectedSiteScope;
  void setScope(ProjectScope? projectScope, SiteScope? siteScope) {
    _selectedProjectScope = projectScope;
    _selectedSiteScope = siteScope;
    // notifyListeners();
  }

  ProjectScope? get selectedProjectScope => _selectedProjectScope;
  // set selectedProjectScope(ProjectScope? projectScope) {
  //   _selectedProjectScope = projectScope;
  //   notifyListeners();
  // }

  SiteScope? get selectedSiteScope => _selectedSiteScope;
  // set selectedSiteScope(SiteScope? siteScope) {
  //   _selectedSiteScope = siteScope;
  //   notifyListeners();
  // }

  String getEffectiveScopeStr() {
    if (_selectedSiteScope != null) {
      return _selectedSiteScope!.name;
    } else {
      return _selectedProjectScope!.name;
    }
  }

  AclScope getEffectiveScope() {
    if (_selectedSiteScope != null) {
      return AclScope.values
          .byName('site_${selectedSiteScope!.name.toLowerCase()}');
    } else {
      if (_selectedProjectScope == ProjectScope.SG_ALL) {
        return AclScope.values.byName('sg_all');
      }
      if (_selectedProjectScope == null) {
        return AclScope.self;
      }
      return AclScope.values
          .byName('project_${selectedProjectScope!.name.toLowerCase()}');
    }
  }

  ScopeProfile({
    required this.projectScope,
    required this.timezone,
    this.currency,
    this.validateEntityName,
    this.validateMeterSn,
    this.allowCustomAmount,
    this.paymentSetting,
    this.projectSites = const [],
    this.projectSitesMap = const [],
    this.meterPhases = const ['1p', '3p'],
    this.meterType,
  });

  factory ScopeProfile.fromJson(Map<String, dynamic> json) {
    List<PaymentModeSetting> paymentSetting = [];
    if (json['payment_mode_setting'] != null) {
      json['payment_mode_setting'].forEach((v) {
        paymentSetting.add(PaymentModeSetting.fromJson(v));
      });
    }
    List<SiteScope> projectSitesName = [];
    List<Map<String, dynamic>> projectSitesMap = [];
    if (json['project_sites'] != null) {
      for (var site in json['project_sites']) {
        if (site is SiteScope) {
          projectSitesName.add(site);
        } else {
          projectSitesMap.add({
            'key': site['key'],
            'name': site['name'],
            'color': site['color'],
          });
        }
      }
    }
    if (json['meter_phases'] != null) {
      List<String> meterPhases = [];
      for (var phase in json['meter_phases']) {
        meterPhases.add(phase);
      }
    }

    return ScopeProfile(
      projectScope: json['project_scope'],
      timezone: json['timezone'],
      currency: json['currency'],
      validateEntityName: json['validate_entity_displayname'],
      validateMeterSn: json['validate_entity_sn'],
      allowCustomAmount: json['allow_custom_amount'] ?? false,
      paymentSetting: paymentSetting,
      projectSites: projectSitesName,
      projectSitesMap: projectSitesMap,
      meterPhases: json['meter_phases'] ?? ['1p', '3p'],
      meterType: json['meter_type'] ?? ItemType.meter,
    );
  }

  PaymentModeSetting? getStripePaymentSetting() {
    for (var setting in paymentSetting!) {
      if (setting.paymentMode == PaymentMode.stripe) {
        return setting;
      }
    }
    return null;
  }
}
