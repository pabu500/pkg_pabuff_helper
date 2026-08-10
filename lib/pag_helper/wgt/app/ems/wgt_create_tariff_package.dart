import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/comm/comm_tariff_package.dart';
import 'package:buff_helper/pag_helper/def_helper/def_item_group.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_tariff_package.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_building_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_location_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_group_profile.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_site_profile.dart';
import 'package:buff_helper/pag_helper/wgt/scope/wgt_scope_setter.dart';
import 'package:buff_helper/pag_helper/wgt/tree/wgt_item_group_tree.dart';
import 'package:buff_helper/pag_helper/wgt/tree/wgt_tree_element.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:buff_helper/pag_helper/def_helper/tariff_package_helper.dart';
import 'package:provider/provider.dart';

import '../../../model/mdl_pag_app_config.dart';

class WgtCreateTariffPackage extends StatefulWidget {
  const WgtCreateTariffPackage({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    this.showTitle = true,
    this.showPortalType = true,
    this.showEnabled = true,
    this.onCreated,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final bool showTitle;
  final bool showPortalType;
  final bool showEnabled;
  final Function? onCreated;

  @override
  State<WgtCreateTariffPackage> createState() => _CreateTariffPackageState();
}

class _CreateTariffPackageState extends State<WgtCreateTariffPackage> {
  // late MdlPagUser? _loggedInUser;
  final double width = 395;

  final int minCycleDay = 1;
  final int maxCycleDay = 25;

  final int minPaymentTerm = 1;
  final int maxPaymentTerm = 30;

  bool _isEditing = false;
  bool _newItem = true;
  bool _createWait = false;
  bool _createSuccess = false;
  String _errorText = '';

  String? _newItemLabel;
  String? _newItemName;
  bool _isNewItemLabelValidated = false;

  bool _enabled = true;

  String? _selectedCycleDay;
  String? _selectedPaymentTermStr;

  MeterTypeTag? _selectedMeterType;
  PagTariffPackageTypeCat? _selectedPackageTypeCat;
  String? _selectedTariffPackageTypeLabelStr;
  String? _selectedSysRatePackageTypeStr;

  PagInterestDurationType? _selectedInterestDuration;

  PagInterestStartDateType? _selectedInterestStartDateType;

  final List<Map<String, dynamic>> _visibleRoleList = [];

  PagTreeNode? _itemChildrenGroupTreeRoot;
  final List<Map<String, dynamic>> _itemChildrenList = [];

  Map<String, dynamic> _itemScopeMap = {};
  UniqueKey? _scopeSetterKey;

  String _interestRateStr = '';
  UniqueKey? _interestRateResetKey;
  bool _isInterestRateValidated = false;

  // hard coded for now
  // multiple TPs with diff cycle days can be created
  // under SP LT Cycle type
  List<String> systemCycleTypeList = [
    'SP LT Cycle',
  ];

  List<String> systemRateTypeList = [
    'SP LT Rate',
  ];
  List<String> regularRateTypeList = [
    'FTF',
  ];

  List<String>? _selectedRateTypeList;

  bool _tpConfigLoaded = false;
  int _tpComingMonthCount = 6;
  int _pullFailCount = 0;

  Future<dynamic> _doResolveTpConfig() async {
    Map<String, dynamic> queryMap = {};

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      _tpComingMonthCount = 6;
      _tpConfigLoaded = true;
    } catch (e) {
      dev.log('error: $e');

      _errorText = 'Error resolving tp coming month count';
      _pullFailCount++;
      dev.log('pull fail count: $_pullFailCount');

      return;
    } finally {
      // setState(() {
      //   _checking = false;
      // });
    }
  }

  Future<dynamic> _createItem() async {
    setState(() {
      _createSuccess = false;
      _createWait = true;
      _errorText = '';
    });

    try {
      Map<String, dynamic> queryMap = {};
      queryMap['scope'] = widget.loggedInUser.selectedScope.toScopeMap();
      queryMap['label'] = _newItemLabel;

      dynamic result;

      // iterate through the list and remove the from_datetime and to_datetime
      // to satify the json encoding in queryMap
      for (var element in _itemChildrenList) {
        element.remove('from_datetime');
        element.remove('to_datetime');
      }

      queryMap['tariff_package_type_label'] =
          _selectedTariffPackageTypeLabelStr;
      queryMap['meter_type'] = _selectedMeterType!.name;
      queryMap['cycle_day'] = _selectedCycleDay;
      queryMap['tariff_rate_list'] = _itemChildrenList;
      queryMap['item_scope_info'] = _itemScopeMap;

      if (_selectedPackageTypeCat == PagTariffPackageTypeCat.systemCycle) {
        queryMap['sys_rate_type'] = _selectedSysRatePackageTypeStr;
      }

      queryMap['interest_rate'] = _interestRateStr;
      queryMap['interest_duration'] =
          _selectedInterestDuration!.name.toLowerCase();
      if (_selectedPaymentTermStr != null) {
        queryMap['payment_term'] = _selectedPaymentTermStr!;
      }

      queryMap['interest_start_date_type'] =
          _selectedInterestStartDateType!.value.toLowerCase();

      result = await doCreatePagTariffPackage(
        widget.loggedInUser,
        widget.appConfig,
        queryMap,
        MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: '',
        ),
      );
      final data = result['data'];
      final tariffPackageInfo = data['tariff_package_info'];
      _newItemName = tariffPackageInfo['name'];

      _newItem = false;
      _createSuccess = true;
    } catch (e) {
      dev.log('error: $e');

      // setState(() {
      _errorText =
          getErrorText(e, defaultErrorText: 'Error creating tariff package');

      _newItem = true;
      _createSuccess = false;
      // });

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

    return _selectedPackageTypeCat != null &&
        _selectedTariffPackageTypeLabelStr != null &&
        _selectedMeterType != null &&
        _selectedCycleDay != null &&
        _itemChildrenGroupTreeRoot != null &&
        _itemScopeMap.isNotEmpty &&
        _isInterestRateValidated &&
        _selectedInterestDuration != null &&
        _selectedPaymentTermStr != null &&
        _selectedInterestStartDateType != null;
  }

  @override
  void initState() {
    super.initState();

    // _loggedInUser =
    //     Provider.of<PagUserProvider>(context, listen: false).currentUser;

    _visibleRoleList.clear();
    _visibleRoleList.addAll(widget.loggedInUser.selectedScope.projectProfile!
        .getVisibleRoleInfoList());
  }

  @override
  Widget build(BuildContext context) {
    bool pullData = !_tpConfigLoaded;
    if (_pullFailCount > 2) {
      pullData = false;
    }

    return SingleChildScrollView(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
              width: width,
              child: pullData
                  ? FutureBuilder(
                      future: _doResolveTpConfig(),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                            dev.log('waiting...');
                            return const Align(
                              alignment: Alignment.topCenter,
                              child: WgtPagWait(size: 35),
                            );
                          default:
                            if (snapshot.hasError) {
                              dev.log('error: ${snapshot.error}');
                              return const Align(
                                alignment: Alignment.topCenter,
                                child: Text('Error loading config'),
                              );
                            } else {
                              return getCompletedWidget();
                            }
                        }
                      },
                    )
                  : getCompletedWidget()),
        ],
      ),
    );
  }

  Widget getCompletedWidget() {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        children: [
          verticalSpaceRegular,
          getTpTypeSelector(),
          verticalSpaceTiny,
          getMeterTypeSelector(),
          verticalSpaceTiny,
          getCycleDate(),
          verticalSpaceTiny,
          getPaymentTerm(),
          verticalSpaceTiny,
          getInterestDurationSelector(),
          verticalSpaceTiny,
          getInterestStartDateTypeSelector(),
          verticalSpaceTiny,
          getInterestRate(),
          verticalSpaceTiny,
          getItemScopeSetter(),
          verticalSpaceTiny,
          if (_selectedCycleDay != null && _selectedMeterType != null)
            getTariffPackageRateList(),
          verticalSpaceRegular,
          WgtCommButton(
            enabled: _checkEnableButton(),
            label: _createWait
                ? 'Creating tariff package...'
                : _createSuccess
                    ? '✓ Tariff package created'
                    : 'Create Tariff Package',
            onPressed: !_checkEnableButton() //_selectedProjectScope == null
                ? null
                : () async {
                    await _createItem();

                    // reset the form
                    setState(() {
                      // _newItem = true;
                      _newItemLabel = null;
                      // _newItemName = null;
                      _selectedPackageTypeCat = null;
                      _selectedTariffPackageTypeLabelStr = null;
                      _selectedSysRatePackageTypeStr = null;
                      _selectedRateTypeList = null;

                      _selectedMeterType = null;
                      _selectedCycleDay = null;
                      _itemChildrenGroupTreeRoot = null;
                      _itemChildrenList.clear();
                      _itemScopeMap.clear();
                      _scopeSetterKey = UniqueKey();
                      _interestRateStr = '';
                      _interestRateResetKey = UniqueKey();
                      _isInterestRateValidated = false;
                      _selectedInterestDuration = null;
                      _selectedPaymentTermStr = null;
                      _selectedInterestStartDateType = null;
                    });
                    widget.onCreated?.call();
                  },
          ),
          if (_newItem && !_createSuccess && _errorText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(_errorText,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (!_newItem && _createSuccess && _errorText.isEmpty)
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(
                'Tariff Package ${_newItemName ?? ''} created',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget getTpTypeSelector() {
    // hard code for now
    List<PagTariffPackageTypeCat> tpTypeList = [
      PagTariffPackageTypeCat.regular,
      // for now, system rate is only created by the system
      // and not by the user
      // PagTariffPackageTypeCat.systemRate,
      PagTariffPackageTypeCat.systemCycle,
    ];
    TextStyle dropDownListTextStyle = TextStyle(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500);
    TextStyle dropDownListHintStyle =
        TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
    Widget dropDownUnderline =
        Container(height: 1, color: Theme.of(context).hintColor.withAlpha(75));
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 95,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text('Base Type:',
                    style: TextStyle(color: Theme.of(context).hintColor)),
              ),
            ),
            horizontalSpaceSmall,
            SizedBox(
              width: 95,
              child: DropdownButton<PagTariffPackageTypeCat>(
                  alignment: AlignmentDirectional.centerStart,
                  hint: Padding(
                      padding: const EdgeInsets.only(bottom: 3.0),
                      child: Text('Rate Type', style: dropDownListHintStyle)),
                  value: _selectedPackageTypeCat,
                  focusColor: Theme.of(context).hoverColor,
                  underline: dropDownUnderline,
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: 21,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                  onChanged: (PagTariffPackageTypeCat? value) async {
                    if (value != null) {
                      if (value == _selectedPackageTypeCat) {
                        return;
                      }
                    }
                    setState(() {
                      _selectedPackageTypeCat = value;
                      _newItem = true;
                      _createSuccess = false;
                      if (_selectedPackageTypeCat ==
                          PagTariffPackageTypeCat.systemCycle) {
                        _selectedRateTypeList = systemCycleTypeList;
                        if (systemCycleTypeList.length == 1) {
                          _selectedTariffPackageTypeLabelStr =
                              systemCycleTypeList.first;
                        } else {
                          _selectedTariffPackageTypeLabelStr = null;
                        }
                        if (systemRateTypeList.length == 1) {
                          _selectedSysRatePackageTypeStr =
                              systemRateTypeList.first;
                        } else {
                          _selectedSysRatePackageTypeStr = null;
                        }
                      } else if (_selectedPackageTypeCat ==
                          PagTariffPackageTypeCat.systemRate) {
                        _selectedRateTypeList = systemRateTypeList;
                        if (systemRateTypeList.length == 1) {
                          _selectedTariffPackageTypeLabelStr =
                              systemRateTypeList.first;
                          if (systemRateTypeList.length == 1) {
                            _selectedSysRatePackageTypeStr =
                                systemRateTypeList.first;
                          } else {
                            _selectedSysRatePackageTypeStr = null;
                          }
                        } else {
                          _selectedTariffPackageTypeLabelStr = null;
                        }
                      } else {
                        _selectedTariffPackageTypeLabelStr =
                            regularRateTypeList.first;
                        _selectedRateTypeList = regularRateTypeList;
                      }
                    });
                  },
                  items: tpTypeList
                      .map<DropdownMenuItem<PagTariffPackageTypeCat>>(
                          (PagTariffPackageTypeCat value) {
                    return DropdownMenuItem<PagTariffPackageTypeCat>(
                      value: value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 3.0),
                        child: Text(value.label),
                      ),
                    );
                  }).toList()),
            ),
          ],
        ),
        if (_selectedPackageTypeCat != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 95,
                child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text('Package Type:',
                        style: TextStyle(color: Theme.of(context).hintColor))),
              ),
              horizontalSpaceSmall,
              SizedBox(
                width: 95,
                child: DropdownButton<String>(
                    alignment: AlignmentDirectional.centerStart,
                    hint: Padding(
                        padding: const EdgeInsets.only(bottom: 3.0),
                        child: Text('Rate Type', style: dropDownListHintStyle)),
                    value: _selectedTariffPackageTypeLabelStr,
                    focusColor: Theme.of(context).hoverColor,
                    underline: dropDownUnderline,
                    icon: const Icon(Icons.arrow_drop_down),
                    iconSize: 21,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                    onChanged: (String? value) async {
                      if (value != null) {
                        if (value == _selectedTariffPackageTypeLabelStr) {
                          return;
                        }
                      }
                      setState(() {
                        _selectedTariffPackageTypeLabelStr = value;
                        _newItem = true;
                        _createSuccess = false;
                        if (_selectedPackageTypeCat ==
                            PagTariffPackageTypeCat.systemCycle) {
                          if (systemRateTypeList.length == 1) {
                            _selectedSysRatePackageTypeStr =
                                systemRateTypeList.first;
                          } else {
                            _selectedSysRatePackageTypeStr = null;
                          }
                        }
                      });
                    },
                    items: (_selectedRateTypeList ?? [])
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3.0),
                          child: Text(value),
                        ),
                      );
                    }).toList()),
              ),
            ],
          ),
        if (_selectedPackageTypeCat == PagTariffPackageTypeCat.systemCycle)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 95,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Text('Sys Rate:',
                      style: TextStyle(color: Theme.of(context).hintColor)),
                ),
              ),
              horizontalSpaceSmall,
              SizedBox(
                width: 95,
                child: DropdownButton<String>(
                    alignment: AlignmentDirectional.centerStart,
                    hint: Padding(
                        padding: const EdgeInsets.only(bottom: 3.0),
                        child: Text('Sys Rate', style: dropDownListHintStyle)),
                    value: _selectedSysRatePackageTypeStr,
                    focusColor: Theme.of(context).hoverColor,
                    underline: dropDownUnderline,
                    icon: const Icon(Icons.arrow_drop_down),
                    iconSize: 21,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                    onChanged: (String? value) async {
                      if (value != null) {
                        if (value == _selectedSysRatePackageTypeStr) {
                          return;
                        }
                      }
                      setState(() {
                        _selectedSysRatePackageTypeStr = value;
                        _newItem = true;
                        _createSuccess = false;
                      });
                    },
                    items: (systemRateTypeList)
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3.0),
                          child: Text(value),
                        ),
                      );
                    }).toList()),
              ),
            ],
          ),
      ],
    );
  }

  Widget getMeterTypeSelector() {
    // hard code for now
    List<MeterTypeTag> meterTypeList = [
      MeterTypeTag.E,
      MeterTypeTag.W,
    ];
    TextStyle dropDownListTextStyle = TextStyle(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500);
    TextStyle dropDownListHintStyle =
        TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
    Widget dropDownUnderline =
        Container(height: 1, color: Theme.of(context).hintColor.withAlpha(75));
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text('Meter Type:',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 96,
          child: DropdownButton<MeterTypeTag>(
              alignment: AlignmentDirectional.centerStart,
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Meter Type', style: dropDownListHintStyle)),
              value: _selectedMeterType,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (MeterTypeTag? value) async {
                if (value != null) {
                  if (value == _selectedMeterType) {
                    return;
                  }
                }
                setState(() {
                  _selectedMeterType = value!;
                  _newItem = true;
                  _createSuccess = false;
                });
              },
              items: meterTypeList
                  .map<DropdownMenuItem<MeterTypeTag>>((MeterTypeTag value) {
                return DropdownMenuItem<MeterTypeTag>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(
                      value.name,
                      // style: dropDownListTextStyle,
                    ),
                  ),
                );
              }).toList()),
        ),
      ],
    );
  }

  Widget getCycleDate() {
    // a drop down list of 1 to 25, and 'month end'
    List<String> cycleDates = [];
    // cycleDates.add('Standard');
    for (int i = minCycleDay; i <= maxCycleDay; i++) {
      cycleDates.add(i.toString());
    }

    TextStyle dropDownListTextStyle = TextStyle(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500);
    TextStyle dropDownListHintStyle =
        TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
    Widget dropDownUnderline =
        Container(height: 1, color: Theme.of(context).hintColor.withAlpha(75));

    // dropdown
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text('Cycle Date:',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 96,
          child: DropdownButton<String>(
              alignment: AlignmentDirectional.centerStart,
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Cycle Date', style: dropDownListHintStyle)),
              value: _selectedCycleDay,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (String? value) async {
                if (value != null) {
                  if (value == _selectedMeterType?.name) {
                    return;
                  }
                }
                setState(() {
                  _selectedCycleDay = value!;
                  _newItem = true;
                  _createSuccess = false;
                });
              },
              items: cycleDates.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(
                      value,
                      // style: dropDownListTextStyle,
                    ),
                  ),
                );
              }).toList()),
        ),
      ],
    );
  }

  Widget getPaymentTerm() {
    // a drop down list of 1 to 25, and 'month end'
    List<String> paymentTerms = [];
    // paymentTerms.add('Standard');
    for (int i = minPaymentTerm; i <= maxPaymentTerm; i++) {
      paymentTerms.add(i.toString());
    }

    TextStyle dropDownListTextStyle = TextStyle(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500);
    TextStyle dropDownListHintStyle =
        TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
    Widget dropDownUnderline =
        Container(height: 1, color: Theme.of(context).hintColor.withAlpha(75));

    // dropdown
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text('Pmt. Term:',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 96,
          child: DropdownButton<String>(
              alignment: AlignmentDirectional.centerStart,
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Pmt. Term', style: dropDownListHintStyle)),
              value: _selectedPaymentTermStr,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (String? value) async {
                if (value != null) {
                  if (value == _selectedMeterType?.name) {
                    return;
                  }
                }
                setState(() {
                  _selectedPaymentTermStr = value!;
                  _newItem = true;
                  _createSuccess = false;
                });
              },
              items: paymentTerms.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(value),
                  ),
                );
              }).toList()),
        ),
      ],
    );
  }

  Widget getInterestDurationSelector() {
    List<PagInterestDurationType> intDur = [
      PagInterestDurationType.month,
      PagInterestDurationType.annum,
    ];
    TextStyle dropDownListTextStyle = TextStyle(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500);
    TextStyle dropDownListHintStyle =
        TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
    Widget dropDownUnderline =
        Container(height: 1, color: Theme.of(context).hintColor.withAlpha(75));
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text('Int. Dur.:',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 96,
          child: DropdownButton<PagInterestDurationType>(
              alignment: AlignmentDirectional.centerStart,
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Int. Dur.', style: dropDownListHintStyle)),
              value: _selectedInterestDuration,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (PagInterestDurationType? value) async {
                if (value != null) {
                  if (value == _selectedInterestDuration) {
                    return;
                  }
                }
                setState(() {
                  _selectedInterestDuration = value!;
                  _newItem = true;
                  _createSuccess = false;
                });
              },
              items: intDur.map<DropdownMenuItem<PagInterestDurationType>>(
                  (PagInterestDurationType value) {
                return DropdownMenuItem<PagInterestDurationType>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(
                      value.name,
                      // style: dropDownListTextStyle,
                    ),
                  ),
                );
              }).toList()),
        ),
      ],
    );
  }

  Widget getInterestStartDateTypeSelector() {
    List<PagInterestStartDateType> intStartDateType = [
      PagInterestStartDateType.dueDate,
      PagInterestStartDateType.billDate,
    ];
    TextStyle dropDownListTextStyle = TextStyle(
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500);
    TextStyle dropDownListHintStyle =
        TextStyle(fontSize: 15, color: Theme.of(context).hintColor);
    Widget dropDownUnderline =
        Container(height: 1, color: Theme.of(context).hintColor.withAlpha(75));
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text('Int. Start Date:',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 120,
          child: DropdownButton<PagInterestStartDateType>(
              alignment: AlignmentDirectional.centerStart,
              hint: Padding(
                  padding: const EdgeInsets.only(bottom: 3.0),
                  child: Text('Int. Start Date', style: dropDownListHintStyle)),
              value: _selectedInterestStartDateType,
              focusColor: Theme.of(context).hoverColor,
              underline: dropDownUnderline,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 21,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              onChanged: (PagInterestStartDateType? value) async {
                if (value != null) {
                  if (value == _selectedInterestStartDateType) {
                    return;
                  }
                }
                setState(() {
                  _selectedInterestStartDateType = value!;
                  _newItem = true;
                  _createSuccess = false;
                });
              },
              items: intStartDateType
                  .map<DropdownMenuItem<PagInterestStartDateType>>(
                      (PagInterestStartDateType value) {
                return DropdownMenuItem<PagInterestStartDateType>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: Text(
                      value.name,
                      // style: dropDownListTextStyle,
                    ),
                  ),
                );
              }).toList()),
        ),
      ],
    );
  }

  Widget getInterestRate() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text('Int. Rate (%):',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
        ),
        horizontalSpaceSmall,
        SizedBox(
          width: 120,
          child: WgtTextField(
            key: _interestRateResetKey,
            appConfig: widget.appConfig,
            hintText: 'Int. Rate (%)',
            labelText: 'Int. Rate (%)',
            required: true,
            // maxLength: maxFullNameLength,
            validator: validateInterestRate,
            onChanged: (val) {
              setState(() {
                _isEditing = true;
                if (val != _interestRateStr) {
                  _errorText = '';
                }
              });
              if (val.trim().isNotEmpty) {
                setState(() {
                  _newItem = true;
                  _createSuccess = false;
                });
              }
              _interestRateStr = val;
              return null;
            },
            onEditingComplete: () {
              setState(() {
                _isEditing = false;
              });
            },
            onValidate: (String? result) {
              setState(() {
                if (result == null) {
                  _isInterestRateValidated = true;
                } else {
                  _isInterestRateValidated = false;
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget getTariffPackageRateList() {
    // double width = width;

    // PagItemGroupType? itemGroupType;
    Map<String, dynamic> queryMap = {};
    String rootName = '';
    String rootLabel = '';

    Map<String, dynamic>? initalValueMap;

    queryMap = {};
    rootName = _newItemLabel ?? 'New tariff package';
    rootLabel = _newItemLabel ?? 'New tariff package';

    int cycleDay = int.parse(_selectedCycleDay!);
    initalValueMap = {'cycle_day': cycleDay};

    // if (itemGroupType == null) {
    //   return Container();
    // }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: WgtItemGroupTree(
        appConfig: widget.appConfig,
        mode: 'create',
        allowAddButton: false,
        width: width,
        loggedInUser: widget.loggedInUser,
        groupItemId: '',
        itemGroupType: PagItemGroupType.tariffPackageTariffRate,
        queryMap: queryMap,
        rootName: rootName,
        rootLabel: rootLabel,
        initalValueMap: initalValueMap,
        onUpdate:
            (PagTreeNode rootNode, List<Map<String, dynamic>> childreanList) {
          String validatedResult = validateTpRateList(
              tpTypeCat: _selectedPackageTypeCat!,
              rateList: childreanList,
              tpComingMonthCount: _tpComingMonthCount,
              timezone: widget.loggedInUser.selectedScope.getProjectTimezone());
          if (validatedResult != 'valid') {
            dev.log('Invalid list');

            setState(() {
              _errorText = validatedResult;
              _newItem = true;
              _createSuccess = false;
            });
            return;
          }

          setState(() {
            _newItem = true;
            _newItemLabel = rootNode.label;
            _createSuccess = false;
            _itemChildrenGroupTreeRoot = rootNode;
            _itemChildrenList.clear();
            _itemChildrenList.addAll(childreanList);
            for (var element in childreanList) {
              if (element['from_datetime'] == null ||
                  element['to_datetime'] == null) {
                _itemChildrenList.clear();
                break;
              } else {
                DateTime fromDateTime = element['from_datetime'];
                DateTime toDateTime = element['to_datetime'];
                element['from_timestamp'] = fromDateTime.toIso8601String();
                element['to_timestamp'] = toDateTime.toIso8601String();
              }
            }
          });
        },
        // newItemWidget: getNewSubWidget(),
      ),
    );
  }

  Widget getItemScopeSetter() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: WgtScopeSetter(
        key: _scopeSetterKey,
        appConfig: widget.appConfig,
        width: width,
        labelWidth: 130,
        // itemScopeMap: widget.itemScopeMap!,
        forItemKind: PagItemKind.tariff,
        // forScopeType: widget.itemType is PagScopeType ? widget.itemType : null,
        onScopeSet: (dynamic profile) {
          if (profile == null) {
            if (kDebugMode) {
              print('Profile is null');
            }
            return {};
          }
          String scopeIdColName = '';
          if (profile is MdlPagSiteGroupProfile) {
            scopeIdColName = 'site_group_id';
          } else if (profile is MdlPagSiteProfile) {
            scopeIdColName = 'site_id';
          } else if (profile is MdlPagBuildingProfile) {
            scopeIdColName = 'building_id';
          } else if (profile is MdlPagLocationGroupProfile) {
            scopeIdColName = 'location_group_id';
          } else if (profile is MdlPagLocation) {
            scopeIdColName = 'location_id';
          }
          if (scopeIdColName.isEmpty) {
            if (kDebugMode) {
              print('Invalid profile type');
            }
            return {};
          }
          setState(() {
            _itemScopeMap[scopeIdColName] = profile.id.toString();
          });
        },
      ),
    );
  }
}
