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
    this.labelLeft,
    this.labelRight,
    required this.onSubmitFiles,
  });

  final String? tooltip;
  final Color? color;
  final int maxFiles;
  final String? labelLeft;
  final String? labelRight;
  final List<String>? fileExtensions;
  final Function onSubmitFiles;

  @override
  State<WgtSubmitFiles> createState() => _WgtSubmitFilesState();
}

class _WgtSubmitFilesState extends State<WgtSubmitFiles> {
  final List<String> _fileContentList = [];

  Future<dynamic> _getFile() async {
    try {
      await FilePicker.platform
          .pickFiles(
              type: FileType.custom,
              allowMultiple: true,
              allowedExtensions: widget.fileExtensions)
          .then((result) {
        if (result == null || result.files.isEmpty) {
          showSnackBar(context, 'Please select a file');
          return;
        }
        if (result.files.length > widget.maxFiles) {
          showSnackBar(context, 'Please select up to ${widget.maxFiles} files');
          return;
        }
        //check if the file is txt or csv
        bool getTextContent = true;
        for (var file in result.files) {
          if (file.extension != 'txt' && file.extension != 'csv') {
            getTextContent = false;
          }
        }
        if (getTextContent) {
          _getTextFileContent(result.files);
        } else {
          _getFileContent(result.files);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('piceker error: $e');
      }
    }
  }

  void _getTextFileContent(List<PlatformFile> textFiles) {
    try {
      _fileContentList.clear();
      try {
        for (var file in textFiles) {
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
        widget.onSubmitFiles(_fileContentList);
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }

      return;
    } catch (e) {
      if (kDebugMode) {
        print('piceker error: $e');
      }
    }
  }

  void _getFileContent(List<PlatformFile> files) {
    try {
      widget.onSubmitFiles(files);
    } catch (e) {
      if (kDebugMode) {
        print('piceker error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.labelLeft != null)
          Padding(
            padding: const EdgeInsets.only(right: 0.0),
            child: Text(
              widget.labelLeft!,
              style: TextStyle(
                color: widget.color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        IconButton(
          onPressed: _getFile,
          icon: Icon(
            Icons.upload_file,
            color: widget.color ?? Theme.of(context).colorScheme.primary,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          tooltip: widget.tooltip ?? 'Submit files',
        ),
        if (widget.labelRight != null)
          Padding(
            padding: const EdgeInsets.only(left: 0.0),
            child: Text(
              widget.labelRight!,
              style: TextStyle(
                color: widget.color ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
