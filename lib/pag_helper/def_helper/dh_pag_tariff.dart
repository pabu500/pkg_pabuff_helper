import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'enum_helper.dart';

enum PagTariff {
  tariffPackage('Tariff Package', 'tariff_package', Symbols.price_change),
  tariffPackageType(
      'Tariff Package Type', 'tariff_package_type', Symbols.rate_review),
  tariffRate('Tariff Rate', 'tariff_rate', Symbols.price_check),
  ;

  const PagTariff(
    this.label,
    this.value,
    this.iconData,
  );

  final String label;
  final String value;
  final IconData iconData;

  static PagTariff? byLabel(String? label) =>
      enumByLabel(label, values, (e) => (e).label);

  static PagTariff? byValue(String? value) =>
      enumByValue(value, values, (e) => (e).value);
}
