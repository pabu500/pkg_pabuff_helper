import 'dart:async';
import 'dart:convert';
import 'package:buff_helper/pagrid_helper/pagrid_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../xt_ui/wdgt/show_model_bottom_sheet.dart';
import 'wgt_bill_rec_finder.dart';

class WgtListSearchBillingRec extends StatefulWidget {
  const WgtListSearchBillingRec({
    super.key,
    required this.appConfig,
    required this.scopeProfile,
    required this.loggedInUser,
    this.title = 'List/Search Billing Records',
    this.isPickerMode = false,
    // this.onSubmitPicked,
    this.allowLcStatusUpdate = false,
    this.initialNoR = 20,
    this.opColConfig,
    this.initialType,
    this.iniShowPanel = true,
    this.onShowPanel,
    this.onSearching,
    this.onListPopulated,
    this.listConfig,
    this.tenantName,
    this.tenantLabel,
    this.lcStatusList,
    this.finderSidePadding = EdgeInsets.zero,
    this.includeTestItems = false,
  });

  final ScopeProfile scopeProfile;
  final Evs2User loggedInUser;
  final PaGridAppConfig appConfig;
  final String title;
  final bool isPickerMode;
  final bool allowLcStatusUpdate;
  // final Function? onSubmitPicked;
  final int initialNoR;
  final Map<String, dynamic>? opColConfig;
  final String? initialType;
  final bool iniShowPanel;
  final Function? onShowPanel;
  final Function? onSearching;
  final Function? onListPopulated;
  final List<Map<String, dynamic>>? listConfig;
  final String? tenantName;
  final String? tenantLabel;
  final List<BillingLcStatus>? lcStatusList;
  final EdgeInsets finderSidePadding;
  final bool includeTestItems;

  @override
  State<WgtListSearchBillingRec> createState() =>
      _WgtListSearchBillingRecState();
}

class _WgtListSearchBillingRecState extends State<WgtListSearchBillingRec> {
  final String sectionName = 'list_search_billing_rec';

  late final List<Map<String, dynamic>> _listConfig = [];
  Map<String, dynamic> _queryMap = {};

  int? _totalNumberOfRec;
  int _maxRowsPerPage = 20;
  int _currentPage = 1;
  String? _sortBy;
  String _sortOrder = 'desc';

  String? _selectedType;

  int _totalItemCount = 0;
  String _itemSelectQuery = '';

  bool _showEmptyResult = false;
  String _emptyResultText = 'No result found';
  String _errorText = '';
  bool _isItemListLoading = false;

  final List<Map<String, dynamic>> _entityItems = [];
  final List<Map<String, dynamic>> _modifiedEntityItems = [];
  final List<GlobalKey> _modifiedFields = [];

  late bool _viewOnly;
  UniqueKey? _refreshKey;
  UniqueKey? _listKey;
  bool _itemUpdated = false;

