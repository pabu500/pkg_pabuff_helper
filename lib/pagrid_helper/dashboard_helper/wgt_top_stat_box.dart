import 'package:buff_helper/pagrid_helper/pagrid_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../pkg_buff_helper.dart';

class WgtTopStatBox extends StatefulWidget {
  const WgtTopStatBox({
    super.key,
    required this.appConfig,
    required this.destPortal,
    required this.scopeProfile,
    required this.loggedInUser,
    required this.getStat,
    this.tenantIdStr = '',
    this.statKey,
    this.title = '',
    this.iconSize = 25,
    this.meterType = MeterType.electricity1p,
    this.width = 250,
    this.height = 130,
    this.unitColor,
    this.showScope = false,
    this.iconTextSpacing = 0,
    required this.lookbackType,
    this.mockValueStr,
    this.statType,
    this.adjK = true,
  });

  final PaGridAppConfig appConfig;
  final DestPortal destPortal;
  final Future<dynamic> Function(
      PaGridAppConfig, DestPortal, Map<String, dynamic>, SvcClaim) getStat;
  final ScopeProfile scopeProfile;
  final Evs2User loggedInUser;
  final String tenantIdStr;
  final UniqueKey? statKey;
  final double width;
  final double height;
  final String title;
  final double iconSize;
  final bool adjK;
  // final String value;
  // final String unit;
  final MeterType meterType;
  final Color? unitColor;
  final bool showScope;
  final double iconTextSpacing;
  final LookbackType lookbackType;
  final String? mockValueStr;
  final TopStatType? statType;

  @override
  _WgtTopStatBoxState createState() => _WgtTopStatBoxState();
}

class _WgtTopStatBoxState extends State<WgtTopStatBox> {
  // late ScopeProfile widget.scopeProfile;
  // late Evs2User? _loggedInUser;

  bool _isLoading = false;
  int _pullFails = 0;
  String _errorText = '';

  String _title = '';
  Widget? _infoIcon;
  Widget? _titleWidget;
  double _iconTextSpacing = 8;
  String _statUnit = '';

  String _valueStr = '';
  String _effectiveScopeStr = '';

  String _lookbackLabel = '';

  UniqueKey? _lookbackKey;

  bool _isK = false;

  Future<dynamic> _getStat() async {
    if (widget.statType == TopStatType.activeMeter) {
      return _getActiveMeterCount();
    } else if (widget.statType == TopStatType.meterUsage) {
      return _getRecentUsage();
    } else if (widget.statType == TopStatType.topup) {
      return _getRecentTopupTotal();
    } else if (widget.statType == TopStatType.mmsStat) {
      return _getMmsStatus();
    } else if (widget.statType == TopStatType.commUsage) {
      return _getRecentCommUsage();
    }
  }

