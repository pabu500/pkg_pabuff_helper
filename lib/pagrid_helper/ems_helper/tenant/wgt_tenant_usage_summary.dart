import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../usage/usage_stat_helper.dart';

class WgtTenantUsageSummary extends StatefulWidget {
  const WgtTenantUsageSummary({
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

  @override
  State<WgtTenantUsageSummary> createState() => _WgtTenantUsageSummaryState();
}

class _WgtTenantUsageSummaryState extends State<WgtTenantUsageSummary> {
  double? _netUsageE;
  double? _netUsageW;
  double? _netUsageB;
  double? _netUsageN;
  double? _netUsageG;

  late final double _subUsageE;
  late final double _subUsageW;
  late final double _subUsageB;
  late final double _subUsageN;
  late final double _subUsageG;

  late final double _rateE;
  late final double _rateW;
  late final double _rateB;
  late final double _rateN;
  late final double _rateG;
  late final double _gst;

  double? _costE;
  double? _costW;
  double? _costB;
  double? _costN;
  double? _costG;

  double? _costLineItems;

  late final double _costTotal;

  final List<Map<String, dynamic>> _groupsE = [];
  final List<Map<String, dynamic>> _groupsW = [];
  final List<Map<String, dynamic>> _groupsB = [];
  final List<Map<String, dynamic>> _groupsN = [];
  final List<Map<String, dynamic>> _groupsG = [];

  double _usageFactorE = 1;
  double _usageFactorW = 1;
  double _usageFactorB = 1;
  double _usageFactorN = 1;
  double _usageFactorG = 1;

  String _renderMode = 'wgt'; // wgt, pdf

  // bool _showChart = false;
  void _getRates() {
    String rateEStr = (widget.meterTypeRates['E'] ?? {}).isEmpty
        ? '0'
        : widget.meterTypeRates['E']['result']['rate'] ?? '0';
    _rateE = double.tryParse(rateEStr) ?? 0;

    String rateWStr = (widget.meterTypeRates['W'] ?? {}).isEmpty
        ? '0'
        : widget.meterTypeRates['W']['result']['rate'] ?? '0';
    _rateW = double.tryParse(rateWStr) ?? 0;

    String rateBStr = (widget.meterTypeRates['B'] ?? {}).isEmpty
        ? '0'
        : widget.meterTypeRates['B']['result']['rate'] ?? '0';
    _rateB = double.tryParse(rateBStr) ?? 0;

    String rateNStr = (widget.meterTypeRates['N'] ?? {}).isEmpty
        ? '0'
        : widget.meterTypeRates['N']['result']['rate'] ?? '0';
    _rateN = double.tryParse(rateNStr) ?? 0;
    String rateGStr = (widget.meterTypeRates['G'] ?? {}).isEmpty
        ? '0'
        : widget.meterTypeRates['G']['result']['rate'] ?? '0';
    _rateG = double.tryParse(rateGStr) ?? 0;

    _gst = widget.gst ?? 0;
  }

  void _sortGroups() {
    _groupsE.clear();
    _groupsW.clear();
    _groupsB.clear();
    _groupsN.clear();
    _groupsG.clear();

    for (var item in widget.tenantUsageSummary) {
      switch (item['meter_type']) {
        case 'E':
          _groupsE.add(item);
          break;
        case 'W':
          _groupsW.add(item);
          break;
        case 'B':
          _groupsB.add(item);
          break;
        case 'N':
          _groupsN.add(item);
          break;
        case 'G':
          _groupsG.add(item);
          break;
        default:
      }
    }
  }

  double? _calcGroupUsage(
      List<Map<String, dynamic>> typeGroupList, MeterType meterType) {
    double? usage;
    double usageFactor = getProjectMeterUsageFactor(
        widget.scopeProfile.selectedProjectScope, scopeProfiles, meterType);
    for (var item in typeGroupList) {
      // String groupTeype = item['meter_type'] ?? '';
      // String groupName = item['meter_group_name'] ?? '';
      // String groupLabel = item['meter_group_label'] ?? '';
      final meterGroupUsageSummary = item['meter_group_usage_summary'] ?? [];
      final meterListUsageSummary =
          meterGroupUsageSummary['meter_list_usage_summary'] ?? [];
      for (var meter in meterListUsageSummary) {
        String usageStr = meter['usage'] ?? '';
        double? usageVal = double.tryParse(usageStr);

        usageVal = usageVal == null ? null : usageVal * usageFactor;

        double? percentage = meter['percentage'];

        if (usageVal != null) {
          usage = usage ?? 0;
          if (percentage != null) {
            usage += usageVal * (percentage / 100);
          } else {
            usage += usageVal;
          }
        }
      }
    }
    if (widget.manualUsages.isNotEmpty) {
      String meterTypeTag = getMeterTypeTag(meterType);
      String key = 'manual_usage_${meterTypeTag.toLowerCase()}';
      String manualUsageStr = widget.manualUsages[key] ?? '';
      double? manualUsageVal = double.tryParse(manualUsageStr);
      if (manualUsageVal != null) {
        usage = (usage ?? 0) + manualUsageVal;
      }
    }
    return usage;
  }

  void _calcUsage() {
    _getRates();

    _sortGroups();
    _netUsageE = _calcGroupUsage(_groupsE, MeterType.electricity1p);
    _netUsageW = _calcGroupUsage(_groupsW, MeterType.water);
    _netUsageB = _calcGroupUsage(_groupsB, MeterType.btu);
    _netUsageN = _calcGroupUsage(_groupsN, MeterType.newater);
    _netUsageG = _calcGroupUsage(_groupsG, MeterType.gas);

    _calcSubTenantUsage();

    //sub tenant usage
    if (widget.subTenantListUsageSummary.isNotEmpty) {
      if (_netUsageE != null) {
        _usageFactorE = getProjectMeterUsageFactor(
            widget.scopeProfile.selectedProjectScope,
            scopeProfiles,
            MeterType.electricity1p);
        _netUsageE = _netUsageE! - _subUsageE * _usageFactorE;
      }
      if (_netUsageW != null) {
        _usageFactorW = getProjectMeterUsageFactor(
            widget.scopeProfile.selectedProjectScope,
            scopeProfiles,
            MeterType.water);
        _netUsageW = _netUsageW! - _subUsageW * _usageFactorW;
      }
      if (_netUsageB != null) {
        _usageFactorB = getProjectMeterUsageFactor(
            widget.scopeProfile.selectedProjectScope,
            scopeProfiles,
            MeterType.btu);
        _netUsageB = _netUsageB! - _subUsageB * _usageFactorB;
      }
      if (_netUsageN != null) {
        _usageFactorN = getProjectMeterUsageFactor(
            widget.scopeProfile.selectedProjectScope,
            scopeProfiles,
            MeterType.newater);
        _netUsageN = _netUsageN! - _subUsageN * _usageFactorN;
      }
      if (_netUsageG != null) {
        _usageFactorG = getProjectMeterUsageFactor(
            widget.scopeProfile.selectedProjectScope,
            scopeProfiles,
            MeterType.gas);
        _netUsageG = _netUsageG! - _subUsageG * _usageFactorG;
      }
    }

    if (widget.isBillMode) {
      if (_netUsageE != null) {
        _costE = _netUsageE! * _rateE;
      }
      if (_netUsageW != null) {
        _costW = _netUsageW! * _rateW;
      }
      if (_netUsageB != null) {
        _costB = _netUsageB! * _rateB;
      }
      if (_netUsageN != null) {
        _costN = _netUsageN! * _rateN;
      }
      if (_netUsageG != null) {
        _costG = _netUsageG! * _rateG;
      }
    }
  }

  void _calcLineItems() {
    double? costLineItems;
    for (var lineItem in widget.lineItems) {
      String valueStr = lineItem['amount'] ?? '';
      double? valueVal = double.tryParse(valueStr);
      if (valueVal != null) {
        costLineItems = (costLineItems ?? 0) + valueVal;
      }
    }
    _costLineItems = costLineItems;
  }

  void _calcSubTenantUsage() {
    double subUsageTotalE = 0;
    double subUsageTotalW = 0;
    double subUsageTotalB = 0;
    double subUsageTotalN = 0;
    double subUsageTotalG = 0;

    for (var subTenantUsage in widget.subTenantListUsageSummary) {
      double? subTenantUsageE;
      double? subTenantUsageW;
      double? subTenantUsageB;
      double? subTenantUsageN;
      double? subTenantUsageG;

      String tenantName = subTenantUsage['tenant_name'] ?? '';
      String tenantLabel = subTenantUsage['tenant_label'] ?? '';
      String id = subTenantUsage['id'] ?? '';
      for (var mg in subTenantUsage['tenant_usage_summary']) {
        String meterGroupName = mg['meter_group_name'] ?? '';
        String meterGroupLabel = mg['meter_group_label'] ?? '';
        String meterType = mg['meter_type'] ?? '';
        final meterGroupUsageSummary = mg['meter_group_usage_summary'] ?? [];
        final meterListUsageSummary =
            meterGroupUsageSummary['meter_list_usage_summary'] ?? [];
        for (var meter in meterListUsageSummary) {
          String usageStr = meter['usage'] ?? '';
          double? usageVal = double.tryParse(usageStr);
          double? percentage = meter['percentage'];

          if (usageVal != null) {
            double usage = usageVal * ((percentage ?? 100) / 100);
            switch (meterType) {
              case 'E':
                subTenantUsageE ??= 0;
                subTenantUsageE += usage;
                subUsageTotalE += usage;
                break;
              case 'W':
                subTenantUsageW ??= 0;
                subTenantUsageW += usage;
                subUsageTotalW += usage;
                break;
              case 'B':
                subTenantUsageB ??= 0;
                subTenantUsageB += usage;
                subUsageTotalB += usage;
                break;
              case 'N':
                subTenantUsageN ??= 0;
                subTenantUsageN += usage;
                subUsageTotalN += usage;
                break;
              case 'G':
                subTenantUsageG ??= 0;
                subTenantUsageG += usage;
                subUsageTotalG += usage;
                break;
              default:
            }
          }
        }
      }

      Map<String, double> subTenantUsageType = {};
      if (subTenantUsageE != null) {
        subTenantUsageType['E'] = subTenantUsageE;
      }
      if (subTenantUsageW != null) {
        subTenantUsageType['W'] = subTenantUsageW;
      }
      if (subTenantUsageB != null) {
        subTenantUsageType['B'] = subTenantUsageB;
      }
      if (subTenantUsageN != null) {
        subTenantUsageType['N'] = subTenantUsageN;
      }
      if (subTenantUsageG != null) {
        subTenantUsageType['G'] = subTenantUsageG;
      }
      subTenantUsage['type_usage'] = subTenantUsageType;
    }

    _subUsageE = subUsageTotalE;
    _subUsageW = subUsageTotalW;
    _subUsageB = subUsageTotalB;
    _subUsageN = subUsageTotalN;
    _subUsageG = subUsageTotalG;
  }

  @override
  void initState() {
    super.initState();

    _calcUsage();
    _calcLineItems();

    _renderMode = widget.renderMode;
  }

  @override
  Widget build(BuildContext context) {
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
                    _netUsageE,
                    _costE,
                    _netUsageW,
                    _costW,
                    _netUsageB,
                    _costB,
                    _netUsageN,
                    _costN,
                    _netUsageG,
                    _costG),
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
              getTotal(
                context,
                _costE,
                _costW,
                _costB,
                _costN,
                _costG,
                _costLineItems,
                _gst,
                widget.tenantType,
              ),
          ],
        ),
      ),
    );
  }

  // Widget getUsageTitle() {
  //   String rangeStr = getTimeRangeStr(
  //     widget.fromDatetime,
  //     widget.toDatetime,
  //     targetInterval: widget.isMonthly ? 'monthly' : 'daily',
  //     useMiddle: widget.isMonthly ? true : false,
  //   );
  //   return ConstrainedBox(
  //     constraints: const BoxConstraints(maxWidth: 350),
  //     child: Container(
  //       padding: const EdgeInsets.only(right: 8),
  //       decoration: BoxDecoration(
  //         border: Border(
  //           right: BorderSide(
  //             color: Theme.of(context).hintColor,
  //             width: 1,
  //           ),
  //         ),
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             widget.tenantLabel ?? '',
  //             style: TextStyle(
  //               fontSize: 21,
  //               fontWeight: FontWeight.bold,
  //               color: Theme.of(context).hintColor,
  //             ),
  //           ),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.start,
  //             children: [
  //               Text(
  //                 widget.tenantName,
  //                 style: TextStyle(
  //                   fontSize: 15,
  //                   fontWeight: FontWeight.bold,
  //                   color: Theme.of(context).hintColor.withOpacity(0.7),
  //                 ),
  //               ),
  //               horizontalSpaceRegular,
  //               Text(
  //                 widget.tenantAccountId,
  //                 style: TextStyle(
  //                   fontSize: 15,
  //                   fontWeight: FontWeight.bold,
  //                   color: Theme.of(context).hintColor.withOpacity(0.7),
  //                 ),
  //               ),
  //             ],
  //           ),
  //           verticalSpaceSmall,
  //           Text(
  //             rangeStr,
  //             style: TextStyle(
  //               fontSize: 15,
  //               fontWeight: FontWeight.bold,
  //               color: Theme.of(context).hintColor,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget getUsageTypeStat() {
  //   TextStyle valueStyle = TextStyle(
  //     fontWeight: FontWeight.bold,
  //     fontSize: 34,
  //     color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
  //     // color: Colors.grey.shade800,
  //   );
  //   return Row(
  //     children: [
  //       if (_netUsageE != null)
  //         Padding(
  //           padding: const EdgeInsets.only(left: 13),
  //           child: Column(
  //             children: [
  //               getMeterTypeWidget(MeterType.electricity1p, context),
  //               widget.isBillMode
  //                   ? getStatWithUnit(
  //                       getCommaNumberStr(_costE,
  //                           decimal: /*widget.costDecimals*/ 2),
  //                       'SGD',
  //                       statStrStyle: valueStyle)
  //                   : getStatWithUnit(
  //                       getCommaNumberStr(_netUsageE,
  //                           decimal: widget.usageDecimals),
  //                       getDeivceTypeUnit(MeterType.electricity1p),
  //                       statStrStyle: valueStyle),
  //             ],
  //           ),
  //         ),
  //       if (_netUsageW != null)
  //         Padding(
  //           padding: const EdgeInsets.only(left: 13),
  //           child: Column(
  //             children: [
  //               getMeterTypeWidget(MeterType.water, context),
  //               widget.isBillMode
  //                   ? getStatWithUnit(
  //                       getCommaNumberStr(_costW,
  //                           decimal: /*widget.costDecimals*/ 2),
  //                       'SGD',
  //                       statStrStyle: valueStyle)
  //                   : getStatWithUnit(
  //                       getCommaNumberStr(_netUsageW,
  //                           decimal: widget.usageDecimals),
  //                       getDeivceTypeUnit(MeterType.water),
  //                       statStrStyle: valueStyle),
  //             ],
  //           ),
  //         ),
  //       if (_netUsageB != null)
  //         Padding(
  //           padding: const EdgeInsets.only(left: 13),
  //           child: Column(
  //             children: [
  //               getMeterTypeWidget(MeterType.btu, context),
  //               widget.isBillMode
  //                   ? getStatWithUnit(
  //                       getCommaNumberStr(_costB,
  //                           decimal: /*widget.costDecimals*/ 2),
  //                       'SGD',
  //                       statStrStyle: valueStyle)
  //                   : getStatWithUnit(
  //                       getCommaNumberStr(_netUsageB,
  //                           decimal: widget.usageDecimals),
  //                       getDeivceTypeUnit(MeterType.btu),
  //                       statStrStyle: valueStyle),
  //             ],
  //           ),
  //         ),
  //       if (_netUsageN != null)
  //         Padding(
  //           padding: const EdgeInsets.only(left: 13),
  //           child: Column(
  //             children: [
  //               getMeterTypeWidget(MeterType.newater, context),
  //               widget.isBillMode
  //                   ? getStatWithUnit(
  //                       getCommaNumberStr(_costN,
  //                           decimal: /*widget.costDecimals*/ 2),
  //                       'SGD',
  //                       statStrStyle: valueStyle)
  //                   : getStatWithUnit(
  //                       getCommaNumberStr(_netUsageN,
  //                           decimal: widget.usageDecimals),
  //                       getDeivceTypeUnit(MeterType.newater),
  //                       statStrStyle: valueStyle),
  //             ],
  //           ),
  //         ),
  //       if (_netUsageG != null)
  //         Padding(
  //           padding: const EdgeInsets.only(left: 13),
  //           child: Column(
  //             children: [
  //               getMeterTypeWidget(MeterType.gas, context),
  //               widget.isBillMode
  //                   ? getStatWithUnit(
  //                       getCommaNumberStr(_costG,
  //                           decimal: /*widget.costDecimals*/ 2),
  //                       'SGD',
  //                       statStrStyle: valueStyle)
  //                   : getStatWithUnit(
  //                       getCommaNumberStr(_netUsageG,
  //                           decimal: widget.usageDecimals),
  //                       getDeivceTypeUnit(MeterType.gas),
  //                       statStrStyle: valueStyle),
  //             ],
  //           ),
  //         ),
  //     ],
  //   );
  // }

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
      width: 720,
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
        getMeterStat(meterStat, meterType, false),
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

  Widget getMeterStat(Map<String, dynamic> meterStat, MeterType meterType,
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
        rate: meterType == MeterType.electricity1p
            ? _rateE
            : meterType == MeterType.water
                ? _rateW
                : meterType == MeterType.btu
                    ? _rateB
                    : meterType == MeterType.newater
                        ? _rateN
                        : _rateG,
        statColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        showTrending: false,
        statVirticalStack: false,
        // height: 110,
        usageDecimals: widget.usageDecimals,
        rateDecimals: widget.rateDecimals,
        costDecimals: widget.costDecimals,
        meterType: meterType,
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
                rate: meterType == MeterType.electricity1p
                    ? _rateE
                    : meterType == MeterType.water
                        ? _rateW
                        : meterType == MeterType.btu
                            ? _rateB
                            : meterType == MeterType.newater
                                ? _rateN
                                : _rateG,
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
            // Text(
            //   '${meterType.name}: ${getCommaNumberStr(usageVal, decimal: 2)} ${getDeivceTypeUnit(meterType)}',
            //   style: TextStyle(
            //     fontSize: 15,
            //     color: Theme.of(context).hintColor.withOpacity(0.5),
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
          );
        }
      }
    }
    return SizedBox(
      width: 700,
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
                color:
                    Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
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
          width: 700,
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

  Widget getSubTenantUsage(
      String tenantName, String tenantLabel, Map<String, double> typeUsage) {
    List<Widget> typeUsageList = [];
    for (var usageType in typeUsage.keys) {
      if (typeUsage[usageType] == null) {
        if (kDebugMode) {
          print('typeUsage[usageType] is null');
        }
      }
      typeUsageList.add(getTypeUsageStat(
          context, usageType, typeUsage[usageType]!,
          usageDecimals: widget.usageDecimals,
          rateDecimals: widget.rateDecimals,
          costDecimals: widget.costDecimals,
          isSubTenant: true));
    }

    return SizedBox(
      width: 700,
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
