import 'package:buff_helper/pag_helper/model/mdl_pag_project_profile.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_building_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_profile.dart';
import 'package:buff_helper/pag_helper/wgt_project_logo.dart';
import 'package:buff_helper/pagrid_helper/comm_helper/local_storage.dart';
import 'package:buff_helper/xt_ui/xt_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class WgtPagScopeSelector3 extends StatefulWidget {
  const WgtPagScopeSelector3({
    super.key,
    required this.projectList,
    required this.onChange,
    required this.iniScope,
    this.readOnly = false,
  });

  final Function(
      MdlPagProjectProfile? pagProjectScope,
      MdlPagSiteGroupProfile? pagSiteGroupScope,
      MdlPagSiteProfile? pagSiteScope,
      MdlPagBuildingProfile? pagBuildingScope,
      MdlPagLocationGroupProfile? pagLocationGroupScope)? onChange;
  final MdlPagScopeProfile iniScope;
  final List<MdlPagProjectProfile> projectList;
  final bool readOnly;

  @override
  State<WgtPagScopeSelector3> createState() => _WgtPagScopeSelector3State();
}

//boilerplate
class _WgtPagScopeSelector3State extends State<WgtPagScopeSelector3> {
  late final MdlPagUser? loggedInUser;
  late MdlPagProjectProfile _selectedProjectProfile;
  MdlPagSiteGroupProfile? _selectedSiteGroupProfile;
  MdlPagSiteProfile? _selectedSiteProfile;
  MdlPagBuildingProfile? _selectedBuildingProfile;
  MdlPagLocationGroupProfile? _selectedLocationGroupProfile;
  final List<MdlPagSiteGroupProfile> _siteGroupProfileList = [];
  final List<MdlPagSiteProfile> _siteProfileList = [];
  final List<MdlPagBuildingProfile> _buildingProfileList = [];
  final List<MdlPagLocationGroupProfile> _locationGroupProfileList = [];

  late final TextStyle dropDownListTextStyle = TextStyle(
      fontSize: 15,
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w500);
  late final TextStyle dropDownListHintStyle =
      TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
  late final Widget dropDownUnderline =
      Container(height: 1, color: Theme.of(context).hintColor.withAlpha(75));

  bool _scopeSet = true;

  UniqueKey? _projectLogoKey;

  Widget _getEffectScopeWidget() {
    String effectiveScopeStr = '';
    String projectScopeLabel = _selectedProjectProfile.label.toUpperCase();

    String siteGroupScopeLabel = _selectedSiteGroupProfile?.label ?? '';
    String siteScopeLabel = _selectedSiteProfile?.label ?? '';
    String buildingScopeLabel = _selectedBuildingProfile?.label ?? '';
    String locationGroupScopeLabel = _selectedLocationGroupProfile?.label ?? '';

    // return effectiveScopeStr;
    List<Widget> scopeWidgetList = [];
    TextStyle scopeTextStyle =
        TextStyle(fontSize: 17, color: pag3.withAlpha(200), height: 0.95);
    scopeWidgetList.add(Icon(Symbols.flag_filled_rounded,
        size: 19, color: Theme.of(context).hintColor.withAlpha(128)));
    scopeWidgetList.add(Padding(
      padding: const EdgeInsets.only(left: 1),
      child: Text(projectScopeLabel, style: scopeTextStyle),
    ));
    if (siteGroupScopeLabel.isNotEmpty) {
      scopeWidgetList.add(Icon(Symbols.arrow_right,
          size: 19, color: Theme.of(context).hintColor.withAlpha(128)));
      scopeWidgetList.add(Icon(Symbols.workspaces,
          size: 19, color: Theme.of(context).hintColor.withAlpha(128)));
      scopeWidgetList.add(Padding(
        padding: const EdgeInsets.only(left: 1),
        child: Text(siteGroupScopeLabel, style: scopeTextStyle),
      ));
    }
    if (siteScopeLabel.isNotEmpty) {
      scopeWidgetList.add(Icon(Symbols.arrow_right,
          size: 19, color: Theme.of(context).hintColor.withAlpha(128)));
      scopeWidgetList.add(Icon(Symbols.home_pin,
          size: 19, color: Theme.of(context).hintColor.withAlpha(128)));
      scopeWidgetList.add(Padding(
        padding: const EdgeInsets.only(left: 1),
        child: Text(siteScopeLabel, style: scopeTextStyle),
      ));
    }
    if (buildingScopeLabel.isNotEmpty) {
      scopeWidgetList.add(Icon(Symbols.arrow_right,
          size: 19, color: Theme.of(context).hintColor.withAlpha(128)));
      scopeWidgetList.add(Icon(Symbols.domain,
          size: 19, color: Theme.of(context).hintColor.withAlpha(128)));
      scopeWidgetList.add(Padding(
        padding: const EdgeInsets.only(left: 1),
        child: Text(buildingScopeLabel, style: scopeTextStyle),
      ));
    }
    if (locationGroupScopeLabel.isNotEmpty) {
      scopeWidgetList.add(Icon(Symbols.arrow_right,
          size: 19, color: Theme.of(context).hintColor.withAlpha(128)));
      scopeWidgetList.add(Icon(Symbols.group_work,
          size: 19, color: Theme.of(context).hintColor.withAlpha(128)));
      scopeWidgetList.add(Padding(
        padding: const EdgeInsets.only(left: 1),
        child: Text(locationGroupScopeLabel, style: scopeTextStyle),
      ));
    }

    return Transform.translate(
      offset: const Offset(-2, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: scopeWidgetList,
      ),
    );
  }

