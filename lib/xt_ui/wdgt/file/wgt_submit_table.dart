import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:developer' as dev;
import '../info/empty_result.dart';

class WgtSubmitTable extends StatefulWidget {
  const WgtSubmitTable({
    super.key,
    this.tooltip,
    this.fileExtensions,
    this.color,
    required this.getList,
    this.getHeader,
    this.onGetFileInfo,
    this.onListLoaded,
  });

  final String? tooltip;
  final Color? color;
  final List<String>? fileExtensions;
  final Function getList;
  final Function(List<String>)? getHeader;
  final Function? onGetFileInfo;
  final Function? onListLoaded;

  @override
  State<WgtSubmitTable> createState() => _WgtSubmitTableState();
}

class _WgtSubmitTableState extends State<WgtSubmitTable> {
  List<List> _table = [];

  Future<dynamic> _getCsv() async {
    FilePickerResult? result;
    File file;
    try {
      result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowMultiple: false,
          allowedExtensions: widget.fileExtensions ?? ['csv']);
    } catch (e) {
      if (kDebugMode) {
        print('piceker error: $e');
      }
    }
    if (result != null && result.files.isNotEmpty) {
      try {
        Uint8List? uploadfile = result.files.single.bytes;
        if (uploadfile == null) {
          if (mounted) {
            showSnackBar(context, 'Please select a csv file');
          }
          return;
        }

        final bytes = utf8.decode(uploadfile.toList());
        final csv = const CsvToListConverter(eol: "\r\n", fieldDelimiter: ",")
            .convert(bytes);

        List<String> header = csv[0].map((e) => e.toString()).toList();

        // setState(() {
        _table = csv;
        // });
        filterEmptyRows(_table);

        widget.getList(_table);
        widget.getHeader?.call(header);

        widget.onListLoaded?.call();
        // String filename = result.files.first.name;
        // widget.onGetFileInfo?.call(filename);
        if (widget.onGetFileInfo != null) {
          String filename = result.files.single.name;
          widget.onGetFileInfo!(filename);
        }
      } catch (e) {
        dev.log(e.toString());
      }
    }

    // if (result != null) {
    //   //check extension
    //   if (result.files.single.extension != 'csv') {
    //     showSnackBar(context, 'Please select a csv file');
    //     return;
    //   }

    //   //NOTE: Path will not work on web
    //   file = File(result.files.single.path!);
    //   final csv = const CsvToListConverter().convert(file.readAsStringSync());
    //   // if (kDebugMode) {
    //   //   print(csv);
    //   // }
    //   setState(() {
    //     _table = csv;
    //   });
    //   widget.getList(_table);
    // } else {
    //   // User canceled the picker
    // }
  }

  void filterEmptyRows(List<List> table) {
    List<List> newTable = [];
    for (var row in table) {
      if (row.any((cell) => cell != null && cell != '')) {
        newTable.add(row);
      }
    }
    setState(() {
      _table = newTable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _getCsv,
      icon: Icon(
        Icons.upload_file,
        color: widget.color ?? Theme.of(context).colorScheme.primary,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      tooltip: widget.tooltip ?? 'Submit csv file',
    );
  }
}
