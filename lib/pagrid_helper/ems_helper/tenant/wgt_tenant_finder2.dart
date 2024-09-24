import 'package:buff_helper/pagrid_helper/pagrid_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/up_helper/helper/tenant_def.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

class WgtTenantFinder2 extends StatefulWidget {
  const WgtTenantFinder2({
    super.key,
    required this.scopeProfile,
    required this.loggedInUser,
    required this.appConfig,
    this.sectionName = '',
    this.width,
    this.onModified,
    this.onSearching,
    required this.onResult,
    this.onClearSearch,
    this.identifySingleItem = false,
    this.getCountOnly = false,
    this.idConstraintKey = 'tenant_name',
    this.showTimeRangePicker = false,
    this.timeRangePicker,
    this.initialNoR,
    this.initialType,
    this.iniShowPanel = true,
    this.onShowPanel,
    this.sidePadding = EdgeInsets.zero,
    this.tenantName,
    this.tenantLabel,
  });
  // final bool showMeterSn;

  final PaGridAppConfig appConfig;
  final ScopeProfile scopeProfile;
  final Evs2User loggedInUser;
  final String sectionName;
  final void Function()? onModified;
  final void Function()? onSearching;
  final void Function(Map<String, dynamic> itemFindResult) onResult;
  final void Function()? onClearSearch;
  final double? width;
  final bool identifySingleItem;
  final bool getCountOnly;
  final String idConstraintKey;
  final bool showTimeRangePicker;
  final Widget? timeRangePicker;
  final int? initialNoR;
  final String? initialType;
  final bool iniShowPanel;
  final Function? onShowPanel;
  final EdgeInsets sidePadding;
  final String? tenantName;
  final String? tenantLabel;

  @override
  State<WgtTenantFinder2> createState() => _WgtTenantFinder2State();
}

class _WgtTenantFinder2State extends State<WgtTenantFinder2> {
  final String panelName = 'tenant_finder';
  final String panelTitle = 'Tenant Finder';

  String? _locationTag;
  UniqueKey? _resetKeyLocationTag;
  String? _locationTag2;
  UniqueKey? _resetKeyLocationTag2;
  String? _sapWbs;
  UniqueKey? _resetKeySapWbs;
  String? _altName;
  UniqueKey? _resetKeyAltName;
  String? _selectedTenantType;

  late final List<String> _tenantTypeList = [];

  Map<String, dynamic> _additionalPropQueryMap = {};
  Map<String, dynamic> _additionalTypeQueryMap = {};

  late TextStyle dropDownListTextStyle;
  late TextStyle dropDownListHintStyle;
  late Widget dropDownUnderline;

  final List<Map<String, dynamic>> _tenantInfoList = [];
  final List<String> _tenantLabelFullList = [];
  final List<String> _tenantLabelTypeList = [];

  int _pullFails = 0;
  bool _loadingTenantInfoList = false;