  void _saveScopePref() {
    Map<String, dynamic> scopePref = {};
    scopePref['selected_project_name'] = _selectedProjectProfile.name;
    if (_selectedSiteGroupProfile != null) {
      scopePref['selected_site_group_name'] = _selectedSiteGroupProfile!.name;
    }
    if (_selectedSiteProfile != null) {
      scopePref['selected_site_name'] = _selectedSiteProfile!.name;
    }
    if (_selectedBuildingProfile != null) {
      scopePref['selected_building_name'] = _selectedBuildingProfile!.name;
    }
    if (_selectedLocationGroupProfile != null) {
      scopePref['selected_location_group_name'] =
          _selectedLocationGroupProfile!.name;
    }

    saveToSharedPref('scope_pref', scopePref, removeBeforeSave: true);
  }

  @override
  void initState() {
    super.initState();

    loggedInUser =
        Provider.of<PagUserProvider>(context, listen: false).currentUser;

    //get the first site of the initial projectScope
    _siteGroupProfileList.clear();
    _siteGroupProfileList
        .addAll(widget.iniScope.projectProfile!.siteGroupProfileList);

    _siteProfileList.clear();
    if (widget.iniScope.siteGroupProfile != null) {
      _siteProfileList
          .addAll(widget.iniScope.siteGroupProfile!.siteProfileList);
    }
    _buildingProfileList.clear();
    if (widget.iniScope.siteProfile != null) {
      _buildingProfileList
          .addAll(widget.iniScope.siteProfile!.buildingProfileList);
    }
    _locationGroupProfileList.clear();
    if (widget.iniScope.buildingProfile != null) {
      _locationGroupProfileList
          .addAll(widget.iniScope.buildingProfile!.locationGroupProfileList);
    }
    _selectedProjectProfile = widget.iniScope.projectProfile!;
    _selectedSiteGroupProfile = widget.iniScope.siteGroupProfile;
    _selectedSiteProfile = widget.iniScope.siteProfile;
    _selectedBuildingProfile = widget.iniScope.buildingProfile;
    _selectedLocationGroupProfile = widget.iniScope.locationGroupProfile;
  }

