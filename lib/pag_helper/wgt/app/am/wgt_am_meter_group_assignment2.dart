import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as dev;

import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/model/acl/mdl_pag_svc_claim.dart';
import 'package:buff_helper/pag_helper/model/mdl_pag_user.dart';
import 'package:buff_helper/pag_helper/model/provider/pag_user_provider.dart';
import 'package:buff_helper/pag_helper/model/scope/mdl_pag_scope.dart';
import 'package:buff_helper/xt_ui/style/evs2_colors.dart';
import 'package:buff_helper/xt_ui/wdgt/info/get_error_text_prompt.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:buff_helper/xt_ui/xt_helpers.dart';

import '../../../../up_helper/exceptions.dart';
import '../../../comm/comm_ex.dart';
import '../../../comm/pag_be_api_base.dart';
import '../../../def_helper/dh_meter_group.dart';
import '../../../model/mdl_pag_app_config.dart';

class WgtAmMeterGroupAssignment2 extends StatefulWidget {
  const WgtAmMeterGroupAssignment2({
    super.key,
    required this.appConfig,
    required this.strItemGroupIndex,
    required this.itemName,
    required this.itemLabel,
    required this.itemScope,
    required this.meterType,
    this.onScopeTreeUpdate,
    this.onUpdate,
  });

  final MdlPagAppConfig appConfig;
  final String strItemGroupIndex;
  final String itemName;
  final String itemLabel;
  final String meterType;
  final MdlPagScope itemScope;
  final Function? onScopeTreeUpdate;
  final Function? onUpdate;

  @override
  State<WgtAmMeterGroupAssignment2> createState() =>
      _WgtAmMeterGroupAssignment2State();
}

