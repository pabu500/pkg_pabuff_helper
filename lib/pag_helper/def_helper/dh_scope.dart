import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum PagScopeType {
  project('Project', 'project', Symbols.flag),
  siteGroup('Site Group', 'site_group', Symbols.workspaces),
  site('Site', 'site', Symbols.home_pin),
  building('Building', 'building', Symbols.domain),
  locationGroup('Location Group', 'location_group', Symbols.group_work),
  location('Location', 'location', Symbols.location_on),
  none('None', 'none', Symbols.help);

  const PagScopeType(
    this.label,
    this.key,
    this.iconData,
  );

  final String label;
  final String key;
  final IconData iconData;

  static PagScopeType byLabel(String? label) =>
      enumByLabel(label, values) ?? none;

  static PagScopeType byKey(String? key) => enumByKey(key, values) ?? none;
}

T? enumByLabel<T extends Enum>(
  String? label,
  List<T> values,
) {
  if (label == null) return null;
  for (var value in values) {
    if (value is PagScopeType && value.label == label) {
      return value as T;
    }
  }
  return null;
}

T? enumByKey<T extends Enum>(String? key, List<T> values) {
  if (key == null) return null;
  for (var value in values) {
    if (value is PagScopeType && value.key == key) {
      return value as T;
    }
  }
  return null;
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

bool isSmallerScope(PagScopeType scopeType1, PagScopeType scopeType2) {
  return scopeType1.index > scopeType2.index;
}

Widget getScopeIcon(BuildContext ctx, PagScopeType scopeType,
    {double size = 24}) {
  return Icon(
    scopeType.iconData,
    size: size,
    color: Theme.of(ctx).hintColor,
  );
}

String getPagScopeTypeStr(dynamic itemType) {
  switch (itemType) {
    case PagScopeType.project:
      return 'project';
    case PagScopeType.siteGroup:
      return 'siteGroup';
    case PagScopeType.site:
      return 'site';
    case PagScopeType.building:
      return 'building';
    case PagScopeType.locationGroup:
      return 'locationGroup';
    case PagScopeType.location:
      return 'location';
    default:
      return '';
  }
}

String? validateLabelScope(String val) {
  if (val.trim().isEmpty) {
    return 'required';
  }

  // validate alphanumric, _, -, #, ' and dash, space,
  // and minimum 5 characters
  String pattern = r"^[a-zA-Z0-9/_ \-#']{5,}$";
  RegExp regExp = RegExp(pattern);
  if (!regExp.hasMatch(val)) {
    return 'min length is 5 and alphanumeric, space, #, /, _, - only';
  }
  return null;
}
