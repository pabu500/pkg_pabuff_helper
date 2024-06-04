import 'package:buff_helper/pagrid_helper/ems_helper/tenant/usage_calc.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../usage/usage_stat_helper.dart';

class WgtTenantUsageSummary2 extends StatefulWidget {
  const WgtTenantUsageSummary2({
    super.key,
    required this.scopeProfile,
    required this.loggedInUser,
    required this.activePortalProjectScope,
    required this.itemType,
    required this.isMonthly,
    required this.fromDatetime,
    required this.toDatetime,
    required this.tenantName,
    required this.tenantType,
    required this.excludeAutoUsage,
    this.renderMode = 'wgt', // wgt, pdf
    this.showRenderModeSwitch = false,
    this.tenantLabel,
    this.tenantAccountId = '',
    this.tenantUsageSummary = const [],
    this.subTenantListUsageSummary = const [],
    this.isBillMode = false,
    this.meterTypeRates = const {},
    this.gst,
    this.manualUsages = const {},
    this.lineItems = const [],
    // this.billedAutoUsages = const {},
    this.usageDecimals = 3,
    this.rateDecimals = 4,
    this.costDecimals = 3,
    this.usageFactor,
  });

  final ScopeProfile scopeProfile;
  final Evs2User loggedInUser;
  final ProjectScope activePortalProjectScope;
  final ItemType itemType;
  final bool isMonthly;
  final DateTime fromDatetime;
  final DateTime toDatetime;
  final String tenantName;
  final String? tenantLabel;
  final String tenantAccountId;
  final String tenantType;
  final bool excludeAutoUsage;
  final List<Map<String, dynamic>> tenantUsageSummary;
  final List<Map<String, dynamic>> subTenantListUsageSummary;
  final bool isBillMode;
  final Map<String, dynamic> meterTypeRates;
  final double? gst;
  final Map<String, dynamic> manualUsages;
  final List<Map<String, dynamic>> lineItems;
  final String renderMode;
  final bool showRenderModeSwitch;
  // final Map<String, dynamic> billedAutoUsages;
  final int usageDecimals;
  final int rateDecimals;
  final int costDecimals;
  final Map<String, dynamic>? usageFactor;

  @override
  State<WgtTenantUsageSummary2> createState() => _WgtTenantUsageSummary2State();
}

class _WgtTenantUsageSummary2State extends State<WgtTenantUsageSummary2> {
  final double widgetWidth = 750;

  final List<String> _meterTypes = ['E', 'W', 'B', 'N', 'G'];

  final Map<String, dynamic> _usageFactor = {};
  final Map<String, dynamic> _typeRates = {};

  final List<Map<String, dynamic>> _manualUsageList = [];
  final List<Map<String, dynamic>> _lineItemList = [];

  late final EmsTypeUsageCalc _emsTypeUsageCalc;

  // double? _netUsageE;
  // double? _netUsageW;
  // double? _netUsageB;
  // double? _netUsageN;
  // double? _netUsageG;

  // late final double _subUsageE;
  // late final double _subUsageW;
  // late final double _subUsageB;
  // late final double _subUsageN;
  // late final double _subUsageG;

  // late final double _rateE;
  // late final double _rateW;
  // late final double _rateB;
  // late final double _rateN;
  // late final double _rateG;
  // late final double _gst;

  // double? _costE;
  // double? _costW;
  // double? _costB;
  // double? _costN;
  // double? _costG;

  // double? _costLineItems;

  // late final double _costTotal;

  // final List<Map<String, dynamic>> _groupsE = [];
  // final List<Map<String, dynamic>> _groupsW = [];
  // final List<Map<String, dynamic>> _groupsB = [];
  // final List<Map<String, dynamic>> _groupsN = [];
  // final List<Map<String, dynamic>> _groupsG = [];

  // double? _usageFactorE;
  // double? _usageFactorW;
  // double? _usageFactorB;
  // double? _usageFactorN;
  // double? _usageFactorG;

  String _renderMode = 'wgt'; // wgt, pdf

  bool _gettingUsageFactor = false;
  int _pullFailed = 0;

