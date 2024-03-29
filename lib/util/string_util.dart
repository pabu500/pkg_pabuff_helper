import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

bool isNumeric(String input) {
  if (input.isEmpty) {
    return false;
  }

  final intVal = int.tryParse(input);
  if (intVal != null) {
    return true;
  }

  final doubleVal = double.tryParse(input);
  if (doubleVal != null) {
    return true;
  }

  return false;
}

bool isAlphaNumeric(String input) {
  if (input.isEmpty) {
    return false;
  }

  final RegExp alphaNumeric = RegExp(r'^[a-zA-Z0-9]+$');
  return alphaNumeric.hasMatch(input);
}

// int getDisplayLength(double width) {
//   int displayLength = (width / 8).floor() - 3;
//   if (displayLength < 3) {
//     displayLength = 3;
//   }
//   return displayLength;
// }
// int getDisplayLength(double width, double fontSize) {
//   int displayLength = (width / fontSize).floor();
//   if (displayLength < 3) {
//     displayLength = 3;
//   }
//   return displayLength;
// }

Size getStringDisplaySize(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr
      //TextDirection.LTR ?? TextDirection.UNKNOWN,
      )
    ..layout(minWidth: 0, maxWidth: double.infinity);
  return textPainter.size;
}

int getDisplayLength(double width, TextStyle style) {
  int displayLength = (width / getStringDisplaySize('a', style).width).floor();
  if (displayLength < 3) {
    displayLength = 3;
  }
  return displayLength;
}

double getMaxFitFontSize(double width, String str, TextStyle style,
    {double? maxFontSize}) {
  double fontSize = maxFontSize ?? 50;

  double displayWidth = double.maxFinite;
  while (displayWidth > width) {
    double decrease = 1;
    if (fontSize < 15) {
      decrease = 0.5;
    }
    fontSize -= decrease;
    if (fontSize < 8) {
      break;
    }
    style = style.copyWith(fontSize: fontSize);
    displayWidth = getStringDisplaySize(str, style).width;
  }
  return fontSize;
}

String lengthyString(String input, int length) {
  if (input.isEmpty) {
    return '';
  }

  if (input.length <= length) {
    return input;
  }

  return '${input.substring(0, length)}...';
}

String convertToDisplayString(
    String input, double containerWidth, TextStyle style) {
  if (input.isEmpty) {
    return '';
  }
  double displayWidth = 1.135 * getStringDisplaySize(input, style).width;

  if (displayWidth <= containerWidth) {
    return input;
  }

  int length = (input.length * containerWidth / displayWidth).floor() - 2;
  if (length < 3) {
    length = 3;
  }

  if (input.length <= length) {
    return input;
  }

  return '${input.substring(0, length)}...';
}

int decideDisplayDecimal(double value) {
  if (value == 0) {
    return 0;
  }
  if (value < 0.001) {
    return 4;
  }
  if (value < 0.01) {
    return 3;
  }
  if (value < 0.1) {
    return 2;
  }
  if (value < 1) {
    return 2;
  }
  if (value < 10) {
    return 1;
  }
  if (value < 100) {
    return 1;
  }
  if (value < 1000) {
    return 0;
  }
  return 0;
}

int getLevelValue(String level) {
  int levelValue = 0;
  levelValue = isNumeric(level)
      ? int.parse(level)
      : level == 'B5'
          ? -5
          : level == 'B4'
              ? -4
              : level == 'B3'
                  ? -3
                  : level == 'B2'
                      ? -2
                      : level == 'B1'
                          ? -1
                          : 0;
  return levelValue;
}

Uint8List dataFromBase64String(String base64String) {
  return base64Decode(base64String);
}

String base64String(Uint8List data) {
  return base64Encode(data);
}

String getK(double amount, int kDecimal) {
  //parse amount 500 into 0.5k etc
  String k = '';
  if (amount >= 1000) {
    k = '${(amount / 1000).toStringAsFixed(0)}k';
  } else {
    k = amount.toStringAsFixed(kDecimal);
  }
  return k;
}

String getCommaNumberStr(double? value, {int decimal = 0}) {
  final NumberFormat commaFormat = NumberFormat.decimalPattern('en_us');
  String valueStr = value == null ? '-' : value.toStringAsFixed(decimal);
  if (valueStr.contains('.')) {
    valueStr = valueStr.replaceAll(RegExp(r'0*$'), '');
    valueStr = valueStr.replaceAll(RegExp(r'\.$'), '');
  }
  if (valueStr == '-') {
    return valueStr;
  }
  return commaFormat.format(double.parse(valueStr));
}
