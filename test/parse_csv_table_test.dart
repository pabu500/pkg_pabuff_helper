import 'package:buff_helper/xt_ui/wdgt/file/parse_csv_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final eol in ['\n', '\r\n', '\r']) {
    test(
      'preserves payment strings and quoted fields with ${eol.codeUnits}',
      () {
        final rows = parseCsvTable(
          '\ufeffamount,tenant_ref_1,remark$eol'
          '-100.00,000123,"line 1\nline 2, ""quoted"""$eol',
        );
        expect(rows, [
          ['amount', 'tenant_ref_1', 'remark'],
          ['-100.00', '000123', 'line 1\nline 2, "quoted"'],
        ]);
      },
    );
  }
  test(
    'ignores newline inside quoted header when detecting record separator',
    () {
      expect(parseCsvTable('"multi\nline",amount\r\nvalue,-100.00\r\n'), [
        ['multi\nline', 'amount'],
        ['value', '-100.00'],
      ]);
    },
  );
  test('rejects malformed quotes', () {
    expect(
      () => parseCsvTable('id,remark\n1,"unterminated'),
      throwsFormatException,
    );
  });
}
