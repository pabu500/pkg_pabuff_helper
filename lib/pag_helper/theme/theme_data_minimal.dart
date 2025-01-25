import 'package:buff_helper/xt_ui/style/evs2_colors.dart';
import 'package:flutter/material.dart';
import 'theme_extension.dart';

final Color onPrimary = Colors.white.withAlpha(230);
final Color onSecondary = Colors.white.withAlpha(230);
final Color onError = Colors.white.withAlpha(230);
final Color onSurfaceDark = Colors.white.withAlpha(230);
final Color onSurfaceLight = Colors.black.withAlpha(230);
Color mainPanelColorLight = Colors.grey.shade200;
Color mainPanelColorDark = Colors.black.withAlpha(21);

ThemeData pagThemeMinimalDark = ThemeData(
  primaryColor: pag1,
  brightness: Brightness.dark,
  highlightColor: pag3,
  colorScheme: ColorScheme.dark(
    primary: pag1,
    secondary: pag2,
    // surface: pag3,
    // error:
    onPrimary: onPrimary,
    onSecondary: onSecondary,
    // onSurface: onSurface,
    onError: onError,
  ),
).copyWith(
  extensions: [
    PanelTheme(
      topStatDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: onSurfaceDark, width: 3.5),
        ),
      ),
      mainStatDecoration: BoxDecoration(color: mainPanelColorDark),
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

ThemeData pagThemeMinimalLight = ThemeData(
  primaryColor: pag1,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.grey.shade200,
  highlightColor: pag3,
  colorScheme: ColorScheme.light(
    primary: pag1,
    secondary: pag2,
    // surface: pag3,
    // error:
    onPrimary: onPrimary,
    onSecondary: onSecondary,
    // onSurface: onSurface,
    onError: onError,
  ),
).copyWith(
  extensions: [
    PanelTheme(
      topStatDecoration: BoxDecoration(
        color: Colors.transparent.withAlpha(21),
        border: Border(
          left: BorderSide(color: onSurfaceLight.withAlpha(210), width: 3.5),
        ),
      ),
      mainStatDecoration:
          BoxDecoration(color: Colors.transparent.withAlpha(21)),
      topStatLabelStyle: TextStyle(
        color: onSurfaceLight,
        fontSize: 45,
        // fontWeight: FontWeight.bold,
        height: 0.95,
        shadows: [
          Shadow(
            blurRadius: 1.0, // Controls the glow effect
            color: onSurfaceLight, // The color of the glow
            offset: const Offset(
                0, 0), // Position of the shadow (0,0) for centered glow
          ),
        ],
      ),
    ),
  ],
);
