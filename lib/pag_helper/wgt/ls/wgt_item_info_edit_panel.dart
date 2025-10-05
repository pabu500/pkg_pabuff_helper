import 'package:buff_helper/pag_helper/comm/comm_batch_op.dart';
import 'package:buff_helper/pag_helper/comm/comm_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/def_role.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_tariff_package_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_controller.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_building_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_profile.dart';
import 'package:buff_helper/pag_helper/wgt/app/ems/wgt_payment_lc_status_op.dart';
import 'package:buff_helper/pagrid_helper/batch_op_helper/wgt_confirm_box.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:buff_helper/pag_helper/def_helper/def_item_group.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as dev;

import '../../def_helper/dh_device.dart';
import '../../def_helper/tariff_package_helper.dart';
import '../../model/mdl_pag_app_config.dart';
import '../scope/wgt_scope_setter.dart';
import '../tree/wgt_item_group_tree.dart';
import '../user/wgt_op_reset_password.dart';
import '../user/wgt_uesr_role_setter.dart';

class WgtPagItemInfoEditPanel extends StatefulWidget {
  const WgtPagItemInfoEditPanel({
    super.key,
    required this.appConfig,
    required this.itemIndexStr,
    required this.itemKind,
    required this.itemDisplayName,
    required this.fields,
    this.itemType,
    this.listController,
    this.itemScopeMap,
    this.itemInfoMap,
    this.onClose,
    this.onUpdate,
    this.onScopeTreeUpdate,
    this.validateTreeChildren,
    this.customProperties,
  });

  final MdlPagAppConfig appConfig;
  final String itemIndexStr;
  final PagItemKind itemKind;
  final String itemDisplayName;
  final MdlPagListController? listController;
  final Map<String, dynamic>? itemScopeMap;
  final Map<String, dynamic>? itemInfoMap;
  final List<Map<String, dynamic>> fields;
  final dynamic itemType;
  final Function? onClose;
  final Function? onUpdate;
  final Function? onScopeTreeUpdate;
  final Function? validateTreeChildren;
  final Map<String, dynamic>? customProperties;

  @override
  State<WgtPagItemInfoEditPanel> createState() =>
      _WgtPagItemInfoEditPanelState();
}

class _WgtPagItemInfoEditPanelState extends State<WgtPagItemInfoEditPanel> {
  late MdlPagUser? _loggedInUser;
  final double width = 500;
  final double labelWidth = 150;

  String? _itemDisplayName;

  String _currentField = '';
  bool _fieldUpdated = false;

  final List<Widget> fields = [];

  bool _isTenantUser = false;

  late final bool isEditableByAcl;

  late bool isDeleteableItem;
  late final bool isDeleteableByAcl;
  bool _isDeleting = false;
  String _deleteResultText = '';

  String _errorText = '';

  UniqueKey? _lcStatusOpsKey;
  late dynamic _lcStatusDisplay;

