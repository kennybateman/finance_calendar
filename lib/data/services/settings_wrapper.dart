import 'package:shared_preferences/shared_preferences.dart';

class SettingsWrapper {
  SharedPreferences? prefs;
  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static const String darkModeKey = 'dark_mode';
  static const String fontSizeKey = 'font_size';

  bool getDarkMode() {
    if (prefs == null) throw Exception("Settings not initialized");
    return prefs!.getBool(darkModeKey) ?? false;
  }

  void setDarkMode(bool enabled) {
    if (prefs == null) throw Exception("Settings not initialized");
    prefs!.setBool(darkModeKey, enabled);
  }

  double getFontSize() {
    return prefs!.getDouble(fontSizeKey) ?? 1.0;
  }

  void setFontSize(double fontSize) {
    prefs!.setDouble(fontSizeKey, fontSize);
  }
}