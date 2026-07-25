import '../../pag_helper/def_helper/enum_helper.dart';

enum ItemType {
  meter,
  meter_3p,
  meter_iwow,
  // meter_iwow_3p,
  // meter_iwow_btu,
  sensor,
  tenant,
  building,
  user,
  meter_group,
  concentrator,
  concentrator_tariff,
  tariff_package,
  tariff_rate_row,
  billing_rec,
  job_type,
  job,
  job_type_sub,
  fleet_health,
}

enum ItemFinderType {
  meter,
  sensor,
  tenant,
  building,
  user,
  meter_group,
  tariff_package,
  concentrator,
}

enum ItemIdType {
  id,
  name,
  code,
  barcode,
  sn,
  qr,
  rfid,
  custom,
  panel_tag,
  alt_name,
  site_tag,
  scope_str,
}

enum PagIdType {
  indexType('id', 'ID', 'id'),
  nameType('name', 'Name', 'name'),
  labelType('label', 'Label', 'label'),
  snType('sn', 'Serial Number', 'sn'),
  tagType('tag', 'Tag', 'tag'),
  usernameType('username', 'Username', 'username'),
  emailType('email', 'Email', 'email'),
  phoneNumberType('phone_number', 'Phone Number', 'phone_number'),
  accountNumberType('account_number', 'Account Number', 'account_number'),
  iccidType('iccid', 'ICCID', 'iccid'),
  ipType('ip', 'IP Address', 'ip'),
  macType('mac', 'MAC Address', 'mac');

  final String label;
  final String value;
  final String tag;

  const PagIdType(
    this.label,
    this.value,
    this.tag,
  );

  static PagIdType? byValue(String? value) => enumByValue(
        value,
        values,
        (e) => (e).value,
      );
  static PagIdType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );
  static PagIdType? byTag(String? tag) => enumByTag(
        tag,
        values,
        (e) => (e).tag,
      );
}