  Future<List<Map<String, dynamic>>> _updateProfile(String key, String value,
      {String? oldVal, String? scopeProfileIdColName}) async {
    try {
      Map<String, dynamic> opItem = {
        'id': widget.itemIndexStr,
        key: value,
        'checked': true,
      };
      if (scopeProfileIdColName != null) {
        opItem['scope_profile_id_column_name'] = scopeProfileIdColName;
      }

      Map<String, dynamic> queryMap = {
        'scope': _loggedInUser!.selectedScope.toScopeMap(),
        'id': widget.itemIndexStr,
        'item_kind': widget.itemKind.name,
        'item_id_type': ItemIdType.id.name,
        'item_id_key': 'id',
        'item_id': widget.itemIndexStr,
        // 'key1, key2, key3, ...'
        'update_key_str': key,
        'op_name': 'multi_key_val_update',
        'op_list': [opItem],
      };

      if (widget.listController != null) {
        queryMap['item_table_name'] = widget.listController!.rootTableName;
      }

      List<Map<String, dynamic>> result = await doPagOpMultiKeyValUpdate(
        widget.appConfig,
        _loggedInUser,
        queryMap,
        MdlPagSvcClaim(
          username: _loggedInUser!.username,
          userId: _loggedInUser!.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      return result;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      //return a Map
      Map<String, dynamic> result = {};
      result['error'] = explainException(e, defaultMsg: 'Error updating field');

      //result is a List
      return [result];
    }
  }

  Future<dynamic> _doDelete(String itemName) async {
    if (_isDeleting) {
      return {};
    }
    setState(() {
      _isDeleting = true;
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    try {
      String itemTypeStr = '';
      if (widget.itemType is PagScopeType) {
        itemTypeStr = (widget.itemType as PagScopeType).name;
      } else if (widget.itemType is PagDeviceCat) {
        itemTypeStr = (widget.itemType as PagDeviceCat).name;
      }
      Map<String, dynamic> queryMap = {
        'scope': _loggedInUser!.selectedScope.toScopeMap(),
        'id': widget.itemIndexStr,
        'item_kind': widget.itemKind.name,
        'item_type': itemTypeStr,
        'item_id_type': ItemIdType.id.name,
        'item_id_key': 'id',
        'item_id_value': widget.itemIndexStr,
        'item_name': itemName,
      };
      if (widget.listController != null) {
        queryMap['item_table_name'] = widget.listController!.rootTableName;
      }

      dynamic data = await doPagDelete(
        widget.appConfig,
        _loggedInUser,
        queryMap,
        MdlPagSvcClaim(
          username: _loggedInUser!.username,
          userId: _loggedInUser!.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      return data;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return {'error': explainException(e, defaultMsg: 'Error deleting item')};
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  void _updateIsTenantUser(List<Map<String, dynamic>> userRoleList) {
    bool isTenantUser = false;
    for (Map<String, dynamic> roleInfo in userRoleList) {
      if (roleInfo['portal_type'] == PagPortalType.pagEmsTp.value) {
        isTenantUser = true;
        break;
      }
    }
    setState(() {
      _isTenantUser = isTenantUser;
    });
  }

  @override
  void initState() {
    super.initState();

    _loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;
    _itemDisplayName = widget.itemDisplayName;
    _fieldUpdated = false;

    bool isAtProjectLevel =
        _loggedInUser!.selectedScope.isAtScopeType(PagScopeType.project);
    bool isAdmin = _loggedInUser!.selectedRole?.isAdmin() ?? false;

    bool isProjectBilling =
        _loggedInUser!.selectedRole?.name.contains('project-billing-') ?? false;

    isEditableByAcl = isAdmin || isAtProjectLevel;

    isDeleteableItem = false;
    if (widget.itemKind == PagItemKind.device) {
      if (widget.itemType is PagDeviceCat) {
        if (widget.itemType == PagDeviceCat.meter) {
          isDeleteableItem = true;
        }
      }
    }

    isDeleteableByAcl = isAtProjectLevel && isAdmin;
  }

  String? tagValidator(String? value) {
    if (value == null) {
      return null;
    }
    //alphanumeric, 2-55
    final RegExp alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
    if (!alphanumeric.hasMatch(value)) {
      return 'Tag must be alphanumeric';
    }
    if (value.length < 2 || value.length > 55) {
      return 'Tag must be between 2 and 55 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    bool isItemMFD = false;
    for (Map<String, dynamic> field in widget.fields) {
      if (field['col_key'] != 'lc_status') {
        continue;
      }

      if (field['value'] is Map) {
        isItemMFD = field['value']['value'] == 'mfd';
      } else {
        isItemMFD = field['value'] == 'mfd';
      }
      break;
    }
    String itemName = '';
    for (Map<String, dynamic> field in widget.fields) {
      if (field['col_key'] == 'name') {
        itemName = field['value'];
        break;
      }
    }
    if (itemName.isEmpty) {
      isDeleteableItem = false;
    }

    return SizedBox(
      width: width,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                if (isDeleteableItem && isDeleteableByAcl && isItemMFD)
                  _isDeleting
                      ? const WgtPagWait(size: 35)
                      : (_deleteResultText.isNotEmpty)
                          ? Text(
                              _deleteResultText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _deleteResultText.contains('deleted')
                                    ? commitColor
                                    : Theme.of(context).colorScheme.error,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return WgtConfirmBox(
                                          title: 'Delete Confirmation',
                                          message1:
                                              'This operation will delete the selected item',
                                          message2:
                                              'It\'s recommended to double check before proceeding',
                                          opName: 'item_delete',
                                          keyInConfirmStrList: [
                                            'delete',
                                            itemName,
                                          ],
                                          itemCount: 1,
                                          onConfirm: () async {
                                            await _doDelete(itemName).then(
                                              (result) {
                                                if (result is Map) {
                                                  if (result['error'] != null) {
                                                    setState(() {
                                                      _deleteResultText =
                                                          result['error'];
                                                    });
                                                  } else {
                                                    setState(() {
                                                      _deleteResultText =
                                                          'Item deleted';
                                                    });
                                                  }
                                                }
                                                widget.onUpdate?.call();
                                              },
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _itemDisplayName ?? '',
                        style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                ),
                Row(
                  // mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    getLcStatusOp(widget.fields.firstWhere(
                        (element) => element['col_key'] == 'lc_status')),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (_fieldUpdated) {
                          widget.onClose?.call();
                        }
                      },
                    ),
                    horizontalSpaceMedium,
                  ],
                ),
              ],
            ),
            // verticalSpaceSmall,
            const Divider(height: 1),
            verticalSpaceSmall,
            _deleteResultText == 'Item deleted'
                ? Container()
                : Column(
                    // alignment: WrapAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).hintColor.withAlpha(50)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 3),
                        width: width,
                        child: Column(
                          children: [
                            ...getFields(),
                          ],
                        ),
                      ),
                      getUserRoleSetter(),
                      getUserPasswordReset(),
                      getItemScopeSetter(),
                      getItemGroupTree(),
                    ],
                  ),
            verticalSpaceSmall,
          ],
        ),
      ),
    );
  }

