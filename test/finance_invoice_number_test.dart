import 'package:buff_helper/pag_helper/def_helper/dh_pag_finance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matching uses the audit number when invoice label differs', () {
    expect(
      getFinanceInvoiceNumber({
        'audit_label': 'MG_OUE-2026-08-00070',
        'label': 'MG_OUE-2026-08-00108',
        'bill_label': 'MG_OUE-2026-08-00108',
      }),
      'MG_OUE-2026-08-00070',
    );
  });

  test('payment apply details use the audit number', () {
    expect(
      getFinanceInvoiceNumber({
        'bill_lc_status': 'released',
        'audit_label': 'MG_OUE-2026-08-00070',
        'bill_label': 'MG_OUE-2026-08-00108',
      }),
      'MG_OUE-2026-08-00070',
    );
  });

  test('missing or blank audit numbers never fall back to invoice labels', () {
    for (final number in [null, '']) {
      expect(
        getFinanceInvoiceNumber({
          'audit_label': number,
          'label': 'MG_OUE-2026-08-00108',
          'bill_label': 'MG_OUE-2026-08-00108',
        }),
        isEmpty,
      );
    }
  });
}
