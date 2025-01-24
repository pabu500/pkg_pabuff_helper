import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'theme_extension.dart';

Color primaryColor = spGreen1;

ThemeData pagThemeVividDark = ThemeData(
  brightness: Brightness.dark,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: Colors.black,
).copyWith(
  extensions: [
    PanelTheme(
      topStatDecoration: BoxDecoration(
        color: primaryColor.withAlpha(180),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            spreadRadius: 0,
            blurRadius: 5,
            offset: const Offset(1, 3), // changes position of shadow
          ),
        ],
      ),
      mainStatDecoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            spreadRadius: 0,
            blurRadius: 5,
            offset: const Offset(1, 3), // changes position of shadow
          ),
        ],
      ),
    ),
  ],
);
