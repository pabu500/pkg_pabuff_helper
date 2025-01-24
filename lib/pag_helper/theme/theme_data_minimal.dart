import 'package:buff_helper/xt_ui/style/evs2_colors.dart';
import 'package:flutter/material.dart';
import 'theme_extension.dart';

final Color onPrimary = Colors.black.withAlpha(230);
final Color onSecondary = Colors.black.withAlpha(230);
final Color onError = Colors.black.withAlpha(230);
final Color onSurface = Colors.white.withAlpha(230);

ThemeData minimalThemeDark = ThemeData(
  primaryColor: pag1,
  colorScheme: ColorScheme.dark(
    primary: pag1,
    secondary: pag2,
    // surface: pag3,
    // error:
    onPrimary: onPrimary,
    onSecondary: onSecondary,
    onSurface: onSurface,
    onError: onError,
  ),
).copyWith(
  extensions: [
    PanelTheme(
      topStatDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: onSurface, width: 3.5),
        ),
      ),
      mainStatDecoration: const BoxDecoration(),
    ),
  ],
);
