import 'package:buff_helper/xt_ui/style/evs2_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scanner_error_widget.dart';
import 'dart:developer' as dev;

class WgtCodeScanner2 extends StatefulWidget {
  const WgtCodeScanner2({
    super.key,
    this.title = 'Scan Code',
    required this.onDetect,
    this.validator,
  });

  final String title;
  final void Function(String code) onDetect;
  final String? Function(String code)? validator;

  @override
  State<WgtCodeScanner2> createState() => _WgtCodeScanner2State();
}

class _WgtCodeScanner2State extends State<WgtCodeScanner2>
    with SingleTickerProviderStateMixin {
  late final TextStyle labelStyle =
      TextStyle(color: commitColor, fontSize: 18, fontWeight: FontWeight.bold);
  // BarcodeCapture? _capture;
  // String _overlayText = "Please scan code";
  bool _isValid = false;
  Barcode? _barcode;

  Widget _barcodePreview() {
    if (_barcode == null) {
      return Text(
        'Scan Barcode/QR Code',
        overflow: TextOverflow.fade,
        style: labelStyle,
      );
    }

    return Text(
      _barcode?.displayValue ?? 'No display value.',
      overflow: TextOverflow.fade,
      style: labelStyle,
    );
  }

  void _onDetect(BarcodeCapture barcodes) {
    if (!mounted) return;

    if (barcodes.barcodes.isEmpty) return;

    _barcode = barcodes.barcodes.firstOrNull;
    if (_barcode == null) {
      return;
    }

    String code = _barcode?.rawValue ?? '';

    setState(() {
      String allCodes = barcodes.barcodes.map((b) => b.rawValue).join(', ');
      dev.log('barcodes found: $allCodes');

      dev.log('code: $code');

      _isValid = widget.validator == null;
      if (widget.validator?.call(code) == null) {
        _isValid = true;
      }
      if (_isValid) {
        dev.log('validated code: $code');
        widget.onDetect(code);
        return Navigator.of(context).pop(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 350,
      height: 230,
    );

    return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Container(),
            MobileScanner(
              // scanWindow: scanWindow,
              // fit: BoxFit.contain,
              onDetect: _onDetect,
              // errorBuilder: (context, ex) {
              //   return ScannerErrorWidget(error: ex);
              // },
              // overlayBuilder: (context, box) {
              //   return Container(
              //     width: scanWindow.width,
              //     height: scanWindow.height,
              //     decoration: BoxDecoration(
              //       border: Border.all(
              //         color: Theme.of(context).colorScheme.primary,
              //         width: 3,
              //       ),
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     child: Transform.translate(
              //       offset: Offset(0, scanWindow.height / 2 + 21),
              //       child: Align(
              //         alignment: Alignment.center,
              //         child: _barcodePreview(),
              //       ),
              //     ),
              //   );
              // },
            ),
          ],
        ));
  }
}
