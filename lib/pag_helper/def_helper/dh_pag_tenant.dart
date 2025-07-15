import 'package:flutter/material.dart';

import 'enum_helper.dart';

enum PagTenantLcStatus {
  onbarding('Onboarding', 'onb', 'onb', Colors.lightGreenAccent),
  normal('Normal', 'normal', 'norm', Colors.teal),
  offboarding('Offboarding', 'offb', 'offb', Colors.orange),
  terminated('Terminated', 'terminated', 'term', Colors.red),
  ;

  const PagTenantLcStatus(
    this.label,
    this.value, // the value that is stored in the database
    this.tag,
    this.color,
  );

  final String label;
  final String value;
  final String tag;

  final Color color;

  static PagTenantLcStatus? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagTenantLcStatus byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      normal;

  static PagTenantLcStatus byTag(String? tag) =>
      enumByTag(
        tag,
        values,
      ) ??
      normal;
}

T? enumByTag<T extends Enum>(String? tag, List<T> values) {
  if (tag == null) return null;
  for (var value in values) {
    if (value is PagTenantLcStatus && value.tag.replaceAll('.', '') == tag) {
      return value as T;
    }
  }
  return null;
}

enum PagTenantUnitType {
  beautyWellness(
      'Beauty & Wellness', 'beauty_wellness', 'b&w', Colors.lightGreenAccent),
  bookStationery('Book & Stationery', 'book_stationery', 'b&s', Colors.blue),
  childrean('Children', 'children', 'child', Colors.lightBlueAccent),
  convenienceStore(
      'Convenience Store', 'convenience_store', 'cvs', Colors.green),
  deptValueStore(
      'Dept. & Value Store', 'dept_value_store', 'dvs', Colors.amber),
  electronicsTelco(
      'Electronics & Telco', 'electronics_telco', 'e&t', Colors.cyan),
  enetertainment('Entertainment', 'entertainment', 'ent', Colors.deepOrange),
  fashion('Fashion', 'fashion', 'fash', Colors.pink),
  foodBeverage('Food & Beverage', 'food_beverage', 'f&b', Colors.redAccent),
  hobbiesLiving('Hobbies & Living', 'hobbies_living', 'h&l', Colors.indigo),
  homeFurnishing('Home & Furnishing', 'home_furnishing', 'h&f', Colors.brown),
  services('Services', 'services', 'serv', Colors.grey),
  sports('Sports', 'sports', 'sp', Colors.teal),
  office('Office', 'office', 'of', Colors.purple),
  others('Others', 'others', 'oth', Colors.grey),
  ;

  const PagTenantUnitType(
    this.label,
    this.value, // the value that is stored in the database
    this.tag,
    this.color,
  );

  final String label;
  final String value;
  final String tag;
  final Color color;

  static PagTenantUnitType? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagTenantUnitType byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      others;

  static PagTenantUnitType byTag(String? tag) =>
      enumByTag(
        tag,
        values,
      ) ??
      others;
}

enum PagTenantPaymentMethod {
  giro('GIRO', 'qiro', 'giro', Colors.green),
  nonGiro('None GIRO', 'non_giro', 'ngiro', Colors.red),
  cheque('Cheque', 'cheque', 'chq', Colors.blue),
  other('Other', 'other', 'oth', Colors.grey),
  ;

  const PagTenantPaymentMethod(
    this.label,
    this.value, // the value that is stored in the database
    this.tag,
    this.color,
  );

  final String label;
  final String value;
  final String tag;
  final Color color;

  static PagTenantPaymentMethod? byLabel(String? label) => enumByLabel(
        label,
        values,
        (e) => (e).label,
      );

  static PagTenantPaymentMethod byValue(String? value) =>
      enumByLabel(
        value,
        values,
        (e) => (e).value,
      ) ??
      other;

  static PagTenantPaymentMethod byTag(String? tag) =>
      enumByTag(
        tag,
        values,
      ) ??
      other;
}