  Future<dynamic> _getUsageFactor() async {
    if (widget.usageFactor != null) {
      for (var type in _meterTypes) {
        _usageFactor[type] = widget.usageFactor!['usage_factor_$type'];
      }
      return;
    }

    setState(() {
      _gettingUsageFactor = true;
    });
    try {
      final usageFactorListReuslt = await getUsageFactor(
        widget.activePortalProjectScope,
        {
          'scope_str': widget.scopeProfile.getEffectiveScopeStr().toLowerCase(),
          'from_timestamp': widget.fromDatetime.toIso8601String(),
          'to_timestamp': widget.toDatetime.toIso8601String(),
        },
        SvcClaim(
          scope: AclScope.global.name,
          target: getAclTargetStr(AclTarget.bill_p_info),
          operation: AclOperation.read.name,
        ),
      );

      for (var usageFactor in usageFactorListReuslt['usage_factor_list']) {
        String type = usageFactor['meter_type'] ?? '';
        double? factor = double.tryParse(usageFactor['usage_factor'] ?? '');
        if (factor != null) {
          usageFactor[type] = factor;
        }
      }
    } catch (e) {
      _pullFailed++;
      if (kDebugMode) {
        print('Error: $e');
      }
    } finally {
      setState(() {
        _gettingUsageFactor = false;
      });
    }
  }

  void _sortManualUsage() {
    _manualUsageList.clear();
    for (var key in widget.manualUsages.keys) {
      String usageStr = widget.manualUsages[key] ?? '';
      double? usageVal = double.tryParse(usageStr);
      if (usageVal != null) {
        _manualUsageList.add({
          'meter_type': key.split('_').last,
          'usage': usageVal,
        });
      }
    }
  }

  void _sortRates() {
    for (var type in _meterTypes) {
      if (widget.meterTypeRates[type] == null) {
        continue;
      }
      String rateStr = widget.meterTypeRates[type]['result']['rate'] ?? '0';
      double? rateVal = double.tryParse(rateStr);
      if (rateVal != null) {
        _typeRates[type] = rateVal;
      }
    }
  }

  void _sortLineItems() {
    _lineItemList.clear();

    for (var lineItem in widget.lineItems) {
      String valueStr = lineItem['amount'] ?? '';
      double? valueVal = double.tryParse(valueStr);
      if (valueVal != null) {
        lineItem['amount'] = valueVal;
      }
      _lineItemList.add(lineItem);
    }
  }

  @override
  void initState() {
    super.initState();
    _renderMode = widget.renderMode;
    // _calcUsage();
    // _calcLineItems();

    _sortRates();
    _sortManualUsage();

    _emsTypeUsageCalc = EmsTypeUsageCalc(
      gst: widget.gst!,
      typeRates: _typeRates,
      usageFactor: _usageFactor,
      autoUsageSummary: widget.tenantUsageSummary,
      subTenantUsageSummary: widget.subTenantListUsageSummary,
      manualUsageList: _manualUsageList,
      lineItemList: widget.lineItems,
    );
    _emsTypeUsageCalc.doCalc();
  }

