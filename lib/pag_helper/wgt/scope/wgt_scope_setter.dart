import 'package:buff_helper/pag_helper/comm/comm_scope.dart';
import 'package:buff_helper/pag_helper/def_helper/pag_item_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_building_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_profile.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/mdl_pag_app_config.dart';
import '../wgt_input_dropdown.dart';

class WgtScopeSetter extends StatefulWidget {
  const WgtScopeSetter({
    super.key,
    required this.appConfig,
    this.width = 360,
    this.labelWidth = 150,
    this.itemScopeMap,
    this.forItemKind, // the kind of item that the scope is being set for
    this.forScopeType, // used when the scope setter is used for a scope type
    this.onScopeSet,
    this.showCommitted = true,
    this.isEditable = true,
    this.isSingleLabel = false,
    this.initialScope,
    // this.singleScopeLabel = '',
    this.committedMessage = 'Change committed',
    // flexScope means the scope can be set to either SG, S, B, LG or L
    // if false, the scope must be set from SG all the way down to L
    this.isFlexiScope = false,
    this.updateUiOnly = false,
  });

  final MdlPagAppConfig appConfig;
  final Map<String, dynamic>? itemScopeMap;
  final PagItemKind? forItemKind;
  final PagScopeType? forScopeType;
  final double width;
  final double labelWidth;
  final bool isEditable;
  final bool isSingleLabel;
  final MdlPagScope? initialScope; // the scope to be set initially
  // final String singleScopeLabel;
  final Function(dynamic)? onScopeSet;
  final bool showCommitted;
  final String committedMessage;
  final bool isFlexiScope;
  final bool
      updateUiOnly; // if true, the scope setter will not commit the scope

  @override
  State<WgtScopeSetter> createState() => _WgtScopeSetterState();
}

class _WgtScopeSetterState extends State<WgtScopeSetter> {
  late final MdlPagUser? loggedInUser;

  final nullSiteProfile = MdlPagSiteProfile(
    id: -1,
    name: '',
    label: '-- None --',
    latitude: -1,
    longitude: -1,
    timezone: -1,
  );
  final nullBuildingProfile = MdlPagBuildingProfile(
    id: -1,
    name: '',
    label: '-- None --',
    latitude: -1,
    longitude: -1,
  );
  final nullLocationGroupProfile = MdlPagLocationGroupProfile(
    id: -1,
    name: '',
    label: '-- None --',
    latitude: -1,
    longitude: -1,
  );
  final nullLocation = MdlPagLocation(
    id: -1,
    name: '',
    label: '-- None --',
  );

  // the setter cannot set a scope that is beyond the prevailing scope
  late final MdlPagScopeProfile prevailingScope;

  late final TextStyle dropDownListTextStyle = TextStyle(
      fontSize: 15,
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w500);
  late final TextStyle dropDownListHintStyle =
      TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
  late final Widget dropDownUnderline =
      Container(height: 1, color: Theme.of(context).hintColor.withAlpha(75));

  final List<MdlPagSiteGroupProfile> _siteGroupProfileList = [];
  final List<MdlPagSiteProfile> _siteProfileList = [];
  final List<MdlPagBuildingProfile> _buildingProfileList = [];
  final List<MdlPagLocationGroupProfile> _locationGroupProfileList = [];
  final List<MdlPagLocation> _locationList = [];

  // original values will be updated after commit
  MdlPagSiteGroupProfile? originalSiteGroupProfile;
  MdlPagSiteProfile? originalSiteProfile;
  MdlPagBuildingProfile? originalBuildingProfile;
  MdlPagLocationGroupProfile? originalLocationGroupProfile;
  MdlPagLocation? originalLocation;

  MdlPagSiteGroupProfile? _selectedSiteGroupProfile;
  MdlPagSiteProfile? _selectedSiteProfile;
  MdlPagBuildingProfile? _selectedBuildingProfile;
  MdlPagLocationGroupProfile? _selectedLocationGroupProfile;
  MdlPagLocation? _selectedLocation;

  // bool _newParentScopeSeletedFromList = false;
  bool _isFetchingChildrenList = false;
  bool _isCommitted = false;
  String _errorText = '';
  bool? _showCommitted;
  late String _committedMessage;
  bool _isEditing = false;
  bool _isReset = false;
  bool _isModified = false;
  bool _childrenListFetched = false;

  // late final TextEditingController _locationInputSelectController = TextEditingController();

