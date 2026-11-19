@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:buff_helper/pag_helper/wgt/ls/landlord_logo_picker_options_web.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_picker_web/file_picker_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'a delayed selection survives focus returning from the dialog',
    () async {
      FilePickerWeb.registerWith(Registrar());
      final selection = FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['png'],
        webOptions: landlordLogoPickerOptions,
      );
      final element = web.document.querySelector(
        'input[type=file]',
      ) as web.HTMLInputElement;
      web.window.dispatchEvent(web.Event('focus'));
      // The plugin's focus-based cancellation timer would expire after 500 ms.
      await Future<void>.delayed(const Duration(milliseconds: 650));
      final data = web.DataTransfer();
      final bytes = Uint8List.fromList([137, 80, 78, 71]);
      data.items.add(web.File([bytes.toJS].toJS, 'logo.png'));
      element.files = data.files;
      element.dispatchEvent(web.Event('change'));

      final picked = await selection.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw StateError('Picker did not deliver its file'),
      );
      expect(picked?.name, 'logo.png');
      expect(await picked!.readAsBytes(), bytes);
    },
  );
}
