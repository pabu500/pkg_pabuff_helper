import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:developer' as dev;

import '../../../comm/comm_fh.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../../model/mdl_pag_user.dart';
import '../../ls/wgt_pag_dashboard_list.dart';

class WgtPagDeviceHealth extends StatefulWidget {
  const WgtPagDeviceHealth({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.deviceCat,
    required this.deviceInfo,
    this.height = 500,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final PagDeviceCat deviceCat;
  final Map<String, dynamic> deviceInfo;
  final double height;

  @override
  State<WgtPagDeviceHealth> createState() => _WgtPagDeviceHealthState();
}

class _WgtPagDeviceHealthState extends State<WgtPagDeviceHealth> {
  late final TextStyle keyStyle = TextStyle(color: Theme.of(context).hintColor);
  late final TextStyle valueStyle =
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 21);
  final keyWidth = 39.0;
  final valueWidth = 230.0;

  bool _isFetching = false;
  bool _isFetched = false;
  String _errorText = '';
  String _message = '';

  final Map<String, dynamic> _deviceHealthData = {};

  Future<void> _fetchDeviceHealth() async {
    if (_isFetching || _isFetched) {
      return;
    }

    _isFetching = true;
    _errorText = '';
    _message = '';

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'device_cat': widget.deviceCat.name,
      'device_info': widget.deviceInfo,
    };

    try {
      // Simulate a network call to fetch device health data
      // await Future.delayed(const Duration(seconds: 2));
      final result = await getDeviceHealthInfo(
          widget.appConfig,
          queryMap,
          MdlPagSvcClaim(
            scope: '',
            target: '',
            operation: '',
          ));
      if (result['info'] != null) {
        _message = result['message'];
      } else {
        _deviceHealthData.clear();
        _deviceHealthData.addAll(result);
      }
    } catch (e) {
      _errorText = 'Error getting device health info';
    } finally {
      setState(() {
        _isFetching = false;
        _isFetched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool fetch = _deviceHealthData.isEmpty && !_isFetched;

    if (_errorText.isNotEmpty) {
      return getErrorTextPrompt(context: context, errorText: _errorText);
    }
    if (_message.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(_message)],
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            child: fetch
                ? FutureBuilder(
                    future: _fetchDeviceHealth(),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                          dev.log('device health: pulling data');

                          return const SizedBox(
                            height: 200,
                            child: Align(
                              alignment: Alignment.center,
                              child: WgtPagWait(),
                            ),
                          );
                        default:
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            return completedWidget();
                          }
                      }
                    },
                  )
                : completedWidget(),
          ),
        ],
      ),
    );
  }

  Widget completedWidget() {
    if (_deviceHealthData.isEmpty) {
      return const SizedBox.shrink();
    }

    String submittedTimestamp = _deviceHealthData['submitted_timestamp'] ?? '';
    final content = _deviceHealthData['content'];
    final version = content['v'];
    final temperature = content['t'];
    final signal = content['s'];
    final errorList = content['el'] ?? [];

    List<Map<String, dynamic>> issueList = [];
    for (var error in errorList) {
      issueList.add({
        'issue_value': error ?? '',
      });
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: keyWidth,
                child: Icon(Symbols.clock_arrow_up,
                    color: Theme.of(context).hintColor)),
            horizontalSpaceTiny,
            SizedBox(
                width: valueWidth,
                child: Text(submittedTimestamp, style: valueStyle)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: keyWidth,
                child: Icon(Symbols.deployed_code,
                    color: Theme.of(context).hintColor)),
            horizontalSpaceTiny,
            SizedBox(
                width: valueWidth, child: Text(version, style: valueStyle)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: keyWidth,
                child: Icon(Symbols.thermostat,
                    color: Theme.of(context).hintColor)),
            horizontalSpaceTiny,
            SizedBox(
                width: valueWidth, child: Text(temperature, style: valueStyle)),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
                width: keyWidth,
                child: Icon(Symbols.signal_cellular_alt,
                    color: Theme.of(context).hintColor)),
            horizontalSpaceTiny,
            SizedBox(width: valueWidth, child: Text(signal, style: valueStyle)),
          ],
        ),
        // if (errorList.isNotEmpty)
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   // crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //     SizedBox(
        //       width: keyWidth,
        //       child: Icon(Symbols.error_outline,
        //           color: Theme.of(context).colorScheme.error),
        //     ),
        //     horizontalSpaceTiny,
        // Column(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //     SizedBox(
        //       width: valueWidth,
        //       child: Text('Errors',
        //           style: valueStyle.copyWith(
        //               color: Theme.of(context).colorScheme.error)),
        //     ),
        //     ...errorWidgets
        //   ],
        // ),
        // ],
        // ),
        if (issueList.isNotEmpty)
          WgtPagDashboardList(
            maxWidth: 120,
            title: 'Error List',
            itemList: issueList,
            reportNamePrefix: 'issue_list',
            listConfig: const [
              {
                'title': 'Value',
                'col_key': 'issue_value',
                'width': 50.0,
                'use_widget': 'box',
              },
            ],
          ),
        verticalSpaceSmall,
      ],
    );
  }
}