  @override
  Widget build(BuildContext context) {
    return _scopeSet
        ? InkWell(
            onTap: widget.readOnly
                ? null
                : // if only one project, site group, site, building and location group is available, then do not allow scope change
                (widget.projectList.length == 1 &&
                        _siteGroupProfileList.length == 1 &&
                        _siteProfileList.length == 1 &&
                        _buildingProfileList.length == 1 &&
                        _locationGroupProfileList.length == 1)
                    ? null
                    : () {
                        setState(() {
                          _scopeSet = false;
                        });
                      },
            child: Padding(
              padding: EdgeInsets.zero,
              child: Row(
                children: [
                  WgtProjectLogo(
                    key: _projectLogoKey,
                    onTap: null,
                  ),
                  horizontalSpaceSmall,
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      getProjectSiteStat(),
                      verticalSpaceTiny,
                      _getEffectScopeWidget(),
                    ],
                  ),
                ],
              ),
            ),
          )
        : Row(
            children: [
              getProjectScopeSelector(),
              horizontalSpaceSmall,
              getSiteGroupScopeSelector(),
              horizontalSpaceSmall,
              getSiteScopeSelector(),
              horizontalSpaceSmall,
              getBuildingScopeSelector(),
              horizontalSpaceSmall,
              getLocationGroupScopeSelector(),
              horizontalSpaceSmall,
              if (!_scopeSet)
                ElevatedButton(
                  onPressed: () {
                    // no change
                    if (_selectedProjectProfile ==
                            widget.iniScope.projectProfile &&
                        (_selectedSiteGroupProfile ==
                            widget.iniScope.siteGroupProfile) &&
                        (_selectedSiteProfile == widget.iniScope.siteProfile) &&
                        (_selectedBuildingProfile ==
                            widget.iniScope.buildingProfile) &&
                        (_selectedLocationGroupProfile ==
                            widget.iniScope.locationGroupProfile)) {
                      setState(() {
                        _scopeSet = true;
                      });
                      return;
                    }

                    widget.onChange?.call(
                      _selectedProjectProfile,
                      _selectedSiteGroupProfile,
                      _selectedSiteProfile,
                      _selectedBuildingProfile,
                      _selectedLocationGroupProfile,
                    );

                    _saveScopePref();

                    setState(() {
                      _scopeSet = true;
                    });
                  },
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    backgroundColor:
                        WidgetStateProperty.all(commitColor.withAlpha(200)),
                  ),
                  child: Text('Apply',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)),
                ),
            ],
          );
  }

  Widget getProjectSiteStat() {
    int projectCount = loggedInUser!.getProjectProfileList().length;
    int siteGroupCount = _selectedProjectProfile.getSiteGroupCount();
    int? siteCount = _selectedSiteGroupProfile?.getSiteProfileCount();
    int? buildingCount = _selectedSiteProfile?.buildingProfileList.length;
    int? locationGroupCount =
        _selectedBuildingProfile?.locationGroupProfileList.length;
    // siteProfileList.length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Tooltip(
          message: projectCount == 1
              ? '1 project is setup for the current user'
              : '$projectCount projects are setup for the current user',
          waitDuration: const Duration(milliseconds: 200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Symbols.flag_filled_rounded,
                color: Theme.of(context).hintColor,
                size: 16,
              ),
              // horizontalSpaceTiny,
              const SizedBox(width: 3),
              Text(
                '$projectCount',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).hintColor,
                  height: 0.95,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Tooltip(
            message: siteGroupCount == 1
                ? '1 site group in selected project'
                : '$siteGroupCount site groups in selected project',
            waitDuration: const Duration(milliseconds: 200),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Symbols.workspaces,
                  color: Theme.of(context).hintColor,
                  size: 15,
                ),
                const SizedBox(width: 3),
                Text(
                  '$siteGroupCount',
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).hintColor,
                    height: 0.95,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (siteCount != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Tooltip(
              message: siteCount == 1
                  ? '1 site in selected site group'
                  : '$siteCount sites in selected project',
              waitDuration: const Duration(milliseconds: 200),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Symbols.home_pin,
                    color: Theme.of(context).hintColor,
                    size: 15,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$siteCount',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).hintColor,
                      height: 0.95,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (buildingCount != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Tooltip(
              message: _buildingProfileList.length == 1
                  ? '1 building in selected site'
                  : '${_buildingProfileList.length} buildings in selected site',
              waitDuration: const Duration(milliseconds: 200),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Symbols.domain,
                    color: Theme.of(context).hintColor,
                    size: 15,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${_buildingProfileList.length}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).hintColor,
                      height: 0.95,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (locationGroupCount != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Tooltip(
              message: _locationGroupProfileList.length == 1
                  ? '1 location group in selected building'
                  : '${_locationGroupProfileList.length} location groups in selected building',
              waitDuration: const Duration(milliseconds: 200),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Symbols.group_work,
                    color: Theme.of(context).hintColor,
                    size: 15,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${_locationGroupProfileList.length}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).hintColor,
                      height: 0.95,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget getProjectScopeSelector() {
    return DropdownButton<MdlPagProjectProfile>(
        alignment: AlignmentDirectional.centerEnd,
        hint: Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Text('Project', style: dropDownListHintStyle)),
        value: _selectedProjectProfile,
        // isDense: true,
        // itemHeight: 55,
        focusColor: Theme.of(context).hoverColor,
        underline: dropDownUnderline,
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 21,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        onChanged: (MdlPagProjectProfile? value) async {
          setState(() {
            loggedInUser!
                .updateSelectedScopeByName(value!.name, '', '', '', '');
            _selectedProjectProfile = value;
            _selectedSiteGroupProfile = null;
            _selectedSiteProfile = null;
            _selectedBuildingProfile = null;
            _selectedLocationGroupProfile = null;
            _scopeSet = false;

            _siteGroupProfileList.clear();
            _siteGroupProfileList
                .addAll(_selectedProjectProfile.siteGroupProfileList);
            if (_siteGroupProfileList.length == 1) {
              _selectedSiteGroupProfile = _siteGroupProfileList[0];
              _siteProfileList.clear();
              _siteProfileList
                  .addAll(_selectedSiteGroupProfile!.siteProfileList);
              if (_siteProfileList.length == 1) {
                _selectedSiteProfile = _siteProfileList[0];
              }
            }

            _siteProfileList.clear();
            if (_selectedSiteGroupProfile == null) {
              // _siteProfileList.addAll(_selectedProjectProfile.getAllSiteProfileList());
            } else {
              _siteProfileList
                  .addAll(_selectedSiteGroupProfile!.siteProfileList);
            }
            if (_siteProfileList.length == 1) {
              _selectedSiteProfile = _siteProfileList[0];
            }

            _buildingProfileList.clear();
            if (_selectedSiteProfile == null) {
              // _buildingProfileList.addAll(_selectedSiteGroupProfile!.getAllBuildingProfileList());
            } else {
              _buildingProfileList
                  .addAll(_selectedSiteProfile!.buildingProfileList);
            }
            if (_buildingProfileList.length == 1) {
              _selectedBuildingProfile = _buildingProfileList[0];
            }

            _locationGroupProfileList.clear();
            if (_selectedBuildingProfile == null) {
              // _locationGroupProfileList.addAll(_selectedSiteProfile!.getAllLocationGroupProfileList());
            } else {
              _locationGroupProfileList
                  .addAll(_selectedBuildingProfile!.locationGroupProfileList);
            }
            if (_locationGroupProfileList.length == 1) {
              _selectedLocationGroupProfile = _locationGroupProfileList[0];
            }
          });
        },
        items: widget.projectList.map<DropdownMenuItem<MdlPagProjectProfile>>(
            (MdlPagProjectProfile projectProfile) {
          return DropdownMenuItem<MdlPagProjectProfile>(
            value: projectProfile,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 3.0),
              child: Text(
                projectProfile.label.toUpperCase(),
                style: dropDownListTextStyle,
              ),
            ),
          );
        }).toList());
  }

  Widget getSiteGroupScopeSelector() {
    return DropdownButton<MdlPagSiteGroupProfile>(
        hint: Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Text('Site Group', style: dropDownListHintStyle)),
        value: _selectedSiteGroupProfile,
        // isDense: true,
        // itemHeight: 55,
        focusColor: Theme.of(context).hoverColor,
        underline: dropDownUnderline,
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 21,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        onChanged: (MdlPagSiteGroupProfile? value) async {
          setState(() {
            loggedInUser!.updateSelectedScopeByName(
                _selectedProjectProfile.name, value!.name, '', '', '');
            _selectedSiteGroupProfile = value;
            _selectedSiteProfile = null;
            _selectedBuildingProfile = null;
            _selectedLocationGroupProfile = null;
            _scopeSet = false;

            _siteProfileList.clear();
            _siteProfileList.addAll(_selectedSiteGroupProfile!.siteProfileList);
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
              _locationGroupProfileList
                  .addAll(_selectedBuildingProfile!.locationGroupProfileList);
              if (_locationGroupProfileList.length == 1) {
                _selectedLocationGroupProfile = _locationGroupProfileList[0];
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
                style: dropDownListTextStyle,
              ),
            ),
          );
        }).toList());
  }

  Widget getSiteScopeSelector() {
    return DropdownButton<MdlPagSiteProfile>(
        hint: Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Text('Site ', style: dropDownListHintStyle)),
        value: _selectedSiteProfile,
        // isDense: true,
        // itemHeight: 55,
        focusColor: Theme.of(context).hoverColor,
        underline: dropDownUnderline,
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 21,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        onChanged: (MdlPagSiteProfile? value) async {
          setState(() {
            loggedInUser!.updateSelectedScopeByName(
                _selectedProjectProfile.name,
                _selectedSiteGroupProfile!.name,
                value!.name,
                '',
                '');

            _selectedSiteProfile = value;
            _selectedBuildingProfile = null;
            _selectedLocationGroupProfile = null;
            _scopeSet = false;

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
              _locationGroupProfileList
                  .addAll(_selectedBuildingProfile!.locationGroupProfileList);
              if (_locationGroupProfileList.length == 1) {
                _selectedLocationGroupProfile = _locationGroupProfileList[0];
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
                style: dropDownListTextStyle,
              ),
            ),
          );
        }).toList());
  }

  Widget getBuildingScopeSelector() {
    return DropdownButton<MdlPagBuildingProfile>(
        hint: Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Text('Building', style: dropDownListHintStyle)),
        value: _selectedBuildingProfile,
        // isDense: true,
        // itemHeight: 55,
        focusColor: Theme.of(context).hoverColor,
        underline: dropDownUnderline,
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 21,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        onChanged: (MdlPagBuildingProfile? value) async {
          setState(() {
            loggedInUser!.updateSelectedScopeByName(
                _selectedProjectProfile.name,
                _selectedSiteGroupProfile!.name,
                _selectedSiteProfile!.name,
                value!.name,
                '');

            _selectedBuildingProfile = value;
            _selectedLocationGroupProfile = null;
            _scopeSet = false;

            _locationGroupProfileList.clear();
            if (_selectedBuildingProfile != null) {
              _locationGroupProfileList
                  .addAll(_selectedBuildingProfile!.locationGroupProfileList);
              if (_locationGroupProfileList.length == 1) {
                _selectedLocationGroupProfile = _locationGroupProfileList[0];
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
                style: dropDownListTextStyle,
              ),
            ),
          );
        }).toList());
  }

  Widget getLocationGroupScopeSelector() {
    return DropdownButton<MdlPagLocationGroupProfile>(
        hint: Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Text('Location Group', style: dropDownListHintStyle)),
        value: _selectedLocationGroupProfile,
        // isDense: true,
        // itemHeight: 55,
        focusColor: Theme.of(context).hoverColor,
        underline: dropDownUnderline,
        icon: const Icon(Icons.arrow_drop_down),
        iconSize: 21,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
        onChanged: (MdlPagLocationGroupProfile? value) async {
          setState(() {
            loggedInUser!.updateSelectedScopeByName(
                _selectedProjectProfile.name,
                _selectedSiteGroupProfile!.name,
                _selectedSiteProfile!.name,
                _selectedBuildingProfile!.name,
                value!.name);

            _selectedLocationGroupProfile = value;
            _scopeSet = false;
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
                style: dropDownListTextStyle,
              ),
            ),
          );
        }).toList());
  }
}
