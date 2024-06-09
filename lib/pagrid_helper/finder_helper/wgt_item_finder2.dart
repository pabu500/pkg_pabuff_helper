import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../app_helper/pagrid_app_config.dart';

class WgtItemFinder2 extends StatefulWidget {
  const WgtItemFinder2({
    super.key,
    required this.scopeProfile,
    required this.loggedInUser,
    required this.appConfig,
    required this.itemType,
    this.sectionName = '',
    this.panelName = '',
    this.panelTitle = '',
    this.width,
    this.onModified,
    this.onSearching,
    required this.onResult,
    this.onClearSearch,
    this.identifySingleItem = false,
    this.getCountOnly = false,
    this.idConstraintKey = 'name',
    this.showTimeRangePicker = false,
    this.timeRangePicker,
    // required this.defaultMaxNumberOfRecords,
    this.itemNameText = 'Item Name',
    this.itemLabelText = 'Item Label',
    this.fixedItemName,
    this.fixedItemLabel,
    // this.itemTypeList = const [],
    this.getAdditionalPropWidget,
    this.additionalPropQueryMap = const {},
    this.additionalTypeQueryMap = const {},
    this.additionalTypeQueryMap2 = const {},
    this.getAdditionalTypeWidget,
    this.getAdditionalTypeWidget2,
    this.initialType,
    this.initialNoR,
    this.iniShowPanel,
    this.onShowPanel,
    this.showProjectScopeSelector = true,
    this.showSiteScopeSelector = true,
    this.sidePadding = EdgeInsets.zero,
  });

  final ScopeProfile scopeProfile;
  final Evs2User loggedInUser;
  final PaGridAppConfig appConfig;
  final ItemType itemType;
  final String sectionName;
  final String panelName;
  final String panelTitle;
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
  final String itemNameText;
  final String itemLabelText;
  final String? fixedItemName;
  final String? fixedItemLabel;
  // final List<String> itemTypeList;
  final Widget Function(Function, Function)? getAdditionalPropWidget;
  final Map<String, dynamic> additionalPropQueryMap;
  final Widget Function(Function, Function)? getAdditionalTypeWidget;
  final Widget Function(Function, Function)? getAdditionalTypeWidget2;
  final Map<String, dynamic> additionalTypeQueryMap;
  final Map<String, dynamic> additionalTypeQueryMap2;
  final String? initialType;
  final int? initialNoR;
  final bool? iniShowPanel;
  final Function? onShowPanel;
  final bool showProjectScopeSelector;
  final bool showSiteScopeSelector;
  final EdgeInsets sidePadding;

  @override
  _WgtItemFinder2State createState() => _WgtItemFinder2State();
}

class _WgtItemFinder2State extends State<WgtItemFinder2> {
  late DateTime _lastLoadingTime;
  DateTime? _lastRequestTime;
  String _errorText = '';

  List<ProjectScope> _projectScopes = [];
  List<SiteScope> _siteScopes = [];

  bool _showPanel = false;

  String? _itemLabel;
  UniqueKey? _resetKeyItemLabel;
  String? _itemName;
  UniqueKey? _resetKeyItemName;
  String? _locationTag;
  UniqueKey? _resetKeyLocationTag;

  String? _selectedItemType;

  final List<String> _infoTypes = [];
  List<Map<String, dynamic>> _items = [];

  final TextEditingController _numberOfRecordsController =
      TextEditingController();

  ProjectScope? _selectedProjectScope;
  SiteScope? _selectedSiteScope;

  final _defaultNorCap = 50;
  final _rowsPerPage = [20, 50, 100];
  int _selectedRowsPerPage = 20;
  int _currentPage = 1;
  final _norCap = 300;
  late TextStyle _dropDownListTextStyle;
  late TextStyle _dropDownListHintStyle;
  late Widget _dropDownUnderline;

  late bool _enableSearch;
  bool _isSearching = false;

  void _getProjectSites() {
    List<SiteScope> projectSites =
        getProjectSites(_selectedProjectScope, scopeProfiles);
    setState(() {
      _siteScopes = projectSites;
    });
  }

