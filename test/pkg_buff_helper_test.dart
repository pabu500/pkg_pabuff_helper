import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:buff_helper/pag_helper/def_helper/dh_acl.dart';
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

  group('validateResLabel', () {
    test('accepts lowerCamelCase paths', () {
      expect(validateResLabel('com'), isNull);
      expect(validateResLabel('myRes'), isNull);
      expect(validateResLabel('com.myRes'), isNull);
      expect(validateResLabel('com.myRes.yourScope'), isNull);
      expect(validateResLabel('res2.child3Value'), isNull);
    });

    test('rejects labels that are not lowerCamelCase paths', () {
      expect(validateResLabel('MyRes'), isNotNull);
      expect(validateResLabel('com.MyRes'), isNotNull);
      expect(validateResLabel('com..myRes'), isNotNull);
      expect(validateResLabel('.com'), isNotNull);
      expect(validateResLabel('com.'), isNotNull);
      expect(validateResLabel('my_res'), isNotNull);
      expect(validateResLabel('my-res'), isNotNull);
      expect(validateResLabel('2res'), isNotNull);
    });
  });
}