class _WgtAmMeterGroupAssignment2State
    extends State<WgtAmMeterGroupAssignment2> {
  late final MdlPagUser? loggedInUser;

  final double width = 395.0;

  bool _isScopeMatchingListFetching = false;
  bool _isScopeMathingItemListFetched = false;
  bool _modified = false;
  String _fetchErrorText = '';

  bool _isCommitting = false;
  bool _isCommitted = false;
  String _commitErrorText = '';

  List<Map<String, dynamic>>? _itemGroupScopeMatchingItemList;
  // List<Map<String, dynamic>>? _itemGroupItemList;
  List<Map<String, dynamic>>? _scopeMismatchItemList;

  // String? _selectedMeterIndexStr;
  bool _isFetchingAllAssignmentInfo = false;
  bool _isAllAssignmentInfoFetched = false;

  final TextEditingController _itemSnFilterController = TextEditingController();
  String _itemSnFilterStr = '';

  Future<void> _doAutoPopulate() async {
    if (_isScopeMatchingListFetching) {
      return;
    }

    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'item_group_id': widget.strItemGroupIndex,
      'service_type': MeterGroupServiceType.comm.value,
    };

    _isScopeMatchingListFetching = true;
    try {
      final result = await ex(
        endpoint: PagUrlBase.eptPagGetAmMeterGroupScopeMeterList,
        crudType: 'read',
        opStr: 'get scope matching meter list',
        appConfig: widget.appConfig,
        queryMap: queryMap,
        svcClaim: MdlPagSvcClaim(
          userId: loggedInUser!.id,
          username: loggedInUser!.username,
          scope: '',
          target: '',
          operation: '',
        ),
      );
      // list of items that are matching the item group scope
      final itemGroupScopeMatchingItemList =
          result['item_group_scope_matching_item_list'];
      if (itemGroupScopeMatchingItemList == null) {
        throw Exception('item_group_scope_matching_item_list is null');
      }
      final scopeMismatchItemList = result['scope_mismatch_item_list'];
      if (scopeMismatchItemList == null) {
        throw Exception('scope_mismatch_item_list is null');
      }
      _itemGroupScopeMatchingItemList = List<Map<String, dynamic>>.from(
        itemGroupScopeMatchingItemList,
      );
      _scopeMismatchItemList =
          List<Map<String, dynamic>>.from(scopeMismatchItemList);

      // sort by label
      _itemGroupScopeMatchingItemList!.sort((a, b) {
        String labelA = a['label'] ?? '';
        String labelB = b['label'] ?? '';
        return labelA.compareTo(labelB);
      });
      for (Map<String, dynamic> itemInfo in _itemGroupScopeMatchingItemList!) {
        // itemInfo['assigned'] = false;
        String meterType = itemInfo['meter_type'] ?? '';
        bool hasMeterTypeMismatch = meterType != widget.meterType;
        itemInfo['meter_type_mismatch'] = hasMeterTypeMismatch;
      }
    } catch (e) {
      dev.log(e.toString());
      _fetchErrorText =
          getErrorText(e, defaultErrorText: 'Error fetching item group data');
      rethrow;
    } finally {
      setState(() {
        _isScopeMatchingListFetching = false;
        _isScopeMathingItemListFetched = true;
      });
    }
  }

  Future<void> _doCommit() async {
    if (_isCommitting) {
      return;
    }
    // filter out items that are not modified
    final List<Map<String, dynamic>> assignmentList =
        _itemGroupScopeMatchingItemList!
            .where((item) => item['assigned_new'] != null)
            .toList();
    if ((_scopeMismatchItemList ?? []).isNotEmpty) {
      assignmentList.clear();
      assignmentList.addAll(_scopeMismatchItemList!
          .where((item) => item['assigned_new'] != null)
          .toList());
    }
    Map<String, dynamic> queryMap = {
      'scope': loggedInUser!.selectedScope.toScopeMap(),
      'item_group_id': widget.strItemGroupIndex,
      'service_type': MeterGroupServiceType.comm.value,
      'item_assignment_list': assignmentList,
    };
    try {
      _isCommitting = true;

      final result = await ex(
        endpoint: PagUrlBase.eptUpdateAmMeterGroupMeterList,
        crudType: 'update',
        opStr: 'commit assignment',
        appConfig: widget.appConfig,
        queryMap: queryMap,
        svcClaim: MdlPagSvcClaim(
          userId: loggedInUser!.id,
          username: loggedInUser!.username,
          scope: '',
          target: '',
          operation: '',
        ),
      );

      // clear assginment info from the item list
      for (Map<String, dynamic> itemInfo in _itemGroupScopeMatchingItemList!) {
        itemInfo.remove('assignment_info');
        itemInfo.remove('assigned_new');
        itemInfo.remove('is_fetching');
      }
      await _doAutoPopulate(); // refresh the item list
    } catch (e) {
      dev.log(e.toString());
      setState(() {
        _commitErrorText = getErrorText(e, defaultErrorText: 'Commit error');
      });
    } finally {
      setState(() {
        _isCommitting = false;
        _isCommitted = true;
        _modified = false;
      });
    }
  }

  bool _checkModified({String assignmentErrorMessage = ''}) {
    bool modified = false;
    if (assignmentErrorMessage.isNotEmpty) {
      return false; // if there is an assignment error, do not consider it modified
    }

    for (Map<String, dynamic> item in _itemGroupScopeMatchingItemList ?? []) {
      if (item['assigned_new'] != null) {
        if (item['assigned'] != item['assigned_new']) {
          modified = true;
          break;
        }
      }
    }

    if ((_scopeMismatchItemList ?? []).isNotEmpty) {
      for (Map<String, dynamic> item in _scopeMismatchItemList!) {
        if (item['assigned_new'] != null) {
          if (item['assigned'] != item['assigned_new']) {
            modified = true;
            break;
          }
        }
      }
    } else {
      for (Map<String, dynamic> item in _itemGroupScopeMatchingItemList ?? []) {
        if (item['assigned_new'] != null) {
          if (item['assigned'] != item['assigned_new']) {
            modified = true;
            break;
          }
        }
      }
    }
    setState(() {
      _modified = modified;
    });
    return modified;
  }

  bool _showItem(Map<String, dynamic> item) {
    if (_itemSnFilterStr.isNotEmpty) {
      String? sn = item['meter_sn'];
      bool snMatches = (sn ?? '').isNotEmpty &&
          (sn ?? '').toLowerCase().contains(_itemSnFilterStr);
      return snMatches;
    }

    return true; // Include item if no filter is applied
  }

  @override
  void initState() {
    super.initState();

    loggedInUser = Provider.of<PagUserProvider>(
      context,
      listen: false,
    ).currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 500,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Symbols.assignment_ind, color: Colors.transparent),
              getItemGroupInfo(),
              IconButton(
                icon: const Icon(Symbols.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const Divider(thickness: 0.5),
          verticalSpaceTiny,
          getOpRow(),
          verticalSpaceSmall,
          Text(
            'List of meters matching the scope of this meter group:',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: getAssignmentOpList(),
          ),
        ],
      ),
    );
  }

  Widget getAssignmentOpList() {
    bool fetchData = false;

    if (_fetchErrorText.isNotEmpty) {
      return getErrorTextPrompt(
        context: context,
        errorText: _fetchErrorText,
      );
    }
    if (!_isScopeMathingItemListFetched) {
      fetchData = true;
    }
    return fetchData
        ? FutureBuilder(
            future: _doAutoPopulate(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const WgtPagWait();
                default:
                  if (snapshot.hasError) {
                    return getErrorTextPrompt(
                      context: context,
                      errorText: 'Error fetching tree data',
                    );
                  } else {
                    return completedWidget();
                  }
              }
            },
          )
        : completedWidget();
  }

  Widget completedWidget() {
    double listHeight = 500;
    if (_scopeMismatchItemList?.isNotEmpty ?? false) {
      listHeight = (_scopeMismatchItemList ?? []).length * 70.0;
    }
    return Container(
      height: listHeight + 85,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
        borderRadius: BorderRadius.circular(5),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: (_scopeMismatchItemList ?? []).isNotEmpty
          ?
          // resolve scope mismatch item list
          getScopeMismatchItemList(listHeight)
          : getScopeItemList(),
    );
  }

  Widget getScopeMismatchItemList(double listHeight) {
    List<Widget> itemWidgetList = [];
    int index = 0;

    for (Map<String, dynamic> itemInfo in (_scopeMismatchItemList ?? [])) {
      Widget tile = getItemRow(itemInfo, ++index);
      itemWidgetList.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: tile,
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border:
            Border.all(color: Theme.of(context).colorScheme.error, width: 5),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Column(
        children: [
          Text(
              'The following list contains the meter(s) with mismatched scope to the meter group. Please resolve the scope mismatch before proceeding with assignment operation.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 18)),
          Text('Clear this scope mismatch list before assignment op',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 18)),
          verticalSpaceSmall,
          SizedBox(
            height: listHeight,
            child: ListView.builder(
              // shrinkWrap: true,
              // itemExtent: 35,
              itemCount: itemWidgetList.length,
              itemBuilder: (context, index) {
                return itemWidgetList[index];
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget getOpRow() {
    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
      borderRadius: BorderRadius.circular(5),
      color: Theme.of(context).colorScheme.primary,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: SizedBox(
            width: 180,
            height: 39,
            child: TextField(
              controller: _itemSnFilterController,
              readOnly: _isCommitting ||
                  _isCommitted ||
                  {_itemGroupScopeMatchingItemList ?? []}.isEmpty,
              decoration: InputDecoration(
                  hintText: 'Meter S/N',
                  hintStyle: TextStyle(
                      color: Theme.of(context)
                          .hintColor) // prefixIcon: Icon(Icons.search),
                  ),
              onChanged: (value) {
                setState(() {
                  _itemSnFilterStr = value.trim().toLowerCase();
                });
              },
            ),
          ),
        ),
        horizontalSpaceSmall,
        InkWell(
          onTap: !_modified ||
                  _isCommitting ||
                  _isCommitted ||
                  (_itemGroupScopeMatchingItemList ?? []).isEmpty
              ? null
              : () async {
                  await _doCommit();
                  widget.onUpdate?.call();
                },
          child: _isCommitted && _commitErrorText.isEmpty
              ? Text(
                  '✓ Committed',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : _commitErrorText.isNotEmpty
                  ? getErrorTextPrompt(
                      context: context,
                      errorText: _commitErrorText,
                    )
                  : _isCommitting
                      ? const WgtPagWait(size: 21)
                      : Icon(
                          Icons.cloud_upload,
                          color: _modified
                              ? commitColor
                              : Theme.of(context).hintColor,
                        ),
        ),
      ],
    );
  }

  Widget getItemGroupInfo() {
    String itemGroupScopeLabel = widget.itemScope.getLeafScopeLabel();
    PagScopeType itemScopeType = widget.itemScope.getScopeType();
    Widget scopeIcon = getScopeIcon(context, itemScopeType, size: 21);
    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
      borderRadius: BorderRadius.circular(5),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Assignment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).hintColor,
          ),
        ),
        horizontalSpaceSmall,
        Text(
          widget.itemName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        horizontalSpaceSmall,
        Text(
          widget.itemLabel.isNotEmpty ? widget.itemLabel : '-',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        horizontalSpaceSmall,
        Container(
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              scopeIcon,
              horizontalSpaceTiny,
              Text(itemGroupScopeLabel),
            ],
          ),
        ),
        horizontalSpaceSmall,
        Container(
          // width: 20,
          decoration: boxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(widget.meterType),
        ),
        horizontalSpaceSmall,
        // Container(
        //   decoration: boxDecoration,
        //   padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        //   child: Text(widget.tariffPackageTypeLabel),
        // ),
      ],
    );
  }

  Widget getScopeItemList() {
    if (_itemGroupScopeMatchingItemList == null ||
        _itemGroupScopeMatchingItemList!.isEmpty) {
      return const Center(child: Text('No item found for this item group'));
    }
    List<Widget> itemWidgetList = [];
    int index = 0;
    for (Map<String, dynamic> itemInfo in _itemGroupScopeMatchingItemList!) {
      bool showItem = _showItem(itemInfo);
      index++;
      if (!showItem) {
        continue; // Skip this item if it doesn't match the filter
      }
      Widget tile = getItemRow(itemInfo, index);
      itemWidgetList.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
          child: tile,
        ),
      );
    }

    return ListView.builder(
      // shrinkWrap: true,
      // itemExtent: 35,
      itemCount: itemWidgetList.length,
      itemBuilder: (context, index) {
        return itemWidgetList[index];
      },
    );
  }

  Widget getItemRow(Map<String, dynamic> itemInfo, int index) {
    String itemName = itemInfo['item_name'] ?? '-';
    String itemLabel = itemInfo['item_label'] ?? '-';
    String meterSn = itemInfo['meter_sn'] ?? '-';
    // bool assigned = itemInfo['assigned'] ?? false;

    BoxDecoration boxDecoration = BoxDecoration(
      border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
      borderRadius: BorderRadius.circular(5),
    );

    TextStyle disabledTextStyle = TextStyle(
      color: Theme.of(context).hintColor.withAlpha(150),
    );

    bool disabled = false; //_hasTptMismatchAssignmentError;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              child: Align(
                alignment: Alignment.centerRight,
                child: SelectableText(
                  index.toString(),
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
            ),
            horizontalSpaceSmall,
            Container(
              width: 150,
              decoration: boxDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: SelectableText(
                itemName,
                style: disabled ? disabledTextStyle : null,
              ),
            ),
            horizontalSpaceSmall,
            Container(
              width: 135,
              decoration: boxDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: SelectableText(
                meterSn,
                style: disabled ? disabledTextStyle : null,
              ),
            ),
            horizontalSpaceSmall,
            Container(
              width: 160,
              decoration: boxDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: SelectableText(
                itemLabel,
                style: disabled ? disabledTextStyle : null,
              ),
            ),
            horizontalSpaceTiny,
            getAssignmentBox(itemInfo),
          ],
        ),
      ],
    );
  }

  Widget getAssignmentBox(Map<String, dynamic> itemInfo) {
    String? meterGroupName = itemInfo['assigned_item_group_name'];
    String? meterGroupLabel = itemInfo['assigned_item_group_label'];
    bool hasAssignmentInfo = meterGroupName != null;

    double barWidth = 180;
    String tooltipMessage = 'assigned to: ${meterGroupName ?? 'None'}';

    double margin = 45;
    bool checked = itemInfo['assigned_new'] ?? hasAssignmentInfo;
    bool disabled = false;
    return SizedBox(
      width: barWidth + margin,
      // height: 26,
      child: Tooltip(
        message: tooltipMessage,
        waitDuration: const Duration(milliseconds: 500),
        child: Row(
          children: [
            Container(
              height: 25,
              width: barWidth,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Theme.of(context).hintColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(meterGroupLabel ?? ''),
            ),
            horizontalSpaceTiny,
            Checkbox(
              value:
                  checked, //itemInfo['assigned_new'] ?? itemInfo['assigned'],
              onChanged: disabled
                  ? null
                  : (bool? value) {
                      setState(() {
                        if (value == null) return;
                        itemInfo['assigned_new'] = value;
                        if (itemInfo['assigned_new'] == true) {
                          itemInfo['percentage'] =
                              100.0; // Set to 100% if assigned
                        }
                        // if (itemInfo['assigned_new'] == false) {
                        //   itemInfo['assignment_info'] = null;
                        // }
                        _checkModified();
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }
}