  Future<dynamic> _getItemList() async {
    if (_queryMap.isEmpty) {
      if (kDebugMode) {
        print('queryMap is empty');
      }
      return null;
    }

    setState(() {
      _isItemListLoading = true;
      _errorText = '';
    });

    _entityItems.clear();
    _modifiedEntityItems.clear();

    Map<String, dynamic> itemFindResult = {};
    _queryMap['current_page'] = '$_currentPage';
    _queryMap['sort_by'] = _sortBy ?? '';
    _queryMap['sort_order'] = _sortOrder;

    try {
      itemFindResult = await doListItems(
        widget.appConfig,
        _queryMap,
        SvcClaim(
          userId: widget.loggedInUser.id,
          username: widget.loggedInUser.username,
          scope: widget.loggedInUser.isAdminAndUp()
              ? AclScope.global.name
              : widget.scopeProfile.getEffectiveScopeStr(),
          target: getAclTargetStr(AclTarget.bill_p_info),
          operation: AclOperation.list.name,
        ),
      );
      List<Map<String, dynamic>> itemList = itemFindResult['item_list'];
      for (var tenant in itemList) {
        _entityItems.add(tenant);
      }

      setState(() {
        if (_currentPage == 1) {
          _totalNumberOfRec = itemFindResult['total_count'];
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    } finally {
      setState(() {
        _isItemListLoading = false;
      });
    }
  }

  void flagModified(bool modified, GlobalKey key) {
    setState(() {
      if (modified) {
        _modifiedFields.add(key);
      } else {
        _modifiedFields.remove(key);
      }
    });
  }

  List<Map<String, dynamic>> getModifiedList() {
    //clean up the list
    _modifiedEntityItems.removeWhere((element) => element.length <= 1);
    return _modifiedEntityItems;
  }

  void _updateCustomize() {
    dynamic listCustmize = readFromSharedPref(sectionName);
    Map<String, dynamic> colCustomize = json.decode(listCustmize ?? '{}');

    for (var item in _listConfig) {
      if (colCustomize.containsKey(item['fieldKey'])) {
        item['show'] = colCustomize[item['fieldKey']];
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _viewOnly = !(widget.loggedInUser.hasPermmision2(
            widget.scopeProfile.getEffectiveScope(),
            AclTarget.bill_p_info,
            AclOperation.read) ||
        widget.loggedInUser.isSubAdminAndUp());

    _selectedType = widget.initialType;

    _listConfig.clear();
    if (widget.listConfig != null) {
      _listConfig.addAll(widget.listConfig!);
    } else {
      _listConfig.addAll([
        {
          'title': 'id',
          'fieldKey': 'id',
          'show': false,
          'editable': false,
          'width': 0.0,
          'hidden': true,
        },
        {
          'title': 'Created',
          'fieldKey': 'created_timestamp',
          'width': 90.0,
          'showSort': true,
        },
        {
          'title': 'Type',
          'fieldKey': 'gen_type',
          'width': 60.0,
          'showSort': true,
          'useWidget': 'tag',
          'getTag': getGenTypeTag,
        },
        {
          'title': 'Identifier',
          'fieldKey': 'name',
          'editable': widget.loggedInUser.isAdminAndUp(),
          'width': 255.0,
          'showSort': true,
          'clickCopy': true,
        },
        {
          'title': 'Tenant Label',
          'fieldKey': 'tenant_label',
          'editable': widget.loggedInUser.isAdminAndUp(),
          'width': 210.0,
          // 'showSort': true,
          'clickCopy': true,
        },
        {
          'title': 'Location',
          'fieldKey': 'location_tag',
          'width': 80.0,
          // 'showSort': true,
        },
        {
          'title': 'Location 2',
          'fieldKey': 'location_tag2',
          'width': 80.0,
          // 'showSort': true,
        },
        {
          'title': 'SAP WBS',
          'fieldKey': 'sap_wbs',
          'width': 130.0,
          // 'showSort': true,
        },
        {
          'title': 'From',
          'fieldKey': 'from_timestamp',
          'editable': widget.loggedInUser.isAdminAndUp(),
          'width': 90.0,
          'showSort': true,
          // 'clickCopy': true,
        },
        {
          'title': 'To',
          'fieldKey': 'to_timestamp',
          'editable': widget.loggedInUser.isAdminAndUp(),
          'width': 90.0,
          // 'showSort': true,
          // 'clickCopy': true,
        },
        {
          'title': 'Rate E',
          'fieldKey': 'tariff_package_rate_id_e_rate',
          'width': 60.0,
        },
        {
          'title': 'Usage E',
          'fieldKey': 'billed_total_usage_e',
          'width': 90.0,
          'show': true
        },
        {
          'title': 'Rate W',
          'fieldKey': 'tariff_package_rate_id_w_rate',
          'width': 60.0,
        },
        {
          'title': 'Usage W',
          'fieldKey': 'billed_total_usage_w',
          'width': 70.0,
        },
        {
          'title': 'Rate B',
          'fieldKey': 'tariff_package_rate_id_b_rate',
          'width': 60.0,
        },
        {
          'title': 'Usage B',
          'fieldKey': 'billed_total_usage_b',
          'width': 100.0,
        },
        {
          'title': 'Rate N',
          'fieldKey': 'tariff_package_rate_id_n_rate',
          'width': 70.0,
        },
        {
          'title': 'Usage N',
          'fieldKey': 'billed_total_usage_n',
          'width': 90.0,
        },
        {
          'title': 'Rate G',
          'fieldKey': 'tariff_package_rate_id_g_rate',
          'width': 60.0,
        },
        {
          'title': 'Usage G',
          'fieldKey': 'billed_total_usage_g',
          'width': 90.0,
        },
        {
          'title': 'Bill Date',
          'fieldKey': 'released_bill_timestamp',
          'editable': widget.loggedInUser.isAdminAndUp(),
          'width': 90.0,
        },
        {
          'title': 'LC',
          'fieldKey': 'lc_status',
          'width': 50.0,
          'showSort': true,
          'getTag': getBillingLcStatusTag,
          'useWidget':
              widget.allowLcStatusUpdate ? 'billingLcSatusUpdate' : null,
        },
      ]);

      _listConfig.addAll([
        {
          'title': 'Bill',
          'fieldKey': 'info',
          'editable': true,
          'width': 40.0,
          'useWidget': 'iconButton',
          'iconData': Symbols.request_quote,
          'iconColor': _viewOnly ? Colors.grey.withOpacity(0.7) : null,
          'iconTooltip': 'View Bill',
          'onTap': _viewOnly
              ? null
              : (BuildContext context,
                  Map<String, dynamic> item,
                  List<Map<String, dynamic>> items,
                  Map<String, dynamic> queryMap) {
                  if (kDebugMode) {
                    print('Config profile for ${item['tenant_name']}');
                  }

                  String tpE = 'not set';
                  if (item['tariff_package_id_e'] != null &&
                      item['tariff_package_id_e'] != -1) {
                    tpE = item['tariff_package_id_e']['name'];
                  }
                  String tpW = 'not set';
                  if (item['tariff_package_id_w'] != null &&
                      item['tariff_package_id_w'] != -1) {
                    tpW = item['tariff_package_id_w']['name'];
                  }
                  String tpB = 'not set';
                  if (item['tariff_package_id_b'] != null &&
                      item['tariff_package_id_b'] != -1) {
                    tpB = item['tariff_package_id_b']['name'];
                  }
                  String tpN = 'not set';
                  if (item['tariff_package_id_n'] != null &&
                      item['tariff_package_id_n'] != -1) {
                    tpN = item['tariff_package_id_n']['name'];
                  }

                  xtShowModelBottomSheet(
                    context,
                    WgtBillView(
                      appConfig: widget.appConfig,
                      loggedInUser: widget.loggedInUser,
                      scopeProfile: widget.scopeProfile,
                      billingRecIndexStr: item['id'],
                      defaultBillLcStatus: item['lc_status'], //'generated',
                      modes: const ['widget', 'pdf'],
                      genTypes: item['lc_status'] == 'released' ||
                              item['lc_status'] == 'pv'
                          ? const ['generated', 'released']
                          : const ['generated'],
                    ),
                  );
                },
        }
      ]);
      if (widget.opColConfig != null) {
        _listConfig.add(widget.opColConfig!);
      }
    }

    _updateCustomize();
  }

  @override
  Widget build(BuildContext context) {
    bool emptyTargetKeys = _queryMap.isEmpty;

    if (_refreshKey != null) {
      if (_refreshKey != _listKey) {
        _listKey = _refreshKey;
        Future.delayed(const Duration(milliseconds: 100), () async {
          await _getItemList();
        });
      }
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          xtInfoBox(
            text: widget.title,
            textStyle:
                opsWidgetTitle.copyWith(color: Theme.of(context).hintColor),
            icon: const Icon(Icons.list_alt),
          ),
          verticalSpaceTiny,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: WgtBillingRecFinder(
              appConfig: widget.appConfig,
              loggedInUser: widget.loggedInUser,
              scopeProfile: widget.scopeProfile,
              includeTestItems: widget.includeTestItems,
              tenantName: widget.tenantName,
              tenantLabel: widget.tenantLabel,
              lcStatusList: widget.lcStatusList,
              idConstraintKey: 'name',
              // initialType: getMeterTypeTag(MeterType.electricity1p),
              initialNoR: widget.initialNoR,
              iniShowPanel: widget.iniShowPanel,
              sidePadding: widget.finderSidePadding,
              onShowPanel: widget.onShowPanel,
              onSearching: () {
                setState(() {
                  _isItemListLoading = true;
                });
                widget.onSearching?.call();
              },
              onResult: (itemFindResult) {
                if (itemFindResult['error'] != null) {
                  setState(() {
                    _isItemListLoading = false;
                    _errorText = itemFindResult['error'];
                  });
                  return;
                }
                _errorText = '';

                Map<String, dynamic> result = itemFindResult['itemFindResult'];
                if (result.isEmpty) {
                  setState(() {
                    _isItemListLoading = false;
                  });
                } else {
                  if (_currentPage == 1) {
                    _totalNumberOfRec = result['total_count'];
                  }
                  _entityItems.clear();
                  final itemList = result['item_list'];

                  for (var item in itemList) {
                    // Tenant tenant = Tenant.fromJson(item);
                    // _entityItems.add(tenant.toJson());
                    String? createdTimestamp = item['created_timestamp'];
                    String? fromTimestamp = item['from_timestamp'];
                    String? toTimestamp = item['to_timestamp'];
                    String? releasedBillTimestamp =
                        item['released_bill_timestamp'];
                    if (createdTimestamp != null) {
                      item['created_timestamp_tooltip'] = createdTimestamp;
                      item['created_timestamp'] =
                          createdTimestamp.substring(0, 10);
                    }
                    if (fromTimestamp != null) {
                      item['from_timestamp_tooltip'] = fromTimestamp;
                      item['from_timestamp'] = fromTimestamp.substring(0, 10);
                    }
                    if (toTimestamp != null) {
                      item['to_timestamp_tooltip'] = toTimestamp;
                      item['to_timestamp'] = toTimestamp.substring(0, 10);
                    }
                    if (releasedBillTimestamp != null) {
                      item['released_bill_timestamp_tooltip'] =
                          releasedBillTimestamp;
                      item['released_bill_timestamp'] =
                          releasedBillTimestamp.substring(0, 10);
                    }

                    _entityItems.add(item);
                  }
                  setState(() {
                    _listKey = UniqueKey();
                    // _entityItems.addAll(itemList);
                    _totalItemCount = result['total_count'];
                    _itemSelectQuery = result['id_select_query'] ?? '';
                    _queryMap = result['query_map'];
                    _maxRowsPerPage =
                        int.parse(_queryMap['max_rows_per_page'] ?? '20');

                    if (_totalItemCount == 0) {
                      _showEmptyResult = true;
                    } else {
                      _showEmptyResult = false;
                    }
                    _isItemListLoading = false;
                  });
                }
                widget.onListPopulated?.call(_entityItems);
              },
              onClearSearch: () {
                reset();
              },
              onModified: () {
                reset();
              },
            ),
          ),
          verticalSpaceRegular,
          _isItemListLoading
              ? xtWait(
                  color: Theme.of(context).colorScheme.primary,
                )
              : _errorText.isNotEmpty
                  ? getErrorTextPrompt(context: context, errorText: _errorText)
                  : _entityItems.isEmpty
                      ? emptyTargetKeys
                          ? Container() //emptyIdentifier(context)
                          : EmptyResult(
                              message: _emptyResultText,
                            )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: WgtEditCommitList(
                            key: _listKey,
                            selectShowColumn: true,
                            sectionName: sectionName,
                            appConfig: widget.appConfig,
                            loggedInUser: widget.loggedInUser,
                            scopeProfile: widget.scopeProfile,
                            listPrefix: 'billing_rec',
                            itemExt: 40,
                            // width:_tableWidth, //0.95 * MediaQuery.of(context).size.width,
                            listConfig: _listConfig,
                            listItems: _entityItems,
                            doCommit: (items, svcClaim) async => {},
                            compareValue:
                                widget.loggedInUser.maxRank!.toDouble(),
                            altCompareValue:
                                widget.loggedInUser.maxRank!.toDouble(),
                            showIndex: true,
                            maxRowsPerPage: _maxRowsPerPage,
                            totalCount: _totalNumberOfRec,
                            currentPage: _currentPage,
                            onPreviousPage: () {
                              setState(() {
                                _currentPage--;
                              });
                              _getItemList();
                            },
                            onNextPage: () {
                              setState(() {
                                _currentPage++;
                              });
                              _getItemList();
                            },
                            onClickPage: (page) {
                              setState(() {
                                _currentPage = page;
                              });
                              _getItemList();
                            },
                            onSort: (sortBy, sortOrder) {
                              setState(() {
                                _sortBy = sortBy;
                                _sortOrder = sortOrder;
                              });
                              _getItemList();
                            },
                            onRequestRefresh: () {
                              setState(() {
                                _refreshKey = UniqueKey();
                              });
                            },
                          ),
                        ),
        ],
      ),
    );
  }

  void reset() {
    setState(() {
      _entityItems.clear();
      _totalItemCount = 0;
      _queryMap = {};
      _currentPage = 1;
      _sortBy = null;
      _sortOrder = 'desc';
    });
  }
}
