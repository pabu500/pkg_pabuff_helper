import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum PagScopeType {
  project('Project', Symbols.flag),
  siteGroup('Site Group', Symbols.workspaces),
  site('Site', Symbols.home_pin),
  building('Building', Symbols.domain),
  locationGroup('Location Group', Symbols.group_work),
  location('Location', Symbols.location_on),
  none('None', Symbols.help);

  const PagScopeType(
    this.label,
    this.iconData,
  );

  final String label;
  final IconData iconData;

  static PagScopeType byLabel(String? label) =>
      enumByLabel(label, values) ?? none;
}

T? enumByLabel<T extends Enum>(String? label, List<T> values) {
  return label == null ? null : values.asNameMap()[label];
}

PagScopeType getChildScopeType(PagScopeType parentScopeType) {
  switch (parentScopeType) {
    case PagScopeType.project:
      return PagScopeType.siteGroup;
    case PagScopeType.siteGroup:
      return PagScopeType.site;
    case PagScopeType.site:
      return PagScopeType.building;
    case PagScopeType.building:
      return PagScopeType.locationGroup;
    case PagScopeType.locationGroup:
      return PagScopeType.location;
    case PagScopeType.location:
      return PagScopeType.none;
    case PagScopeType.none:
      return PagScopeType.none;
  }
}