  final Map<String, dynamic> _additionalPropQueryMap = {};
  final Map<String, dynamic> _additionalTypeQueryMap = {};
  final Map<String, dynamic> _additionalTypeQueryMap2 = {};

  Future<dynamic> _getItemList({
    Map<String, dynamic>? additionalPropQueryMap,
    Map<String, dynamic>? additionalTypeQueryMap,
    Map<String, dynamic>? additionalTypeQueryMap2,
  }) async {
    setState(() {
      _isSearching = true;
      _errorText = '';
    });
    widget.onSearching?.call();

    Map<String, dynamic> result = {};

    if (additionalPropQueryMap != null) {
      _additionalPropQueryMap.clear();
      for (var entry in additionalPropQueryMap.entries) {
        _additionalPropQueryMap[entry.key] = entry.value ?? '';
      }
    } else {
      for (var entry in (widget.additionalPropQueryMap).entries) {
        _additionalPropQueryMap[entry.key] = entry.value ?? '';
      }
    }
    if (additionalTypeQueryMap != null) {
      _additionalTypeQueryMap.clear();
      for (var entry in additionalTypeQueryMap.entries) {
        _additionalTypeQueryMap[entry.key] = entry.value ?? '';
      }
    }
    // else {
    //   for (var entry in (widget.additionalTypeQueryMap).entries) {
    //     _additionalTypeQueryMap[entry.key] = entry.value ?? '';
    //   }
    //   for (var entry in (widget.additionalTypeQueryMap2).entries) {
    //     _additionalTypeQueryMap2[entry.key] = entry.value ?? '';
    //   }
    // }
    if (additionalTypeQueryMap2 != null) {
      _additionalTypeQueryMap2.clear();
      for (var entry in additionalTypeQueryMap2.entries) {
        _additionalTypeQueryMap2[entry.key] = entry.value ?? '';
      }
    }

    Map<String, dynamic> queryMap = {
      'project_scope':
          _selectedProjectScope == null ? '' : _selectedProjectScope!.name,
      'site_scope': _selectedSiteScope == null ? '' : _selectedSiteScope!.name,
      'item_type': widget.itemType.name,
      'info_types': _infoTypes.join(','),
      'label': (_itemLabel ?? '').trim(),
      'name': (_itemName ?? '').trim(),
      'location_tag': (_locationTag ?? '').trim(),
      'item_sub_type': _selectedItemType ?? '',
      'max_rows_per_page': '$_selectedRowsPerPage',
      'current_page': '$_currentPage',
      'sort_by': '',
      'sort_order': 'desc',
      'get_count_only': widget.getCountOnly ? 'true' : 'false',
      'id_constraint_key': widget.idConstraintKey,
      ..._additionalPropQueryMap,
      ..._additionalTypeQueryMap,
      ..._additionalTypeQueryMap2,
    };

    AclTarget aclTarget = getAclTargetFromItemType(widget.itemType);

    try {
      result = await doListItems(
        widget.appConfig,
        queryMap,
        SvcClaim(
          username: widget.loggedInUser.username,
          scope: widget.loggedInUser.isAdminAndUp()
              ? AclScope.global.name
              : widget.scopeProfile.getEffectiveScopeStr(),
          target: getAclTargetStr(aclTarget),
          operation: AclOperation.list.name,
        ),
      );

      return result;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      widget.onResult({'error': 'Error getting item list'});
    } finally {
      setState(() {
        // _isItemListLoading = false;
        _isSearching = false;
        // if (widget.onSearching != null) widget.onSearching!();
      });
    }
  }

  bool _enableSearchButton() {
    if (widget.identifySingleItem) {
      return (_itemLabel ?? '').isNotEmpty || (_itemName ?? '').isNotEmpty;
    }
    return _selectedProjectScope != null ||
        _selectedSiteScope != null ||
        // _tenantLabelController.text.trim().isNotEmpty ||
        // _tenantNameController.text.trim().isNotEmpty ||
        _selectedItemType != null ||
        (_itemLabel != null && _itemLabel!.isNotEmpty) ||
        (_itemName != null && _itemName!.isNotEmpty);
  }

