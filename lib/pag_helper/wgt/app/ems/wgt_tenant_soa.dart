import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../xt_ui/wdgt/wgt_pag_wait.dart';
import '../../../comm/comm_tenant.dart';
import '../../../model/acl/mdl_pag_svc_claim.dart';
import '../../../model/mdl_pag_app_config.dart';
import '../../../model/mdl_pag_user.dart';

class WgtTenantSoA extends StatefulWidget {
  const WgtTenantSoA({
    super.key,
    required this.appConfig,
    required this.loggedInUser,
    required this.teneantInfo,
  });

  final MdlPagAppConfig appConfig;
  final MdlPagUser loggedInUser;
  final Map<String, dynamic> teneantInfo;

  @override
  State<WgtTenantSoA> createState() => _WgtTenantSoAState();
}

class _WgtTenantSoAState extends State<WgtTenantSoA> {
  late final tenantName;
  late final tenantLabel;

  bool _fetching = false;
  bool _fetched = false;
  String _errorText = '';

  final List<Map<String, dynamic>> _soaData = [];

  Future<dynamic> _doFetchSoaData() async {
    if (_fetching) {
      return;
    }
    Map<String, dynamic> queryMap = {};

    _errorText = '';
    _fetched = false;
    _fetching = true;

    try {
      final result = await doGetTenantSoa(
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
    } catch (e) {
      if (kDebugMode) {
        print('error: $e');
      }

      _errorText = 'Error fetching SoA data';

      return;
    } finally {
      setState(() {
        _fetched = true;
        _fetching = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    tenantName = widget.teneantInfo['name'] ?? '';
    tenantLabel = widget.teneantInfo['label'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (tenantName.isEmpty || tenantLabel.isEmpty) {
      return getErrorTextPrompt(
          context: context, errorText: 'Error: Misising tenant name or label');
    }

    bool pullData = _soaData.isEmpty && !_fetching && !_fetched;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Statement of Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tenant: $tenantName ($tenantLabel)',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        verticalSpaceSmall,
        pullData
            ? FutureBuilder(
                future: _doFetchSoaData(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      if (kDebugMode) {
                        print('waiting...');
                      }
                      return const Align(
                        alignment: Alignment.topCenter,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [WgtPagWait(size: 35)],
                        ),
                      );
                    // return getCompletedWidget();
                    default:
                      if (snapshot.hasError) {
                        if (kDebugMode) {
                          print(snapshot.error);
                        }
                        return getErrorTextPrompt(
                            context: context, errorText: 'Serivce Error');
                      } else {
                        return getCompletedWidget();
                      }
                  }
                })
            : getCompletedWidget()
      ],
    );
  }

  Widget getCompletedWidget() {
    if (_errorText.isNotEmpty) {
      return getErrorTextPrompt(context: context, errorText: _errorText);
    }
    if (_soaData.isEmpty) {
      return const Text('No SoA data available for this tenant.');
    }

    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [getSoA()],
    ));
  }

  Widget getSoA() {
    return Container(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _soaData.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              '${item['date']}: ${item['description']} - ${item['amount']}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
