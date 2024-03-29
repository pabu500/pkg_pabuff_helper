import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = contentColorCyan;
  static const Color menuBackground = Color(0xFF090912);
  static const Color itemsBackground = Color(0xFF1B2339);
  static const Color pageBackground = Color(0xFF282E45);
  static const Color mainTextColor1 = Colors.white;
  static const Color mainTextColor2 = Colors.white70;
  static const Color mainTextColor3 = Colors.white38;
  static const Color mainGridLineColor = Colors.white10;
  static const Color borderColor = Colors.white54;
  static const Color gridLinesColor = Color(0x11FFFFFF);

  static const Color contentColorBlack = Colors.black;
  static const Color contentColorWhite = Colors.white;
  static const Color contentColorBlue = Color(0xFF2196F3);
  static const Color contentColorYellow = Color(0xFFFFC300);
  static const Color contentColorOrange = Color(0xFFFF683B);
  static const Color contentColorGreen = Color(0xFF3BFF49);
  static const Color contentColorPurple = Color(0xFF6E1BFF);
  static const Color contentColorPink = Color(0xFFFF3AF2);
  static const Color contentColorRed = Color(0xFFFE0034);
  static const Color contentColorCyan = Color(0xFF50E4FF);
  static const Color contentColorGrey = Color(0xFF9E9E9E);
  static const Color contentColorMagneta = Color(0xFFFF00FF);
  static const Color contentColorTeal = Color(0xFF008080);
  static const Color contentColorLime = Color(0xFF00FF00);
  static const Color contentColorBrown = Color(0xFFA52A2A);
  static const Color contentColorAmber = Color(0xFFFFBF00);
  static const Color contentColorIndigo = Color(0xFF4B0082);
  static const Color contentColorLightBlue = Color(0xFFADD8E6);
  static const Color contentColorLightGreen = Color(0xFF90EE90);
  static const Color contentColorDeepPurple = Color(0xFF9370DB);
  static const Color contentColorDeepOrange = Color(0xFFFF8C00);
  static const Color contentColorLightPink = Color(0xFFFFB6C1);
  static const Color contentColorLightRed = Color(0xFFFF6347);
  static const Color contentColorLightCyan = Color(0xFFE0FFFF);
  static const Color contentColorLightGrey = Color(0xFFD3D3D3);
  static const Color contentColorLightMagneta = Color(0xFFFFC0CB);
  static const Color contentColorLightTeal = Color(0xFFAFEEEE);
  static const Color contentColorLightLime = Color(0xFF32CD32);
  static const Color contentColorLightBrown = Color(0xFFB8860B);
  static const Color contentColorLightAmber = Color(0xFFFFD700);
  static const Color contentColorLightIndigo = Color(0xFF9370DB);
  static const Color contentColorDarkBlue = Color(0xFF00008B);
  static const Color contentColorDarkYellow = Color(0xFFB8860B);
  static const Color contentColorDarkOrange = Color(0xFFFF4500);
  static const Color contentColorDarkGreen = Color(0xFF006400);
  static const Color contentColorDarkPurple = Color(0xFF800080);
  static const Color contentColorDarkPink = Color(0xFFC71585);
  static const Color contentColorDarkRed = Color(0xFF8B0000);
  static const Color contentColorDarkCyan = Color(0xFF008B8B);
  static const Color contentColorDarkGrey = Color(0xFFA9A9A9);
  static const Color contentColorDarkMagneta = Color(0xFF8B008B);
  static const Color contentColorDarkTeal = Color(0xFF008080);
  static const Color contentColorDarkLime = Color(0xFF006400);
  static const Color contentColorDarkBrown = Color(0xFF8B4513);
  static const Color contentColorDarkAmber = Color(0xFFB8860B);
  static const Color contentColorDarkIndigo = Color(0xFF4B0082);
  // static const Color contentColorDarkLightBlue = Color(0xFFADD8E6);
  // static const Color contentColorDarkLightGreen = Color(0xFF90EE90);
  // static const Color contentColorDarkLightPurple = Color(0xFF9370DB);
  // static const Color contentColorDarkLightPink = Color(0xFFFFB6C1);
  // static const Color contentColorDarkLightRed = Color(0xFFFF6347);
  // static const Color contentColorDarkLightCyan = Color(0xFFE0FFFF);
  // static const Color contentColorDarkLightGrey = Color(0xFFD3D3D3);
  static const List<Color> tier1colorsAlt = [
    contentColorCyan,
    contentColorLightPink,
    contentColorOrange,
    contentColorPink,
    contentColorMagneta,
    // contentColorPink,
    contentColorYellow,
    contentColorBlue,
    // contentColorOrange,
    contentColorRed,
    contentColorGreen,
    contentColorPurple,
  ];
  static const List<Color> tier1colorsGreenBlue = [
    contentColorGreen,
    contentColorCyan,
    contentColorBlue,
    contentColorLightBlue,
    contentColorLightGreen,
    contentColorLightCyan,
    // contentColorDarkBlue,
    // contentColorDarkGreen,
  ];
  static const List<Color> tier1colors = [
    contentColorRed,
    contentColorBlue,
    contentColorYellow,
    contentColorGreen,
    contentColorOrange,
    contentColorPurple,
    contentColorPink,
    contentColorCyan,
    contentColorGrey,
  ];

  static const List<Color> tier2colors = [
    contentColorMagneta,
    contentColorTeal,
    contentColorLime,
    contentColorBrown,
    contentColorAmber,
    contentColorIndigo,
  ];

  static const List<Color> tier3colors = [
    contentColorLightBlue,
    contentColorLightGreen,
    contentColorDeepPurple,
    contentColorDeepOrange,
    contentColorLightPink,
    contentColorLightRed,
    contentColorLightCyan,
    contentColorLightGrey,
    contentColorLightMagneta,
    contentColorLightTeal,
    contentColorLightLime,
    contentColorLightBrown,
    contentColorLightAmber,
    contentColorLightIndigo,
    contentColorDarkBlue,
    contentColorDarkYellow,
    contentColorDarkOrange,
    contentColorDarkGreen,
    contentColorDarkPurple,
    contentColorDarkPink,
    contentColorDarkRed,
    contentColorDarkCyan,
    contentColorDarkGrey,
    contentColorDarkMagneta,
    contentColorDarkTeal,
    contentColorDarkLime,
    contentColorDarkBrown,
    contentColorDarkAmber,
    contentColorDarkIndigo,
  ];

  final Color commitColor = Colors.amber.shade900.withOpacity(0.8);

  static List<Color> getColorList(int colorsNeeded) {
    List<Color> colorList = [];
    if (colorsNeeded <= tier1colors.length) {
      colorList = tier1colors.sublist(0, colorsNeeded);
    } else if (colorsNeeded <= tier1colors.length + tier2colors.length) {
      colorList = tier1colors +
          tier2colors.sublist(0, colorsNeeded - tier1colors.length);
    } else if (colorsNeeded <=
        tier1colors.length + tier2colors.length + tier3colors.length) {
      colorList = tier1colors +
          tier2colors +
          tier3colors.sublist(
              0, colorsNeeded - tier1colors.length - tier2colors.length);
    } else {
      colorList = tier1colors + tier2colors + tier3colors;
    }
    return colorList;
  }

  static List<Color> getColorListBlueGreen() {
    List<Color> colorList = [];
    colorList = [
      contentColorBlue,
      contentColorGreen,
      contentColorDarkBlue,
      contentColorDarkGreen,
      contentColorLightBlue,
      contentColorLightGreen,
    ];
    return colorList;
  }

  static List<Color> getColorListCGB() {
    List<Color> colorList = [];
    colorList = [
      // contentColorDarkAmber,

      contentColorCyan,
      contentColorLightGrey,
      contentColorLightTeal,
    ];
    return colorList;
  }

  static List<Color> getColorListGreys() {
    List<Color> colorList = [];
    colorList = [
      Colors.grey.shade700,
      Colors.blueGrey,
      Colors.grey.shade500,
    ];
    return colorList;
  }
}
