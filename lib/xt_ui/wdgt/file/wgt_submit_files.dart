import 'dart:async';
import 'dart:convert';

import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class WgtSubmitFiles extends StatefulWidget {
  const WgtSubmitFiles({
    super.key,
    this.tooltip,
    this.fileExtensions,
    this.color,
    this.maxFiles = 10,
    required this.onImportFiles,
  });

  final String? tooltip;
  final Color? color;
  final int maxFiles;
  final List<String>? fileExtensions;
  final Function onImportFiles;

  @override
  State<WgtSubmitFiles> createState() => _WgtSubmitFilesState();
}

class _WgtSubmitFilesState extends State<WgtSubmitFiles> {
  final List<String> _fileContentList = [];

  Future<dynamic> _getTextFileContent() async {
    try {
      await FilePicker.platform
          .pickFiles(
              type: FileType.custom,
              allowMultiple: true,
              allowedExtensions: widget.fileExtensions)
          .then((result) {
        if (result != null && result.files.isNotEmpty) {
          if (result.files.length > widget.maxFiles) {
            showSnackBar(
                context, 'Please select up to ${widget.maxFiles} files');

            return;
          }
          _fileContentList.clear();
          try {
            for (var file in result.files) {
              Uint8List? uploadfile = file.bytes;
              if (uploadfile == null) {
                if (uploadfile == null) {
                  showSnackBar(context, 'Please select a file');
                  return;
                }
              }

              final bytes = utf8.decode(uploadfile);
              _fileContentList.add(bytes);
            }
            widget.onImportFiles(_fileContentList);
          } catch (e) {
            if (kDebugMode) {
              print(e);
            }
          }
        }
        return;
      });
    } catch (e) {
      if (kDebugMode) {
        print('piceker error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _getTextFileContent,
      icon: Icon(
        Icons.upload_file,
        color: widget.color ?? Theme.of(context).colorScheme.primary,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      tooltip: widget.tooltip ?? 'Submit files',
    );
  }
}