  Future<dynamic> _getParentScopeChildrenList() async {
    if (_selectedLocationGroupProfile == null) return;
    // if (widget.forScopeType == null) return;
    if (widget.forScopeType == PagScopeType.location) return;

    if (_isFetchingChildrenList) return;
    // setState(() {
    _isFetchingChildrenList = true;
    _isCommitted = false;
    _errorText = '';
    _isReset = false;
    // _isModified = false;
    _committedMessage = '';
    // _newParentScopeSeletedFromList = false;
    _childrenListFetched = false;
    // });

    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      // must use id, not name or label
      // 'location_group_id_value': _selectedLocationGroupProfile!.id.toString(),
      'scope_type': widget.forScopeType ==
              null // scope setter is used for items other than scope
          ? PagScopeType.locationGroup.name
          : widget.forScopeType!.name,
      'parent_id': widget.forScopeType ==
              null // scope setter is used for items other than scope
          ? _selectedLocationGroupProfile!.id.toString()
          : widget.forScopeType == PagScopeType.site
              ? _selectedSiteGroupProfile!.id.toString()
              : widget.forScopeType == PagScopeType.building
                  ? _selectedSiteProfile!.id.toString()
                  : widget.forScopeType == PagScopeType.locationGroup
                      ? _selectedBuildingProfile!.id.toString()
                      : widget.forScopeType == PagScopeType.location
                          ? _selectedLocationGroupProfile!.id.toString()
                          : '',
    };
    try {
      var result = await getScopeChildrenList(
        widget.appConfig,
        loggedInUser,
        queryMap,
        MdlPagSvcClaim(
          userId: loggedInUser!.id,
          username: loggedInUser!.username,
          scope: '',
          target: '',
          operation: '',
        ),
      );
      if (result['scope_info_list'] == null) {
        throw Exception('Failed to get scope_info list');
      }

      switch (widget.forScopeType) {
        case PagScopeType.location:
          _onLocationListFetched(result);
          break;
        case PagScopeType.locationGroup:
          _onLocationGroupListFetched(result);
          break;
        case PagScopeType.building:
          _onBuildingListFetched(result);
          break;
        case PagScopeType.site:
          _onSiteListFetched(result);
          break;
        case PagScopeType.siteGroup:
          _onSiteGroupListFetched(result);
          break;
        default:
          // for setting scope for items other than scope
          _onLocationListFetched(result);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      rethrow;
    } finally {
      _isFetchingChildrenList = false;
      _childrenListFetched = true;
      // if (mounted) {
      //   setState(() {
      //     _enableSearch = _enableSearchButton();
      //   });
      // }
    }
  }

  void _onLocationListFetched(var result) {
    if (widget.isFlexiScope && _selectedLocation?.id == -1) {
      return;
    }

    _locationList.clear();
    for (var item in result['scope_info_list']) {
      _locationList.add(MdlPagLocation.fromJson(item));
    }
    if (widget.isFlexiScope) {
      _locationList.add(nullLocation);
    }

    _selectedLocationGroupProfile?.locationList = _locationList;

    // _selectedLocation is null on first load
    // use widget.itemScopeMap to set the location
    // after any commit, _selectedLocation is set to the committed location
    // and no longer use the value from widget.itemScopeMap
    String? locationName =
        _selectedLocation?.name ?? widget.itemScopeMap?['location_name'];
    _selectedLocation =
        _selectedLocationGroupProfile!.getLocationByName(locationName);

    if (_selectedLocation != null) {
      bool hasSelectedLocation = false;
      for (var location in _locationList) {
        if (location == _selectedLocation) {
          hasSelectedLocation = true;
          break;
        }
      }
      assert(hasSelectedLocation);
      // set originalLocation here instead of in initState
      if (originalLocation == null || _isCommitted) {
        originalLocation = _selectedLocation;
      }

      // _locationInputSelectController.text = _selectedLocation!.label;
    }
  }

  void _onLocationGroupListFetched(var result) {
    _locationGroupProfileList.clear();
    for (var item in result['scope_info_list']) {
      _locationGroupProfileList.add(MdlPagLocationGroupProfile.fromJson(item));
    }
    if (widget.isFlexiScope) {
      _locationGroupProfileList.add(nullLocationGroupProfile);
    }

    _selectedBuildingProfile?.locationGroupProfileList =
        _locationGroupProfileList;

    // _selectedLocationGroupProfile is null on first load
    // use widget.itemScopeMap to set the location group
    // after any commit, _selectedLocationGroupProfile is set to the committed location group
    // and no longer use the value from widget.itemScopeMap
    String? locationGroupName = _selectedLocationGroupProfile?.name ??
        widget.itemScopeMap?['location_group_name'];
    _selectedLocationGroupProfile = _selectedBuildingProfile!
        .getLocationGroupProfileByName(locationGroupName);

    if (_selectedLocationGroupProfile != null) {
      bool hasSelectedLocationGroup = false;
      for (var locationGroup in _locationGroupProfileList) {
        if (locationGroup == _selectedLocationGroupProfile) {
          hasSelectedLocationGroup = true;
          break;
        }
      }
      assert(hasSelectedLocationGroup);
      // set originalLocationGroupProfile here instead of in initState
      if (originalLocationGroupProfile == null || _isCommitted) {
        originalLocationGroupProfile = _selectedLocationGroupProfile;
      }
    }
  }

  void _onBuildingListFetched(var result) {
    _buildingProfileList.clear();
    for (var item in result['scope_info_list']) {
      _buildingProfileList.add(MdlPagBuildingProfile.fromJson(item));
    }
    if (widget.isFlexiScope) {
      _buildingProfileList.add(nullBuildingProfile);
    }

    _selectedSiteProfile?.buildingProfileList = _buildingProfileList;

    // _selectedBuildingProfile is null on first load
    // use widget.itemScopeMap to set the building
    // after any commit, _selectedBuildingProfile is set to the committed building
    // and no longer use the value from widget.itemScopeMap
    String? buildingName =
        _selectedBuildingProfile?.name ?? widget.itemScopeMap?['building_name'];
    _selectedBuildingProfile =
        _selectedSiteProfile!.getBuildingProfileByName(buildingName);

    if (_selectedBuildingProfile != null) {
      bool hasSelectedBuilding = false;
      for (var building in _buildingProfileList) {
        if (building == _selectedBuildingProfile) {
          hasSelectedBuilding = true;
          break;
        }
      }
      assert(hasSelectedBuilding);
      // set originalBuildingProfile here instead of in initState
      if (originalBuildingProfile == null || _isCommitted) {
        originalBuildingProfile = _selectedBuildingProfile;
      }
    }
  }

