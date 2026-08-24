import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adds one to input values', () {
    final calculator = Calculator();
    expect(calculator.addOne(2), 3);
    expect(calculator.addOne(-7), -6);
    expect(calculator.addOne(0), 1);
  });

  group('getBillInvoiceNumber', () {
    test('returns the audit label for a released bill', () {
      expect(
        getBillInvoiceNumber({
          'lc_status': 'released',
          'audit_label': 'MG1-2026-06-00479',
          'bill_label': 'legacy-label',
        }),
        'MG1-2026-06-00479',
      );
    });

    test('returns an empty value for a bill that is not released', () {
      expect(
        getBillInvoiceNumber({
          'lc_status': 'pending_verification',
          'audit_label': 'MG1-2026-06-00479',
        }),
        isEmpty,
      );
    });

    test('returns an empty value when a released bill has no audit label', () {
      expect(getBillInvoiceNumber({'lc_status': 'released'}), isEmpty);
    });
  });
}
