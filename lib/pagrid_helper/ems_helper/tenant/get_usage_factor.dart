import 'package:buff_helper/pagrid_helper/pagrid_helper.dart';
import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';

Future<dynamic> pullUsageFactor({
  required PaGridAppConfig appConfig,
  required String scopeStr,
  required DateTime fromDatetime,
  required DateTime toDatetime,
  // required Function onPulling,
  // required Function onPulled,
  // required Function onEexception,
  required Map<String, dynamic> usageFactor,
}) async {
  List<String> meterTypes = ['E', 'W', 'B', 'N', 'G'];

  if (usageFactor.isNotEmpty) {
    for (var type in meterTypes) {
      usageFactor[type] = usageFactor['usage_factor_$type'.toLowerCase()];
    }
    return usageFactor;
  }

  // onPulling();

  try {
    final usageFactorListReuslt = await getUsageFactor(
      appConfig,
      {
        'scope_str': scopeStr,
        'from_timestamp': fromDatetime.toIso8601String(),
        'to_timestamp': toDatetime.toIso8601String(),
      },
      SvcClaim(
        username: '123',
        userId: 123,
        scope: AclScope.global.name,
        target: getAclTargetStr(AclTarget.bill_p_info),
        operation: AclOperation.read.name,
      ),
    );

    for (var usageFactor in usageFactorListReuslt['usage_factor_list']) {
      // get last char of the name
      String type =
          usageFactor['name'].replaceAll('usage_factor_', '').toUpperCase();
      double? factor = double.tryParse(usageFactor['value'] ?? '');
      if (factor != null) {
        usageFactor[type] = factor;
      }
    }
    return usageFactor;
  } catch (e) {
    // onEexception(e);
    if (kDebugMode) {
      print('Error: $e');
    }
  } finally {
    // onPulled();
  }
}
