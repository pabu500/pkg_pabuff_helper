import 'package:buff_helper/pag_helper/comm/comm_pref.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_list.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getListColumnPrefKey', () {
    test('includes distinct item type', () {
      expect(
        getListColumnPrefKey(
          aclResLabel: 'ems.meterManager.meterList',
          itemKind: PagItemKind.device,
          itemType: PagDeviceCat.meter,
          listContextType: PagListContextType.info,
        ),
        'ems.meterManager.meterList.device.meter.info',
      );
    });

    test('omits item type when it repeats item kind', () {
      expect(
        getListColumnPrefKey(
          aclResLabel: 'ems.tenantManager.tenantUsage',
          itemKind: PagItemKind.tenant,
          itemType: PagItemKind.tenant,
          listContextType: PagListContextType.usage,
        ),
        'ems.tenantManager.tenantUsage.tenant.usage',
      );
    });

    test('omits absent item type', () {
      expect(
        getListColumnPrefKey(
          aclResLabel: 'ems.billingManager.billList',
          itemKind: PagItemKind.bill,
          itemType: null,
          listContextType: PagListContextType.info,
        ),
        'ems.billingManager.billList.bill.info',
      );
    });
  });
}
