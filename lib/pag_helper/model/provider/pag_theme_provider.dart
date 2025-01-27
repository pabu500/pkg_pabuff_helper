import 'package:buff_helper/pkg_buff_helper.dart';
import 'package:flutter/material.dart';

class PagThemeProvider extends ChangeNotifier {
  late MdlThemePref _preferences;

  bool get isDark => _preferences.isDark;

  //setter for isDark
  set isDark(bool isDark) {
    _preferences.setThemeIsDark(isDark);
    notifyListeners();
  }

  PagThemeProvider({bool isDark = true, String themeKey = "theme"}) {
    _preferences = MdlThemePref(
      isDark: isDark,
      themeKey: themeKey,
    );
    // getPref();
  }

  String getThemeKey() {
    _preferences.getPref();

    return _preferences.themeKey;
  }

  setPrefThemeKey({required String themeKey}) {
    _preferences.setThemeKey(themeKey);
    notifyListeners();
  }

  setPrefIsDark({required bool isDark}) {
    _preferences.setThemeIsDark(isDark);
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

  setThemeKey(String themeKey) async {
    this.themeKey = themeKey;
    prefs.setString("theme_key", themeKey);
  }

  setThemeIsDark(bool isDark) async {
    this.isDark = isDark;
    prefs.setBool("theme_is_dark", isDark);
  }

  Future<MdlThemePref> getPref() async {
    isDark = prefs.getBool("theme_is_dark") ?? true;
    themeKey = prefs.getString("theme_key") ?? "minimal";
    return this;
  }
}
