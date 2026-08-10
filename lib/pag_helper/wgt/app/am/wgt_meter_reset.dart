import 'package:flutter/material.dart';
import 'dart:developer' as dev;

import 'package:buff_helper/pkg_buff_helper.dart';
import '../../../comm/comm_ex.dart';
import '../../../comm/pag_be_api_base.dart';
import '../../../def_helper/dh_pag_item.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../wgt_comm_button.dart';

class WgtMeterReset extends StatefulWidget {
  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final double width;
  final Map<String, dynamic> meterInfo;

  const WgtMeterReset({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.width,
    required this.meterInfo,
  });

  @override
  State<WgtMeterReset> createState() => _WgtMeterResetState();
}

class _WgtMeterResetState extends State<WgtMeterReset> {
  final List<Map<String, dynamic>> resetInfoList = [];

  late final leftMostDate;
  late final rightMostDate;

  bool _isFetchingResetInfo = false;
  bool _resetInfoFetched = false;
  String _fetchErrorText = '';

  bool _isAddingResetInfo = false;
  bool _resetInfoAdded = false;
  String _addResetInfoErrorText = '';

  String? _resetTimestamp;
  bool _isResetTimestampValidated = false;
  String? _resetAtReading;
  bool _isResetValueValidated = false;

  bool _isDeletingResetInfo = false;
  bool _resetInfoDeleted = false;
  String _deleteResetInfoErrorText = '';

  Future<void> _fetchMeterResetInfo() async {
    if (_isFetchingResetInfo) return;

    _isFetchingResetInfo = true;
    _resetInfoFetched = false;
    _fetchErrorText = '';

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'meter_id': widget.meterInfo['id'] ?? '',
    };

    try {
      final result = await ex(
        endpoint: PagUrlBase.eptGetMeterResetInfo,
        crudType: 'read',
        opStr: 'fetch meter reset history',
        appConfig: widget.appConfig,
        queryMap: queryMap,
        svcClaim: MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: 'read',
        ),
      );
      final meterResetHistory = result['meter_reset_history'];
      resetInfoList.clear();
      for (var resetInfo in meterResetHistory) {
        resetInfoList.add(resetInfo as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log(e.toString());
      _fetchErrorText = getErrorText(e,
          defaultErrorText: 'Error fetching meter reset history');
      rethrow;
    } finally {
      setState(() {
        _isFetchingResetInfo = false;
        _resetInfoFetched = true;
      });
    }
  }

  Future<void> _addMeterReset() async {
    if (_isAddingResetInfo) return;

    _isAddingResetInfo = true;
    _resetInfoAdded = false;
    _addResetInfoErrorText = '';

    _resetInfoDeleted = false;
    _deleteResetInfoErrorText = '';

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'meter_id': widget.meterInfo['id'] ?? '',
      'reset_timestamp': _resetTimestamp ?? '',
      'reset_at_reading': _resetAtReading ?? '',
    };

    try {
      final result = await ex(
        endpoint: PagUrlBase.eptAddMeterReset,
        crudType: 'create',
        opStr: 'add meter reset',
        appConfig: widget.appConfig,
        queryMap: queryMap,
        svcClaim: MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: 'create',
        ),
      );
      final meterResetHistory = result['meter_reset_history'];
      resetInfoList.clear();
      for (var resetInfo in meterResetHistory) {
        resetInfoList.add(resetInfo as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log(e.toString());
      _addResetInfoErrorText =
          getErrorText(e, defaultErrorText: 'Error adding meter reset');
      rethrow;
    } finally {
      setState(() {
        _isAddingResetInfo = false;
        _resetInfoAdded = true;
      });
    }
  }

  Future<void> _deleteMeterReset(String resetId, String resetTimestamp) async {
    if (_isDeletingResetInfo) return;

    _isDeletingResetInfo = true;
    _resetInfoDeleted = false;
    _deleteResetInfoErrorText = '';

    _resetInfoAdded = false;
    _addResetInfoErrorText = '';

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'meter_id': widget.meterInfo['id'] ?? '',
      'reset_timestamp': resetTimestamp,
      'meter_reset_id': resetId,
    };

