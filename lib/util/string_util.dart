import 'dart:convert';
import 'dart:typed_data';

import 'package:buff_helper/util/util.dart';
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

Size getStringDisplaySize2(BuildContext context, String text, TextStyle style) {
  final textSpan = TextSpan(
    text: text,
    style: style,
  );
  // and get the media query
  final media = MediaQuery.of(context);
  final tp = TextPainter(
      text: textSpan,
      textDirection: ui.TextDirection.ltr,
      textScaler: media.textScaler);
  tp.layout();
  return tp.size;
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

String getCommaNumberStr(double? value,
    {int decimal = 0, bool isRoundUp = false}) {
  final NumberFormat commaFormat = NumberFormat.decimalPatternDigits(
      locale: 'en_us', decimalDigits: decimal);
  String valueStr = (value == null)
      ? '-'
      : isRoundUp
          ? getRoundUp(value, decimal).toStringAsFixed(decimal)
          : value.toStringAsFixed(decimal);

  if (valueStr.contains('.')) {
    valueStr = valueStr.replaceAll(RegExp(r'0*$'), '');
    valueStr = valueStr.replaceAll(RegExp(r'\.$'), '');
  }
  if (valueStr == '-') {
    return valueStr;
  }
  String formattedValue = commaFormat.format(double.parse(valueStr));
  return formattedValue;
}

String getValueUnitDisplayStr(
  double? value,
  String? unit, {
  int decimal = 0,
  bool useK = false,
  double kThreshold = 1000000,
  String kUnit = 'k',
}) {
  double? useValue = value;
  bool isK = false;
  if (value == null) {
    return '-';
  }

  if (useK && value >= kThreshold) {
    useValue = value / 1000;
    isK = true;
  }

  String valueStr = getCommaNumberStr(useValue, decimal: decimal);
  if (unit != null) {
    if (isK) {
      valueStr = '$valueStr$kUnit';
    } else {
      valueStr = '$valueStr $unit';
    }
  }
  return valueStr;
}

Map<String, dynamic> getValueUnitDisplayStr2(
  double? value,
  String? unit, {
  int decimal = 0,
  bool useK = false,
  double kThreshold = 100000,
  double kDecimal = 1,
  String kUnit = 'k',
  bool forceK = false,
  bool useM = false,
  double mThreshold = 1000000,
  int mDecimal = 1,
  String mUnit = 'M',
  bool forceM = false,
  bool useG = false,
  double gThreshold = 1000000000,
  int gDecimal = 1,
  String gUnit = 'G',
  bool forceG = false,
}) {
  double? useValue = value;
  bool isK = false;
  bool isM = false;
  bool isG = false;

  if (value == null) {
    return {'value': '-', 'isK': false};
  }

  if (useK && value >= kThreshold) {
    useValue = value / 1000;
    isK = true;
  }
  if (forceK) {
    useValue = value / 1000;
    isK = true;
  }

  if (useM && value >= mThreshold) {
    useValue = value / 1000000;
    isM = true;
    isK = false;
  }
  if (forceM) {
    useValue = value / 1000000;
    isM = true;
    isK = false;
  }

  if (useG && value >= gThreshold) {
    useValue = value / 1000000000;
    isG = true;
    isK = false;
    isM = false;
  }
  if (forceG) {
    useValue = value / 1000000000;
    isG = true;
    isK = false;
    isM = false;
  }

  String valueStr = getCommaNumberStr(useValue, decimal: decimal);
  if (unit != null) {
    if (isK) {
      valueStr = '$valueStr$kUnit';
    } else if (isM) {
      valueStr = '$valueStr$mUnit';
    } else if (isG) {
      valueStr = '$valueStr$gUnit';
    } else {
      valueStr = '$valueStr$unit';
    }
  }
  return {'value': valueStr, 'isK': isK, 'isM': isM, 'isG': isG};
}

final Color statColorDark = Colors.grey.shade800;
final defStatStyleLarge = TextStyle(
  fontSize: 30,
  fontWeight: FontWeight.bold,
  color: Colors.grey.shade800,
);
final defStatStyle = TextStyle(
  fontSize: 21,
  fontWeight: FontWeight.bold,
  color: Colors.grey.shade600,
);
final defStatStyleSmall = TextStyle(
  fontSize: 13,
  color: Colors.grey.shade600,
);

Widget getStatWithUnit(String statStr, String unit,
    {TextStyle? statStrStyle, TextStyle? unitStyle, bool showUnit = true}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(statStr, style: statStrStyle ?? defStatStyle),
      if (showUnit)
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(unit, style: unitStyle ?? defStatStyleSmall),
        ),
    ],
  );
}
