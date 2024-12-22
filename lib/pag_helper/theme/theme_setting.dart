import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

enum PagTheme {
  pagNeo,
  pagNeoLight,
}

enum PagWgt {
  pagCube,
  buttonFace,
}

final ScrollbarThemeData scrollbarTheme =
    ScrollbarThemeData(thumbVisibility: WidgetStateProperty.all<bool>(true));

final ThemeData thmPagNeo = ThemeData(
  colorScheme: const ColorScheme.dark(
    primary: pag1, //pagNeo,
    secondary: pag2, //spGreen1,
  ),
  scrollbarTheme: scrollbarTheme,
);

final ThemeData thmPagNeoLight = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: pag1,
    secondary: pag2,
  ),
);

Color getColor({
  required BuildContext context,
  required PagWgt pagWgt,
}) {
  switch (pagWgt) {
    case PagWgt.pagCube:
      return Theme.of(context).colorScheme.primary.withAlpha(220);
    case PagWgt.buttonFace:
      return Theme.of(context).colorScheme.primary;
    default:
      return Theme.of(context).colorScheme.primary;
  }
}
