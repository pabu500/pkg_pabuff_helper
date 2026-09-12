import 'package:buff_helper/pag_helper/comm/comm_ex.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_list.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';

const String _getPrefEndpoint = '/pref/get_pref';
const String _setPrefEndpoint = '/pref/set_pref';
const String _resetPrefEndpoint = '/pref/reset_pref';

class PagListColumnPreference {
  const PagListColumnPreference({
    required this.found,
    required this.columnVisibility,
    required this.revision,
  });

  final bool found;
  final Map<String, bool> columnVisibility;
  final int revision;
}

class PagFinderPinPreference {
  const PagFinderPinPreference({
    required this.found,
    required this.filterPinned,
    required this.revision,
  });

  final bool found;
  final Map<String, bool> filterPinned;
  final int revision;
}

final Expando<Map<String, bool>> _listColumnDefaults =
    Expando<Map<String, bool>>('listColumnDefaults');
final Expando<Map<String, bool>> _finderPinDefaults =
    Expando<Map<String, bool>>('finderPinDefaults');

Map<String, bool> getListColumnDefaults(MdlPagListController listController) {
  final existing = _listColumnDefaults[listController];
  if (existing != null) return Map<String, bool>.from(existing);
  final defaults = <String, bool>{};
  for (final column in listController.listColControllerList) {
    defaults[column.colKey] = column.showColumn;
  }
  _listColumnDefaults[listController] = Map<String, bool>.from(defaults);
  return defaults;
}

Map<String, bool> getFinderPinDefaults(MdlPagListController listController) {
  final existing = _finderPinDefaults[listController];
  if (existing != null) return Map<String, bool>.from(existing);
  final defaults = <String, bool>{};
  for (final column in listController.listColControllerList) {
    defaults[column.colKey] = column.pinned;
  }
  _finderPinDefaults[listController] = Map<String, bool>.from(defaults);
  return defaults;
}

String getListColumnPrefKey({
  required String aclResLabel,
  required PagItemKind itemKind,
  required dynamic itemType,
  required PagListContextType listContextType,
}) {
  final parts = <String>[
    aclResLabel.trim(),
    itemKind.value,
  ];
  final itemTypeValue = getItemTypeValue(itemType);
  if (itemTypeValue.isNotEmpty &&
      itemTypeValue != 'NOT_SET' &&
      itemTypeValue != itemKind.value) {
    parts.add(itemTypeValue);
  }
  parts.add(listContextType.value);
  return parts.join('.');
}

String getFinderPinPrefKey({
  required String aclResLabel,
  required PagItemKind itemKind,
  required dynamic itemType,
  required PagListContextType listContextType,
}) {
  return '${getListColumnPrefKey(
    aclResLabel: aclResLabel,
    itemKind: itemKind,
    itemType: itemType,
    listContextType: listContextType,
  )}.finder';
}

Future<PagListColumnPreference> getListColumnPreference({
  required MdlPagAppConfig appConfig,
  required MdlPagUser user,
  required int projectId,
  required String prefKey,
}) async {
  final result = await ex2(
    endpoint: _getPrefEndpoint,
    crudType: 'read',
    opStr: 'get list column preference',
    appConfig: appConfig,
    queryMap: {
      'project_id': projectId,
      'portal_type': appConfig.portalType.value,
      'pref_key': prefKey,
    },
    svcClaim: _claimFor(user),
  );
  return _preferenceFromResult(result);
}

Future<PagListColumnPreference> setListColumnPreference({
  required MdlPagAppConfig appConfig,
  required MdlPagUser user,
  required int projectId,
  required String prefKey,
  required Map<String, bool> columnVisibility,
  required int expectedRevision,
}) async {
  final result = await ex2(
    endpoint: _setPrefEndpoint,
    crudType: 'update',
    opStr: 'save list column preference',
    appConfig: appConfig,
    queryMap: {
      'project_id': projectId,
      'portal_type': appConfig.portalType.value,
      'pref_key': prefKey,
      'expected_revision': expectedRevision,
      'pref_value': {
        'schema_version': 1,
        'column_visibility': columnVisibility,
      },
    },
    svcClaim: _claimFor(user),
  );
  return _preferenceFromResult(result);
}

