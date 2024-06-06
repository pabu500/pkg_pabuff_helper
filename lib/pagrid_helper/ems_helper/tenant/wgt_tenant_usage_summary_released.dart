import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_helper/pagrid_app_config.dart';
import '../usage/usage_stat_helper.dart';

class WgtTenantUsageSummaryReleased extends StatefulWidget {
  const WgtTenantUsageSummaryReleased({
    super.key,
    required this.scopeProfile,
    required this.loggedInUser,
    required this.appConfig,
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
    this.isBillMode = false,
    this.meterTypeRates = const {},
    this.gst,
    this.manualUsages = const {},
    this.lineItems = const [],
    this.billedAutoUsages = const {},
    this.billedSubTenantUsages = const {},
    required this.billedUsageFactor,
    this.usageDecimals = 3,
    this.rateDecimals = 4,
    this.costDecimals = 3,
  });

  final Map<String, dynamic> billedUsageFactor;
  final ScopeProfile scopeProfile;
  final Evs2User loggedInUser;
  final PaGridAppConfig appConfig;
  final ItemType itemType;
  final bool isMonthly;
  final DateTime fromDatetime;
  final DateTime toDatetime;
  final String tenantName;
  final String tenantAccountId;
  final String? tenantLabel;
  final String tenantType;
  final bool excludeAutoUsage;
  final bool isBillMode;
  final Map<String, dynamic> meterTypeRates;
  final double? gst;
  final Map<String, dynamic> manualUsages;
  final List<Map<String, dynamic>> lineItems;
  final String renderMode;
  final bool showRenderModeSwitch;
  final Map<String, dynamic> billedAutoUsages;
  final Map<String, dynamic> billedSubTenantUsages;
  final int usageDecimals;
  final int rateDecimals;
  final int costDecimals;

  @override
  State<WgtTenantUsageSummaryReleased> createState() =>
      _WgtTenantUsageSummaryReleasedState();
}

