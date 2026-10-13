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

  test('legacy payment apply details fall back to their bill label', () {
    expect(
      getFinanceInvoiceNumber({
        'bill_lc_status': 'released',
        'audit_label': null,
        'bill_label': 'MG_OUE-2026-07-00107',
      }),
      'MG_OUE-2026-07-00107',
    );
  });

  test('opening bills fall back to their label', () {
    expect(
      getFinanceInvoiceNumber({
        'audit_label': null,
        'label': 'INI-BILL-C3300225FTA',
      }),
      'INI-BILL-C3300225FTA',
    );
  });

  test('bill label is preferred to the generic label for payment details', () {
    expect(
      getFinanceInvoiceNumber({
        'audit_label': null,
        'bill_label': 'MG_OUE-2026-07-00107',
        'label': 'Payment label',
      }),
      'MG_OUE-2026-07-00107',
    );
  });

  test('fallback is null-only and preserves an existing empty audit number', () {
    expect(
      getFinanceInvoiceNumber({
        'audit_label': '',
        'bill_label': 'MG_OUE-2026-07-00107',
      }),
      isEmpty,
    );
  });

  test('missing all invoice identifiers stays empty', () {
    expect(getFinanceInvoiceNumber({}), isEmpty);
    expect(
      getFinanceInvoiceNumber({
        'audit_label': null,
        'bill_label': null,
        'label': null,
      }),
      isEmpty,
    );
  });
}
