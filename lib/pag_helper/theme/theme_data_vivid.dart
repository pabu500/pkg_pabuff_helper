import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';
import 'theme_extension.dart';

final Color onPrimary = Colors.white.withAlpha(230);
final Color onSecondary = Colors.white.withAlpha(230);
final Color onError = Colors.white.withAlpha(230);
Color primaryColor = spGreen1;
Color surfaceColorLight = Colors.white;
final Color mainPanelColorDark = Colors.grey.shade800;
Color mainPanelColorLight = Colors.grey.shade200;

ThemeData pagThemeVividDark = ThemeData(
  brightness: Brightness.dark,
  highlightColor: pag3,
  colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: spGreen3,
      onPrimary: onPrimary,
      onError: onError,
      surfaceContainer: mainPanelColorDark,
      onSecondary: onSecondary
      // onSurface: Colors.white.withAlpha(230),
      ),
  // scaffoldBackgroundColor: Colors.black,
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
      topStatLabelStyle: TextStyle(
        color: onPrimary,
        fontSize: 45,
        // fontWeight: FontWeight.bold,
        height: 0.95,
        shadows: [
          Shadow(
            blurRadius: 1.0, // Controls the glow effect
            color: onPrimary, // The color of the glow
            offset: const Offset(
                0, 0), // Position of the shadow (0,0) for centered glow
          ),
        ],
      ),
    ),
  ],
);

ThemeData pagThemeVividLight = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.grey.shade300,
  highlightColor: pag3,
  colorScheme: ColorScheme.light(
    primary: primaryColor,
    secondary: spGreen3,
    onPrimary: onPrimary,
    surfaceContainer: mainPanelColorLight,
    onSecondary: onSecondary,
    // onSurface: Colors.white.withAlpha(230),
    onError: onError,
  ),
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
        color: mainPanelColorLight,
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
      topStatLabelStyle: TextStyle(
        color: onPrimary,
        fontSize: 45,
        // fontWeight: FontWeight.bold,
        height: 0.95,
        shadows: [
          Shadow(
            blurRadius: 1.0, // Controls the glow effect
            color: onPrimary, // The color of the glow
            offset: const Offset(
                0, 0), // Position of the shadow (0,0) for centered glow
          ),
        ],
      ),
    ),
  ],
);
