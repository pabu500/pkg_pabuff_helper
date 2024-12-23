import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:download/download.dart';
import 'dart:io';

import '../info/empty_result.dart';

// import 'package:evs2op/wgt/empty_result.dart';

class WgtSaveTable extends StatefulWidget {
  const WgtSaveTable({
    super.key,
    // required this.table,
    // required this.list,
    required this.getList,
    this.getListAsync,
    required this.fileName,
    this.directory,
    this.extension,
    this.tooltip,
    this.color,
    this.iconSize,
    this.enabled = true,
  });

  // final List<List<dynamic>> table;
  // final List<dynamic> list;
  final Function getList;
  final Function? getListAsync;
  final String fileName;
  final Directory? directory;
  final String? extension;
  final String? tooltip;
  final bool enabled;
  final double? iconSize;
  final Color? color;

  @override
  State<WgtSaveTable> createState() => _WgtSaveTableState();
}

class _WgtSaveTableState extends State<WgtSaveTable> {
  // Future<void> downloadCSV(Stream<String> stream, String filename) async {
  //   final bytes = await stream.toList();
  //   final file = File(filename);
  //   // file.writeAsBytes(bytes);
  //   file.writeAsString(bytes.toString());
  // }
  // Future<File> downloadCSV(String csv, String filename) async {
  //   final file = File(filename);
  //   // file.writeAsBytes(bytes);
  //   file.writeAsString(csv);
  //   return file;
  // }

  Future<void> _download(String csv, String filename) async {
    final stream = Stream.fromIterable(csv.codeUnits);
    download(stream, filename);
  }

  Future<String> _saveTable() async {
    // _download('bbb');
    // return 'ok';
    // Directory? path;
    // if (widget.directory != null) {
    //   path = widget.directory;
    // } else {
    // print('getDownloadsDirectory');
    // path = await getDownloadsDirectory();

    // }
    // if (widget.extension != null) {
    //   path = Directory('${path!.path}/${widget.fileName}.${widget.extension}');
    // } else {
    //   path = Directory('${path!.path}/${widget.fileName}.csv');
    // }
    // print('path: ${path.path}');
    try {
      late List<List<dynamic>> table;
      if (widget.getListAsync != null) {
        table = await widget.getListAsync!();
      } else {
        table = widget.getList();
      }
      // File file = File(path.path);
      if (kDebugMode) {
        print('convert to csv..');
      }
      String csv = const ListToCsvConverter().convert(table);
      if (kDebugMode) {
        print('write to file..');
      }
      String filename = '${widget.fileName}.csv';
      await _download(csv, filename);
      // final file = File(filename);
      // print('write to file..');
      // await file.writeAsString(csv);
      // print('save file..');
      // await FileSaver.instance.saveFile(
      //   name: filename,
      //   file: file,
      //   ext: 'csv',
      //   mimeType: MimeType.csv,
      // );
      // print('file saved..');
      if (mounted) {
        String msg = 'Report saved to $filename';
        showSnackBar(context, msg);
      }
      // return path.path;
      return filename;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      String msg = 'Failed to save report';
      if (mounted) {
        showSnackBar(context, msg);
      }
      return '';
    }
  }

  // @override
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.enabled ? _saveTable : null,
      icon: Icon(
        Icons.cloud_download,
        color: widget.color ?? Theme.of(context).hintColor.withOpacity(0.55),
        size: widget.iconSize,
        // size: 16,
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      tooltip: widget.tooltip ?? 'Download CSV',
    );
  }
}
