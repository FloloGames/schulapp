import 'package:flutter/material.dart';
import 'package:schulapp/code_behind/time_table_manager.dart';

///singelton damit es immer nur eine instanz gibt
class ThemeManager with ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._privateConstructor();
  ThemeManager._privateConstructor();

  factory ThemeManager() {
    return _instance;
  }

  ThemeMode get themeMode {
    return TimetableManager().settings.themeMode;
  }

  set themeMode(ThemeMode mode) {
    TimetableManager().settings.themeMode = mode;
    notifyListeners();
  }
}