class _WgtTenantUsageSummaryReleasedState
    extends State<WgtTenantUsageSummaryReleased> {
  final widgetWidth = 750.0;

  double? _netUsageE;
  double? _netUsageW;
  double? _netUsageB;
  double? _netUsageN;
  double? _netUsageG;

  late double? _autoUsageE;
  late double? _autoUsageW;
  late double? _autoUsageB;
  late double? _autoUsageN;
  late double? _autoUsageG;

  late double? _manualUsageE;
  late double? _manualUsageW;
  late double? _manualUsageB;
  late double? _manualUsageN;
  late double? _manualUsageG;

  late final double? _subTenantUsageE;
  late final double? _subTenantUsageW;
  late final double? _subTenantUsageB;
  late final double? _subTenantUsageN;
  late final double? _subTenantUsageG;

  late final double _billedUsageFactorE;
  late final double _billedUsageFactorW;
  late final double _billedUsageFactorB;
  late final double _billedUsageFactorN;
  late final double _billedUsageFactorG;

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

  String _renderMode = 'wgt'; // wgt, pdf

  void _getBilledRates() {
    String rateEStr = (widget.meterTypeRates['E'] ?? {}).isEmpty
        ? '0'
        : widget.meterTypeRates['E'] ?? '0';
    _rateE = double.tryParse(rateEStr) ?? 0;

    String rateWStr = (widget.meterTypeRates['W'] ?? {}).isEmpty
        ? '0'
        : widget.meterTypeRates['W'] ?? '0';
    _rateW = double.tryParse(rateWStr) ?? 0;

    String rateBStr = (widget.meterTypeRates['B'] ?? {}).isEmpty
        ? '0'
        : widget.meterTypeRates['B'] ?? '0';
    _rateB = double.tryParse(rateBStr) ?? 0;

    String rateNStr = (widget.meterTypeRates['N'] ?? {}).isEmpty
        ? '0'
        : widget.meterTypeRates['N'] ?? '0';
    _rateN = double.tryParse(rateNStr) ?? 0;
    String rateGStr = (widget.meterTypeRates['G'] ?? {}).isEmpty
        ? '0'
        : widget.meterTypeRates['G'] ?? '0';
    _rateG = double.tryParse(rateGStr) ?? 0;

    _gst = widget.gst ?? 0;
  }

  void _calcUsage() {
    _getBilledRates();

    //auto usage
    if (widget.billedAutoUsages.isNotEmpty) {
      _autoUsageE =
          double.tryParse(widget.billedAutoUsages['billed_auto_usage_e'] ?? '');
      if (_autoUsageE != null) {
        _netUsageE = _autoUsageE;
      }
      _autoUsageW =
          double.tryParse(widget.billedAutoUsages['billed_auto_usage_w'] ?? '');
      if (_autoUsageW != null) {
        _netUsageW = _autoUsageW;
      }
      _autoUsageB =
          double.tryParse(widget.billedAutoUsages['billed_auto_usage_b'] ?? '');
      if (_autoUsageB != null) {
        _netUsageB = _autoUsageB;
      }
      _autoUsageN =
          double.tryParse(widget.billedAutoUsages['billed_auto_usage_n'] ?? '');
      if (_autoUsageN != null) {
        _netUsageN = _autoUsageN;
      }
      _autoUsageG =
          double.tryParse(widget.billedAutoUsages['billed_auto_usage_g'] ?? '');
      if (_autoUsageG != null) {
        _netUsageG = _autoUsageG;
      }
    }
    //sub tenant usage
    if (widget.billedSubTenantUsages.isNotEmpty) {
      _subTenantUsageE = double.tryParse(
          widget.billedSubTenantUsages['billed_sub_tenant_usage_e'] ?? '');
      if (_subTenantUsageE != null) {
        if (_netUsageE != null) {
          _netUsageE = _netUsageE! - _subTenantUsageE;
        }
      }
      _subTenantUsageW = double.tryParse(
          widget.billedSubTenantUsages['billed_sub_tenant_usage_w'] ?? '');
      if (_subTenantUsageW != null) {
        if (_netUsageW != null) {
          _netUsageW = _netUsageW! - _subTenantUsageW;
        }
      }
      _subTenantUsageB = double.tryParse(
          widget.billedSubTenantUsages['billed_sub_tenant_usage_b'] ?? '');
      if (_subTenantUsageB != null) {
        if (_netUsageB != null) {
          _netUsageB = _netUsageB! - _subTenantUsageB;
        }
      }
      _subTenantUsageN = double.tryParse(
          widget.billedSubTenantUsages['billed_sub_tenant_usage_n'] ?? '');
      if (_subTenantUsageN != null) {
        if (_netUsageN != null) {
          _netUsageN = _netUsageN! - _subTenantUsageN;
        }
      }
      _subTenantUsageG = double.tryParse(
          widget.billedSubTenantUsages['billed_sub_tenant_usage_g'] ?? '');
      if (_subTenantUsageG != null) {
        if (_netUsageG != null) {
          _netUsageG = _netUsageG! - _subTenantUsageG;
        }
      }
    }

    //manual usage
    if (widget.manualUsages.isNotEmpty) {
      _manualUsageE =
          double.tryParse(widget.manualUsages['manual_usage_e'] ?? '');
      if (_manualUsageE != null) {
        if (_netUsageE != null) {
          _netUsageE = _netUsageE! + _manualUsageE!;
        } else {
          _netUsageE = _manualUsageE;
        }
      }
      _manualUsageW =
          double.tryParse(widget.manualUsages['manual_usage_w'] ?? '');
      if (_manualUsageW != null) {
        if (_netUsageW != null) {
          _netUsageW = _netUsageW! + _manualUsageW!;
        } else {
          _netUsageW = _manualUsageW;
        }
      }
      _manualUsageB =
          double.tryParse(widget.manualUsages['manual_usage_b'] ?? '');
      if (_manualUsageB != null) {
        if (_netUsageB != null) {
          _netUsageB = _netUsageB! + _manualUsageB!;
        } else {
          _netUsageB = _manualUsageB;
        }
      }
      _manualUsageN =
          double.tryParse(widget.manualUsages['manual_usage_n'] ?? '');
      if (_manualUsageN != null) {
        if (_netUsageN != null) {
          _netUsageN = _netUsageN! + _manualUsageN!;
        } else {
          _netUsageN = _manualUsageN;
        }
      }
      _manualUsageG =
          double.tryParse(widget.manualUsages['manual_usage_g'] ?? '');
      if (_manualUsageG != null) {
        if (_netUsageG != null) {
          _netUsageG = _netUsageG! + _manualUsageG!;
        } else {
          _netUsageG = _manualUsageG;
        }
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
    double costLineItems = 0;
    for (var lineItem in widget.lineItems) {
      String valueStr = lineItem['amount'] ?? '';
      double? valueVal = double.tryParse(valueStr) ?? 0;
      costLineItems += valueVal;
    }
    _costLineItems = costLineItems;
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
            widget.excludeAutoUsage
                ? getAutoUsageExcludedInfo(context)
                : getAutoUsage(),
            verticalSpaceSmall,
            getManualUsage(),
            verticalSpaceSmall,
            getSubTenantUsage(),
            verticalSpaceSmall,
            verticalSpaceSmall,
            getTypeUsageNet(
              context,
              widget.loggedInUser,
              widget.scopeProfile,
              widget.appConfig,
              _netUsageE,
              _rateE,
              _netUsageW,
              _rateW,
              _netUsageB,
              _rateB,
              _netUsageN,
              _rateN,
              _netUsageG,
              _rateG,
              usageDecimals: widget.usageDecimals,
              rateDecimals: widget.rateDecimals,
              costDecimals: widget.costDecimals,
            ),
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

  Widget getAutoUsage() {
    if (widget.billedAutoUsages.isEmpty) {
      return Container();
    }
    List<Widget> autoUsageList = [];
    for (var key in widget.billedAutoUsages.keys) {
      String usageStr = widget.billedAutoUsages[key] ?? '';
      double? usageVal = double.tryParse(usageStr);
      String meterTypeTag = key.split('_').last;
      if (usageVal != null) {
        MeterType? meterType = getMeterType(meterTypeTag);
        if (meterType != null) {
          autoUsageList.add(
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: WgtUsageStatCore(
                loggedInUser: widget.loggedInUser,
                scopeProfile: widget.scopeProfile,
                appConfig: widget.appConfig,
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
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                showTrending: false,
                statVirticalStack: false,
                height: 110,
                usageDecimals: widget.usageDecimals,
                rateDecimals: widget.rateDecimals,
                costDecimals: widget.costDecimals,
                meterType: meterType,
                meterId: meterTypeTag.toUpperCase(),
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
              Icon(Symbols.auto_awesome_motion,
                  size: 21, color: Theme.of(context).colorScheme.primary),
              horizontalSpaceTiny,
              Text('Auto Usage',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).hintColor.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          ...autoUsageList,
        ],
      ),
    );
  }

  Widget getSubTenantUsage() {
    if (widget.billedSubTenantUsages.isEmpty) {
      return Container();
    }
    if (widget.billedSubTenantUsages.values
        .every((element) => element == null)) {
      return Container();
    }
    List<Widget> subTenantUsageList = [];
    for (var key in widget.billedSubTenantUsages.keys) {
      String usageStr = widget.billedSubTenantUsages[key] ?? '';
      double? usageVal = double.tryParse(usageStr);
      String meterTypeTag = key.split('_').last;
      if (usageVal != null) {
        MeterType? meterType = getMeterType(meterTypeTag);
        if (meterType != null) {
          subTenantUsageList.add(
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: WgtUsageStatCore(
                loggedInUser: widget.loggedInUser,
                scopeProfile: widget.scopeProfile,
                appConfig: widget.appConfig,
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
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                showTrending: false,
                statVirticalStack: false,
                height: 110,
                usageDecimals: widget.usageDecimals,
                rateDecimals: widget.rateDecimals,
                costDecimals: widget.costDecimals,
                meterType: meterType,
                meterId: meterTypeTag.toUpperCase(),
                meterIdType: ItemIdType.name,
                itemType: widget.itemType,
                historyType: Evs2HistoryType.meter_list_usage_summary,
                isStaticUsageStat: true,
                isSubstractUsage: true,
                meterStat: {'usage': usageStr},
                showRate: false,
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
              Icon(Symbols.group,
                  size: 21, color: Theme.of(context).colorScheme.primary),
              horizontalSpaceTiny,
              Text('Sub Tenant Usage',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).hintColor.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          ...subTenantUsageList,
        ],
      ),
    );
  }

  Widget getManualUsage() {
    if (widget.manualUsages.isEmpty) {
      return Container();
    }
    if (widget.manualUsages.values.every((element) => element == null)) {
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
                appConfig: widget.appConfig,
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
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  // Widget getTotal() {
  //   double totalCost = (_costE ?? 0) +
  //       (_costW ?? 0) +
  //       (_costB ?? 0) +
  //       (_costN ?? 0) +
  //       (_costG ?? 0) +
  //       (_costLineItems ?? 0);
  //   return Container(
  //     width: 700,
  //     height: 80,
  //     padding: const EdgeInsets.symmetric(horizontal: 3),
  //     // constraints: const BoxConstraints(maxHeight: 130),
  //     decoration: BoxDecoration(
  //       border:
  //           Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
  //       borderRadius: BorderRadius.circular(5.0),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.only(top: 10),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         crossAxisAlignment: CrossAxisAlignment.center,
  //         children: [
  //           SizedBox(
  //             width: 210,
  //             child: Text(
  //               'Total',
  //               style: defStatStyleLarge,
  //             ),
  //           ),
  //           horizontalSpaceSmall,
  //           getStatWithUnit(
  //             getCommaNumberStr(totalCost, decimal: 2),
  //             'SGD',
  //             statStrStyle: defStatStyleLarge.copyWith(
  //               color:
  //                   Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}