  void _clearSearch(bool setState) {
    _itemLabel = null;
    _resetKeyItemLabel = UniqueKey();
    _itemName = null;
    _resetKeyItemName = UniqueKey();

    if (widget.fixedItemName != null) {
      _itemName = widget.fixedItemName;
    }
    if (widget.fixedItemLabel != null) {
      _itemLabel = widget.fixedItemLabel;
    }

    _numberOfRecordsController.clear();

    _selectedProjectScope = null;
    _selectedSiteScope = null;

    _itemLabel = null;
    _itemName = null;
    _selectedItemType = null;

    _currentPage = 1;

    _additionalPropQueryMap.clear();
    _additionalTypeQueryMap.clear();

    if (setState) {
      widget.onClearSearch?.call();
      widget.onModified?.call();
    }
  }

  void _iniScopesPreload() {
    if (widget.loggedInUser.projectScopes == null) {
      if (kDebugMode) {
        print('itemFilder: projectScopes is null');
      }
    } else {
      _projectScopes = widget.loggedInUser.projectScopes!;
    }
    if (widget.loggedInUser.siteScopes == null) {
      if (kDebugMode) {
        print('itemFilder: siteScopes is null');
      }
    } else {
      _siteScopes = widget.loggedInUser.siteScopes!;
    }
    if (_projectScopes.length == 1) {
      _selectedProjectScope = _projectScopes[0];
    }
    if (_siteScopes.length == 1) {
      _selectedSiteScope = _siteScopes[0];
    }

    if (widget.fixedItemName != null) {
      _itemName = widget.fixedItemName;
    }
    if (widget.fixedItemLabel != null) {
      _itemLabel = widget.fixedItemLabel;
    }

    // for (var entry in (widget.additionalPropQueryMap).entries) {
    //   _additionalPropQueryMap[entry.key] = entry.value ?? '';
    // }
    // for (var entry in (widget.additionalTypeQueryMap).entries) {
    //   _additionalTypeQueryMap[entry.key] = entry.value ?? '';
    // }
  }

  @override
  void initState() {
    super.initState();

    //remove NONE and ALL
    _projectScopes = evs2Projects
        .where((element) =>
            element != ProjectScope.NONE && element != ProjectScope.SG_ALL)
        .toList();

    _siteScopes = widget.scopeProfile.projectSites;

    _selectedRowsPerPage = widget.initialNoR ?? _defaultNorCap;
    //if the initialNoR is not in the list, add it then sort it
    if (!_rowsPerPage.contains(_selectedRowsPerPage)) {
      _rowsPerPage.add(_selectedRowsPerPage);
      _rowsPerPage.sort();
    }

    _iniScopesPreload();

    _enableSearch = _enableSearchButton();

    if (widget.iniShowPanel != null) {
      _showPanel = widget.iniShowPanel!;
    } else {
      dynamic showPanel =
          readFromSharedPref('${widget.sectionName}_${widget.panelName}_viz');
      if (showPanel != null && showPanel is bool) {
        _showPanel = showPanel;
      } else {
        _showPanel = true;
      }
    }

    _lastLoadingTime = DateTime.now();
  }

  @override
  void dispose() {
    // _tenantLabelController.dispose();
    // _tenantNameController.dispose();
    _numberOfRecordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _dropDownListTextStyle =
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
    _dropDownListHintStyle =
        TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
    _dropDownUnderline = Container(
        height: 1, color: Theme.of(context).hintColor.withOpacity(0.3));
    double width = widget.width ?? MediaQuery.of(context).size.width;

    bool prePop = false;

    String result;
    return prePop ? Container() : completedWidget(width);
  }

  Widget completedWidget(double width) {
    return width > 800
        ? Padding(
            padding: widget.sidePadding,
            child: getItemPickerWide(width),
          )
        : getItemPickerNarrow();
  }

