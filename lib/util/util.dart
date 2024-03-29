import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'dart:ui';

Map<String, dynamic> getElementMapByKey(
    List<Map<String, dynamic>> listOfMaps, String key) {
  Map<String, dynamic> foundMap = listOfMaps
      // .firstWhere((map) => map[keyName] == keyValue, orElse: () => {});
      .firstWhere((element) => element.containsKey(key), orElse: () => {});
  return foundMap;
}

Map<String, dynamic> getElementMapByValue(
    List<Map<String, dynamic>> listOfMaps, String keyName, String keyValue) {
  Map<String, dynamic> foundMap = listOfMaps
      .firstWhere((map) => map[keyName] == keyValue, orElse: () => {});

  return foundMap;
}

double findMax(List<double> list) {
  double max = 0;
  for (double item in list) {
    if (item > max) {
      max = item;
    }
  }
  return max;
}

//random number between min and max
double rand(double min, double max) {
  Random rand = Random();
  return min + rand.nextDouble() * (max - min);
}

bool isBetween(double value, double min, double max) {
  return value.compareTo(min) >= 0 && value.compareTo(max) <= 0;
}

Size getSafeSize(context) {
  var padding = MediaQuery.of(context).padding;
  double height = MediaQuery.of(context).size.height;
  double width = MediaQuery.of(context).size.width;
  double safeHeight = height - padding.top - padding.bottom;
  return Size(width, safeHeight);
}

bool isJwtToken(String token) {
  RegExp jwtPattern =
      RegExp(r'^[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*$');
  return jwtPattern.hasMatch(token);
}

String explainException(Object e, {String? defaultMsg}) {
  String msg = '';
  String errorMessage = e.toString();
  if (errorMessage.toLowerCase().contains('device') &&
      errorMessage.toLowerCase().contains('not online')) {
    return 'device not online';
  }
  if (errorMessage.toLowerCase().contains('no ') &&
      errorMessage.toLowerCase().contains('permission')) {
    return 'no permission';
  }
  if (errorMessage.toLowerCase().contains('remote computer') &&
      errorMessage.toLowerCase().contains('refused')) {
    return 'service not available';
  }
  if (errorMessage.toLowerCase().contains('unable to connect') &&
      errorMessage.toLowerCase().contains('authentication')) {
    return 'authentication server not available';
  }
  if (errorMessage.toLowerCase().contains('internal server') &&
      errorMessage.toLowerCase().contains('error')) {
    return 'service error';
  }
  if (errorMessage.toLowerCase().contains('not authorized') &&
      errorMessage.toLowerCase().contains('perform this operation')) {
    return 'permission not authorized';
  }
  if (errorMessage.toLowerCase().contains('duplicate key value')) {
    return 'duplicate value error';
  }
  if (errorMessage.toLowerCase().contains('no') &&
      errorMessage.toLowerCase().contains('found')) {
    return 'no record found';
  }

  return msg.isEmpty ? (defaultMsg ?? '') : msg;
}

String makeReportName(
    String prefix, String? targetSpec, DateTime? start, DateTime? end) {
  String reportName = '';
  //suffix: get currrent datetime
  String suffix = DateFormat('MMddHHmmss').format(DateTime.now());
  String targetSpecSec =
      targetSpec == null || targetSpec.isEmpty ? '' : '_$targetSpec';
  String startSec =
      start == null ? '' : '_${start.year}${start.month}${start.day}';
  String endSec = end == null ? '' : '_${end.year}${end.month}${end.day}';
  reportName = '$prefix$targetSpecSec$startSec${endSec}_$suffix';
  return reportName;
}

bool canPullData(bool hasData, DateTime? lastRequst, int? reqInterval,
    DateTime? lastLoad, int? loadInteval) {
  // if (!hasData) {
  //   return true;
  // }
  if (!hasData) {
    if (lastRequst == null) {
      return true;
    }

    //send request not more than once every 5 seconds
    if (DateTime.now().difference(lastRequst).inSeconds < (reqInterval ?? 5)) {
      return false;
    }
  }

  bool pullData = true;
  if (lastRequst != null) {
    if (DateTime.now().difference(lastRequst).inSeconds < (reqInterval ?? 3)) {
      pullData = false;
    }
  }
  if (pullData) {
    if (hasData) {
      if (lastLoad != null) {
        if (DateTime.now().difference(lastLoad).inSeconds <
            (loadInteval ?? 60)) {
          pullData = false;
        }
      }
    }
  }
  return pullData;
}

