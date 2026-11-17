import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:buff_helper/pag_helper/comm/comm_helper.dart';
import 'package:buff_helper/pag_helper/comm/comm_tenant_auth.dart';

void main() {
  test('conversion errors remove leading wrappers and retain the full message', () {
    const message =
        'Conversion commit result is unknown; refresh the tenant before retrying';
    for (final error in [
      message,
      StateError(message),
      Exception('m:$message'),
      Exception('Bad state: m:$message'),
      {'message': 'm:$message'},
      {
        'error': {'message': message},
      },
    ]) {
      expect(previousSystemDebtorErrorText(error), message);
    }
    expect(
      previousSystemDebtorErrorText(Exception('Please sign in again')),
      'Please sign in again',
    );
    expect(
      previousSystemDebtorErrorText('Keep Exception: inside the message'),
      'Keep Exception: inside the message',
    );
    expect(previousSystemDebtorErrorText(null), 'Conversion failed');
    expect(
      previousSystemDebtorErrorText('Exception: m: '),
      'Conversion failed',
    );
  });

  test('shared backend response errors are readable in the convert flow', () {
    const message =
        'Service end date is required and must not be after cutover';
    final response = jsonEncode({
      'error': {'message': 'm:$message'},
    });
    try {
      getResultFromResp(response);
      fail('Expected a backend error');
    } catch (error) {
      expect(previousSystemDebtorErrorText(error), message);
    }
  });
}
