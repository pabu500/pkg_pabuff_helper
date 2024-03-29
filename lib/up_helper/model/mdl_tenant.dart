import '../helper/tenant_def.dart';

class Tenant {
  int? id;
  String? tenantLabel;
  String? tenantName;
  String? locationTag;
  String? sapWbs;
  String? meterGroupInfoStr;
  TenantType? tenantType;
  String? createdTimeStr;
  int? tpIde;
  int? tpIdw;
  int? tpIdb;
  int? tpIdn;

  Tenant({
    this.id = 0,
    this.tenantLabel,
    this.tenantName,
    this.locationTag,
    this.sapWbs,
    this.meterGroupInfoStr,
    this.tenantType,
    this.createdTimeStr,
    this.tpIde,
    this.tpIdw,
    this.tpIdb,
    this.tpIdn,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: int.tryParse(json['id']) ?? -1,
      tenantLabel: json['tenant_label'] ?? '',
      tenantName: json['tenant_name'] ?? '',
      locationTag: json['location_tag'] ?? '',
      sapWbs: json['sap_wbs'] ?? '',
      meterGroupInfoStr: json['meter_group_info_str'] ?? '',
      tenantType: TenantType.values.byName(json['type'] ?? ''),
      createdTimeStr: json['created_timestamp'] ?? '',
      tpIde: int.tryParse(json['tariff_package_id_e'] ?? '') ?? -1,
      tpIdw: int.tryParse(json['tariff_package_id_w'] ?? '') ?? -1,
      tpIdb: int.tryParse(json['tariff_package_id_b'] ?? '') ?? -1,
      tpIdn: int.tryParse(json['tariff_package_id_n'] ?? '') ?? -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_label': tenantLabel,
      'tenant_name': tenantName,
      'location_tag': locationTag,
      'sap_wbs': sapWbs,
      'meter_group_info_str': meterGroupInfoStr,
      'type': tenantType?.name,
      'created_timestamp': createdTimeStr,
      'tariff_package_id_e': tpIde,
      'tariff_package_id_w': tpIdw,
      'tariff_package_id_b': tpIdb,
      'tariff_package_id_n': tpIdn,
    };
  }
}
