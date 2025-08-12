import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scanner_error_widget.dart';

class WgtCodeScanner extends StatefulWidget {
  const WgtCodeScanner({
    super.key,
    this.title = 'Scan Code',
    required this.onDetect,
    this.validator,
  });

  final String title;
  final void Function(String code) onDetect;
  final String? Function(String code)? validator;

  @override
  State<WgtCodeScanner> createState() => _WgtCodeScannerState();
}

class _WgtCodeScannerState extends State<WgtCodeScanner>
    with SingleTickerProviderStateMixin {
  BarcodeCapture? _capture;
  String _overlayText = "Please scan code";
  bool _isValid = false;

  void _onBarcodeDetect(BarcodeCapture barcodeCapture) {
    final barcode = barcodeCapture.barcodes.last;
    setState(() {
      _overlayText = barcodeCapture.barcodes.last.displayValue ??
          barcode.rawValue ??
          'Barcode has no displayable value';

      _capture = barcodeCapture;
      if (_capture == null) return;

      if (_capture!.barcodes.isNotEmpty) {
        String code = _capture!.barcodes.first.rawValue ?? '';
        if (kDebugMode) {
          print('Barcode detected: $code');
        }

        _isValid = false;
        if (widget.validator != null) {
          if (widget.validator!(code) == null) {
            _isValid = true;
          } else {
            if (kDebugMode) {
              print('Invalid code');
            }
          }
        } else {
          _isValid = true;
        }
        if (_isValid) {
          widget.onDetect(code);
          return Navigator.of(context).pop(code);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 350,
      height: 100,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      backgroundColor: Colors.black,
      body: Builder(
        builder: (context) {
          return Stack(
            children: [
              MobileScanner(
                scanWindow: scanWindow,
                fit: BoxFit.contain,
                onDetect: _onBarcodeDetect,
                errorBuilder: (context, ex) {
                  return ScannerErrorWidget(error: ex);
                },
                overlayBuilder: (context, box) {
                  return Container(
                    width: scanWindow.width,
                    height: scanWindow.height,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Transform.translate(
                      offset: Offset(0, scanWindow.height / 2 + 21),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          _overlayText,
                          style: TextStyle(
                            backgroundColor: Colors.black26,
                            color: _isValid
                                ? Theme.of(context).colorScheme.primary
                                : _capture == null
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // CustomPaint(
              //   painter: ScannerOverlay(
              //       scanWindow, Theme.of(context).colorScheme.primary),
              // ),
              // Align(
              //   alignment: Alignment.bottomCenter,
              //   child: Container(
              //     alignment: Alignment.bottomCenter,
              //     height: 100,
              //     color: Colors.black.withOpacity(0.4),
              //     child: Center(
              //       child: Padding(
              //         padding: const EdgeInsets.only(bottom: 50.0),
              //         child: SizedBox(
              //           width: MediaQuery.of(context).size.width - 120,
              //           height: 50,
              //           child: FittedBox(
              //             child: Text(
              //               _capture?.barcodes.first.rawValue ??
              //                   'Please scan code',
              //               overflow: TextOverflow.fade,
              //               style: Theme.of(context)
              //                   .textTheme
              //                   .headlineMedium!
              //                   .copyWith(color: Colors.white),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          );
        },
      ),
    );
  }
}
