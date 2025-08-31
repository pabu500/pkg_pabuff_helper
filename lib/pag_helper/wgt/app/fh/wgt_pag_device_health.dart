import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/xt_ui/wdgt/wgt_pag_wait.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

import '../../../comm/comm_fh.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../../model/mdl_pag_user.dart';

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
  bool _isFetching = false;
  bool _isFetched = false;
  String _errorText = '';

  final Map<String, dynamic> _deviceHealthData = {};

  Future<void> _fetchDeviceHealth() async {
    if (_isFetching || _isFetched) {
      return;
    }

    _isFetching = true;
    _errorText = '';

    Map<String, dynamic> queryMap = {
      'scope': widget.loggedInUser.selectedScope.toScopeMap(),
      'device_cat': widget.deviceCat.name,
      'device_info': widget.deviceInfo,
    };

    try {
      // Simulate a network call to fetch device health data
      // await Future.delayed(const Duration(seconds: 2));
      final result = await getDeviceHealth(
          widget.appConfig,
          queryMap,
          MdlPagSvcClaim(
            scope: '',
            target: '',
            operation: '',
          ));
    } catch (e) {
      _errorText = 'Failed to fetch device health data';
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
    return Container(
      height: widget.height,
      child: const Center(
        child: Text('Device Health Data Loaded'),
      ),
    );
  }
}