  List<Widget> getFields() {
    // List<Widget> fields = [];

    fields.clear();
    for (Map<String, dynamic> field in widget.fields) {
      if (field['show_edit_panel'] == false) {
        continue;
      }

      if (field['col_key'] == 'updated_timestamp') {
        continue;
      }

      String? hintText;
      if (field['type'] == PagFilterGroupType.DATETIME) {
        hintText = 'YYYY-MM-DD hh:mm:ss';
        if (field['validator'] == null) {
          field['validator'] = (String? value) {
            if (value == null || value.isEmpty) {
              // return 'Please enter a date';
              return null;
            }
            DateTime? dateTime = DateTime.tryParse(value);
            if (dateTime == null) {
              return 'Invalid date format';
            }
            return null;
          };
        }
      }

      if (field['col_key'] == 'tag') {
        if (field['validator'] == null) {
          field['validator'] = tagValidator;
        }
      }

      fields.add(
        (field['widget'] ?? 'input') == 'input'
            ? Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: WgtViewEditField(
                    width: width,
                    editable: isEditableByAcl && (field['editable'] ?? false),
                    showCopy: field['show_copy'] ?? false,
                    useDatePicker: field['useDatePicker'] ?? false,
                    showLabel: true,
                    labelWidth: labelWidth,
                    hintText: hintText,
                    labelText: field['label'] ?? field['title'],
                    originalValue: field['value'] ?? field['val'] ?? '',
                    onFocus: (hasFocus) {
                      setState(() {
                        _currentField = field['col_key'];
                      });
                    },
                    hasFocus: _currentField == field['col_key'],
                    onSetValue: (newValue) async {
                      List<Map<String, dynamic>> result = await _updateProfile(
                        field['col_key'],
                        newValue,
                      );
                      Map<String, dynamic> resultMap = result[0];
                      if (resultMap['error'] == null) {
                        setState(() {
                          field['value'] = newValue;
                          field['val'] = newValue;
                          _fieldUpdated = true;
                          widget.onUpdate?.call();
                        });
                      }

                      return resultMap;
                    },
                    validator: field['validator'],
                    textStyle: null,
                    onPullRefVal: field['onPullRefVal'] == null
                        ? null
                        : () {
                            // return field['onPullRefVal'].call(itemNameField['val']);
                          }
                    // field['onPullRefVal'].call(itemNameField['val']),
                    ),
              )
            : field['widget'] == 'dropdown' && field['value_list'] != null
                ? WgtViewEditDropdown(
                    width: width,
                    readOnly:
                        !(isEditableByAcl && (field['editable'] ?? false)),
                    hasFocus: _currentField == field['col_key'],
                    showLabel: true,
                    labelWidth: labelWidth,
                    dropdownValueListMap: field['value_list'],
                    originalValueMap: field['value'] ?? field['val'],
                    hint: 'NOT SET', //field['label'] ?? field['title'],
                    labelText: field['label'] ?? field['title'],
                    onFocus: (hasFocus) {
                      setState(() {
                        _currentField = field['col_key'];
                      });
                    },
                    onSetValue: (newValue) async {
                      String value;
                      if (newValue is Map) {
                        value = newValue['value'] ?? newValue['val'];
                      } else {
                        value = newValue;
                      }
                      List<Map<String, dynamic>> result = await _updateProfile(
                        field['col_key'],
                        value,
                      );
                      Map<String, dynamic> resultMap = result[0];
                      if (resultMap['error'] == null) {
                        setState(() {
                          field['value'] = newValue;
                          field['val'] = newValue;
                          _fieldUpdated = true;
                          widget.onUpdate?.call();
                        });
                      }
                      return resultMap;
                    },
                  )
                : Container(),
      );
      // fields.add(verticalSpaceSmall);
    }
    return fields;
  }

  Widget getUserPasswordReset() {
    if ((widget.itemKind != PagItemKind.user) || (_loggedInUser == null)) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: WgtOpResetPassword(
        appConfig: widget.appConfig,
        loggedInUser: _loggedInUser!,
        targetUserIndexStr: widget.itemIndexStr,
        targetUsername: widget.itemInfoMap?['username'] ?? '',
        targetUserAuthProvider: widget.itemInfoMap?['auth_provider'] ?? '',
        // height: 200,
        onPasswordReset: () {
          // setState(() {
          //   _fieldUpdated = true;
          //   widget.onUpdate?.call();
          // });
        },
      ),
    );
  }

  Widget getUserRoleSetter() {
    if ((widget.itemKind != PagItemKind.user) || (_loggedInUser == null)) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: WgtUesrRoleSetter(
        appConfig: widget.appConfig,
        loggedInUser: _loggedInUser!,
        userIndexStr: widget.itemIndexStr,
        height: 350,
        onUserRoleListLoaded: (List<Map<String, dynamic>> userRoleList) {
          if (userRoleList.isEmpty) {
            return;
          }
          _updateIsTenantUser(userRoleList);
          // for (Map<String, dynamic> roleInfo in userRoleList) {
          //   if (roleInfo['portal_type'] == 'ems-tp') {
          //     setState(() {
          //       _isTenantUser = true;
          //     });
          //     break;
          //   }
          // }
        },
        onUserRoleListSet: (List<Map<String, dynamic>> userRoleList) {
          _updateIsTenantUser(userRoleList);
          setState(() {
            _fieldUpdated = true;
            widget.onUpdate?.call();
          });
        },
      ),
    );
  }

  Widget getItemScopeSetter() {
    if ((widget.itemScopeMap ?? {}).isEmpty) {
      return Container();
    }
    if (widget.itemKind == PagItemKind.jobType ||
        widget.itemKind == PagItemKind.user ||
        widget.itemKind == PagItemKind.role ||
        widget.itemKind == PagItemKind.finance) {
      return Container();
    }

    bool isSingleLabel = false;
    bool isEditableByKind = true;
    bool isEditableByMapping = true;
    // String leafScopeLabel = '';
    MdlPagScope? initialScope;
    if (widget.itemKind == PagItemKind.tariffPackage ||
        /*widget.itemKind == PagItemKind.meterGroup ||*/
        widget.itemKind == PagItemKind.landlord) {
      isSingleLabel = true;
      isEditableByKind = false;

      initialScope = MdlPagScope.fromJson(
        widget.itemScopeMap!,
      );
      // leafScopeLabel = scope.getLeafScopeLabel();
    }

    // if tenant_id for meter group is not null (meter group is assigned to a tenant),
    // disable scope edit
    if (widget.itemKind == PagItemKind.meterGroup &&
        (widget.itemInfoMap?['tenant_id'] != null)) {
      isEditableByMapping = false;
    }

    bool isFlexiScope = false;
    if (widget.itemKind == PagItemKind.scope ||
        widget.itemKind == PagItemKind.meterGroup ||
        widget.itemKind == PagItemKind.tariffPackage) {
      isFlexiScope = true;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: WgtScopeSetter(
        appConfig: widget.appConfig,
        isEditable: isEditableByKind && isEditableByAcl && isEditableByMapping,
        isSingleLabel: isSingleLabel,
        // singleScopeLabel: leafScopeLabel,
        initialScope: initialScope,
        width: width,
        labelWidth: 130,
        itemScopeMap: widget.itemScopeMap!,
        forItemKind: widget.itemKind,
        isFlexiScope: isFlexiScope,
        forScopeType: widget.itemType is PagScopeType ? widget.itemType : null,
        onScopeSet: (dynamic profile) async {
          if (profile == null) {
            if (kDebugMode) {
              print('Profile is null');
            }
            return {};
          }
          String scopeIdColName = '';
          if (profile is MdlPagSiteGroupProfile) {
            scopeIdColName = 'site_group_id';
            widget.onScopeTreeUpdate?.call();
          } else if (profile is MdlPagSiteProfile) {
            scopeIdColName = 'site_id';
            widget.onScopeTreeUpdate?.call();
          } else if (profile is MdlPagBuildingProfile) {
            scopeIdColName = 'building_id';
            widget.onScopeTreeUpdate?.call();
          } else if (profile is MdlPagLocationGroupProfile) {
            scopeIdColName = 'location_group_id';
            widget.onScopeTreeUpdate?.call();
          } else if (profile is MdlPagLocation) {
            scopeIdColName = 'location_id';
          }

          if (scopeIdColName.isEmpty) {
            if (kDebugMode) {
              print('Invalid profile type');
            }
            return {};
          }
          List<Map<String, dynamic>> result = await _updateProfile(
            isFlexiScope ? 'scope_id' : scopeIdColName,
            profile.id.toString(),
            scopeProfileIdColName: scopeIdColName,
          );
          Map<String, dynamic> resultMap = result[0];
          if (resultMap['error'] == null) {
            setState(() {
              _fieldUpdated = true;
              widget.onUpdate?.call();
            });
          }
          return resultMap;
        },
      ),
    );
  }

  Widget getItemGroupTree() {
    PagItemGroupType? itemGroupType;
    Map<String, dynamic> queryMap = {};
    String rootName = '';
    String rootLabel = '';

    String? addButtonLabelSuffix;

    switch (widget.itemKind) {
      case PagItemKind.user:
        if (!_isTenantUser) {
          return Container();
        }

        itemGroupType = PagItemGroupType.userTenant;

        String userId = widget.itemIndexStr;
        String userName = widget.fields
            .firstWhere((element) => element['col_key'] == 'username')['value'];

        queryMap = {'user_id': userId, 'username': userName};
        rootName = userName;
        rootLabel = userName;
        addButtonLabelSuffix = 'tenant';
        break;
      case PagItemKind.tenant:
        itemGroupType = PagItemGroupType.tenantUser;

        String tenantId = widget.itemIndexStr;
        String tenantName = widget.fields
            .firstWhere((element) => element['col_key'] == 'name')['value'];

        queryMap = {'tenant_id': tenantId, 'tenantName': tenantName};
        rootName = tenantName;
        rootLabel = tenantName;
        addButtonLabelSuffix = 'user';
        break;
      case PagItemKind.jobType:
        itemGroupType = PagItemGroupType.jobTypeSub;
        queryMap = {'job_type_id': widget.itemIndexStr};
        rootName = widget.itemDisplayName;
        rootLabel = widget.itemDisplayName;
        addButtonLabelSuffix = 'sub';
        break;
      case PagItemKind.tariffPackage:
        itemGroupType = PagItemGroupType.tariffPackageTariffRate;
        queryMap = {'tariff_package_id': widget.itemIndexStr};
        rootName = widget.itemDisplayName;
        rootLabel = widget.itemDisplayName;
        addButtonLabelSuffix = 'tariff rate';
        break;
      default:
        break;
    }

    if (itemGroupType == null) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 200,
          maxHeight: 395,
          // maxWidth: _width,
        ),
        child: WgtItemGroupTree(
          appConfig: widget.appConfig,
          mode: 'edit',
          width: width,
          loggedInUser: _loggedInUser!,
          groupItemId: widget.itemIndexStr,
          itemGroupType: itemGroupType,
          queryMap: queryMap,
          rootName: rootName,
          rootLabel: rootLabel,
          initalValueMap: widget.itemInfoMap,
          addButtonLabelSuffix: addButtonLabelSuffix,
          // newItemWidget: getNewSubWidget(),
          validateTreeChildren: (List<Map<String, dynamic>> childreanList) {
            if (widget.itemKind != PagItemKind.tariffPackage) {
              return 'valid';
            }
            int tpComingMonthCount = 6;
            PagTariffPackageTypeCat? tpTypeCat =
                widget.customProperties?['tpTypeCat'];
            assert(tpTypeCat != null);

            String validatedResult = widget.validateTreeChildren?.call() ??
                validateTpRateList(
                  isEdit: true,
                  tpTypeCat: tpTypeCat!,
                  rateList: childreanList,
                  tpComingMonthCount: tpComingMonthCount,
                  timezone: _loggedInUser!.selectedScope.getProjectTimezone(),
                );

            if (validatedResult != 'valid') {
              if (kDebugMode) {
                print('Invalid list');
              }
              return validatedResult;
            }
            return 'valid';
          },
        ),
      ),
    );
  }

  Widget getLcStatusOp(Map<String, dynamic> field) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: WgtPagPaymentLcStatusOp(
        key: _lcStatusOpsKey,
        appConfig: widget.appConfig,
        loggedInUser: _loggedInUser,
        enableEdit: false,
        paymentInfo: field,
        initialStatus: _lcStatusDisplay,
        onCommitted: (newStatus) {
          setState(() {
            _lcStatusOpsKey = UniqueKey();
            // _bill['lc_status'] = newStatus.value;
            field['lc_status'] = newStatus.value;

            _lcStatusDisplay = newStatus;
          });
          dev.log('on committed: $newStatus');
          widget.onUpdate?.call();
        },
      ),
    );
  }
}