Future<void> resetListColumnPreference({
  required MdlPagAppConfig appConfig,
  required MdlPagUser user,
  required int projectId,
  required String prefKey,
  required int expectedRevision,
}) async {
  await ex2(
    endpoint: _resetPrefEndpoint,
    crudType: 'delete',
    opStr: 'reset list column preference',
    appConfig: appConfig,
    queryMap: {
      'project_id': projectId,
      'portal_type': appConfig.portalType.value,
      'pref_key': prefKey,
      'expected_revision': expectedRevision,
    },
    svcClaim: _claimFor(user),
  );
}

Future<PagFinderPinPreference> getFinderPinPreference({
  required MdlPagAppConfig appConfig,
  required MdlPagUser user,
  required int projectId,
  required String prefKey,
}) async {
  final result = await ex2(
    endpoint: _getPrefEndpoint,
    crudType: 'read',
    opStr: 'get finder pin preference',
    appConfig: appConfig,
    queryMap: {
      'project_id': projectId,
      'portal_type': appConfig.portalType.value,
      'pref_key': prefKey,
    },
    svcClaim: _claimFor(user),
  );
  final parsed = _preferenceMapFromResult(result, 'filter_pinned');
  return PagFinderPinPreference(
    found: parsed.found,
    filterPinned: parsed.values,
    revision: parsed.revision,
  );
}

Future<PagFinderPinPreference> setFinderPinPreference({
  required MdlPagAppConfig appConfig,
  required MdlPagUser user,
  required int projectId,
  required String prefKey,
  required Map<String, bool> filterPinned,
  required int expectedRevision,
}) async {
  final result = await ex2(
    endpoint: _setPrefEndpoint,
    crudType: 'update',
    opStr: 'save finder pin preference',
    appConfig: appConfig,
    queryMap: {
      'project_id': projectId,
      'portal_type': appConfig.portalType.value,
      'pref_key': prefKey,
      'expected_revision': expectedRevision,
      'pref_value': {
        'schema_version': 1,
        'filter_pinned': filterPinned,
      },
    },
    svcClaim: _claimFor(user),
  );
  final parsed = _preferenceMapFromResult(result, 'filter_pinned');
  return PagFinderPinPreference(
    found: parsed.found,
    filterPinned: parsed.values,
    revision: parsed.revision,
  );
}

MdlPagSvcClaim2 _claimFor(MdlPagUser user) {
  return MdlPagSvcClaim2(
    userId: user.id,
    username: user.username,
    roleId: user.selectedRole?.id,
    roleName: user.selectedRole?.name,
    roleLabel: user.selectedRole?.label,
    userScope: user.selectedScope.toScopeMap(),
  );
}

PagListColumnPreference _preferenceFromResult(dynamic result) {
  final parsed = _preferenceMapFromResult(result, 'column_visibility');
  return PagListColumnPreference(
    found: parsed.found,
    columnVisibility: parsed.values,
    revision: parsed.revision,
  );
}

({bool found, Map<String, bool> values, int revision}) _preferenceMapFromResult(
    dynamic result, String valueKey) {
  if (result is! Map) {
    throw Exception('Invalid preference response');
  }
  final resultMap = Map<String, dynamic>.from(result);
  final found = resultMap['found'] == true;
  final revisionValue = resultMap['revision'];
  final revision = revisionValue is num
      ? revisionValue.toInt()
      : int.tryParse(revisionValue?.toString() ?? '') ?? 0;
  final values = <String, bool>{};
  final prefValue = resultMap['pref_value'];
  if (prefValue is Map) {
    final rawValues = prefValue[valueKey];
    if (rawValues is Map) {
      for (final entry in rawValues.entries) {
        if (entry.value is bool) {
          values[entry.key.toString()] = entry.value as bool;
        }
      }
    }
  }
  return (
    found: found,
    values: values,
    revision: revision,
  );
}