  void _onSiteListFetched(var result) {
    _siteProfileList.clear();
    for (var item in result['scope_info_list']) {
      _siteProfileList.add(MdlPagSiteProfile.fromJson(item));
    }
    if (widget.isFlexiScope) {
      _siteProfileList.add(nullSiteProfile);
    }

    _selectedSiteGroupProfile?.siteProfileList = _siteProfileList;

    // _selectedSiteProfile is null on first load
    // use widget.itemScopeMap to set the site
    // after any commit, _selectedSiteProfile is set to the committed site
    // and no longer use the value from widget.itemScopeMap
    String? siteName =
        _selectedSiteProfile?.name ?? widget.itemScopeMap?['site_name'];
    _selectedSiteProfile =
        _selectedSiteGroupProfile!.getSiteProfileByName(siteName);

    if (_selectedSiteProfile != null) {
      bool hasSelectedSite = false;
      for (var site in _siteProfileList) {
        if (site == _selectedSiteProfile) {
          hasSelectedSite = true;
          break;
        }
      }
      assert(hasSelectedSite);
      // set originalSiteProfile here instead of in initState
      if (originalSiteProfile == null || _isCommitted) {
        originalSiteProfile = _selectedSiteProfile;
      }
    }
  }

  void _onSiteGroupListFetched(var result) {
    _siteGroupProfileList.clear();
    for (var item in result['scope_info_list']) {
      _siteGroupProfileList.add(MdlPagSiteGroupProfile.fromJson(item));
    }

    prevailingScope.projectProfile!.siteGroupProfileList =
        _siteGroupProfileList;

    // _selectedSiteGroupProfile is null on first load
    // use widget.itemScopeMap to set the site group
    // after any commit, _selectedSiteGroupProfile is set to the committed site group
    // and no longer use the value from widget.itemScopeMap
    String? siteGroupName = _selectedSiteGroupProfile?.name ??
        widget.itemScopeMap?['site_group_name'];
    _selectedSiteGroupProfile = prevailingScope.projectProfile!
        .getSiteGroupProfileByName(siteGroupName);

    if (_selectedSiteGroupProfile != null) {
      bool hasSelectedSiteGroup = false;
      for (var siteGroup in _siteGroupProfileList) {
        if (siteGroup == _selectedSiteGroupProfile) {
          hasSelectedSiteGroup = true;
          break;
        }
      }
      assert(hasSelectedSiteGroup);
      // set originalSiteGroupProfile here instead of in initState
      if (originalSiteGroupProfile == null || _isCommitted) {
        originalSiteGroupProfile = _selectedSiteGroupProfile;
      }
    }
  }

  void _iniScopePreLoad() async {
    _selectedSiteGroupProfile = originalSiteGroupProfile;
    _selectedSiteProfile = originalSiteProfile;
    _selectedBuildingProfile = originalBuildingProfile;
    _selectedLocationGroupProfile = originalLocationGroupProfile;
    _selectedLocation = originalLocation;

    if (prevailingScope.siteGroupProfile != null) {
      _siteGroupProfileList.add(prevailingScope.siteGroupProfile!);
    } else {
      if (loggedInUser!.selectedScope.projectProfile != null) {
        _siteGroupProfileList.addAll(
            loggedInUser!.selectedScope.projectProfile!.siteGroupProfileList);
      }
    }
    if (widget.forScopeType == PagScopeType.site) {
      assert(_selectedSiteGroupProfile == null ||
          _siteGroupProfileList.contains(_selectedSiteGroupProfile));
    }

    if (prevailingScope.siteProfile != null) {
      _siteProfileList.add(prevailingScope.siteProfile!);
    } else {
      if (_selectedSiteGroupProfile != null) {
        _siteProfileList.addAll(_selectedSiteGroupProfile!.siteProfileList);
      }
    }
    if (widget.isFlexiScope) {
      _siteProfileList.add(nullSiteProfile);
    }

    if (widget.forScopeType == PagScopeType.building) {
      assert(_selectedSiteProfile == null ||
          _siteProfileList.contains(_selectedSiteProfile));
    }

    if (prevailingScope.buildingProfile != null) {
      _buildingProfileList.add(prevailingScope.buildingProfile!);
    } else {
      if (_selectedSiteProfile != null) {
        _buildingProfileList.addAll(_selectedSiteProfile!.buildingProfileList);
      }
    }
    if (widget.isFlexiScope) {
      _buildingProfileList.add(nullBuildingProfile);
    }

    if (widget.forScopeType == PagScopeType.locationGroup) {
      assert(_selectedBuildingProfile == null ||
          _buildingProfileList.contains(_selectedBuildingProfile));
    }

    if (prevailingScope.locationGroupProfile != null) {
      _locationGroupProfileList.add(prevailingScope.locationGroupProfile!);
    } else {
      if (_selectedBuildingProfile != null) {
        _locationGroupProfileList
            .addAll(_selectedBuildingProfile!.locationGroupProfileList);
      }
    }
    if (widget.isFlexiScope) {
      _locationGroupProfileList.add(nullLocationGroupProfile);
    }

    if (widget.forScopeType == PagScopeType.location) {
      assert(_selectedLocationGroupProfile == null ||
          _locationGroupProfileList.contains(_selectedLocationGroupProfile));
    }

    // if (_selectedLocation != null) {
    //   _locationList.add(_selectedLocation!);
    // } else {
    //   _locationList.addAll(_selectedLocationGroupProfile!.locationList);
    // }
    setState(() {});
  }

