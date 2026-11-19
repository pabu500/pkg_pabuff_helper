import 'package:file_picker_web/file_picker_web.dart';

// Returning focus from the Windows dialog can precede delivery of its file.
const landlordLogoPickerOptions = FilePickerWebOptions(
  cancelUploadOnWindowBlur: false,
);