  Future<dynamic> _getTenantInfoList() async {
    // List<Map<String, dynamic>> tenantInfoList = [];
    try {
      setState(() {
        _loadingTenantInfoList = true;
        _tenantInfoList.clear();
        _tenantLabelFullList.clear();
        _tenantLabelTypeList.clear();
      });
      List<Map<String, dynamic>> result = await doGetAllTenantList(
        widget.appConfig,
        {},
        SvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: widget.scopeProfile.getEffectiveScopeStr(),
          target: getAclTargetStr(AclTarget.tenant_p_info),
          operation: AclOperation.list.name,
        ),
      );
      if (result.isNotEmpty) {
        //drop all labels start with 'test'
        if (!widget.appConfig.includeTestItems) {
          result.removeWhere((element) => element['tenant_label']
              .toString()
              .toLowerCase()
              .startsWith('test'));
          result.removeWhere((element) => element['tenant_label']
              .toString()
              .toLowerCase()
              .contains('delete'));
        }
        _tenantInfoList.addAll(result);
        _tenantLabelFullList
            .addAll(result.map((e) => e['tenant_label'] as String));

        _tenantLabelTypeList.addAll(_tenantLabelFullList);
      }
      _pullFails = 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      _pullFails++;
    } finally {
      // if (kDebugMode) {
      //   print('tenantLabelList: $tenantLabelList');
      // }
      setState(() {
        _loadingTenantInfoList = false;
      });
    }
  }

  void _updateTenantLabelTypeList() {
    _tenantLabelTypeList.clear();
    if (_selectedTenantType == null) {
      _tenantLabelTypeList.addAll(_tenantLabelFullList);
    } else {
      for (Map<String, dynamic> tenantInfo in _tenantInfoList) {
        if (tenantInfo['type'] == _selectedTenantType) {
          _tenantLabelTypeList.add(tenantInfo['tenant_label']);
        }
      }
    }
  }

  void _updateAdditionalPropQueryMap() {
    _additionalPropQueryMap = {
      'location_tag': _locationTag,
      'location_tag2': _locationTag2,
      'sap_wbs': _sapWbs,
      'alt_name': _altName,
    };
  }

  void _updateAdditionalTypeQueryMap() {
    _additionalTypeQueryMap = {
      'tenant_type': _selectedTenantType ?? '',
    };
  }

  void _prePop() {
    _tenantTypeList.clear();
    if (widget.appConfig.activePortalProjectScope == ProjectScope.EMS_CW_NUS) {
      if (widget.loggedInUser.hasRoleStr(['Ops', '_CL'], matchAll: true)) {
        _tenantTypeList.addAll([
          TenantType.cw_nus_retail_dining.name,
        ]);
      } else {
        _tenantTypeList.addAll([
          '   ',
          TenantType.cw_nus_internal.name,
          TenantType.cw_nus_external.name,
          TenantType.cw_nus_retail_dining.name,
          TenantType.cw_nus_virtual.name,
        ]);
      }
      if (_tenantTypeList.length == 1) {
        _selectedTenantType = _tenantTypeList[0];
      } else {
        _selectedTenantType = null;
      }
    }
    _updateAdditionalPropQueryMap();
    _updateAdditionalTypeQueryMap();
  }

  void _reset() {
    _prePop();

    setState(() {
      // _itemLabel = null;
      // _resetKeyItemLabel = UniqueKey();
      _locationTag = null;
      _resetKeyLocationTag = UniqueKey();
      _locationTag2 = null;
      _resetKeyLocationTag2 = UniqueKey();
      _sapWbs = null;
      _resetKeySapWbs = UniqueKey();
      _altName = null;
      _resetKeyAltName = UniqueKey();
      // _selectedTenantType = null;
      // _additionalTypeQueryMap.clear();
      // _additionalPropQueryMap.clear();
    });
  }

  @override
  void initState() {
    super.initState();

    _tenantTypeList.clear();

    _prePop();

    _pullFails = 0;
  }

  @override
  Widget build(BuildContext context) {
    dropDownListTextStyle =
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
    dropDownListHintStyle =
        TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
    dropDownUnderline = Container(
        height: 1, color: Theme.of(context).hintColor.withOpacity(0.3));

    bool pullData = _tenantInfoList.isEmpty && !_loadingTenantInfoList;
    if (_pullFails >= 3) {
      if (kDebugMode) {
        print('billing release: pull fails more than $_pullFails times');
      }
      pullData = false;
      return SizedBox(
          height: 60,
          child: Center(
              child: getErrorTextPrompt(
                  context: context, errorText: 'Error getting data')));
    }
    return pullData
        ? FutureBuilder<void>(
            future: _getTenantInfoList(),
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return Center(
                      child: xtWait(
                    color: Theme.of(context).colorScheme.primary,
                  ));

                default:
                  if (snapshot.hasError) {
                    return Center(
                        child: getErrorTextPrompt(
                            context: context, errorText: 'Error getting data'));
                  } else {
                    return buildFinder();
                  }
              }
            },
          )
        : buildFinder();
  }

  Widget buildFinder() {
    return WgtItemFinder2(
      appConfig: widget.appConfig,
      loggedInUser: widget.loggedInUser,
      scopeProfile: widget.scopeProfile,
      showSiteScopeSelector: false,
      sectionName: widget.sectionName,
      useItemLabelDropdownSelector: true,
      itemLableList: _tenantLabelTypeList,
      panelTitle: panelTitle,
      panelName: panelName,
      sidePadding: widget.sidePadding,
      itemNameText: 'Identifier',
      fixedItemName: widget.tenantName,
      fixedItemLabel: widget.tenantLabel,
      itemType: ItemType.tenant,
      initialNoR: widget.initialNoR,
      iniShowPanel: widget.iniShowPanel,
      onShowPanel: widget.onShowPanel,
      identifySingleItem: widget.identifySingleItem,
      idConstraintKey: widget.idConstraintKey,
      getAdditionalPropWidget: getTenantAdditionalPropWidget,
      getAdditionalTypeWidget: getAdditionalTypeWidget,
      additionalPropQueryMap: _additionalPropQueryMap,
      additionalTypeQueryMap: _additionalTypeQueryMap,
      onResult: widget.onResult,
      onClearSearch: () {
        _reset();

        widget.onClearSearch?.call();
      },
      onModified: widget.onModified,
      onSearching: widget.onSearching,
      timeRangePicker: widget.timeRangePicker,
      showTimeRangePicker: widget.showTimeRangePicker,
    );
  }

  Widget getTenantAdditionalPropWidget(getItemList, updateEnableSearchButton) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WgtFinderFieldInput(
          appConfig: widget.appConfig,
          width: 220,
          labelText: 'Location',
          hintText: 'Location',
          initialValue: _locationTag,
          resetKey: _resetKeyLocationTag,
          onChanged: (value) {
            _locationTag = value;
            updateEnableSearchButton(value);
          },
          onEditingComplete: () async {
            widget.onModified?.call();
            // if (_locationTag == null) {
            //   return null;
            // }
            // if (_locationTag!.trim().isEmpty) {
            //   return null;
            // }

            // setState(() {
            //   _finderKey = UniqueKey();
            // });
            _additionalPropQueryMap['location_tag'] = _locationTag;

            Map<String, dynamic> itemFindResult = await getItemList(
              additionalPropQueryMap: _additionalPropQueryMap,
              additionalTypeQueryMap: _additionalTypeQueryMap,
            );
            widget.onResult({'itemFindResult': itemFindResult});
          },
          onClear: () {
            _locationTag = null;
            _updateAdditionalPropQueryMap();
            widget.onModified?.call();
          },
          onModified: widget.onModified,
          onUpdateEnableSearchButton: () {
            updateEnableSearchButton('');
          },
        ),
        WgtFinderFieldInput(
          appConfig: widget.appConfig,
          width: 220,
          labelText: 'Location 2',
          hintText: 'Location 2',
          initialValue: _locationTag2,
          resetKey: _resetKeyLocationTag2,
          onChanged: (value) {
            _locationTag2 = value;
            updateEnableSearchButton(value);
          },
          onEditingComplete: () async {
            widget.onModified?.call();
            // if (_locationTag == null) {
            //   return null;
            // }
            // if (_locationTag!.trim().isEmpty) {
            //   return null;
            // }

            // setState(() {
            //   _finderKey = UniqueKey();
            // });
            _additionalPropQueryMap['location_tag2'] = _locationTag2;

            Map<String, dynamic> itemFindResult = await getItemList(
              additionalPropQueryMap: _additionalPropQueryMap,
              additionalTypeQueryMap: _additionalTypeQueryMap,
            );
            widget.onResult({'itemFindResult': itemFindResult});
          },
          onClear: () {
            _locationTag2 = null;
            _updateAdditionalPropQueryMap();
            widget.onModified?.call();
          },
          onModified: widget.onModified,
          onUpdateEnableSearchButton: () {
            updateEnableSearchButton('');
          },
        ),
        WgtFinderFieldInput(
          appConfig: widget.appConfig,
          width: 220,
          labelText: 'WBS',
          hintText: 'WBS',
          initialValue: _sapWbs,
          resetKey: _resetKeySapWbs,
          onChanged: (value) {
            _sapWbs = value;
            updateEnableSearchButton(value);
          },
          onEditingComplete: () async {
            widget.onModified?.call();

            // if (_sapWbs == null) {
            //   return null;
            // }
            // if (_sapWbs!.trim().isEmpty) {
            //   return null;
            // }
            _additionalPropQueryMap['sap_wbs'] = _sapWbs;

            Map<String, dynamic> itemFindResult = await getItemList(
              additionalPropQueryMap: _additionalPropQueryMap,
              additionalTypeQueryMap: _additionalTypeQueryMap,
            );
            widget.onResult({'itemFindResult': itemFindResult});
          },
          onClear: () {
            _sapWbs = null;
            _updateAdditionalPropQueryMap();
            widget.onModified?.call();
          },
          onModified: widget.onModified,
          onUpdateEnableSearchButton: () {
            updateEnableSearchButton('');
          },
        ),
        WgtFinderFieldInput(
          appConfig: widget.appConfig,
          width: 220,
          labelText: 'Alt Name',
          hintText: 'Alt Name',
          initialValue: _altName,
          resetKey: _resetKeyAltName,
          onChanged: (value) {
            _altName = value;
            updateEnableSearchButton(value);
          },
          onEditingComplete: () async {
            widget.onModified?.call();

            // if (_sapWbs == null) {
            //   return null;
            // }
            // if (_sapWbs!.trim().isEmpty) {
            //   return null;
            // }
            _additionalPropQueryMap['alt_name'] = _altName;

            Map<String, dynamic> itemFindResult = await getItemList(
              additionalPropQueryMap: _additionalPropQueryMap,
              additionalTypeQueryMap: _additionalTypeQueryMap,
            );
            widget.onResult({'itemFindResult': itemFindResult});
          },
          onClear: () {
            _altName = null;
            _updateAdditionalPropQueryMap();
            widget.onModified?.call();
          },
          onModified: widget.onModified,
          onUpdateEnableSearchButton: () {
            updateEnableSearchButton('');
          },
        ),
      ],
    );
  }

  Widget getAdditionalTypeWidget(updateType, updateEnableSearchButton) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: DropdownButton<String>(
          alignment: AlignmentDirectional.centerEnd,
          hint: Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Text('Type', style: dropDownListHintStyle),
          ),
          value: _selectedTenantType,
          // isDense: true,
          // itemHeight: 21,
          focusColor: Theme.of(context).hoverColor,
          underline: dropDownUnderline,
          icon: const Icon(Icons.arrow_drop_down),
          iconSize: 21,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
          onChanged: (String? value) async {
            if (value != null) {
              if (value == _selectedTenantType) {
                return;
              }
            }
            setState(() {
              _selectedTenantType = value;
              // _finderKey = UniqueKey();
              _additionalTypeQueryMap['tenant_type'] =
                  _selectedTenantType ?? '';
              _updateTenantLabelTypeList();
              updateType(_additionalTypeQueryMap);
              updateEnableSearchButton(value);
            });
            if (widget.onModified != null) {
              widget.onModified!();
            }
          },
          items: _tenantTypeList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3.0),
                child: Text(getTenantTypeTag(getTenantType(value)),
                    style: dropDownListTextStyle),
              ),
            );
          }).toList()),
    );
  }
}