  void _restoreInitialScope() {
    setState(() {
      _isReset = true;
      _selectedSiteGroupProfile = null;
      _selectedSiteProfile = null;
      _selectedBuildingProfile = null;
      _selectedLocationGroupProfile = null;
      _selectedLocation = null;

      _siteGroupProfileList.clear();
      _siteProfileList.clear();
      _buildingProfileList.clear();
      _locationGroupProfileList.clear();
      _locationList.clear();

      _iniScopePreLoad();
    });
  }

  void _updateOriginalScope() {
    originalSiteGroupProfile = _selectedSiteGroupProfile;
    originalSiteProfile = _selectedSiteProfile;
    originalBuildingProfile = _selectedBuildingProfile;
    originalLocationGroupProfile = _selectedLocationGroupProfile;
    originalLocation = _selectedLocation;
  }

  bool _isNullScope() {
    bool isNull = false;
    if (widget.forScopeType == PagScopeType.siteGroup) {
      isNull = isNull || _selectedSiteProfile == null;
    }
    if (widget.forScopeType == PagScopeType.site) {
      isNull = isNull || _selectedSiteGroupProfile == null;
    }
    if (widget.forScopeType == PagScopeType.building) {
      isNull = isNull || _selectedSiteProfile == null;
    }
    if (widget.forScopeType == PagScopeType.locationGroup) {
      isNull = isNull || _selectedBuildingProfile == null;
    }
    // if (widget.forItemKind != PagItemKind.scope) {
    if (widget.forScopeType == PagScopeType.location) {
      isNull = isNull || _selectedLocationGroupProfile == null;
    }
    return isNull;
  }

  void _markModified() {
    _isModified = true;
    _isCommitted = false;
    _committedMessage = '';
  }

  @override
  void initState() {
    super.initState();

    loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    _committedMessage = widget.committedMessage;

    prevailingScope = loggedInUser!.selectedScope;

    // get values that are already set for the item
    String? siteGroupName = widget.itemScopeMap?['site_group_name'];
    originalSiteGroupProfile = prevailingScope.projectProfile!
        .getSiteGroupProfileByName(siteGroupName);

    String? siteName = widget.itemScopeMap?['site_name'];
    originalSiteProfile =
        originalSiteGroupProfile?.getSiteProfileByName(siteName);

    String? buildingName = widget.itemScopeMap?['building_name'];
    originalBuildingProfile =
        originalSiteProfile?.getBuildingProfileByName(buildingName);

    String? locationGroupName = widget.itemScopeMap?['location_group_name'];
    originalLocationGroupProfile = originalBuildingProfile
        ?.getLocationGroupProfileByName(locationGroupName);

    String? locationName = widget.itemScopeMap?['location_name'];
    originalLocation =
        originalLocationGroupProfile?.getLocationByName(locationName);

    _iniScopePreLoad();
  }

