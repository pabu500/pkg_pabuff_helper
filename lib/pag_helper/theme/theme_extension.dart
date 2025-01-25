import 'package:flutter/material.dart';

class PanelTheme extends ThemeExtension<PanelTheme> {
  final BoxDecoration? topStatDecoration;
  final BoxDecoration? mainStatDecoration;
  final TextStyle? topStatLabelStyle;

  const PanelTheme({
    this.topStatDecoration,
    this.mainStatDecoration,
    this.topStatLabelStyle,
  });

  @override
  PanelTheme copyWith({BoxDecoration? panelDecoration}) {
    return PanelTheme(
      topStatDecoration: topStatDecoration ?? topStatDecoration,
      mainStatDecoration: mainStatDecoration ?? mainStatDecoration,
      topStatLabelStyle: topStatLabelStyle ?? topStatLabelStyle,
    );
  }

  @override
  PanelTheme lerp(ThemeExtension<PanelTheme>? other, double t) {
    if (other is! PanelTheme) return this;
    return PanelTheme(
      topStatDecoration: BoxDecoration.lerp(
        topStatDecoration,
        other.topStatDecoration,
        t,
      ),
      mainStatDecoration: BoxDecoration.lerp(
        mainStatDecoration,
        other.mainStatDecoration,
        t,
      ),
      topStatLabelStyle: TextStyle.lerp(
        topStatLabelStyle,
        other.topStatLabelStyle,
        t,
      ),
    );
  }
}
