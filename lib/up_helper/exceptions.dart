import 'package:buff_helper/xt_ui/wdgt/info/get_copy.dart';
import 'package:flutter/material.dart';

class InvalidCredentialsException implements Exception {
  final String message;
  InvalidCredentialsException(this.message);
}

class AccessDeniedException implements Exception {
  final String message;
  AccessDeniedException(this.message);
}

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException(this.message);
}

class ItemNotFoundException implements Exception {
  final String message;
  ItemNotFoundException(this.message);
}

class EmptyHistoryException implements Exception {
  final String message;
  EmptyHistoryException(this.message);
}

class TooManyRequestsException implements Exception {
  final String message;
  TooManyRequestsException(this.message);
}

String getErrorText(dynamic e, {String defaultErrorText = 'general error'}) {
  String errorText;
  if (e is InvalidCredentialsException) {
    errorText =
        'Invalid credentials provided. Please check your login details.';
  } else if (e is AccessDeniedException) {
    errorText =
        'Access denied. You do not have permission to perform this action.';
  } else if (e is TokenExpiredException) {
    errorText = 'Your session has expired. Please log in again.';
  } else if (e is ItemNotFoundException) {
    errorText = 'The requested item was not found.';
  } else if (e is EmptyHistoryException) {
    errorText = 'No history available for this item.';
  } else if (e is TooManyRequestsException) {
    errorText = 'Too many requests. Please try again later.';
  } else {
    // if e.toString() contains 'Exception: ', remove it
    errorText = e.toString().replaceAll('Exception: ', '');

    bool isForUser = false;
    if (errorText.isNotEmpty) {
      //case 1: if errorText starts with capital letter and ends with period, keep as is
      final firstChar = errorText[0];
      final lastChar = errorText[errorText.length - 1];
      if (firstChar.toUpperCase() == firstChar && lastChar == '.') {
        isForUser = true;
      }
      // case 2: if start with 'm:'
      else if (errorText.startsWith('m:')) {
        isForUser = true;
        errorText = errorText.substring(2).trim();
      }
    }
    if (errorText.contains('OQG')) {
      isForUser = false;
    }
    if (!isForUser) {
      errorText = defaultErrorText;
    }
  }

  return errorText;
}

void showInfoDialog(BuildContext context, String title, String text,
    {TextStyle? infoTextStyle, String type = 'error'}) {
  TextStyle? defaultStyle;
  if (type == 'error') {
    defaultStyle =
        infoTextStyle ?? TextStyle(color: Theme.of(context).colorScheme.error);
  } else {
    defaultStyle = infoTextStyle;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Row(
          children: [
            SelectableText(text, style: defaultStyle),
            SizedBox(
                width: 40,
                child: getCopyButton(context, text, direction: 'left'))
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