  @override
  Widget build(BuildContext context) {
    if (_pullFailed > 3) {
      return getErrorTextPrompt(
          context: context, errorText: 'Failed to get usage factor');
    }

    return _usageFactor.isEmpty && !_gettingUsageFactor
        ? FutureBuilder(
            future: _getUsageFactor(),
            builder: (context, snapshot) {
              if (_gettingUsageFactor) {
                return Center(
                  child: xtWait(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
              return completedWidget();
            },
          )
        : completedWidget();
  }

  Widget completedWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 13),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).hintColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // getUsageTitle(),
                // getUsageTypeStat(),
                getUsageTitle(
                  context,
                  widget.fromDatetime,
                  widget.toDatetime,
                  widget.isMonthly,
                  widget.tenantLabel,
                  widget.tenantName,
                  widget.tenantAccountId,
                ),
                getUsageTypeStat(
                  context,
                  widget.isBillMode,
                  _emsTypeUsageCalc.typeUsageE.usage,
                  _emsTypeUsageCalc.typeUsageE.cost,
                  _emsTypeUsageCalc.typeUsageW.usage,
                  _emsTypeUsageCalc.typeUsageW.cost,
                  _emsTypeUsageCalc.typeUsageB.usage,
                  _emsTypeUsageCalc.typeUsageB.cost,
                  _emsTypeUsageCalc.typeUsageN.usage,
                  _emsTypeUsageCalc.typeUsageN.cost,
                  _emsTypeUsageCalc.typeUsageG.usage,
                  _emsTypeUsageCalc.typeUsageG.cost,
                ),
              ],
            ),
            Divider(color: Theme.of(context).hintColor),
            if (!widget.excludeAutoUsage) ...getStat(),
            if (widget.excludeAutoUsage) getAutoUsageExcludedInfo(context),
            verticalSpaceSmall,
            getManualUsage(),
            verticalSpaceSmall,
            getSubTenantUsageList(),
            verticalSpaceSmall,
            verticalSpaceSmall,
            getLineItem(),
            verticalSpaceSmall,
            if (widget.isBillMode)
              getTotal2(
                context,
                _emsTypeUsageCalc.gst,
                _emsTypeUsageCalc.subTotalCost,
                _emsTypeUsageCalc.gstAmount!,
                _emsTypeUsageCalc.totalCost!,
                widget.tenantType,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> getStat() {
    List<Widget> typeStat = [];

    typeStat.add(getTypeStat('E'));
    typeStat.add(getTypeStat('W'));
    typeStat.add(getTypeStat('B'));
    typeStat.add(getTypeStat('N'));
    typeStat.add(getTypeStat('G'));

    return typeStat;
  }

  Widget getTypeStat(String typeStr) {
    List<Widget> typeGroups = [];
    List<Map<String, dynamic>> typeGroupInfoList = [];
    typeGroupInfoList = widget.tenantUsageSummary
        .where((element) => element['meter_type'] == typeStr)
        .toList();
    for (var groupInfo in typeGroupInfoList) {
      String meterTypeTag = groupInfo['meter_type'] ?? '';
      MeterType? meterType = getMeterType(meterTypeTag);
      typeGroups.add(getGroupMeterStat(groupInfo, meterType));
    }
    return SizedBox(
      width: widgetWidth,
      child: Column(
        children: [...typeGroups],
      ),
    );
  }

  Widget getGroupMeterStat(
      Map<String, dynamic> groupInfo, MeterType? meterType) {
    String groupType = groupInfo['meter_type'] ?? '';
    MeterType? meterType = getMeterType(groupType);
    if (meterType == null) {
      return Container();
    }
    String groupName = groupInfo['meter_group_name'] ?? '';
    String groupLabel = groupInfo['meter_group_label'] ?? '';
    final meterGroupUsageSummary = groupInfo['meter_group_usage_summary'] ?? [];
    final meterListUsageSummary =
        meterGroupUsageSummary['meter_list_usage_summary'] ?? [];

    List<Widget> meterList = [];
    List<Map<String, dynamic>> meterStatList = [];

    double usageFactor = getProjectMeterUsageFactor(
        widget.scopeProfile.selectedProjectScope, scopeProfiles, meterType);
    for (var meterStat in meterListUsageSummary) {
      String usageStr = meterStat['usage'] ?? '';
      double? usageVal = double.tryParse(usageStr);
      if (usageVal != null) {
        usageVal = usageVal * usageFactor;
        meterStat['usage_factored'] = usageVal.toString();
        meterStat['factor'] = usageFactor;
      }

      meterStatList.add(meterStat);
      meterList.add(
        getMeterStat(meterStat, groupType, false),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        verticalSpaceSmall,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
                onTap: () {
                  setState(() {
                    groupInfo['showChart'] = !(groupInfo['showChart'] ?? false);
                  });
                },
                child: Icon(Symbols.analytics,
                    size: 21, color: Theme.of(context).colorScheme.primary)),
            horizontalSpaceTiny,
            Text(groupName,
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).hintColor.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
        // verticalSpaceTiny,
        Text(groupLabel,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).hintColor.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            )),
        if (groupInfo['showChart'] ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: WgtMeterGroupStatCore(
              loggedInUser: widget.loggedInUser,
              scopeProfile: widget.scopeProfile,
              activePortalProjectScope: widget.activePortalProjectScope,
              statColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              itemType: widget.itemType,
              meterType: meterType,
              meterIdType: ItemIdType.name,
              meterIdFieldKey: 'item_name',
              groupId: groupName,
              selectedMeterStat: meterStatList,
              isMonthly: widget.isMonthly,
              startDateTime: widget.fromDatetime,
              endDateTime: widget.toDatetime,
              decimals: 2,
            ),
          ),
        // verticalSpaceTiny,
        ...meterList
      ],
    );
  }

  Widget getMeterStat(Map<String, dynamic> meterStat, String meterTypeTag,
      bool calcUsageFromReadings) {
    String meterName = meterStat['item_name'];
    String meterSn = meterStat['item_sn'];
    String altName = meterStat['alt_name'];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: WgtUsageStatCore(
        loggedInUser: widget.loggedInUser,
        scopeProfile: widget.scopeProfile,
        calcUsageFromReadings: calcUsageFromReadings,
        activePortalProjectScope: widget.activePortalProjectScope,
        isBillMode: widget.isBillMode,
        rate: _typeRates[meterTypeTag] ?? 0,
        statColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        showTrending: false,
        statVirticalStack: false,
        // height: 110,
        usageDecimals: widget.usageDecimals,
        rateDecimals: widget.rateDecimals,
        costDecimals: widget.costDecimals,
        meterType: getMeterType(meterTypeTag)!,
        meterId: meterName,
        meterIdType: ItemIdType.name,
        itemType: widget.itemType,
        historyType: Evs2HistoryType.meter_list_usage_summary,
        meterStat: meterStat,
      ),
    );
  }

  Widget getManualUsage() {
    if (widget.manualUsages.isEmpty) {
      return Container();
    }
    List<Widget> manualUsageList = [];
    for (var key in widget.manualUsages.keys) {
      String usageStr = widget.manualUsages[key] ?? '';
      double? usageVal = double.tryParse(usageStr);
      String meterTypeTag = key.split('_').last;
      if (usageVal != null) {
        MeterType? meterType = getMeterType(meterTypeTag);
        if (meterType != null) {
          manualUsageList.add(
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: WgtUsageStatCore(
                loggedInUser: widget.loggedInUser,
                scopeProfile: widget.scopeProfile,
                activePortalProjectScope: widget.activePortalProjectScope,
                isBillMode: widget.isBillMode,
                rate: _typeRates[meterTypeTag] ?? 0,
                statColor:
                    Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                showTrending: false,
                statVirticalStack: false,
                height: 110,
                usageDecimals: widget.usageDecimals,
                rateDecimals: widget.rateDecimals,
                costDecimals: widget.costDecimals,
                meterType: meterType,
                meterId: ' (m.)',
                meterIdType: ItemIdType.name,
                itemType: widget.itemType,
                historyType: Evs2HistoryType.meter_list_usage_summary,
                isStaticUsageStat: true,
                meterStat: {'usage': usageStr},
              ),
            ),
          );
        }
      }
    }
    return SizedBox(
      width: widgetWidth,
      child: Column(
        children: [
          verticalSpaceSmall,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.edit,
                  size: 21, color: Theme.of(context).colorScheme.primary),
              horizontalSpaceTiny,
              Text('Manual Usage',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).hintColor.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          ...manualUsageList,
        ],
      ),
    );
  }

  Widget getLineItem() {
    if (widget.lineItems.isEmpty) {
      return Container();
    }
    if (widget.lineItems.first.isEmpty) {
      return Container();
    }
    List<Widget> lineItemList = [];
    for (var lineItem in widget.lineItems) {
      String label = lineItem['label'] ?? '';
      String valueStr = lineItem['amount'] ?? '';
      double? valueVal = double.tryParse(valueStr) ?? 0;
      lineItemList.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 210,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).hintColor.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            horizontalSpaceSmall,
            getStatWithUnit(
              getCommaNumberStr(valueVal, decimal: 2),
              'SGD',
              statStrStyle: defStatStyle.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.edit,
                size: 21, color: Theme.of(context).colorScheme.primary),
            horizontalSpaceTiny,
            Text(
              'Line Item',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).hintColor.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        verticalSpaceSmall,
        Container(
          width: widgetWidth,
          padding: const EdgeInsets.symmetric(horizontal: 3),
          constraints: const BoxConstraints(
            maxHeight: 55,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade600, width: 1),
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...lineItemList,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget getSubTenantUsageList() {
    List<Widget> subTenantUsageList = [];
    for (var subTenantUsage in widget.subTenantListUsageSummary) {
      String tenantName = subTenantUsage['tenant_name'] ?? '';
      String tenantLabel = subTenantUsage['tenant_label'] ?? '';

      subTenantUsageList.add(
        getSubTenantUsage(
          tenantName,
          tenantLabel,
          subTenantUsage['type_usage'] ?? {},
        ),
      );
    }
    return Column(
      children: [...subTenantUsageList],
    );
  }

  // widget only, no calculation
  Widget getSubTenantUsage(
      String tenantName, String tenantLabel, Map<String, double> typeUsage) {
    List<Widget> typeUsageList = [];
    Map<String, double> usage = {};
    for (var usageTypeTag in typeUsage.keys) {
      if (typeUsage[usageTypeTag] == null) {
        if (kDebugMode) {
          print('typeUsage[usageType] is null');
        }
      } else {
        double usageVal = typeUsage[usageTypeTag] as double;
        double usageFactor = getProjectMeterUsageFactor(
            widget.scopeProfile.selectedProjectScope,
            scopeProfiles,
            getMeterType(usageTypeTag));
        usage['usage_factored'] = usageVal;
        usage['factor'] = usageFactor;
      }
      typeUsageList.add(
        getTypeUsageStat(context, usageTypeTag, usage,
            usageDecimals: widget.usageDecimals,
            rateDecimals: widget.rateDecimals,
            costDecimals: widget.costDecimals,
            isSubTenant: true),
      );
    }

    return SizedBox(
      width: widgetWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          verticalSpaceSmall,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.group,
                  size: 21, color: Theme.of(context).colorScheme.primary),
              horizontalSpaceTiny,
              Text(tenantLabel,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).hintColor.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          ...typeUsageList,
        ],
      ),
    );
  }
}
