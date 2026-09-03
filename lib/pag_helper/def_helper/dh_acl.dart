import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'enum_helper.dart';
import 'dh_pag_item.dart';

enum PagAclType {
  resource('Resource', 'res', 'res', Symbols.topic),
  permission('Permission', 'perm', 'perm', Symbols.key),
  policy('Policy', 'policy', 'policy', Symbols.policy),
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

String? Function(String) getResourceTypeValidator(String key,
    {bool isValueRequired = true}) {
  switch (key) {
    case 'label':
      return getValidator(validateItemLabel, isValueRequired);
    default:
      dev.log('No validator found for meter group key: $key');
      return (String value) {
        return null;
      };
  }
}

String? Function(String) getAclValidator(String key, dynamic itemType,
    {bool isValueRequired = true}) {
  switch (itemType) {
    case PagAclType.resource:
      return getResourceValidator(key, isValueRequired: isValueRequired);
    case PagAclType.permission:
      return getPermissionTypeValidator(key, isValueRequired: isValueRequired);
    default:
      dev.log('No validator found for key: $key');
      return (String? value) {
        return null;
      };
  }
}

String? Function(String) getResourceValidator(String key,
    {bool isValueRequired = true}) {
  switch (key) {
    case 'label':
      return getValidator(validateItemLabel, isValueRequired);
    default:
      dev.log('No validator found for resource key: $key');
      return (String value) {
        return null;
      };
  }
}

String? Function(String) getPermissionTypeValidator(String key,
    {bool isValueRequired = true}) {
  switch (key) {
    case 'label':
      return getValidator(validateItemLabel, isValueRequired);
    default:
      dev.log('No validator found for permission type key: $key');
      return (String value) {
        return null;
      };
  }
}

enum PagAclOperationType {
  create('Create', 'create', 'create', Symbols.add),
  read('Read', 'read', 'read', Symbols.visibility),
  update('Update', 'update', 'update', Symbols.edit),
  delete('Delete', 'delete', 'delete', Symbols.delete),
  list('List', 'list', 'list', Symbols.list),
  all('Full', 'full', 'full', Symbols.all_inclusive);

  const PagAclOperationType(
    this.label,
    this.value,
    this.tag,
    this.iconData,
  );

  final String label;
  final String value; // the value that is stored in the database
  final String tag; // a short tag for the device category
  final IconData iconData;

  static PagAclOperationType? byLabel(String? label) =>
      enumByLabel(label, values, (e) => (e).label);

  static PagAclOperationType? byValue(String? value) =>
      enumByValue(value, values, (e) => (e).value);

  static PagAclOperationType? byTag(String? tag) =>
      enumByValue(tag, values, (e) => (e).tag);
}

String? validateResLabel(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'required';
  }

  if (value.length > 255) {
    return 'must be at most 255 characters';
  }

  // One or more dot-separated lowerCamelCase segments.
  final lowerCamelCasePath = RegExp(
    r'^[a-z][a-zA-Z0-9]*(\.[a-z][a-zA-Z0-9]*)*$',
  );
  if (!lowerCamelCasePath.hasMatch(value)) {
    return 'must use lowerCamelCase separated by dots, e.g. com.myRes.yourScope';
  }

  return null;
}

String getAclResLabel(PagAclType aclType) {
  switch (aclType) {
    case PagAclType.resource:
    case PagAclType.permission:
    case PagAclType.policy:
      return aclType.label;
    default:
      return '';
  }
}
