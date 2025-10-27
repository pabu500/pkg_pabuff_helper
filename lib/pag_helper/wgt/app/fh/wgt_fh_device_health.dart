import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/wgt/wgt_comm_button.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:developer' as dev;

import '../../../comm/comm_fh.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../ls/wgt_pag_dashboard_list.dart';

class WgtFhDeviceHealth extends StatefulWidget {
  const WgtFhDeviceHealth({
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
  State<WgtFhDeviceHealth> createState() => _WgtFhDeviceHealthState();
}

class _WgtFhDeviceHealthState extends State<WgtFhDeviceHealth> {
  late final TextStyle keyStyle = TextStyle(color: Theme.of(context).hintColor);
  late final TextStyle valueStyle =
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 18);
  final keyWidth = 30.0;
  final keyIconSize = 25.0;
  final valueWidth = null;
  final contentWidth = 375.0;

  final okColor = Colors.green.shade700;
  late final errorColor = Theme.of(context).colorScheme.error;
  final unknownColor = Colors.grey.shade600.withAlpha(210);

  final int minimumCooldownSeconds = 21;

  bool _isFetching = false;
  bool _isFetched = false;
  String _errorText = '';
  String _message = '';

  Map<String, dynamic> _selectedMeterInfo = {};
  bool? _isCheckingMeter;
  String _checkMeterErrorText = '';
  String _checkMeterMessage = '';

  final Map<String, dynamic> _gatewayHealthData = {};
  final Map<String, dynamic> _meterHealthData = {};

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
        final gatewayHealthInfo = result['gateway_health_info'];
        _gatewayHealthData.clear();
        _gatewayHealthData.addAll(gatewayHealthInfo);
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

  Future<void> _checkMeterStatus() async {
    if (_selectedMeterInfo.isEmpty) {
      return;
    }
    if (_isCheckingMeter == true) {
      return;
    }

    setState(() {
      _isCheckingMeter = true;
      _checkMeterErrorText = '';
      _checkMeterMessage = '';
    });

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'device_cat': PagDeviceCat.meter.name,
      'device_info': {
        'meter_sn': _selectedMeterInfo['meter_sn'],
        'meter_tag': _selectedMeterInfo['meter_tag'],
        'gateway_id': widget.deviceInfo['id'],
        'gateway_tag': widget.deviceInfo['tag'],
      },
    };

    try {
      final result = await getDeviceHealthInfo(
          widget.appConfig,
          queryMap,
          MdlPagSvcClaim(
            scope: '',
            target: '',
            operation: '',
          ));
      if (result['info'] != null) {
        _checkMeterMessage = result['message'];
        if (_checkMeterMessage.toLowerCase().contains('timeout')) {
          _checkMeterErrorText = 'Request timout';
        }
      } else {
        final meterHealthInfo = result['meter_health_info'];
        _meterHealthData.clear();
        _meterHealthData.addAll(meterHealthInfo);

        String commCheckResult = _meterHealthData['comm_check_result'] ?? '';
        if (commCheckResult == 'ok') {
          // remove the meter tag from the error list
          final content = _gatewayHealthData['content'];
          final errorList = content['el'] ?? [];
          for (var errMeterTag in errorList) {
            if (errMeterTag == _selectedMeterInfo['meter_tag']) {
              errorList.remove(errMeterTag);
              break;
            }
          }
        }
        if (commCheckResult == 'fail') {
          // add the meter tag to the error list if not already there
          final content = _gatewayHealthData['content'];
          final errorList = content['el'] ?? [];
          bool alreadyInList = false;
          for (var errMeterTag in errorList) {
            if (errMeterTag == _selectedMeterInfo['meter_tag']) {
              alreadyInList = true;
              break;
            }
          }
          if (!alreadyInList) {
            errorList.add(_selectedMeterInfo['meter_tag']);
          }
        }
      }
    } catch (e) {
      dev.log('Error checking meter status: $e');
      _checkMeterErrorText = 'Error checking meter status';
    } finally {
      setState(() {
        _isCheckingMeter = false;
        _isFetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool fetch = _gatewayHealthData.isEmpty && !_isFetched;

    if (_errorText.isNotEmpty) {
      return getErrorTextPrompt(context: context, errorText: _errorText);
    }
    if (_message.isNotEmpty) {
      return Container(
        width: contentWidth,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).hintColor.withAlpha(130)),
          borderRadius: BorderRadius.circular(5.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Symbols.info, color: Theme.of(context).hintColor),
            horizontalSpaceTiny,
            Flexible(
              child: Text(_message, style: valueStyle),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: contentWidth,
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
    if (_gatewayHealthData.isEmpty) {
      return const SizedBox.shrink();
    }

    String submittedTimestamp = _gatewayHealthData['submitted_timestamp'] ?? '';
    final content = _gatewayHealthData['content'];
    final version = content['v'];
    final temperature = content['t'];
    final signal = content['s'];
    final errorList = content['el'] ?? [];

    final meterGroupLabel =
        _gatewayHealthData['meter_group_label'] ?? 'Unknown';

    final meterInfoList = _gatewayHealthData['meter_info_list'] ?? [];

    List<Map<String, dynamic>> issueList = [];
    for (var error in errorList) {
      issueList.add({
        'issue_value': error ?? '',
      });
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        getTopStatPnl(),
        verticalSpaceSmall,
        getMeterGroupStatus(),
        verticalSpaceSmall,
        getMeterIssuePanel(),
        verticalSpaceMedium,
        if (false)
          // if (issueList.isNotEmpty)
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

  Widget getTopStatPnl() {
    String submittedTimestamp = _gatewayHealthData['submitted_timestamp'] ?? '';
    final content = _gatewayHealthData['content'];
    final version = content['v'];
    final temperature = content['t'];
    final signal = content['s'];
    final signalPercentage = content['s'] == null
        ? '-'
        : '${(int.parse(content['s'] as String) * 100 / 31).clamp(0, 100).toInt()}%';
    final ping = content['p'] == null ? ' - ' : '${content['p']}ms';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(130)),
        borderRadius: BorderRadius.circular(5.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: Column(
        children: [
          Tooltip(
            message: 'Last Health Data Submit Time',
            waitDuration: const Duration(milliseconds: 500),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: keyWidth,
                    child: Icon(Symbols.clock_arrow_up,
                        color: Theme.of(context).hintColor)),
                // horizontalSpaceTiny,
                SizedBox(
                    width: valueWidth,
                    child: Text(submittedTimestamp, style: valueStyle)),
              ],
            ),
          ),
          verticalSpaceSmall,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Version',
                waitDuration: const Duration(milliseconds: 500),
                child: Row(
                  children: [
                    Icon(Symbols.deployed_code,
                        size: keyIconSize - 3,
                        color: Theme.of(context).hintColor),
                    SizedBox(
                        width: valueWidth,
                        child: Text(version, style: valueStyle)),
                  ],
                ),
              ),
              horizontalSpaceSmall,
              Tooltip(
                message: 'Core Temperature',
                waitDuration: const Duration(milliseconds: 500),
                child: Wrap(
                  children: [
                    Icon(Symbols.thermostat,
                        size: keyIconSize - 2,
                        color: Theme.of(context).hintColor),
                    SizedBox(
                        width: valueWidth,
                        child: Text('$temperature°C', style: valueStyle)),
                  ],
                ),
              ),
              horizontalSpaceSmall,
              Tooltip(
                message: 'Signal Strength',
                waitDuration: const Duration(milliseconds: 500),
                child: Wrap(
                  children: [
                    Icon(Symbols.signal_cellular_alt,
                        size: keyIconSize - 2,
                        color: Theme.of(context).hintColor),
                    // horizontalSpaceTiny,
                    SizedBox(
                        width: valueWidth,
                        child: Text('$signal:$signalPercentage',
                            style: valueStyle)),
                  ],
                ),
              ),
              horizontalSpaceSmall,
              Tooltip(
                message: 'Ping Response Time',
                waitDuration: const Duration(milliseconds: 500),
                child: Wrap(
                  children: [
                    Icon(Symbols.network_ping,
                        size: keyIconSize - 2,
                        color: Theme.of(context).hintColor),
                    // horizontalSpaceTiny,
                    SizedBox(
                        width: valueWidth,
                        child: Text(ping, style: valueStyle)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget getMeterGroupStatus() {
    final meterGroupLabel =
        _gatewayHealthData['meter_group_label'] ?? 'Unknown';

    final content = _gatewayHealthData['content'];
    final errorList = content['el'];
    final meterInfoList = _gatewayHealthData['meter_info_list'] ?? [];

    // sort by tag strings
    meterInfoList.sort((a, b) {
      String tagA = a['meter_tag'] ?? '';
      String tagB = b['meter_tag'] ?? '';
      return tagA.compareTo(tagB);
    });

    // get a array of meeters,
    List<Widget> meterRowList = [];
    for (var meterInfo in meterInfoList) {
      final meterSn = meterInfo['meter_sn'] ?? 'Unknown';
      final meterTag = meterInfo['meter_tag'] ?? 'Unknown';

      bool hasError = false;
      bool isUnknown = false;
      if (errorList == null) {
        hasError = false;
        isUnknown = true;
      } else {
        for (var errMeterTag in errorList) {
          if (errMeterTag == meterTag) {
            hasError = true;
            isUnknown = false;
            break;
          }
        }
      }

      meterRowList.add(getMeterBox(meterTag, meterSn, hasError, isUnknown));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(130)),
        borderRadius: BorderRadius.circular(5.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: Column(
        children: [
          Tooltip(
            message: 'Meter Group',
            waitDuration: const Duration(milliseconds: 500),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: keyWidth,
                    child: Icon(PagDeviceCat.meterGroup.iconData,
                        color: Theme.of(context).hintColor)),
                horizontalSpaceTiny,
                SizedBox(
                    width: valueWidth,
                    child: Text(meterGroupLabel, style: valueStyle)),
              ],
            ),
          ),
          verticalSpaceSmall,
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              ...meterRowList,
            ],
          ),
        ],
      ),
    );
  }

  Widget getMeterBox(
      String meterTag, String meterSn, bool hasError, bool isUnknown) {
    return InkWell(
      onTap: _isCheckingMeter == true
          ? null
          : () {
              setState(() {
                if (meterSn == _selectedMeterInfo['meter_sn']) {
                  _selectedMeterInfo = {};
                  return;
                }
                _selectedMeterInfo = {
                  'meter_sn': meterSn,
                  'meter_tag': meterTag,
                };
                _checkMeterErrorText = '';
                _meterHealthData.clear();
              });
            },
      child: Container(
        width: 60,
        decoration: BoxDecoration(
          border: _selectedMeterInfo['meter_sn'] == meterSn
              ? Border.all(
                  color: Theme.of(context).hintColor.withAlpha(130), width: 5)
              : null,
          borderRadius: BorderRadius.circular(5.0),
          color: hasError
              ? errorColor
              : isUnknown
                  ? unknownColor
                  : okColor,
        ),
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
        child: Center(
            child: Text(meterTag,
                style: valueStyle.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary))),
      ),
    );
  }

  Widget getMeterIssuePanel() {
    if (_selectedMeterInfo.isEmpty) {
      return const SizedBox.shrink();
    }

    final content = _gatewayHealthData['content'];
    final errorList = content['el'] ?? [];
    final meterInfoList = _gatewayHealthData['meter_info_list'] ?? [];

    String gatewayLastStatusQueryTimestampStr =
        _gatewayHealthData['gateway_last_status_query_timestamp'] ?? '';
    String meterLastStatusQueryTimestampStr =
        _meterHealthData['last_status_query_timestamp'] ?? '';
    if (meterLastStatusQueryTimestampStr.isEmpty) {
      // search in the meter info list
      for (var meterInfo in meterInfoList) {
        if (meterInfo['meter_sn'] == _selectedMeterInfo['meter_sn']) {
          meterLastStatusQueryTimestampStr =
              meterInfo['meter_last_status_query_timestamp'] ?? '';
          break;
        }
      }
    }

    DateTime? gatewayLastStatusQueryTimestamp;
    DateTime? meterLastStatusQueryTimestamp;
    DateTime? localNow = getTargetLocalDatetimeNow(
        widget.loggedInUser.selectedScope.getProjectTimezone());
    if (gatewayLastStatusQueryTimestampStr.isNotEmpty) {
      gatewayLastStatusQueryTimestamp =
          DateTime.parse(gatewayLastStatusQueryTimestampStr).toLocal();
    }
    if (meterLastStatusQueryTimestampStr.isNotEmpty) {
      meterLastStatusQueryTimestamp =
          DateTime.parse(meterLastStatusQueryTimestampStr).toLocal();
    }

    String meterCooldownText = '';
    if (gatewayLastStatusQueryTimestamp != null) {
      int secondsSinceLastQuery =
          localNow.difference(gatewayLastStatusQueryTimestamp).inSeconds;
      if (secondsSinceLastQuery < minimumCooldownSeconds) {
        int waitSeconds = minimumCooldownSeconds - secondsSinceLastQuery;
        if (waitSeconds > 1) {
          meterCooldownText =
              'Comms in cooldown. Please wait $waitSeconds seconds before checking again.';
        }
      }
    }
    if (meterLastStatusQueryTimestamp != null) {
      int secondsSinceLastQuery =
          localNow.difference(meterLastStatusQueryTimestamp).inSeconds;
      if (secondsSinceLastQuery < minimumCooldownSeconds) {
        int waitSeconds = minimumCooldownSeconds - secondsSinceLastQuery;
        if (waitSeconds > 1) {
          meterCooldownText =
              'Comms in cooldown. Please wait $waitSeconds seconds before checking again.';
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(130)),
        borderRadius: BorderRadius.circular(5.0),
        color: _meterHealthData.isNotEmpty
            ? (_meterHealthData['comm_check_result'] == 'ok'
                ? okColor
                : (_meterHealthData['comm_check_result'] == 'fail'
                    ? errorColor
                    : unknownColor))
            : unknownColor,
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Last checked at: ', style: keyStyle),
              Text(
                  meterLastStatusQueryTimestampStr.isEmpty
                      ? '[unknown]'
                      : meterLastStatusQueryTimestampStr,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary)),
            ],
          ),
          verticalSpaceSmall,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //copy button for meter sn
              InkWell(
                child: Icon(Icons.copy,
                    size: 20, color: Theme.of(context).hintColor),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: _selectedMeterInfo['meter_sn']));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
              horizontalSpaceTiny,
              SelectableText('S/N: ${_selectedMeterInfo['meter_sn']}',
                  style: valueStyle.copyWith(
                      color: Theme.of(context).colorScheme.onSecondary)),
              horizontalSpaceSmall,
              WgtCommButton(
                  enabled: _isCheckingMeter != true &&
                      _isFetching != true &&
                      _meterHealthData.isEmpty &&
                      (_checkMeterErrorText.isEmpty),
                  label: 'Check Status',
                  labelWidget: Icon(Symbols.wifi_find,
                      color: Theme.of(context).colorScheme.onSecondary),
                  onPressed: () async {
                    await _checkMeterStatus();
                  }),
            ],
          ),
          if (_checkMeterErrorText.isNotEmpty)
            getErrorTextPrompt(
                context: context, errorText: _checkMeterErrorText),
          if (_meterHealthData.isNotEmpty) getMeterHealth(),
          verticalSpaceTiny,
          if (meterCooldownText.isNotEmpty)
            getErrorTextPrompt(
                context: context,
                errorText: meterCooldownText,
                textColor: Theme.of(context).hintColor,
                borderColor: Theme.of(context).hintColor),
        ],
      ),
    );
  }

  Widget getMeterHealth() {
    if (_meterHealthData.isEmpty) {
      return const SizedBox.shrink();
    }

    String commCheckResult = _meterHealthData['comm_check_result'] ?? '';

    return Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        child: commCheckResult.isEmpty
            ? Container()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      commCheckResult == 'ok'
                          ? 'Comm OK'
                          : commCheckResult == 'fail'
                              ? 'Comm Fail'
                              : _checkMeterMessage.isNotEmpty
                                  ? _checkMeterMessage
                                  : 'Comm Unknown',
                      style: valueStyle.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary)),
                ],
              ));
  }

  // Widget getOpPanel(Map<String, dynamic> fhStat) {
  //   if (widget.opPanelType == 'issue') {
  //     return WgtScopeEventIssuePanel(
  //       issueData: fhStat,
  //       title: 'Device Issues',
  //     );
  //   }

  //   return Container();
  // }
}