    try {
      final result = await ex(
        endpoint: PagUrlBase.eptDeleteMeterReset,
        crudType: 'delete',
        opStr: 'delete meter reset',
        appConfig: widget.appConfig,
        queryMap: queryMap,
        svcClaim: MdlPagSvcClaim(
          username: widget.loggedInUser.username,
          userId: widget.loggedInUser.id,
          scope: '',
          target: '',
          operation: 'delete',
        ),
      );
      final meterResetHistory = result['meter_reset_history'];
      resetInfoList.clear();
      for (var resetInfo in meterResetHistory) {
        resetInfoList.add(resetInfo as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log(e.toString());
      _deleteResetInfoErrorText =
          getErrorText(e, defaultErrorText: 'Error deleting meter reset');
      rethrow;
    } finally {
      setState(() {
        _isDeletingResetInfo = false;
        _resetInfoDeleted = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    leftMostDate = DateTime(2000, 1, 1);
    rightMostDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withAlpha(50)),
        borderRadius: BorderRadius.circular(5.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      child: resetInfoList.isEmpty && !_resetInfoFetched
          ? WgtCommButton(
              label: 'Get Meter Reset History',
              onPressed: () async {
                await _fetchMeterResetInfo();
              },
            )
          : Column(
              children: [
                Text(
                  'Meter Reset History',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                const SizedBox(height: 5.0),
                getResetHistory(),
                Divider(color: Theme.of(context).hintColor.withAlpha(50)),
                getAddReset(),
              ],
            ),
    );
  }

  Widget getResetHistory() {
    if (_resetInfoFetched && resetInfoList.isEmpty) {
      return Text('No meter reset history found',
          style: TextStyle(color: Theme.of(context).hintColor));
    }
    if (_fetchErrorText.isNotEmpty) {
      return getErrorTextPrompt(context: context, errorText: _fetchErrorText);
    }
    if (_deleteResetInfoErrorText.isNotEmpty) {
      return getErrorTextPrompt(
          context: context, errorText: _deleteResetInfoErrorText);
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: resetInfoList.length,
      itemBuilder: (context, index) {
        final resetInfo = resetInfoList[index];
        String strResetId = resetInfo['id'] ?? '';
        String resetTimestamp = resetInfo['reset_timestamp'] ?? '';
        String resetAtReading = resetInfo['reset_at_reading'] ?? '';
        return ListTile(
          title: Row(
            children: [
              Text('Reset Date: $resetTimestamp'),
              IconButton(
                icon: Icon(Icons.delete,
                    size: 21, color: Theme.of(context).colorScheme.error),
                onPressed: () async {
                  await _deleteMeterReset(strResetId, resetTimestamp);
                },
              ),
            ],
          ),
          subtitle: Text('Reset At Reading: $resetAtReading'),
        );
      },
    );
  }

  Widget getAddReset() {
    if (_addResetInfoErrorText.isNotEmpty) {
      return getErrorTextPrompt(
          context: context, errorText: _addResetInfoErrorText);
    }
    if (_resetInfoAdded && _addResetInfoErrorText.isEmpty) {
      return Text('Meter reset added successfully',
          style: TextStyle(color: Theme.of(context).colorScheme.primary));
    }
    return Column(
      children: [
        SizedBox(
          width: 350,
          child: WgtTextField(
            appConfig: widget.appConfig,
            hintText: 'Reset Timestamp (YYYY-MM-DD HH:MM:SS)',
            labelText: 'Reset Timestamp (YYYY-MM-DD HH:MM:SS)',
            validator: getValidator(validateDatTimeStr, true),
            validateOnChange: false,
            onChanged: (val) {
              setState(() {
                _resetTimestamp = val;
                dev.log('Reset timestamp changed: $_resetTimestamp');
              });
            },
            onEditingComplete: () {},
            onValidate: (String? result) {
              setState(() {
                if (result == null) {
                  _isResetTimestampValidated = true;
                } else {
                  _isResetTimestampValidated = false;
                }
              });
            },
          ),
        ),
        SizedBox(
          width: 350,
          child: WgtTextField(
            appConfig: widget.appConfig,
            hintText: 'Reset At Reading',
            labelText: 'Reset At Reading',
            validator: getValidator(validateNumeric, true),
            validateOnChange: false,
            onChanged: (val) {
              setState(() {
                _resetAtReading = val;
                dev.log('Reset At Reading changed: $_resetAtReading');
              });
            },
            onEditingComplete: () {},
            onValidate: (String? result) {
              setState(() {
                if (result == null) {
                  _isResetValueValidated = true;
                } else {
                  _isResetValueValidated = false;
                }
              });
            },
          ),
        ),
        verticalSpaceSmall,
        WgtCommButton(
          label: 'Add Meter Reset',
          enabled: _isResetTimestampValidated && _isResetValueValidated,
          onPressed: () async {
            await _addMeterReset();
          },
        ),
        verticalSpaceSmall,
      ],
    );
  }
}
