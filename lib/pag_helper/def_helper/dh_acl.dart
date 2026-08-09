import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'enum_helper.dart';

enum PagAclType {
  resource('Resource', 'res', 'res', Symbols.topic),
  permission('Permission', 'perm', 'perm', Symbols.key),
  ;

  const PagAclType(
    this.label,
    this.value,
    this.tag,
    this.iconData,
  );

  final String label;
  final String value; // the value that is stored in the database
  final String tag; // a short tag for the device category
  final IconData iconData;

  static PagAclType? byLabel(String? label) =>
      enumByLabel(label, values, (e) => (e).label);

  static PagAclType? byValue(String? value) =>
      enumByValue(value, values, (e) => (e).value);

  static PagAclType? byTag(String? tag) =>
      enumByValue(tag, values, (e) => (e).tag);
}