  Widget getItemPickerNarrow() {
    return _showPanel
        ? Container(
            width: widget.width,
            padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 5),
            decoration: BoxDecoration(
              // color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: Theme.of(context).hintColor /*.withOpacity(0.3)*/,
                  width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getItemPropertySelector(330),
                verticalSpaceTiny,
                getScopeSelector(),
                if (widget.timeRangePicker != null) verticalSpaceTiny,
                if (widget.timeRangePicker != null)
                  Row(children: [widget.timeRangePicker!]),
                verticalSpaceSmall,
                getControls(),
              ],
            ),
          )
        : getCollapsedBar(
            context: context,
            saveToSharedPref: saveToSharedPref,
            color: Theme.of(context).colorScheme.primary,
            width: widget.width,
            height: 38,
            sectionName: widget.sectionName,
            panelTitle: widget.panelTitle,
            panelName: widget.panelName,
            onTap: () {
              setState(() {
                // _onViz = true;
                _showPanel = true;
                widget.onShowPanel?.call(true);
              });
            },
          );
  }

  Widget getItemPickerWide(double width) {
    return _showPanel
        ? Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
            decoration: BoxDecoration(
              // color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                  color: Theme.of(context).hintColor /*.withOpacity(0.3)*/,
                  width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                getClearButton(),
                horizontalSpaceTiny,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            getItemPropertySelector(280),
                            verticalSpaceSmall,
                            getScopeSelector(),
                          ],
                        ),
                        horizontalSpaceMedium,
                        getItemAdditionalProp(),
                      ],
                    ),
                    if (widget.timeRangePicker != null) verticalSpaceSmall,
                    widget.timeRangePicker ?? Container(),
                  ],
                ),
                getCollapseButton(),
                horizontalSpaceTiny,
                getRowsPerPage(),
                horizontalSpaceSmall,
                getSearchButton(),
              ],
            ),
          )
        : getCollapsedBar(
            context: context,
            saveToSharedPref: saveToSharedPref,
            color: Theme.of(context).colorScheme.primary,
            width: widget.width,
            height: 38,
            sectionName: widget.sectionName,
            panelTitle: widget.panelTitle,
            panelName: widget.panelName,
            onTap: () {
              setState(() {
                // _onViz = true;
                _showPanel = true;
                widget.onShowPanel?.call(true);
              });
            },
          );
  }

  //serial number, display name, conc,
  Widget getItemPropertySelector(double width) {
    double height = 60;
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: width,
          // height: height,
          child: WgtFinderFieldInput(
            appConfig: widget.appConfig,
            width: 220,
            labelText: widget.itemLabelText,
            hintText: widget.itemLabelText,
            initialValue: widget.fixedItemLabel ?? _itemLabel,
            isInitialValueMutable: widget.fixedItemLabel == null,
            resetKey: _resetKeyItemLabel,
            onChanged: (value) {
              _itemLabel = value;
              if (value.isNotEmpty && !_enableSearch) {
                setState(() {
                  _enableSearch = _enableSearchButton();
                });
              }
            },
            onEditingComplete: () async {
              widget.onModified?.call();

              if (_itemLabel == null) {
                return null;
              }
              if (_itemLabel!.trim().isEmpty) {
                return null;
              }
              Map<String, dynamic> itemFindResult = await _getItemList();

              widget.onResult({'itemFindResult': itemFindResult});
            },
            onClear: () {
              _itemLabel = null;
              widget.onModified?.call();
            },
            onModified: widget.onModified,
            onUpdateEnableSearchButton: _enableSearchButton,
          ),
        ),
        SizedBox(
          width: width,
          // height: height,
          child: WgtFinderFieldInput(
            appConfig: widget.appConfig,
            width: 220,
            labelText: widget.itemNameText,
            hintText: widget.itemNameText,
            initialValue: widget.fixedItemName ?? _itemName,
            isInitialValueMutable: widget.fixedItemName == null,
            resetKey: _resetKeyItemName,
            onChanged: (value) {
              _itemName = value;
              if (value.isNotEmpty && !_enableSearch) {
                setState(() {
                  _enableSearch = _enableSearchButton();
                });
              }
            },
            onEditingComplete: () async {
              widget.onModified?.call();
              if (_itemName == null) {
                return null;
              }
              if (_itemName!.trim().isEmpty) {
                return null;
              }
              Map<String, dynamic> itemFindResult = await _getItemList();
              widget.onResult({'itemFindResult': itemFindResult});
            },
            onClear: () {
              _itemName = null;
              widget.onModified?.call();
            },
            onModified: widget.onModified,
            onUpdateEnableSearchButton: _enableSearchButton,
          ),
        ),
      ],
    );
  }

  Widget getItemAdditionalProp() {
    return widget.getAdditionalPropWidget?.call(
          _getItemList,
          (value) {
            if ((value ?? '').isNotEmpty && !_enableSearch) {
              setState(() {
                _enableSearch = _enableSearchButton();
              });
            }
          },
        ) ??
        Container();
  }

  Widget getFiledInput(double width, String fieldKey, String labelText,
      String hintText, String? initialValue, UniqueKey? resetKey,
      {required String? Function(String?) validator,
      required void Function(String?) onChanged,
      required String? Function() onEditingComplete,
      required void Function() onClear}) {
    double height = 60;
    return Column(
      children: [
        SizedBox(
          width: width,
          // height: height,
          child: xtTextField2(
              appConfig: widget.appConfig,
              labelText: labelText,
              hintText: hintText,
              initialValue: initialValue,
              resetKey: resetKey,
              // validator: validator,
              onChanged: (value) {
                onChanged(value);
                if (value.isNotEmpty && !_enableSearch) {
                  setState(() {
                    _enableSearch = _enableSearchButton();
                  });
                }
              },
              onEditingComplete: () async {
                if (widget.onModified != null) {
                  widget.onModified!();
                }

                String? result = onEditingComplete();
                if (result == null) {
                  return;
                }

                Map<String, dynamic> itemFindResult = await _getItemList();

                widget.onResult({'itemFindResult': itemFindResult});
              },
              onClear: () {
                onClear();

                if (widget.onModified != null) {
                  widget.onModified!();
                }
              }),
        ),
      ],
    );
  }

  Widget getScopeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (widget.showProjectScopeSelector)
          SizedBox(
            width: 105,
            child: DropdownButton<ProjectScope>(
                alignment: AlignmentDirectional.centerStart,
                hint: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text('Project', style: _dropDownListHintStyle)),
                // padding: const EdgeInsets.only(bottom: 0.0),
                value: _selectedProjectScope,
                // isDense: true,
                // itemHeight: 55,
                focusColor: Theme.of(context).hoverColor,
                underline: _dropDownUnderline,
                icon: const Icon(Icons.arrow_drop_down),
                iconSize: 21,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                onChanged: (ProjectScope? value) async {
                  if (value != null) {
                    if (value == _selectedProjectScope) {
                      return;
                    }
                  }
                  setState(() {
                    _selectedProjectScope = value!;
                    if (_projectScopes.length > 1) {
                      _selectedSiteScope = null;
                    }
                    _enableSearch = _enableSearchButton();
                  });
                  if (widget.onModified != null) {
                    widget.onModified!();
                  }
                  _getProjectSites();
                },
                items: _projectScopes
                    .map<DropdownMenuItem<ProjectScope>>((ProjectScope value) {
                  return DropdownMenuItem<ProjectScope>(
                    value: value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 3.0),
                      child: Text(
                        getProjectDisplayString(value),
                        style: _dropDownListTextStyle,
                      ),
                    ),
                  );
                }).toList()),
          ),
        if (widget.showSiteScopeSelector)
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: DropdownButton<SiteScope>(
                // alignment: AlignmentDirectional.centerEnd,
                hint: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text('Site ', style: _dropDownListHintStyle)),
                // padding: const EdgeInsets.only(bottom: 0.0),
                value: _selectedSiteScope,
                // isDense: true,
                // itemHeight: 55,
                focusColor: Theme.of(context).hoverColor,
                underline: _dropDownUnderline,
                // dropdownColor: Theme.of(context).colorScheme.background,
                icon: const Icon(Icons.arrow_drop_down),
                iconSize: 21,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                onChanged: (SiteScope? value) async {
                  if (value != null) {
                    if (value == _selectedSiteScope) {
                      return;
                    }
                  }
                  setState(() {
                    _selectedSiteScope = value!;
                  });
                  if (widget.onModified != null) {
                    widget.onModified!();
                  }
                },
                items: _siteScopes
                    .map<DropdownMenuItem<SiteScope>>((SiteScope value) {
                  return DropdownMenuItem<SiteScope>(
                    value: value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 3.0),
                      child: Text(
                        value.name,
                        style: _dropDownListTextStyle,
                      ),
                    ),
                  );
                }).toList()),
          ),
        if (widget.showProjectScopeSelector || widget.showSiteScopeSelector)
          horizontalSpaceTiny,
        widget.getAdditionalTypeWidget?.call(
              (additionalTypeQueryMap) {
                if ((additionalTypeQueryMap ?? {}).isEmpty) {
                  return;
                }
                setState(() {
                  for (var entry in (additionalTypeQueryMap ?? {}).entries) {
                    _additionalTypeQueryMap[entry.key] = entry.value ?? '';
                  }
                  _enableSearch = _enableSearchButton();
                });
                if (widget.onModified != null) {
                  widget.onModified!();
                }
              },
              (value) {
                if ((value ?? '').isNotEmpty && !_enableSearch) {
                  setState(() {
                    _enableSearch = _enableSearchButton();
                  });
                }
              },
            ) ??
            Container(),
        horizontalSpaceTiny,
        widget.getAdditionalTypeWidget2?.call(
              (additionalTypeQueryMap) {
                if ((additionalTypeQueryMap ?? {}).isEmpty) {
                  return;
                }
                setState(() {
                  for (var entry in (additionalTypeQueryMap ?? {}).entries) {
                    _additionalTypeQueryMap[entry.key] = entry.value ?? '';
                  }
                  _enableSearch = _enableSearchButton();
                });
                if (widget.onModified != null) {
                  widget.onModified!();
                }
              },
              (value) {
                if ((value ?? '').isNotEmpty && !_enableSearch) {
                  setState(() {
                    _enableSearch = _enableSearchButton();
                  });
                }
              },
            ) ??
            Container(),
      ],
    );
  }

  Widget getControls() {
    return Row(
      children: [
        getClearButton(),
        horizontalSpaceTiny,
        Expanded(child: Container()),
        horizontalSpaceTiny,
        getRowsPerPage(),
        horizontalSpaceRegular,
        _isSearching
            ? xtWait(
                color: Theme.of(context).colorScheme.primary,
              )
            : getSearchButton(),
      ],
    );
  }

  Widget getRowsPerPage() {
    return widget.identifySingleItem || widget.getCountOnly
        ? Container()
        : Tooltip(
            message: 'Records per page',
            child: DropdownButton<int>(
              // alignment: AlignmentDirectional.centerEnd,
              // hint: Text('Rows per page'),
              // padding: const EdgeInsets.only(bottom: 0.0),
              // isDense: true,
              // itemHeight: 21,
              value: _selectedRowsPerPage,
              focusColor: Theme.of(context).hoverColor,
              underline: _dropDownUnderline,
              // dropdownColor: Theme.of(context).colorScheme.background,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).hintColor),
              onChanged: (int? value) {
                setState(() {
                  _selectedRowsPerPage = value!;
                });
              },
              items: _rowsPerPage.map<DropdownMenuItem<int>>((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child:
                        Text(value.toString(), style: _dropDownListTextStyle),
                  ),
                );
              }).toList(),
            ),
          );
  }

  Widget getClearButton() {
    return IconButton(
      iconSize: 25,
      tooltip: 'Clear search',
      icon: Icon(Icons.restart_alt, color: Theme.of(context).colorScheme.error),
      onPressed: () {
        _clearSearch(true);
        _iniScopesPreload();
      },
    );
  }

  Widget getSearchButton() {
    return IconButton(
      iconSize: 25,
      tooltip: 'Search',
      icon: Icon(Icons.search,
          color: _enableSearch
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).hintColor.withOpacity(0.3)),
      onPressed: _enableSearch
          ? () async {
              Map<String, dynamic> itemFindResult = await _getItemList();

              widget.onResult({'itemFindResult': itemFindResult});
            }
          : null,
    );
  }

  Widget getCollapseButton() {
    return IconButton(
      iconSize: 25,
      // tooltip: 'Hide search panel',
      icon: Icon(Symbols.expand_circle_up,
          color: Theme.of(context).colorScheme.primary),
      onPressed: () {
        setState(() {
          _showPanel = false;
          widget.onShowPanel?.call(false);
        });
      },
    );
  }
}
