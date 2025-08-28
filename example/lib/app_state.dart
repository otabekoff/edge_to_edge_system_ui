import 'package:flutter/material.dart';

// App-wide theme mode notifier (Auto/System, Light, Dark)
final ValueNotifier<ThemeMode> appThemeModeNotifier = ValueNotifier(
  ThemeMode.system,
);
