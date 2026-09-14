import 'dart:convert';
import 'package:download/download.dart';
import 'package:flutter/material.dart';
import 'tenant_meter_readings_csv.dart';

class WgtMeterReadingsDownload extends StatefulWidget {
  const WgtMeterReadingsDownload({
    super.key,
    required this.rows,
    required this.fallbackRows,
    required this.error,
    required this.tenantName,
    required this.fromDatetime,
    required this.toDatetime,
  });

  final List<dynamic>? rows;
  final List<dynamic> fallbackRows;
  final String? error;
  final String tenantName;
  final DateTime fromDatetime;
  final DateTime toDatetime;

  @override
  State<WgtMeterReadingsDownload> createState() =>
      _WgtMeterReadingsDownloadState();
}

class _WgtMeterReadingsDownloadState extends State<WgtMeterReadingsDownload> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final rows = widget.rows ?? widget.fallbackRows;
      if (rows.isEmpty && widget.error != null) throw Exception(widget.error);
      final tenant =
          widget.tenantName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final from = widget.fromDatetime.toIso8601String().split('T').first;
      final to = widget.toDatetime.toIso8601String().split('T').first;
      final csv = tenantMeterReadingsCsv(rows);
      await download(Stream<int>.fromIterable(utf8.encode('\uFEFF$csv')),
          '${tenant}_meter_readings_${from}_$to.csv');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Download all meter readings (CSV)',
        onPressed: _downloading ? null : _download,
        icon: _downloading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.cloud_download),
      );
}
