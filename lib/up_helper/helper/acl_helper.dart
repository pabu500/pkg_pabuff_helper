import '../enum/enum_acl.dart';
import '../enum/enum_item.dart';

String getAclTargetStr(AclTarget target) {
  return target.name.replaceAll('_p_', '.');
}

AclTarget getAclTargetFromItemType(ItemType itemType) {
  switch (itemType) {
    case ItemType.meter:
      return AclTarget.meter_p_info;
    case ItemType.meter_3p:
      return AclTarget.meter_p_info;
    case ItemType.meter_iwow:
      return AclTarget.meter_p_info;
    case ItemType.sensor:
      return AclTarget.sensor_p_info;
    case ItemType.tenant:
      return AclTarget.tenant_p_info;
    // case ItemType.building:
    //   return AclTarget.building_p_info;
    case ItemType.user:
      return AclTarget.evs2user_p_profile;
    case ItemType.meter_group:
      return AclTarget.meter_group_p_info;
    case ItemType.concentrator:
      return AclTarget.concentrator_p_info;
    // case ItemType.concentrator_tariff:
    //   return AclTarget.concentrator_tariff_p_info;
    case ItemType.tariff_package:
      return AclTarget.meter_p_tariff;
    case ItemType.job_type:
      return AclTarget.job_type_p_info;
    case ItemType.job:
      return AclTarget.job_p_info;
    default:
      return AclTarget.meter_p_info;
  }
}