bool canPullData2(bool hasData, DateTime? lastRequst, int? reqIntervalMillis,
    DateTime? lastLoad, int? loadIntevalMillis,
    {bool log = false}) {
  if (!hasData) {
    if (lastRequst == null) {
      return true;
    }
  }

  if (lastRequst != null) {
    int diff = DateTime.now().difference(lastRequst).inMilliseconds;
    if (diff < (reqIntervalMillis ?? 3000)) {
      if (log) {
        if (kDebugMode) {
          print(
              'canPullData2: false reqIntervalMillis: $lastRequst $diff < $reqIntervalMillis');
        }
      }
      return false;
    }
  }
  if (hasData) {
    if (lastLoad != null) {
      int diff = DateTime.now().difference(lastLoad).inMilliseconds;
      if (diff < (loadIntevalMillis ?? 60000)) {
        if (log) {
          if (kDebugMode) {
            print(
                'canPullData2: false loadIntevalMillis: $lastLoad $diff < $loadIntevalMillis');
          }
        }
        return false;
      }
    }
  }
  return true;
}

bool canPullData3(bool hasData, DateTime? lastRequst, int? reqIntervalMillis,
    DateTime? lastLoad, int? loadIntevalMillis,
    {int timeoutMillis = 13000, bool log = false}) {
  if (!hasData) {
    if (lastRequst == null) {
      return true;
    }
  }

  if (lastRequst != null) {
    int diff = DateTime.now().difference(lastRequst).inMilliseconds;
    if (diff < (reqIntervalMillis ?? 3000)) {
      if (log) {
        if (kDebugMode) {
          print(
              'canPullData2: false reqIntervalMillis: $diff < $reqIntervalMillis');
        }
      }
      return false;
    }
    if (!hasData) {
      if (diff > (timeoutMillis)) {
        if (log) {
          if (kDebugMode) {
            print('canPullData2: false timeoutMillis: $diff > $timeoutMillis');
          }
        }
        return false;
      }
      return false;
    }
  }
  if (hasData) {
    if (lastLoad != null) {
      int diff = DateTime.now().difference(lastLoad).inMilliseconds;
      if (diff < (loadIntevalMillis ?? 60000)) {
        if (log) {
          if (kDebugMode) {
            print(
                'canPullData2: false loadIntevalMillis: $diff < $loadIntevalMillis');
          }
        }
        return false;
      }
    }
  }
  return true;
}

double screenWidth(BuildContext context, {double? minW, double? maxW}) {
  if (minW == null && maxW == null) {
    return MediaQuery.of(context).size.width;
  } else if (minW != null && maxW == null) {
    return max(minW, MediaQuery.of(context).size.width);
  } else if (minW == null && maxW != null) {
    return min(maxW, MediaQuery.of(context).size.width);
  } else {
    return min(maxW!, max(minW!, MediaQuery.of(context).size.width));
  }
}

double screenWidthMinR(BuildContext context, {double? minWR, double? maxW}) {
  double screenWidth = MediaQuery.of(context).size.width;
  if (minWR == null && maxW == null) {
    return screenWidth;
  } else if (minWR != null && maxW == null) {
    return max(minWR * screenWidth, screenWidth);
  } else if (minWR == null && maxW != null) {
    return min(maxW, screenWidth);
  } else {
    return min(maxW!, max(minWR! * screenWidth, screenWidth));
  }
}

double screenWidthMaxR(BuildContext context, {double? minW, double? maxWR}) {
  double screenWidth = MediaQuery.of(context).size.width;
  if (minW == null && maxWR == null) {
    return screenWidth;
  } else if (minW != null && maxWR == null) {
    return max(minW, screenWidth);
  } else if (minW == null && maxWR != null) {
    return min(maxWR * screenWidth, screenWidth);
  } else {
    return min(maxWR! * screenWidth, max(minW!, screenWidth));
  }
}

double screenWidthMinMaxR(BuildContext context,
    {double? minWR, double? maxWR}) {
  double screenWidth = MediaQuery.of(context).size.width;
  if (minWR == null && maxWR == null) {
    return screenWidth;
  } else if (minWR != null && maxWR == null) {
    return max(minWR * screenWidth, screenWidth);
  } else if (minWR == null && maxWR != null) {
    return min(maxWR * screenWidth, screenWidth);
  } else {
    return min(maxWR! * screenWidth, max(minWR! * screenWidth, screenWidth));
  }
}

double screenWidthRMinMax(BuildContext context, double perentage,
    {double? minW, double? maxW}) {
  double screenWidth = MediaQuery.of(context).size.width;
  if (minW == null && maxW == null) {
    return screenWidth * perentage;
  } else if (minW != null && maxW == null) {
    return max(minW, screenWidth * perentage);
  } else if (minW == null && maxW != null) {
    return min(maxW, screenWidth * perentage);
  } else {
    return min(maxW!, max(minW!, screenWidth * perentage));
  }
}

Widget getPalletteColorWidget(BuildContext context) {
  return Container(
    color: Colors.yellow,
    child: Row(children: [
      Text('canvasColor',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).canvasColor)),
      Text('indicatorColor',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).indicatorColor)),
      Text('primary',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary)),
      Text('secondary',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary)),
      Text('background',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.background)),
      Text('surface',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.surface)),
      Text('error',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error)),
      Text('onPrimary',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary)),
      Text('onSecondary',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSecondary)),
      Text('onBackground',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground)),
      Text('onSurface',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface)),
      Text('onError',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onError)),
    ]),
  );
}