  Future<void> _getActiveMeterCount() async {
    int activeMeterCount = 0;
    setState(() {
      _isLoading = true;
      _errorText = '';
    });
    try {
      activeMeterCount = await widget.getStat(
          widget.appConfig,
          widget.destPortal,
          {
            'tenant_id': widget.tenantIdStr,
          },
          SvcClaim(
            userId: widget.loggedInUser.id,
            username: widget.loggedInUser.username,
            scope: AclScope.global.name,
            target: getAclTargetStr(AclTarget.meter_p_info),
            operation: AclOperation.read.name,
          ));
      _valueStr = activeMeterCount.toString();
    } catch (e) {
      _pullFails++;
      if (kDebugMode) {
        print(e);
      }
      if (e.toString().contains('ore') && e.toString().contains('server')) {
        _errorText = 'ORE offline';
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getRecentUsage() async {
    double usage = 0;
    setState(() {
      _isLoading = true;
      _errorText = '';
    });
    Map<String, dynamic> queryMap = {
      'tenant_index': widget.tenantIdStr,
      'meter_type': getMeterTypeTag(widget.meterType),
      'lookback': widget.lookbackType.name,
      'project_scope':
          widget.scopeProfile.selectedProjectScope!.name.toLowerCase(),
      'site_scope': widget.scopeProfile.selectedSiteScope == null
          ? ''
          : widget.scopeProfile.selectedSiteScope!.name,
    };
    try {
      usage = await widget.getStat(
        widget.appConfig,
        widget.destPortal,
        queryMap,
        SvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: widget.scopeProfile.getEffectiveScopeStr(),
          target: getAclTargetStr(AclTarget.meter_p_info),
          operation: AclOperation.read.name,
        ),
        // widget.scopeProfile.selectedProjectScope,
        // widget.scopeProfile.selectedSiteScope,
      );
      double usageFactor = getProjectMeterUsageFactor(
          widget.scopeProfile.selectedProjectScope,
          scopeProfiles,
          widget.meterType);
      usage = usage * usageFactor;

      _valueStr = usage.toStringAsFixed(0);
    } catch (e) {
      _pullFails++;
      if (kDebugMode) {
        print(e);
      }
      String errMsg = e.toString().toLowerCase();
      if (errMsg.contains('type meter group found') ||
          errMsg.contains('type meter group not found')) {
        _valueStr = '--';
      } else if (errMsg.contains('no usage data found')) {
        _valueStr = '-';
      } else {
        if (e.toString().contains('ore') && e.toString().contains('server')) {
          _errorText = 'ORE offline';
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getRecentTopupTotal() async {
    double topupTotal = 0;
    setState(() {
      _isLoading = true;
      _errorText = '';
    });
    try {
      topupTotal = await widget.getStat(
        widget.appConfig,
        widget.destPortal,
        {
          'project_scope': widget.scopeProfile.selectedProjectScope,
          'site_scope': widget.scopeProfile.selectedSiteScope
        },
        SvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: AclScope.global.name,
          target: getAclTargetStr(AclTarget.meter_p_info),
          operation: AclOperation.read.name,
        ),
      );
      _valueStr = topupTotal.toStringAsFixed(0);
    } catch (e) {
      _pullFails++;
      if (kDebugMode) {
        print(e);
      }
      if (e.toString().contains('ore') && e.toString().contains('server')) {
        _errorText = 'ORE offline';
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getMmsStatus() async {
    Map<String, dynamic> mmsStatus = {};
    setState(() {
      _isLoading = true;
      _errorText = '';
    });
    try {
      mmsStatus = await widget.getStat(
          widget.appConfig,
          widget.destPortal,
          {},
          SvcClaim(
            userId: widget.loggedInUser.id,
            username: widget.loggedInUser.username,
            scope: AclScope.global.name,
            target: getAclTargetStr(AclTarget.meter_p_info),
            operation: AclOperation.read.name,
          ));
      int? onlineCount = mmsStatus['online'];
      _valueStr = onlineCount == null ? '--' : onlineCount.toString();
    } catch (e) {
      _pullFails++;
      if (kDebugMode) {
        print(e);
      }
      if (e.toString().contains('ore') && e.toString().contains('server')) {
        _errorText = 'ORE offline';
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getRecentCommUsage() async {
    double commUsage = 0;
    setState(() {
      _isLoading = true;
      _errorText = '';
    });
    try {
      commUsage = await widget.getStat(
        widget.appConfig,
        widget.destPortal,
        {},
        SvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: AclScope.global.name,
          target: getAclTargetStr(AclTarget.meter_p_info),
          operation: AclOperation.read.name,
        ),
      );
      _valueStr = commUsage.toStringAsFixed(1);
    } catch (e) {
      _pullFails++;
      if (kDebugMode) {
        print(e);
      }
      if (e.toString().contains('ore') && e.toString().contains('server')) {
        _errorText = 'ORE offline';
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateTitle() {
    _lookbackLabel = getLookbackTypeLabel(widget.lookbackType);

    if (widget.statType == TopStatType.activeMeter) {
      _title = '$_lookbackLabel Active Meters';
      _iconTextSpacing = 8;
      _statUnit = '';
    } else if (widget.statType == TopStatType.meterUsage) {
      String deviceTypeLabel = getDeivceTypeLabel(widget.meterType);
      if (deviceTypeLabel == 'Electricity' ||
          deviceTypeLabel == 'Electricity 3P') {
        deviceTypeLabel = 'E';
      }
      _title = '$_lookbackLabel $deviceTypeLabel Usage';
      _iconTextSpacing = 8;
      if (_isK) {
        _statUnit = getDeivceTypeUnitK(widget.meterType);
      } else {
        _statUnit = getDeivceTypeUnit(widget.meterType);
      }
    } else if (widget.statType == TopStatType.topup) {
      _title = '$_lookbackLabel Topup Total';
      _iconTextSpacing = 8;
      _statUnit = 'SGD';
    } else if (widget.statType == TopStatType.mmsStat) {
      _title = 'MMS Online';
      _iconTextSpacing = 8;
      _statUnit = '';
    } else if (widget.statType == TopStatType.commUsage) {
      _title = '$_lookbackLabel Comm Usage';
      _iconTextSpacing = 8;
      _statUnit = 'MB';
    } else {
      _title = widget.title;
      _iconTextSpacing = widget.iconTextSpacing;
      if (_isK) {
        _statUnit = getDeivceTypeUnitK(widget.meterType);
      } else {
        _statUnit = getDeivceTypeUnit(widget.meterType);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    String effectiveScopeStr = widget.scopeProfile.getEffectiveScopeStr();
    if (effectiveScopeStr != _effectiveScopeStr) {
      _effectiveScopeStr = effectiveScopeStr;
    }
    _pullFails = 0;

    _updateTitle();
  }

  @override
  Widget build(BuildContext context) {
    String valueStr = widget.mockValueStr ?? _valueStr;
    if (widget.mockValueStr == null && '--' != valueStr && '-' != valueStr) {
      double value = double.tryParse(valueStr) ?? 0;
      if (widget.adjK) {
        if (value > 1000000) {
          _isK = true;
          value = value / 1000;
          valueStr = getCommaNumberStr(value);
        } else {
          _isK = false;
        }
      }
      valueStr = getCommaNumberStr(value);
    }

    if (widget.statKey != null) {
      if (_lookbackKey != widget.statKey) {
        _lookbackKey = widget.statKey as UniqueKey;
        _lookbackLabel = getLookbackTypeLabel(widget.lookbackType);
        _valueStr = '';
      }
    }

    _updateTitle();

    if (widget.statType != null) {
      if (widget.statType == TopStatType.activeMeter) {
        _infoIcon = const Icon(
          Icons.electric_meter,
          color: Colors.lightGreenAccent,
        );
      } else if (widget.statType == TopStatType.meterUsage) {
        _infoIcon = getDeviceTypeIcon(widget.meterType);
        if (widget.appConfig.activePortalProjectScope == ProjectScope.SG_ALL) {
          _infoIcon = const Icon(
            Icons.bolt,
            color: Colors.lightGreenAccent,
          );
        }
      } else if (widget.statType == TopStatType.topup) {
        _infoIcon = const Icon(
          Icons.attach_money,
          color: Colors.lightGreenAccent,
        );
      } else if (widget.statType == TopStatType.mmsStat) {
        _infoIcon = const Icon(
          Icons.electric_meter,
          color: Colors.lightGreenAccent,
        );
      } else if (widget.statType == TopStatType.commUsage) {
        _infoIcon = const Icon(
          Icons.signal_cellular_alt,
          color: Colors.lightGreenAccent,
        );
      }
    }

    bool pullData = false;
    if (widget.statType != null) {
      if (_valueStr.isEmpty) {
        pullData = true;
      }
    }
    // if (_pullFails >= 5) {
    //   if (kDebugMode) {
    //     print('top stat box: pull fails more than $_pullFails times');
    //   }
    //   pullData = false;
    //   return getErrorTextPrompt(
    //       context: context, errorText: 'Error getting stat');
    // }

    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.76),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 5,
            offset: const Offset(1, 3), // changes position of shadow
          ),
        ],
      ),
      child: Tooltip(
        message: '',
        waitDuration: const Duration(milliseconds: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 13),
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _title,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                  if (_title.isNotEmpty) horizontalSpaceSmall,
                  if (_statUnit.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: _statUnit.contains('MWh')
                            ? Colors.yellowAccent.shade100.withOpacity(0.8)
                            : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                      child: Text(
                        _statUnit,
                        style: TextStyle(
                            color: widget.unitColor ??
                                Theme.of(context).colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    )
                ],
              ),
            ),
            Center(
              child: SizedBox(
                height: 50,
                child: _pullFails > 5
                    ? Center(
                        child: getErrorTextPrompt(
                            context: context, errorText: 'Error getting stat'),
                      )
                    : Transform.translate(
                        // offset: const Offset(-13, 0),
                        offset: const Offset(-5, 0),
                        child: pullData
                            ? FutureBuilder(
                                future: _getStat(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<dynamic> snapshot) {
                                  switch (snapshot.connectionState) {
                                    case ConnectionState.waiting:
                                      return Align(
                                        alignment: Alignment.center,
                                        child: xtWait(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      );
                                    default:
                                      if (snapshot.hasError) {
                                        return const Center(
                                            child: Text('Error loading data'));
                                      } else {
                                        return getStatInfo(valueStr);
                                      }
                                  }
                                },
                              )
                            : getStatInfo(valueStr),
                      ),
              ),
            ),
            Expanded(child: Container()),
            if (widget.showScope)
              _effectiveScopeStr == 'SG_ALL'
                  ? const SizedBox.shrink()
                  : getEffectiveScopeTag(context, _effectiveScopeStr)
          ],
        ),
      ),
    );
  }

  Widget getStatInfo(String valueStr) {
    return xtInfoBox(
      icon: _infoIcon ??
          getDeviceTypeIcon(
            widget.meterType,
            iconSize: widget.iconSize,
          ),
      padding: const EdgeInsets.all(0),
      iconTextSpace: _iconTextSpacing,
      isSelectable: true,
      iconOffset: 5,
      text: valueStr,
      //  widget.value.toStringAsFixed(widget.decimal),
      textStyle: const TextStyle(
          color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
      // superText: theUnit,
      // superTextStyle: TextStyle(
      //     color: unitColor,
      //     fontSize: 13,
      //     fontWeight: FontWeight.w500),
    );
  }
}
