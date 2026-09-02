import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_ex.dart';
import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_config.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_building_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_profile.dart';
import 'package:buff_helper/pag_helper/wgt/scope/wgt_scope_setter.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

class WgtCreatePermission2 extends StatefulWidget {
  const WgtCreatePermission2({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Function? onCreated;

  @override
  State<WgtCreatePermission2> createState() => _WgtCreatePermission2State();
}

class _WgtCreatePermission2State extends State<WgtCreatePermission2> {
  static const double _width = 720;
  static const List<String> _operations = <String>[
    'create',
    'read',
    'update',
    'delete',
    'list',
  ];

  final Map<String, dynamic> _itemScopeMap = <String, dynamic>{};
  final Map<String, Set<String>> _selectedOperations = <String, Set<String>>{};
  final Map<String, Set<String>> _originalOperations = <String, Set<String>>{};

  List<Map<String, dynamic>> _resourceTypes = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _resources = <Map<String, dynamic>>[];

  bool _scopeSelected = false;
  bool _isProjectScope = false;
  bool _loadingResourceTypes = false;
  bool _loadingResources = false;
  bool _creating = false;
  bool _createSuccess = false;

  String? _selectedResourceTypeId;
  String? _permissionLabel;
  UniqueKey? _labelResetKey;
  bool _isLabelValid = true;
  String _errorText = '';
  String _resourceErrorText = '';
  int _createdCount = 0;
  int _deletedCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResourceTypes();
    });
  }

  MdlPagSvcClaim _svcClaim() {
    return MdlPagSvcClaim(
      userId: widget.loggedInUser.id,
      username: widget.loggedInUser.username,
      roleId: widget.loggedInUser.selectedRole?.id,
      roleName: widget.loggedInUser.selectedRole?.name,
      roleLabel: widget.loggedInUser.selectedRole?.label,
      scope: '',
      target: '',
      operation: '',
    );
  }

  Future<void> _loadResourceTypes() async {
    if (_loadingResourceTypes) return;
    setState(() {
      _loadingResourceTypes = true;
      _errorText = '';
    });

    try {
      final dynamic result = await ex(
        endpoint: PagUrlBase.eptGetResTypeInfoList,
        crudType: 'read',
        opStr: 'get resource type list',
        appConfig: widget.appConfig,
        queryMap: <String, dynamic>{
          'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        },
        svcClaim: _svcClaim(),
      );
      final List<dynamic> values =
          result['res_type_info_list'] as List<dynamic>? ?? <dynamic>[];
      _resourceTypes = values
          .whereType<Map>()
          .map((Map value) => Map<String, dynamic>.from(value))
          .toList()
        ..sort((Map<String, dynamic> left, Map<String, dynamic> right) =>
            (left['label'] ?? '').toString().compareTo(
                  (right['label'] ?? '').toString(),
                ));
    } catch (error) {
      dev.log('Error loading resource types: $error');
      _errorText = getErrorText(
        error,
        defaultErrorText: 'Error fetching resource type list',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingResourceTypes = false;
        });
      }
    }
  }

  Future<void> _loadResources() async {
    final String? resourceTypeId = _selectedResourceTypeId;
    if (!_scopeSelected || resourceTypeId == null || _loadingResources) return;

    setState(() {
      _loadingResources = true;
      _resourceErrorText = '';
      _resources = <Map<String, dynamic>>[];
      _selectedOperations.clear();
      _originalOperations.clear();
      _createSuccess = false;
    });

    try {
      final dynamic result = await ex(
        endpoint: PagUrlBase.eptGetAclScopeResList2,
        crudType: 'read',
        opStr: 'get scoped resource list',
        appConfig: widget.appConfig,
        queryMap: <String, dynamic>{
          'scope': widget.loggedInUser.selectedScope.toScopeMap(),
          'item_scope_info': Map<String, dynamic>.from(_itemScopeMap),
          'is_project_scope': _isProjectScope.toString(),
          'res_type_id': resourceTypeId,
        },
        svcClaim: _svcClaim(),
      );

      final List<dynamic> values =
          result['resource_list'] as List<dynamic>? ?? <dynamic>[];
      _resources = values
          .whereType<Map>()
          .map((Map value) => Map<String, dynamic>.from(value))
          .toList();
      for (final Map<String, dynamic> resource in _resources) {
        final String resourceId = resource['id'].toString();
        final Set<String> existingOperations =
            ((resource['existing_operations'] as List<dynamic>?) ?? <dynamic>[])
                .map((dynamic value) => value.toString())
                .where(_operations.contains)
                .toSet();
        _originalOperations[resourceId] = Set<String>.from(existingOperations);
        _selectedOperations[resourceId] = Set<String>.from(existingOperations);
      }
    } catch (error) {
      dev.log('Error loading resources: $error');
      _resourceErrorText = getErrorText(
        error,
        defaultErrorText: 'Error fetching resources',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingResources = false;
        });
      }
    }
  }

  Future<void> _commitPermissions() async {
    if (!_canCreate()) return;

    final List<Map<String, dynamic>> changeList = <Map<String, dynamic>>[];
    for (final String resourceId in _selectedOperations.keys) {
      final Set<String> selected =
          _selectedOperations[resourceId] ?? <String>{};
      final Set<String> original =
          _originalOperations[resourceId] ?? <String>{};
      for (final String operation in _operations) {
        if (selected.contains(operation) != original.contains(operation)) {
          changeList.add(<String, dynamic>{
            'resource_id': resourceId,
            'operation': operation,
            'selected': selected.contains(operation),
          });
        }
      }
    }

    setState(() {
      _creating = true;
      _createSuccess = false;
      _errorText = '';
    });

    try {
      final dynamic result = await ex(
        endpoint: PagUrlBase.eptCreateAclPermission2,
        crudType: 'create',
        opStr: 'create permissions',
        appConfig: widget.appConfig,
        queryMap: <String, dynamic>{
          'scope': widget.loggedInUser.selectedScope.toScopeMap(),
          'item_scope_info': Map<String, dynamic>.from(_itemScopeMap),
          'is_project_scope': _isProjectScope.toString(),
          'res_type_id': _selectedResourceTypeId,
          'label': _permissionLabel?.trim(),
          'permission_change_list': changeList,
        },
        svcClaim: _svcClaim(),
      );

      _createdCount = int.tryParse(result['added_count'].toString()) ?? 0;
      _deletedCount = int.tryParse(result['deleted_count'].toString()) ?? 0;
      for (final MapEntry<String, Set<String>> entry
          in _selectedOperations.entries) {
        _originalOperations[entry.key] = Set<String>.from(entry.value);
      }
      _permissionLabel = null;
      _labelResetKey = UniqueKey();
      _isLabelValid = true;
      _createSuccess = true;
      widget.onCreated?.call();
    } catch (error) {
      dev.log('Error creating permissions: $error');
      _errorText = getErrorText(
        error,
        defaultErrorText: 'Error creating permissions',
      );
    } finally {
      if (mounted) {
        setState(() {
          _creating = false;
        });
      }
    }
  }

  bool _canCreate() {
    return _scopeSelected &&
        _selectedResourceTypeId != null &&
        !_loadingResources &&
        !_creating &&
        _isLabelValid &&
        _errorText.isEmpty &&
        _hasChanges();
  }

  bool _hasChanges() {
    for (final String resourceId in _selectedOperations.keys) {
      final Set<String> selected =
          _selectedOperations[resourceId] ?? <String>{};
      final Set<String> original =
          _originalOperations[resourceId] ?? <String>{};
      if (!_setsEqual(selected, original)) return true;
    }
    return false;
  }

  bool _setsEqual(Set<String> left, Set<String> right) {
    return left.length == right.length && left.containsAll(right);
  }

  void _onScopeSet(dynamic profile) {
    final Map<String, dynamic> nextScope = <String, dynamic>{};
    bool projectScope = false;

    if (profile == null) {
      projectScope = true;
    } else if (profile is MdlPagSiteGroupProfile) {
      nextScope['site_group_id'] = profile.id.toString();
      nextScope['site_group_name'] = profile.name;
    } else if (profile is MdlPagSiteProfile) {
      nextScope['site_id'] = profile.id.toString();
      nextScope['site_name'] = profile.name;
    } else if (profile is MdlPagBuildingProfile) {
      nextScope['building_id'] = profile.id.toString();
      nextScope['building_name'] = profile.name;
    } else if (profile is MdlPagLocationGroupProfile) {
      nextScope['location_group_id'] = profile.id.toString();
      nextScope['location_group_name'] = profile.name;
    } else if (profile is MdlPagLocation) {
      nextScope['location_id'] = profile.id.toString();
      nextScope['location_name'] = profile.name;
    } else {
      setState(() {
        _scopeSelected = false;
        _errorText = 'Invalid scope selection';
      });
      return;
    }

    setState(() {
      _itemScopeMap
        ..clear()
        ..addAll(nextScope);
      _scopeSelected = true;
      _isProjectScope = projectScope;
      _selectedResourceTypeId = null;
      _resources = <Map<String, dynamic>>[];
      _selectedOperations.clear();
      _originalOperations.clear();
      _resourceErrorText = '';
      _errorText = '';
      _createSuccess = false;
    });
  }

  void _toggleOperation(String resourceId, String operation, bool selected) {
    setState(() {
      final Set<String> operations =
          _selectedOperations.putIfAbsent(resourceId, () => <String>{});
      if (selected) {
        operations.add(operation);
      } else {
        operations.remove(operation);
      }
      _createSuccess = false;
      _errorText = '';
    });
  }

  void _toggleReadOnly(String resourceId, bool selected) {
    setState(() {
      final Set<String> operations =
          _selectedOperations.putIfAbsent(resourceId, () => <String>{});
      if (selected) {
        operations.addAll(<String>{'read', 'list'});
      } else {
        operations.removeAll(<String>{'read', 'list'});
      }
      _createSuccess = false;
      _errorText = '';
    });
  }

  void _toggleFull(String resourceId, bool selected) {
    setState(() {
      final Set<String> operations =
          _selectedOperations.putIfAbsent(resourceId, () => <String>{});
      if (selected) {
        operations.addAll(_operations);
      } else {
        operations.removeAll(_operations);
      }
      _createSuccess = false;
      _errorText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: _width,
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Create/Edit Permissions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 16),
                ),
                verticalSpaceSmall,
                WgtScopeSetter(
                  appConfig: widget.appConfig,
                  width: _width,
                  labelWidth: 130,
                  allowProjectScope: true,
                  // showCommitted: false,
                  forItemKind: PagItemKind.acl,
                  onScopeSet: _onScopeSet,
                ),
                verticalSpaceSmall,
                _buildResourceTypeSelector(),
                verticalSpaceSmall,
                _buildResourceOperationList(),
                verticalSpaceSmall,
                WgtTextField(
                  key: _labelResetKey,
                  appConfig: widget.appConfig,
                  hintText: 'Leave blank if no label is needed',
                  labelText: 'Permission label (Optional)',
                  maxLength: maxFullNameLength,
                  maxLines: 1,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return validateItemLabel(value);
                  },
                  onChanged: (String value) {
                    _permissionLabel = value;
                    if (_errorText.isNotEmpty) {
                      setState(() {
                        _errorText = '';
                      });
                    }
                    return null;
                  },
                  onValidate: (String? error) {
                    setState(() {
                      _isLabelValid = error == null;
                    });
                  },
                ),
                verticalSpaceRegular,
                Align(
                  alignment: Alignment.center,
                  child: WgtCommButton(
                    enabled: _canCreate(),
                    label: _creating ? 'Committing...' : 'Commit Permissions',
                    onPressed: _canCreate() ? _commitPermissions : null,
                  ),
                ),
                if (_errorText.isNotEmpty)
                  getErrorTextPrompt(
                    context: context,
                    errorText: _errorText,
                  ),
                if (_createSuccess)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      '✓ $_createdCount added, $_deletedCount deleted',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                verticalSpaceMedium,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResourceTypeSelector() {
    if (!_scopeSelected) {
      return _emptyPanel('Select a permission scope first');
    }
    if (_loadingResourceTypes) {
      return const SizedBox(
        height: 50,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return DropdownButtonFormField<String>(
      key: ValueKey<String?>(_selectedResourceTypeId),
      initialValue: _selectedResourceTypeId,
      decoration: InputDecoration(
        // labelText: 'Resource Type',
        isDense: true,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).hintColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).hintColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).hintColor),
        ),
      ),
      hint: Text(_scopeSelected
          ? 'Select resource type'
          : 'Select permission scope first'),
      items: _resourceTypes.map((Map<String, dynamic> resourceType) {
        return DropdownMenuItem<String>(
          value: resourceType['id'].toString(),
          child: Text(
              (resourceType['label'] ?? resourceType['name'] ?? '').toString()),
        );
      }).toList(),
      onChanged: !_scopeSelected
          ? null
          : (String? value) {
              setState(() {
                _selectedResourceTypeId = value;
                _resources = <Map<String, dynamic>>[];
                _selectedOperations.clear();
                _originalOperations.clear();
                _resourceErrorText = '';
                _createSuccess = false;
              });
              if (value != null) {
                _loadResources();
              }
            },
    );
  }

  Widget _buildResourceOperationList() {
    if (!_scopeSelected) {
      return _emptyPanel('Select a permission scope first');
    }
    if (_selectedResourceTypeId == null) {
      return _emptyPanel('Select a resource type');
    }
    if (_loadingResources) {
      return const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_resourceErrorText.isNotEmpty) {
      return getErrorTextPrompt(
        context: context,
        errorText: _resourceErrorText,
      );
    }
    if (_resources.isEmpty) {
      return _emptyPanel('No matching resources');
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: <Widget>[
          Container(
            color: Theme.of(context).hoverColor,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Resource',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
                _operationHeader('C', 'Create'),
                _operationHeader('R', 'Read'),
                _operationHeader('U', 'Update'),
                _operationHeader('D', 'Delete'),
                _operationHeader('L', 'List'),
                _operationHeader('RO', 'Read only: Read + List', width: 48),
                _operationHeader('Full', 'All operations', width: 54),
              ],
            ),
          ),
          ..._resources.map(_buildResourceRow),
        ],
      ),
    );
  }

  Widget _buildResourceRow(Map<String, dynamic> resource) {
    final String resourceId = resource['id'].toString();
    final Set<String> selected = _selectedOperations[resourceId] ?? <String>{};
    final Set<String> original = _originalOperations[resourceId] ?? <String>{};
    final bool readOnlySelected =
        selected.contains('read') && selected.contains('list');
    final bool readOnlyChanged = <String>['read', 'list'].any(
      (String operation) =>
          selected.contains(operation) != original.contains(operation),
    );
    final bool fullSelected =
        _operations.every((String operation) => selected.contains(operation));
    final bool fullChanged = _operations.any(
      (String operation) =>
          selected.contains(operation) != original.contains(operation),
    );
    final String label = (resource['label'] ?? '').toString();
    final String name = (resource['name'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).hintColor),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Tooltip(
              message: name,
              child: Text(
                label.isNotEmpty ? label : name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          ..._operations.map((String operation) => _operationCheckbox(
                selected.contains(operation),
                (bool value) => _toggleOperation(resourceId, operation, value),
                changed: selected.contains(operation) !=
                    original.contains(operation),
              )),
          _operationCheckbox(
            readOnlySelected,
            (bool value) => _toggleReadOnly(resourceId, value),
            changed: readOnlyChanged,
            width: 48,
          ),
          _operationCheckbox(
            fullSelected,
            (bool value) => _toggleFull(resourceId, value),
            changed: fullChanged,
            width: 54,
          ),
        ],
      ),
    );
  }

  Widget _operationHeader(
    String label,
    String tooltip, {
    double width = 35,
  }) {
    return SizedBox(
      width: width,
      child: Tooltip(
        message: tooltip,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      ),
    );
  }

  Widget _operationCheckbox(
    bool selected,
    ValueChanged<bool> onChanged, {
    required bool changed,
    double width = 35,
  }) {
    return SizedBox(
      width: width,
      child: Checkbox(
        value: selected,
        activeColor:
            changed ? commitColor : Theme.of(context).colorScheme.primary,
        side: BorderSide(
          color: changed ? commitColor : Theme.of(context).hintColor,
          width: changed ? 2 : 1,
        ),
        focusColor: Theme.of(context).colorScheme.primary,
        checkColor: Theme.of(context).colorScheme.onPrimary,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: (bool? value) => onChanged(value ?? false),
      ),
    );
  }

  Widget _emptyPanel(String message) {
    return Container(
      height: 65,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).hintColor),
      ),
    );
  }
}
