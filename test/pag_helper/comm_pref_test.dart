import 'package:buff_helper/pag_helper/comm/comm_pref.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_device.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_list.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_pag_item.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_scope.dart';
import 'package:buff_helper/pag_helper/model/list/mdl_list_col_controller.dart';
import 'package:flutter/widgets.dart';
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

  test('finder preference key has a distinct suffix', () {
    expect(
      getFinderPinPrefKey(
        aclResLabel: 'ems.meterManager.meterList',
        itemKind: PagItemKind.device,
        itemType: PagDeviceCat.meter,
        listContextType: PagListContextType.info,
      ),
      'ems.meterManager.meterList.device.meter.info.finder',
    );
  });

  group('list info pinned default', () {
    test('accepts string true', () {
      final column = MdlListColController.fromJson({
        'col_key': 'name',
        'pinned': 'true',
      });

      expect(column.pinned, isTrue);
    });

    test('is false when omitted', () {
      final column = MdlListColController.fromJson({'col_key': 'name'});

      expect(column.pinned, isFalse);
    });
  });

  group('list column padding', () {
    test('parses left, top, right, bottom string values', () {
      final column = MdlListColController.fromJson({
        'col_key': 'balance',
        'padding': ['0', '0', '8', '0'],
      });

      expect(column.padding, const EdgeInsets.fromLTRB(0, 0, 8, 0));
    });

    test('also accepts numeric values', () {
      final column = MdlListColController.fromJson({
        'col_key': 'balance',
        'padding': [1, 2.5, 3, 4],
      });

      expect(column.padding, const EdgeInsets.fromLTRB(1, 2.5, 3, 4));
    });

    test('accepts margin as a configuration alias', () {
      final column = MdlListColController.fromJson({
        'col_key': 'balance',
        'margin': ['0', '0', '8', '0'],
      });

      expect(column.padding, const EdgeInsets.fromLTRB(0, 0, 8, 0));
    });

    test('serializes values as strings', () {
      final column = MdlListColController(
        colKey: 'balance',
        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
      );

      expect(column.toJson()['padding'], ['0.0', '0.0', '8.0', '0.0']);
    });
  });

  group('list column preference eligibility', () {
    test('allows a column visible in the list configuration', () {
      final column = MdlListColController(colKey: 'name', colTitle: 'Name');

      expect(
        canUserOverrideListColumnVisibility(column, {'name': true}),
        isTrue,
      );
    });

    test('rejects a column hidden by the list configuration', () {
      final column = MdlListColController(colKey: 'name', colTitle: 'Name');

      expect(
        canUserOverrideListColumnVisibility(column, {'name': false}),
        isFalse,
      );
    });

    test('rejects a permanently hidden column', () {
      final column = MdlListColController(
        colKey: 'name',
        colTitle: 'Name',
        hidden: true,
      );

      expect(
        canUserOverrideListColumnVisibility(column, {'name': true}),
        isFalse,
      );
    });
  });

  group('list column scope visibility', () {
    const config = {
      'col_key': 'label',
      'visible_at_scope_list': ['project'],
    };

    test('shows the column at an allowed scope', () {
      final column = MdlListColController.fromJson(
        config,
        currentScopeType: PagScopeType.project,
      );

      expect(column.showColumn, isTrue);
    });

    test('hides the column at a different scope', () {
      final column = MdlListColController.fromJson(
        config,
        currentScopeType: PagScopeType.site,
      );

      expect(column.showColumn, isFalse);
    });

    test('scope restriction cannot be overridden by a saved preference', () {
      final column = MdlListColController.fromJson(
        config,
        currentScopeType: PagScopeType.site,
      );

      expect(
        canUserOverrideListColumnVisibility(column, {
          'label': column.showColumn,
        }),
        isFalse,
      );
    });

    test('hides a restricted column when the current scope is unavailable', () {
      final column = MdlListColController.fromJson(config);

      expect(column.showColumn, isFalse);
    });

    test('leaves an unrestricted column visible', () {
      final column = MdlListColController.fromJson({
        'col_key': 'name',
      }, currentScopeType: PagScopeType.site);

      expect(column.showColumn, isTrue);
    });
  });
}
