import 'package:buff_helper/pag_helper/def_helper/def_fleet_health.dart';
import 'package:buff_helper/pag_helper/wgt/ls/wgt_pag_dashboard_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class WgtScopeEventIssuePanel extends StatefulWidget {
  const WgtScopeEventIssuePanel({
    super.key,
    this.issueData,
    this.title = 'Issues',
  });

  final String title;
  final Map<String, dynamic>? issueData;

  @override
  State<WgtScopeEventIssuePanel> createState() =>
      _WgtScopeEventIssuePanelState();
}

class _WgtScopeEventIssuePanelState extends State<WgtScopeEventIssuePanel> {
  final List<Map<String, dynamic>> _issueList = [];

  RenderBox? _renderBox;

  void _popluateList() {
    if (widget.issueData == null) {
      return;
    }

    // if (widget.issueData!['prop_stat'] != null) {
    //   var propStatList = widget.issueData!['prop_stat'];
    //   assert(propStatList != null);
    //   assert(propStatList is List);
    //   for (var propStat in propStatList) {
    //     String propStatName = propStat['name'];
    //     String propStatValue = propStat['value'];
    //     String propStatUnit = propStat['unit'];
    //     String propStatLabel = propStat['label'];

    //     _issueList.add({
    //       'item_label': propStatLabel,
    //       'issue_type_name': 'prop_stat',
    //       'issue_value': propStatValue + ' ' + propStatUnit,
    //       'health': 'normal',
    //     });
    //   }
    // }

    var fleetHealthList = widget.issueData!['fleet_health_list'];
    if (fleetHealthList == null) {
      return;
    }

    List<Map<String, dynamic>> issueList = [];

    for (var fhHealth in fleetHealthList) {
      String scopeName = fhHealth['name'];
      var fhDataList = fhHealth['fleet_health'];
      assert(fhDataList != null);
      assert(fhDataList is List);

      for (var fhData in fhDataList) {
        //fh of list of devices in the scope
        var fhList = fhData['fh_list'];
        assert(fhList != null);
        assert(fhList is List);

        String fhTypeNameStr = fhData['fh_type'] ?? '';

        PagFleetHealthIssueType fhType = PagFleetHealthIssueType.unknown;
        try {
          fhType = PagFleetHealthIssueType.values.byName(fhTypeNameStr);
        } catch (e) {
          if (kDebugMode) {
            print('Error: $e');
          }
        }

        String issueTypeKey = '';
        switch (fhType) {
          case PagFleetHealthIssueType.lrt:
            issueTypeKey = 'last_reading_timestamp';
            break;
          default:
            issueTypeKey = '';
        }

        for (var fh in fhList) {
          String itemName = fh['name'] ?? '';
          String? itemLabel = fh['label'];
          String buildingLabel = fh['building_label'] ?? '';
          String locationLabel = fh['location_label'] ?? '';
          String issueTypeValue = fh[issueTypeKey] ?? '';
          String health = fh['health'] ?? '';

          if (health == 'normal') {
            continue;
          }

          // print('itemlabel: $itemLabel, itemName: $itemName, issueTypeValue: $issueTypeValue, health: $health');

          issueList.add({
            // 'index': (index++).toString(),
            'item_label': itemLabel ?? itemName,
            'issue_type_name': fhType.name,
            'issue_value': issueTypeValue,
            'health': health,
            'building_label': buildingLabel,
            'location_label': locationLabel,
          });
        }
      }
    }

    // sort to put health 'unknown' at the end, adjusting index
    issueList.sort((a, b) {
      String healthA = a['health'];
      String healthB = b['health'];

      if (healthA == 'unknown') {
        return 1;
      } else if (healthB == 'unknown') {
        return -1;
      } else {
        return healthA.compareTo(healthB);
      }
    });
    int index = 1;
    for (var issue in issueList) {
      issue['index'] = (index++).toString();
    }

    _issueList.clear();
    _issueList.addAll(issueList);
  }

  @override
  void initState() {
    super.initState();

    _popluateList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _renderBox = context.findRenderObject() as RenderBox;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_renderBox == null) {
      return Container();
    }

    double width = _renderBox!.size.width;
    double height = _renderBox!.size.height;

    return Container(
      child: _issueList.isEmpty
          ? getOkPanel()
          : WgtPagDashboardList(
              maxHeight: height - 20,
              maxWidth: width - 50,
              title: widget.title,
              itemList: _issueList,
              reportNamePrefix: 'issue_list',
              showSelected: true,
              listConfig: const [
                {
                  'title': '#',
                  'col_key': 'index',
                  'width': 21.0,
                },
                {
                  'title': 'Type',
                  'col_key': 'issue_type_name',
                  'width': 35.0,
                  'use_widget': 'tagList',
                  'tooltip': 'Issue Type',
                },
                {
                  'title': 'Item',
                  'col_key': 'item_label',
                  'width': 120.0,
                },
                {
                  'title': 'Health',
                  'col_key': 'health',
                  'width': 35.0,
                  'use_widget': 'tagList',
                  // 'customWidget': getEventListItemField,
                },
                {
                  'title': 'Value',
                  'col_key': 'issue_value',
                  'width': 135.0,
                  'use_widget': 'box',
                },
                {
                  'title': 'Building',
                  'col_key': 'building_label',
                  'width': 135.0,
                  // 'use_widget': 'box',
                },
                {
                  'title': 'Location',
                  'col_key': 'location_label',
                  'width': 135.0,
                  'use_widget': 'box',
                },
              ],
            ),
    );
  }

  Widget getOkPanel() {
    return Container(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.done_outline,
              color: Colors.green.withAlpha(130),
              size: 55,
            ),
            Text('No issues found',
                style: TextStyle(
                  color: Colors.green.withAlpha(160),
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
      ),
    );
  }
}
