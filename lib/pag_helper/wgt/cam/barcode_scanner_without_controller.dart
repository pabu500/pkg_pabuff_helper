import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'scanner_error_widget.dart';

class WgtBarcodeScannerWithoutController extends StatefulWidget {
  const WgtBarcodeScannerWithoutController({
    super.key,
    this.title = 'Scan Code',
    required this.onDetect,
    this.validator,
  });

  final String title;
  final void Function(String code) onDetect;
  final String? Function(String code)? validator;

  @override
  State<WgtBarcodeScannerWithoutController> createState() =>
      _WgtBarcodeScannerWithoutControllerState();
}

class _WgtBarcodeScannerWithoutControllerState
    extends State<WgtBarcodeScannerWithoutController>
    with SingleTickerProviderStateMixin {
  BarcodeCapture? capture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      backgroundColor: Colors.black,
      body: Builder(
        builder: (context) {
          return Stack(
            children: [
              MobileScanner(
                fit: BoxFit.contain,
                errorBuilder: (context, ex) {
                  return ScannerErrorWidget(error: ex);
                },
                onDetect: (capture) {
                  setState(() {
                    this.capture = capture;

                    if (capture.barcodes.isNotEmpty) {
                      String code = capture.barcodes.first.rawValue ?? '';
                      if (widget.validator != null) {
                        if (widget.validator!(code) == null) {
                          widget.onDetect(code);
                        } else {
                          if (kDebugMode) {
                            print('Invalid code');
                          }
                        }
                      } else {
                        widget.onDetect(code);
                        return Navigator.of(context).pop(code);
                      }
                    }
                  });
                },
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  alignment: Alignment.bottomCenter,
                  height: 100,
                  color: Colors.black.withOpacity(0.4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 120,
                          height: 50,
                          child: FittedBox(
                            child: Text(
                              capture?.barcodes.first.rawValue ??
                                  'Please scan code',
                              overflow: TextOverflow.fade,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