  @override
  void dispose() {
    // _locationInputSelectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool pullChildrenList = false;

    if (_isModified && !_childrenListFetched) {
      pullChildrenList = true;
    }

    if (_isReset) {
      pullChildrenList = true;
    }

    bool case1 = (widget.forScopeType == PagScopeType.location &&
        _selectedLocation == null);
    // bool case2 = (widget.forItemKind != PagItemKind.scope && _selectedLocation == null);
    bool case3 = (widget.forScopeType == PagScopeType.locationGroup &&
        _selectedLocationGroupProfile == null);
    bool case4 = (widget.forScopeType == PagScopeType.building &&
        _selectedBuildingProfile == null);
    bool case5 = (widget.forScopeType == PagScopeType.site &&
        _selectedSiteProfile == null);
    bool case6 = (widget.forScopeType == PagScopeType.siteGroup &&
        _selectedSiteGroupProfile == null);

    if (case1 || /*case2 ||*/ case3 || case4 || case5 || case6) {
      pullChildrenList = true;
    }

    // for scope, or for item kinds with flexi scope
    if (widget.forItemKind == PagItemKind.scope ||
        widget.forItemKind == PagItemKind.meterGroup ||
        widget.forItemKind == PagItemKind.tariffPackage) {
      if (_selectedLocationGroupProfile == null) {
        pullChildrenList = false;
      }
    }

    String initialScopeLabel = widget.initialScope?.getLeafScopeLabel() ?? '';
    Widget? scopeIcon;
    PagScopeType? itemScopeType = widget.initialScope?.getScopeType();
    if (widget.isSingleLabel) {
      assert(itemScopeType != null,
          'itemScopeType cannot be null when isSingleLabel is true');
      scopeIcon = getScopeIcon(context, itemScopeType!, size: 21);
    }

    double height = widget.forItemKind == PagItemKind.scope ? 60 : 90;
    if (_errorText.isNotEmpty) {
      height += 40;
    }

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: widget.isSingleLabel
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: widget.width,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      scopeIcon!,
                      horizontalSpaceTiny,
                      Text(initialScopeLabel),
                    ],
                  ),
                  // Text(widget.singleScopeLabel, style: dropDownListTextStyle),
                ),
                getControl(),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...getSelectorList(),
                pullChildrenList
                    ? SizedBox(
                        height: height,
                        child: FutureBuilder<void>(
                          future: _getParentScopeChildrenList(),
                          builder: (context, AsyncSnapshot<void> snapshot) {
                            switch (snapshot.connectionState) {
                              case ConnectionState.waiting:
                                if (kDebugMode) {
                                  print('waiting scope list...');
                                }
                                return const SizedBox(
                                    height: 35, child: WgtPagWait(size: 21));
                              default:
                                if (snapshot.hasError) {
                                  if (kDebugMode) {
                                    print(snapshot.error);
                                  }

                                  _errorText = 'Error getting scope list';

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      getErrorTextPrompt(
                                          context: context,
                                          errorText: _errorText),
                                      getControl(errorText: _errorText),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.forItemKind !=
                                          PagItemKind.scope)
                                        getLocationSelector(),
                                      getControl(),
                                    ],
                                  );
                                }
                            }
                          },
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.forItemKind != PagItemKind.scope)
                            getLocationSelector(),
                          // ...getSelectorList(),
                          getControl(),
                        ],
                      ),
              ],
            ),
    );
  }

  List<Widget> getSelectorList() {
    if (widget.forScopeType == PagScopeType.siteGroup) {
      return [Container()];
    }
    switch (widget.forScopeType) {
      case PagScopeType.site:
        return [getSiteGroupScopeSelector()];
      case PagScopeType.building:
        return [getSiteGroupScopeSelector(), getSiteScopeSelector()];
      case PagScopeType.locationGroup:
        return [
          getSiteGroupScopeSelector(),
          getSiteScopeSelector(),
          getBuildingScopeSelector()
        ];
      case PagScopeType.location:
        return [
          getSiteGroupScopeSelector(),
          getSiteScopeSelector(),
          getBuildingScopeSelector(),
          getLocationGroupScopeSelector()
        ];
      default:
        return [
          getSiteGroupScopeSelector(),
          getSiteScopeSelector(),
          getBuildingScopeSelector(),
          getLocationGroupScopeSelector()
        ];
    }
  }

  Widget getSiteGroupScopeSelector() {
    if (widget.forScopeType == PagScopeType.siteGroup) {
      return Container();
    }
    return Row(
      children: [
        Container(
            width: widget.labelWidth,
            alignment: Alignment.centerRight,
            child: Text('Site Group: ', style: dropDownListHintStyle)),
        IgnorePointer(
          ignoring: !_isEditing,
          child: DropdownButton<MdlPagSiteGroupProfile>(
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Site Group', style: dropDownListHintStyle)),
              value: _selectedSiteGroupProfile,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (MdlPagSiteGroupProfile? value) {
                if (_selectedSiteGroupProfile == value) {
                  return;
                }
                setState(() {
                  _selectedSiteGroupProfile = value;
                  _selectedSiteProfile = null;
                  _selectedBuildingProfile = null;
                  _selectedLocationGroupProfile = null;
                  _selectedLocation = null;

                  _markModified();

                  _siteProfileList.clear();
                  _siteProfileList
                      .addAll(_selectedSiteGroupProfile!.siteProfileList);
                  if (_siteProfileList.length == 1) {
                    _selectedSiteProfile = _siteProfileList[0];
                  }

                  _buildingProfileList.clear();
                  if (_selectedSiteProfile != null) {
                    _buildingProfileList
                        .addAll(_selectedSiteProfile!.buildingProfileList);
                    if (_buildingProfileList.length == 1) {
                      _selectedBuildingProfile = _buildingProfileList[0];
                    }
                  }

                  _locationGroupProfileList.clear();
                  if (_selectedBuildingProfile != null) {
                    _locationGroupProfileList.addAll(
                        _selectedBuildingProfile!.locationGroupProfileList);
                    if (_locationGroupProfileList.length == 1) {
                      _selectedLocationGroupProfile =
                          _locationGroupProfileList[0];
                    }
                    if (widget.isFlexiScope) {
                      _locationGroupProfileList.add(nullLocationGroupProfile);
                    }
                  }

                  _locationList.clear();
                  if (_selectedLocationGroupProfile != null) {
                    _locationList
                        .addAll(_selectedLocationGroupProfile!.locationList);
                    if (_locationList.length == 1) {
                      _selectedLocation = _locationList[0];
                    }
                  }
                });
              },
              items: _siteGroupProfileList
                  .map<DropdownMenuItem<MdlPagSiteGroupProfile>>(
                      (MdlPagSiteGroupProfile siteGroupProfile) {
                return DropdownMenuItem<MdlPagSiteGroupProfile>(
                  value: siteGroupProfile,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(
                      siteGroupProfile.label,
                      style: _isEditing
                          ? dropDownListTextStyle
                          : dropDownListHintStyle,
                    ),
                  ),
                );
              }).toList()),
        ),
      ],
    );
  }

  Widget getSiteScopeSelector() {
    if (widget.forScopeType == PagScopeType.site) {
      return Container();
    }
    return Row(
      children: [
        Container(
            width: widget.labelWidth,
            alignment: Alignment.centerRight,
            child: Text('Site: ', style: dropDownListHintStyle)),
        IgnorePointer(
          ignoring: !_isEditing,
          child: DropdownButton<MdlPagSiteProfile>(
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Site', style: dropDownListHintStyle)),
              value: _selectedSiteProfile,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (MdlPagSiteProfile? value) {
                if (_selectedSiteProfile == value) {
                  return;
                }
                setState(() {
                  _selectedSiteProfile = value;
                  if (widget.isFlexiScope && _selectedSiteProfile!.id == -1) {
                    _selectedSiteProfile = null;
                  }
                  _selectedBuildingProfile = null;
                  _selectedLocationGroupProfile = null;
                  _selectedLocation = null;

                  _markModified();

                  _buildingProfileList.clear();
                  if (_selectedSiteProfile != null) {
                    _buildingProfileList
                        .addAll(_selectedSiteProfile!.buildingProfileList);
                    if (_buildingProfileList.length == 1) {
                      _selectedBuildingProfile = _buildingProfileList[0];
                    }
                  }

                  _locationGroupProfileList.clear();
                  if (_selectedBuildingProfile != null) {
                    _locationGroupProfileList.addAll(
                        _selectedBuildingProfile!.locationGroupProfileList);
                    if (_locationGroupProfileList.length == 1) {
                      _selectedLocationGroupProfile =
                          _locationGroupProfileList[0];
                    }
                    if (widget.isFlexiScope) {
                      _locationGroupProfileList.add(nullLocationGroupProfile);
                    }
                  }

                  _locationList.clear();
                  if (_selectedLocationGroupProfile != null) {
                    _locationList
                        .addAll(_selectedLocationGroupProfile!.locationList);
                    if (_locationList.length == 1) {
                      _selectedLocation = _locationList[0];
                    }
                  }
                });
              },
              items: _siteProfileList.map<DropdownMenuItem<MdlPagSiteProfile>>(
                  (MdlPagSiteProfile siteProfile) {
                return DropdownMenuItem<MdlPagSiteProfile>(
                  value: siteProfile,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(
                      siteProfile.label,
                      style: _isEditing
                          ? dropDownListTextStyle
                          : dropDownListHintStyle,
                    ),
                  ),
                );
              }).toList()),
        ),
      ],
    );
  }

  Widget getBuildingScopeSelector() {
    if (widget.forScopeType == PagScopeType.building) {
      return Container();
    }
    return Row(
      children: [
        Container(
            width: widget.labelWidth,
            alignment: Alignment.centerRight,
            child: Text('Building: ', style: dropDownListHintStyle)),
        IgnorePointer(
          ignoring: !_isEditing,
          child: DropdownButton<MdlPagBuildingProfile>(
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Building', style: dropDownListHintStyle)),
              value: _selectedBuildingProfile,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (MdlPagBuildingProfile? value) {
                if (_selectedBuildingProfile == value) {
                  return;
                }

                setState(() {
                  _selectedBuildingProfile = value;
                  if (widget.isFlexiScope &&
                      _selectedBuildingProfile!.id == -1) {
                    _selectedBuildingProfile = null;
                  }
                  _selectedLocationGroupProfile = null;
                  _selectedLocation = null;

                  _markModified();

                  _locationGroupProfileList.clear();
                  if (_selectedBuildingProfile != null) {
                    _locationGroupProfileList.addAll(
                        _selectedBuildingProfile!.locationGroupProfileList);
                    if (_locationGroupProfileList.length == 1) {
                      _selectedLocationGroupProfile =
                          _locationGroupProfileList[0];
                    }
                    if (widget.isFlexiScope) {
                      _locationGroupProfileList.add(nullLocationGroupProfile);
                    }
                  }

                  _locationList.clear();
                  if (_selectedLocationGroupProfile != null) {
                    _locationList
                        .addAll(_selectedLocationGroupProfile!.locationList);
                    if (_locationList.length == 1) {
                      _selectedLocation = _locationList[0];
                    }
                  }
                });
              },
              items: _buildingProfileList
                  .map<DropdownMenuItem<MdlPagBuildingProfile>>(
                      (MdlPagBuildingProfile buildingProfile) {
                return DropdownMenuItem<MdlPagBuildingProfile>(
                  value: buildingProfile,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(
                      buildingProfile.label,
                      style: _isEditing
                          ? dropDownListTextStyle
                          : dropDownListHintStyle,
                    ),
                  ),
                );
              }).toList()),
        ),
      ],
    );
  }

  Widget getLocationGroupScopeSelector() {
    if (widget.forScopeType == PagScopeType.locationGroup) {
      return Container();
    }
    return Row(
      children: [
        Container(
            width: widget.labelWidth,
            alignment: Alignment.centerRight,
            child: Text('Location Group: ', style: dropDownListHintStyle)),
        IgnorePointer(
          ignoring: !_isEditing,
          child: DropdownButton<MdlPagLocationGroupProfile>(
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Location Group', style: dropDownListHintStyle)),
              value: _selectedLocationGroupProfile,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (MdlPagLocationGroupProfile? value) async {
                if (_selectedLocationGroupProfile == value) {
                  return;
                }
                if (_selectedLocationGroupProfile == null) {
                  if (value?.id == -1) {
                    return;
                  }
                }

                if (widget.forScopeType != PagScopeType.location) {
                  await _getParentScopeChildrenList();
                }

                setState(() {
                  _selectedLocationGroupProfile = value;

                  if (value?.id == -1) {
                    _selectedLocationGroupProfile = null;
                  }

                  _selectedLocation = null;
                  if (_locationList.length == 1) {
                    _selectedLocation = _locationList[0];
                  }

                  _markModified();
                });
              },
              items: _locationGroupProfileList
                  .map<DropdownMenuItem<MdlPagLocationGroupProfile>>(
                      (MdlPagLocationGroupProfile locationGroupProfile) {
                return DropdownMenuItem<MdlPagLocationGroupProfile>(
                  value: locationGroupProfile,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(
                      locationGroupProfile.label,
                      style: _isEditing
                          ? dropDownListTextStyle
                          : dropDownListHintStyle,
                    ),
                  ),
                );
              }).toList()),
        ),
      ],
    );
  }

  Widget getLocationSelector() {
    // if (widget.forItemKind == PagItemKind.scope) {
    if (widget.forScopeType == PagScopeType.location) {
      return Container();
    }
    return Row(
      children: [
        Container(
            width: widget.labelWidth,
            alignment: Alignment.centerRight,
            child: Text('Location: ', style: dropDownListHintStyle)),
        IgnorePointer(
          ignoring: !_isEditing,
          child: WgtInputDropdown(
            // height: 50,
            width: 150,
            // key: UniqueKey(), // prevent reuse of the same widget (and its state)
            hint: 'Location',
            enabled: _isEditing,
            textStyle:
                _isEditing ? dropDownListTextStyle : dropDownListHintStyle,
            items: _locationList
                .map((MdlPagLocation location) => {
                      'value': location.id.toString(),
                      'label': location.label,
                    })
                .toList(),
            // if null the widget will use its own controller
            // but if want to control the value from outside the dropdown widget,
            // you can pass a controller
            // controller: _locationInputSelectController,
            initialValue: _selectedLocation == null
                ? null
                : {
                    'value': _selectedLocation?.id.toString(),
                    'label': _selectedLocation?.label,
                  },
            isInitialValueMutable: true, //colController.valueList!.length > 1,
            onSelected: (Map<String, dynamic>? value) {
              if (value == null) {
                return;
              }
              MdlPagLocation? location = _locationList.firstWhere(
                  (MdlPagLocation location) =>
                      location.id.toString() == value['value']);
              if (_selectedLocation == location) {
                return;
              }

              setState(() {
                _selectedLocation = location;
                // if (widget.isFlexiScope && _selectedLocation?.id == -1) {
                //   _selectedLocation = null;
                // }
                _markModified();
              });
            },
            onClear: () {
              setState(() {
                _selectedLocation = null;
                _markModified();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget getControl({String errorText = ''}) {
    bool isChanged = false;
    if (_selectedSiteGroupProfile == originalSiteGroupProfile) {
      isChanged = true;
    }
    if (_selectedSiteProfile == originalSiteProfile) {
      isChanged = true;
    }
    if (_selectedBuildingProfile == originalBuildingProfile) {
      isChanged = true;
    }
    if (!(_selectedLocationGroupProfile == originalLocationGroupProfile)) {
      isChanged = true;
    }
    if (_selectedLocation == originalLocation) {
      isChanged = true;
    }

    // check enable commit
    bool enableCommit = errorText.isEmpty && _committedMessage.isEmpty;

    // if (widget.forItemKind != PagItemKind.scope) {
    //   if (_selectedLocation == null) {
    //     enableCommit = false;
    //   }
    // }
    switch (widget.forItemKind) {
      case PagItemKind.scope:
        break;
      case PagItemKind.tariffPackage:
        break;
      case PagItemKind.tenant:
        if (_selectedLocation == null) {
          enableCommit = false;
        }
        break;
      case PagItemKind.meterGroup:
        break;
      default:
        if (_selectedLocation == null) {
          enableCommit = false;
        }
        break;
    }

    bool isNull = _isNullScope();

    if (isNull) {
      enableCommit = false;
    }
    /////////////////////////

    bool showClear = true;
    if (isNull) {
      showClear = false;
    }
    if (_committedMessage.isNotEmpty) {
      showClear = false;
    }
    if (errorText.isNotEmpty) {
      showClear = false;
    }
    if (!isChanged) {
      showClear = false;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_committedMessage.isNotEmpty && _errorText.isNotEmpty)
          getErrorTextPrompt(context: context, errorText: _errorText),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            horizontalSpaceSmall,
            SizedBox(
              width: 35,
              child: showClear
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _restoreInitialScope();
                      },
                    )
                  : Container(),
            ),
            Expanded(child: Container()),
            if (_showCommitted ?? false)
              Row(
                children: [
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      _committedMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            Expanded(child: Container()),
            _isFetchingChildrenList
                ? Container()
                : _isEditing
                    ? IconButton(
                        icon: Icon(Icons.check,
                            color: enableCommit
                                ? Theme.of(context).colorScheme.primary
                                : null),
                        onPressed: !enableCommit
                            ? null
                            : () async {
                                bool isNull = _isNullScope();

                                if (isNull) {
                                  setState(() {
                                    _isEditing = false;
                                  });
                                  return;
                                }
                                bool isEqual = true;
                                if (widget.forScopeType !=
                                    PagScopeType.siteGroup) {
                                  isEqual = isEqual &&
                                      (_selectedSiteGroupProfile ==
                                          originalSiteGroupProfile);
                                }
                                if (widget.forScopeType != PagScopeType.site) {
                                  isEqual = isEqual &&
                                      (_selectedSiteProfile ==
                                          originalSiteProfile);
                                }
                                if (widget.forScopeType !=
                                    PagScopeType.building) {
                                  isEqual = isEqual &&
                                      (_selectedBuildingProfile ==
                                          originalBuildingProfile);
                                }
                                if (widget.forScopeType !=
                                    PagScopeType.locationGroup) {
                                  isEqual = isEqual &&
                                      (_selectedLocationGroupProfile ==
                                          originalLocationGroupProfile);
                                }
                                // if (widget.forItemKind != PagItemKind.scope) {
                                if ((widget.forScopeType !=
                                        PagScopeType.location) ||
                                    (widget.forItemKind != PagItemKind.scope)) {
                                  isEqual = isEqual &&
                                      (_selectedLocation == originalLocation);
                                }
                                if (isEqual) {
                                  setState(() {
                                    _isEditing = false;
                                  });
                                  return;
                                }

                                if (!_isModified) {
                                  setState(() {
                                    _isEditing = false;
                                  });
                                  return;
                                }

                                dynamic scope;
                                switch (widget.forScopeType) {
                                  case PagScopeType.siteGroup:
                                    break;
                                  case PagScopeType.site:
                                    scope = _selectedSiteGroupProfile;
                                    break;
                                  case PagScopeType.building:
                                    scope = _selectedSiteProfile;
                                    break;
                                  case PagScopeType.locationGroup:
                                    scope = _selectedBuildingProfile;
                                    break;
                                  case PagScopeType.location:
                                    scope = _selectedLocationGroupProfile;
                                    break;
                                  default:
                                    // setting scope for item kind other than scope
                                    scope = _selectedLocation;
                                    break;
                                }

                                bool updateUiOnly = false;
                                if (widget.forItemKind ==
                                        PagItemKind.tariffPackage ||
                                    widget.forItemKind == PagItemKind.tenant ||
                                    widget.forItemKind == PagItemKind.device) {
                                  updateUiOnly = true;
                                }
                                if (widget.updateUiOnly) {
                                  updateUiOnly = true;
                                }
                                // get leaf scope
                                if (_selectedLocation != null &&
                                    _selectedLocation?.id != -1) {
                                  scope = _selectedLocation;
                                } else if (_selectedLocationGroupProfile !=
                                        null &&
                                    _selectedLocationGroupProfile?.id != -1) {
                                  scope = _selectedLocationGroupProfile;
                                } else if (_selectedBuildingProfile != null &&
                                    _selectedBuildingProfile?.id != -1) {
                                  scope = _selectedBuildingProfile;
                                } else if (_selectedSiteProfile != null &&
                                    _selectedSiteProfile?.id != -1) {
                                  scope = _selectedSiteProfile;
                                } else if (_selectedSiteGroupProfile != null &&
                                    _selectedSiteGroupProfile?.id != -1) {
                                  scope = _selectedSiteGroupProfile;
                                }

                                // // always add project id and name to the scope
                                // scope = scope.copyWith(
                                //   projectId: loggedInUser!
                                //       .selectedScope.projectProfile!.id,
                                //   projectName: loggedInUser!
                                //       .selectedScope.projectProfile!.name,
                                // );

                                if (updateUiOnly) {
                                  // update UI only
                                  setState(() {
                                    _isEditing = false;
                                  });

                                  widget.onScopeSet?.call(scope);
                                } else {
                                  // commit to db
                                  final result =
                                      await widget.onScopeSet?.call(scope);

                                  if (result == null) {
                                    if (kDebugMode) {
                                      print('Error setting scope');
                                    }
                                    return;
                                  }

                                  if (result['error'] == null) {
                                    _errorText = '';
                                    _updateOriginalScope();
                                    _showCommitted = widget.showCommitted;
                                    // _newParentScopeSeletedFromList = false;
                                    if (result['show_committed'] != null) {
                                      _showCommitted = result['show_committed'];
                                    }
                                    _committedMessage =
                                        result['message'] ?? 'Change committed';
                                  } else {
                                    _committedMessage = 'Error setting scope';
                                    _errorText =
                                        'Error setting scope'; //result['error'];
                                  }

                                  setState(() {
                                    _isEditing = false;
                                    _isReset = false;
                                  });
                                }
                              },
                      )
                    : !widget.isEditable
                        ? Container()
                        : IconButton(
                            icon: Icon(Icons.edit,
                                color: Theme.of(context).hintColor),
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                                _showCommitted = false;
                              });
                            },
                          ),
            horizontalSpaceSmall,
          ],
        ),
      ],
    );
  }
}

