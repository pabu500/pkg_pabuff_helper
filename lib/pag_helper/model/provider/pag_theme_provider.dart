import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

class PagThemeProvider extends ChangeNotifier {
  late MdlThemePref _preferences;

  bool get isDark => _preferences.isDark;

  //setter for isDark
  set isDark(bool value) {
    _preferences.isDark = value;
    _preferences.setTheme(value, _preferences.themeKey);
    notifyListeners();
  }

  PagThemeProvider({bool isDark = true, String themeKey = "theme"}) {
    _preferences = MdlThemePref(
      isDark: isDark,
      themeKey: themeKey,
    );
    getPreferences();
  }

  getPreferences() async {
    _preferences = await _preferences.getPref();
    notifyListeners();
  }
}

class MdlThemePref {
  bool isDark = false;
  String themeKey = "theme";

  MdlThemePref({
    required this.isDark,
    required this.themeKey,
  });

  setTheme(bool value, String themeKey) async {
    prefs.setBool("theme_is_dark", value);
    prefs.setString("theme_key", themeKey);
  }

  Future<MdlThemePref> getPref() async {
    isDark = prefs.getBool("theme_is_dark") ?? true;
    themeKey = prefs.getString("theme_key") ?? "theme";
    return this;
  }
}
