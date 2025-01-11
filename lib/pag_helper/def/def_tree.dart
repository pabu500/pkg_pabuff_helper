import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum PagTreePartType {
  project('Project', Symbols.flag_filled_rounded),
  siteGroup('Site Group', Symbols.workspaces),
  site('Site', Symbols.home_pin),
  building('Building', Symbols.domain),
  locationGroup('Location Group', Symbols.group_work),
  location('Location', Symbols.location_on),
  user('User', Symbols.person),
  tenant('Tenant', Symbols.location_away),
  jobType('Job Type', Symbols.assignment),
  jobTypeSub('Job Type Sub', Symbols.group),
  addButton('Add Button', Symbols.add_circle),
  removeButton('Remove Button', Symbols.remove),
  none('None', Symbols.error_outline),
  ;

  const PagTreePartType(this.label, this.iconData);

  final String label;
  final IconData iconData;

  static PagTreePartType byLabel(String? label) =>
      enumByLabel(label, values) ?? none;
}

T? enumByLabel<T extends Enum>(String? label, List<T> values) {
  return label == null ? null : values.asNameMap()[label];
}