// Widget getItemScopeSetter({
//   required MdlPagAppConfig appConfig,
//   UniqueKey? scopeSetterKey,
//   required PagItemKind itemKind,
//   double width = 395,
//   Function(String, String)? onSetState,
// }) {
//   return Padding(
//     padding: const EdgeInsets.only(top: 8.0),
//     child: WgtScopeSetter(
//       appConfig: appConfig,
//       key: scopeSetterKey,
//       width: width,
//       labelWidth: 130,
//       // itemScopeMap: widget.itemScopeMap!,
//       forItemKind: itemKind,
//       // forScopeType: widget.itemType is PagScopeType ? widget.itemType : null,
//       onScopeSet: (dynamic profile) {
//         if (profile == null) {
//           if (kDebugMode) {
//             print('Profile is null');
//           }
//           return {};
//         }
//         String scopeIdColName = '';
//         if (profile is MdlPagSiteGroupProfile) {
//           scopeIdColName = 'site_group_id';
//         } else if (profile is MdlPagSiteProfile) {
//           scopeIdColName = 'site_id';
//         } else if (profile is MdlPagBuildingProfile) {
//           scopeIdColName = 'building_id';
//         } else if (profile is MdlPagLocationGroupProfile) {
//           scopeIdColName = 'location_group_id';
//         } else if (profile is MdlPagLocation) {
//           scopeIdColName = 'location_id';
//         }
//         if (scopeIdColName.isEmpty) {
//           if (kDebugMode) {
//             print('Invalid profile type');
//           }
//           return {};
//         }
//         onSetState?.call(scopeIdColName, profile.id.toString());
//         // setState(() {
//         //   _itemScopeMap[scopeIdColName] = profile.id.toString();
//         // });
//       },
//     ),
//   );
// }
