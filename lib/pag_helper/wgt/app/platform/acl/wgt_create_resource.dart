import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_ex.dart';
import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/comm/pag_be_api_base.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_page_route.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_acl.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_app_context.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_building_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_profile.dart';
import 'package:buff_helper/pag_helper/wgt/scope/wgt_scope_setter.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pag_helper/pag_app_context_list.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

import '../../../../../xt_ui/wdgt/wgt_pag_wait.dart';
import '../../../../def_helper/dh_acl.dart';
import '../../../../model/mdl_pag_app_config.dart';

class WgtCreateResource extends StatefulWidget {
  const WgtCreateResource({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Function? onCreated;

  @override
  State<WgtCreateResource> createState() => _WgtCreateResourceState();
}

class _WgtCreateResourceState extends State<WgtCreateResource> {
  // late MdlPagUser? _loggedInUser;
  final double width = 395;

  bool _newItem = true;
  bool _createWait = false;
  bool _createSuccess = false;
  String _errorText = '';

  String? _newItemLabel;
  String? _newItemName;
  bool _isNewItemLabelValidated = false;
  UniqueKey? _newItemLabelResetKey;
  String _generatedLabelStatus = '';
  int _generatedLabelCheckGeneration = 0;

  String? _resTypeLabel;
  // bool _isResourceTypeNameValidated = false;
  UniqueKey? _resTypeNameResetKey;
  final TextEditingController resTypeLabelController = TextEditingController();

  MdlPagAppContext? _selectedAppContext;
  PagPageRoute? _selectedPageRoute;
  PageSection? _selectedPageSection;
  final TextEditingController _appContextController = TextEditingController();
  final TextEditingController _pageRouteController = TextEditingController();
  final TextEditingController _pageSectionController = TextEditingController();

  final Map<String, dynamic> _itemScopeMap = {};
  UniqueKey? _scopeSetterKey;

  final List<String> _resTypeLabelList = [];
  bool _isFetchingResTypeList = false;
  bool _isResTypeListFetched = false;
  String _resTypeListErrorText = '';

  bool _isProjectScope = false;

  bool get _isPageSectionResourceType {
    final normalizedLabel =
        _resTypeLabel?.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    return normalizedLabel == 'pagesection';
  }

  void _clearGeneratedLabel() {
    _generatedLabelCheckGeneration++;
    _newItemLabel = null;
    _isNewItemLabelValidated = false;
    _generatedLabelStatus = '';
    _newItemLabelResetKey = UniqueKey();
  }

  void _resetPageSectionSelection({bool clearLabel = true}) {
    _selectedAppContext = null;
    _selectedPageRoute = null;
    _selectedPageSection = null;
    _appContextController.clear();
    _pageRouteController.clear();
    _pageSectionController.clear();
    if (clearLabel) {
      _clearGeneratedLabel();
    }
  }

  Future<void> _updateGeneratedPageSectionLabel() async {
    final appContext = _selectedAppContext;
    final pageRoute = _selectedPageRoute;
    final pageSection = _selectedPageSection;
    if (appContext == null || pageRoute == null || pageSection == null) {
      setState(_clearGeneratedLabel);
      return;
    }

    final generatedLabel =
        getResNameByPageRouteSection(appContext, pageRoute, pageSection)!;
    final validationResult = validateResLabel(generatedLabel);
    final requestGeneration = ++_generatedLabelCheckGeneration;

    setState(() {
      _newItemLabel = generatedLabel;
      _isNewItemLabelValidated = false;
      _generatedLabelStatus = validationResult ?? 'checking';
      _newItemLabelResetKey = UniqueKey();
      _errorText = '';
      _newItem = true;
      _createSuccess = false;
    });

    if (validationResult != null) return;

    try {
      final projectName =
          widget.loggedInUser.selectedScope.projectProfile!.name;
      final result = await doPagCheckUnique(
        widget.appConfig,
        'label',
        generatedLabel,
        '$projectName.acl_res_$projectName',
      );
      if (!mounted ||
          requestGeneration != _generatedLabelCheckGeneration ||
          generatedLabel != _newItemLabel) {
        return;
      }

      final exists = result['exists'] == true;
      setState(() {
        _isNewItemLabelValidated = !exists;
        _generatedLabelStatus = exists ? 'taken' : 'available';
      });
    } catch (e) {
      dev.log('error checking generated resource label: $e');
      if (!mounted || requestGeneration != _generatedLabelCheckGeneration) {
        return;
      }
      setState(() {
        _isNewItemLabelValidated = false;
        _generatedLabelStatus = 'error';
      });
    }
  }

  Future<dynamic> _getResTypeLabelList() async {
    if (_isFetchingResTypeList || _isResTypeListFetched) {
      return;
    }

    setState(() {
      _isFetchingResTypeList = true;
      _resTypeListErrorText = '';
    });

    try {
      final result = await ex(
        endpoint: PagUrlBase.eptGetResTypeInfoList,
        crudType: 'read',
        opStr: 'get resource type list',
        appConfig: widget.appConfig,
        queryMap: {
          'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        },
        svcClaim: MdlPagSvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          roleId: widget.loggedInUser.selectedRole?.id,
          roleName: widget.loggedInUser.selectedRole?.name,
          roleLabel: widget.loggedInUser.selectedRole?.label,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      final resTypeInfoList = result['res_type_info_list'] as List<dynamic>;
      for (var resTypeInfo in resTypeInfoList) {
        String label = resTypeInfo['label'] as String;
        _resTypeLabelList.add(label);
      }
    } catch (e) {
      dev.log('error: $e');
      _resTypeListErrorText = getErrorText(e,
          defaultErrorText: 'Error fetching resource type list');
    } finally {
      setState(() {
        _isFetchingResTypeList = false;
        _isResTypeListFetched = true;
      });
    }
  }

  Future<dynamic> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
      _newItemName = null;
    });

    try {
      // _itemScopeMap['project_id'] =
      //     widget.loggedInUser.selectedScope.projectProfile!.id.toString();
      // _itemScopeMap['project_name'] =
      //     widget.loggedInUser.selectedScope.projectProfile!.name;

      Map<String, dynamic> queryMap = {
        'scope': widget.loggedInUser.selectedScope.toScopeMap(),
        'item_kind': PagItemKind.acl.value,
        'acl_type': PagAclType.resource.value,
        'label': _newItemLabel,
        'res_type_label': _resTypeLabel,
        'item_scope_info': _itemScopeMap,
        'is_project_scope': _isProjectScope.toString(),
      };

      final result = await ex(
        endpoint: PagUrlBase.eptCreateAclItem,
        crudType: 'create',
        opStr: 'create resource',
        appConfig: widget.appConfig,
        queryMap: queryMap,
        svcClaim: MdlPagSvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          roleId: widget.loggedInUser.selectedRole?.id,
          roleName: widget.loggedInUser.selectedRole?.name,
          roleLabel: widget.loggedInUser.selectedRole?.label,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      _newItemLabel = result['label'];
      _newItemName = result['name'];

      _newItem = false;
      _createSuccess = true;
    } catch (e) {
      dev.log('error: $e');

      // _errorText = 'Error creating resource';
      // String eStr = e.toString().toLowerCase();
      _errorText = getErrorText(e, defaultErrorText: 'Error creating resource');

      _newItem = true;
      _createSuccess = false;

      return;
    } finally {
      setState(() {
        _createWait = false;
      });
    }
  }

  bool _checkEnableButton() {
    if (!_newItem) {
      return false;
    }
    if (_createWait) {
      return false;
    }
    if (_errorText.isNotEmpty) {
      return false;
    }
    if (_newItemLabel == null || !_isNewItemLabelValidated) {
      return false;
    }

    return _newItemLabel != null &&
        _resTypeLabel != null &&
        (_itemScopeMap.isNotEmpty || _isProjectScope);
  }

  @override
  void initState() {
    super.initState();

    // _loggedInUser =
    //     Provider.of<PagUserProvider>(context, listen: false).currentUser;
  }

  @override
  void dispose() {
    resTypeLabelController.dispose();
    _appContextController.dispose();
    _pageRouteController.dispose();
    _pageSectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool fetchResTypeList = false;
    if (!_isResTypeListFetched && !_isFetchingResTypeList) {
      fetchResTypeList = true;
    }
    if (fetchResTypeList) {
      // future builder to fetch resource type list
      return FutureBuilder(
        future: _getResTypeLabelList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: WgtPagWait());
          } else if (snapshot.hasError) {
            return Center(
              child: getErrorTextPrompt(
                  context: context,
                  errorText: 'Error fetching resource type list'),
            );
          } else {
            return _buildForm();
          }
        },
      );
    } else {
      return _buildForm();
    }
  }

  Widget _buildForm() {
    if (_resTypeListErrorText.isNotEmpty) {
      return Center(
        child: getErrorTextPrompt(
            context: context, errorText: _resTypeListErrorText),
      );
    }
    return SingleChildScrollView(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: width,
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: [
                  // verticalSpaceRegular,
                  // getServiceTypeSelector(),
                  // verticalSpaceTiny,
                  getBasicInfoBlock(),
                  verticalSpaceTiny,
                  getResourceType(),
                  if (_isPageSectionResourceType) ...[
                    verticalSpaceTiny,
                    getPageSectionResourceSelectors(),
                  ],
                  verticalSpaceTiny,
                  getItemScopeSetter(),
                  verticalSpaceRegular,
                  WgtCommButton(
                    enabled: _checkEnableButton(),
                    label: _createWait
                        ? 'Creating resource...'
                        : _createSuccess
                            ? '✓ Resource created'
                            : 'Create Resource',
                    onPressed:
                        !_checkEnableButton() //_selectedProjectScope == null
                            ? null
                            : () async {
                                await _createItem();
                                if (_newItem &&
                                    !_createSuccess &&
                                    _errorText.isNotEmpty) {
                                  // don't reset the form if there is an error creating the item, allow user to fix the error
                                } else {
                                  // reset the form
                                  setState(() {
                                    // _newItem = true;
                                    if (_isPageSectionResourceType) {
                                      _resetPageSectionSelection();
                                    } else {
                                      _newItemLabel = null;
                                      _isNewItemLabelValidated = false;
                                      _newItemLabelResetKey = UniqueKey();
                                    }

                                    _itemScopeMap.clear();
                                    _scopeSetterKey = UniqueKey();
                                  });

                                  widget.onCreated?.call();
                                }
                              },
                  ),
                  if (_newItem && !_createSuccess && _errorText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(_errorText,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ),
                  if (!_newItem && _createSuccess && _errorText.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        'Resource ${_newItemName ?? ''} created',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  verticalSpaceRegular,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getBasicInfoBlock() {
    MdlPagScopeProfile scopeProfile = widget.loggedInUser.selectedScope;
    String projectName = scopeProfile.projectProfile!.name;

    return Column(
      children: [
        verticalSpaceTiny,
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).hintColor.withAlpha(30),
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Column(children: [
            WgtTextField(
              key: _newItemLabelResetKey,
              appConfig: widget.appConfig,
              initialValue: _newItemLabel,
              hintText: 'Label',
              labelText: 'Label',
              maxLength: maxFullNameLength,
              enabled: !_isPageSectionResourceType,
              showClearButton: !_isPageSectionResourceType,
              requireUnique: !_isPageSectionResourceType,
              validator: validateResLabel,
              checkUnique: doPagCheckUnique,
              uniqueKey: 'label',
              itemTableName: '$projectName.acl_res_$projectName',
              suffix: _isPageSectionResourceType
                  ? _getGeneratedLabelStatusWidget()
                  : null,
              onChanged: (val) {
                setState(() {
                  if (val != _newItemLabel) {
                    _errorText = '';
                  }
                });
                if (val.trim().isNotEmpty) {
                  setState(() {
                    _newItem = true;
                    _createSuccess = false;
                  });
                }
                _newItemLabel = val;
                return null;
              },
              onValidate: (String? result) {
                setState(() {
                  if (result == null) {
                    _isNewItemLabelValidated = true;
                  } else {
                    _isNewItemLabelValidated = false;
                  }
                });
              },
            ),
          ]),
        ),
      ],
    );
  }

  Widget getResourceType() {
    return Column(
      children: [
        verticalSpaceTiny,
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).hintColor.withAlpha(30),
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Column(children: [
            // WgtTextField(
            //   key: _resourceTypeNameResetKey,
            //   appConfig: widget.appConfig,
            //   hintText: 'Resource Type Name',
            //   labelText: 'Resource Type Name',
            //   maxLength: maxFullNameLength,
            //   validator: validateItemLabel,
            //   onChanged: (val) {
            //     setState(() {
            //       _isEditing = true;
            //       if (val != _resourceTypeName) {
            //         _errorText = '';
            //       }
            //     });
            //     if (val.trim().isNotEmpty) {
            //       setState(() {
            //         _newItem = true;
            //         _createSuccess = false;
            //       });
            //     }
            //     _resourceTypeName = val;
            //     return null;
            //   },
            //   onEditingComplete: () {
            //     setState(() {
            //       _isEditing = false;
            //     });
            //   },
            //   onValidate: (String? result) {
            //     setState(() {
            //       if (result == null) {
            //         _isResourceTypeNameValidated = true;
            //       } else {
            //         _isResourceTypeNameValidated = false;
            //       }
            //     });
            //   },
            // ),
            WgtDropdownSelector(
              key: _resTypeNameResetKey,
              hint: 'Select Resource Type',
              items: _resTypeLabelList,
              controller: resTypeLabelController,
              initialValue: _resTypeLabel,
              // isInitialValueMutable: widget.fixedItemLabel == null,
              height: 50,
              width: 420,
              onSelected: (String? value) async {
                if (value == _resTypeLabel) {
                  return;
                }
                final wasPageSectionResourceType = _isPageSectionResourceType;
                setState(() {
                  _resTypeLabel = value;
                  if (wasPageSectionResourceType ||
                      _isPageSectionResourceType) {
                    _resetPageSectionSelection();
                  }
                  // _enableSearch = _enableSearchButton();
                  _errorText = '';
                  _newItem = true;
                  _createSuccess = false;

                  _checkEnableButton();
                });
                // widget.onModified?.call();
                // widget.onLabelSelected?.call(_resourceTypeLabel!);
              },
            ),
          ]),
        ),
      ],
    );
  }

  Widget getPageSectionResourceSelectors() {
    final pageRoutes = _selectedAppContext?.routeList ?? const [];
    final pageSections = _selectedPageRoute?.pageSectionList ?? const [];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).hintColor.withAlpha(30),
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Column(
        children: [
          WgtDropdownSelector(
            hint: 'Select App Context',
            items: appContextList.map((appContext) => appContext.name).toList(),
            controller: _appContextController,
            initialValue: _selectedAppContext?.name,
            height: 50,
            width: 420,
            onSelected: (String? value) {
              setState(() {
                _selectedAppContext = value == null
                    ? null
                    : appContextList
                        .where((appContext) => appContext.name == value)
                        .firstOrNull;
                _selectedPageRoute = null;
                _selectedPageSection = null;
                _pageRouteController.clear();
                _pageSectionController.clear();
                _clearGeneratedLabel();
                _errorText = '';
                _newItem = true;
                _createSuccess = false;
              });
            },
          ),
          if (_selectedAppContext != null) ...[
            verticalSpaceTiny,
            WgtDropdownSelector(
              key: ValueKey('page-route-${_selectedAppContext!.name}'),
              hint: 'Select Page Route',
              items: pageRoutes.map((pageRoute) => pageRoute.name).toList(),
              controller: _pageRouteController,
              initialValue: _selectedPageRoute?.name,
              height: 50,
              width: 420,
              onSelected: (String? value) {
                setState(() {
                  _selectedPageRoute = value == null
                      ? null
                      : pageRoutes
                          .where((pageRoute) => pageRoute.name == value)
                          .firstOrNull;
                  _selectedPageSection = null;
                  _pageSectionController.clear();
                  _clearGeneratedLabel();
                  _errorText = '';
                  _newItem = true;
                  _createSuccess = false;
                });
              },
            ),
          ],
          if (_selectedPageRoute != null) ...[
            verticalSpaceTiny,
            WgtDropdownSelector(
              key: ValueKey('page-section-${_selectedPageRoute!.name}'),
              hint: 'Select Page Section',
              items:
                  pageSections.map((pageSection) => pageSection.name).toList(),
              controller: _pageSectionController,
              initialValue: _selectedPageSection?.name,
              height: 50,
              width: 420,
              onSelected: (String? value) async {
                setState(() {
                  _selectedPageSection = value == null
                      ? null
                      : pageSections
                          .where((pageSection) => pageSection.name == value)
                          .firstOrNull;
                });
                await _updateGeneratedPageSectionLabel();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _getGeneratedLabelStatusWidget() {
    switch (_generatedLabelStatus) {
      case 'checking':
        return WgtPagWait(
          size: 20,
          showCenterSquare: false,
          colorA: Theme.of(context).colorScheme.primary,
        );
      case 'available':
        return const Text('available', style: TextStyle(color: Colors.green));
      case 'taken':
        return Text(
          'taken',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        );
      case 'error':
        return Text(
          'error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        );
      case '':
        return const SizedBox();
      default:
        return Text(
          _generatedLabelStatus,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        );
    }
  }

  Widget getItemScopeSetter() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: WgtScopeSetter(
        key: _scopeSetterKey,
        appConfig: widget.appConfig,
        width: width,
        labelWidth: 130,
        allowProjectScope: true,
        // itemScopeMap: widget.itemScopeMap!,
        forItemKind: PagItemKind.acl,
        // forScopeType: widget.itemType is PagScopeType ? widget.itemType : null,
        onScopeSet: (dynamic profile) {
          if (profile == null) {
            // dev.log('Profile is null');
            // return {};
            // null means project scope
          }
          String scopeIdColName = '';
          String scopeNameColName = '';
          if (profile is MdlPagSiteGroupProfile) {
            scopeIdColName = 'site_group_id';
            scopeNameColName = 'site_group_name';
          } else if (profile is MdlPagSiteProfile) {
            scopeIdColName = 'site_id';
            scopeNameColName = 'site_name';
          } else if (profile is MdlPagBuildingProfile) {
            scopeIdColName = 'building_id';
            scopeNameColName = 'building_name';
          } else if (profile is MdlPagLocationGroupProfile) {
            scopeIdColName = 'location_group_id';
            scopeNameColName = 'location_group_name';
          } else if (profile is MdlPagLocation) {
            scopeIdColName = 'location_id';
            scopeNameColName = 'location_name';
          }
          if (scopeIdColName.isEmpty) {
            // dev.log('Invalid profile type');
            // null means project scope, so we can return an empty map
            _isProjectScope = true;
          }
          setState(() {
            if (!_isProjectScope) {
              _itemScopeMap[scopeIdColName] = profile.id.toString();
              _itemScopeMap[scopeNameColName] = profile.name;
            }
            if (_itemScopeMap.isNotEmpty) {
              _isProjectScope = false;
            }
            _checkEnableButton();
          });
        },
      ),
    );
  }
}
