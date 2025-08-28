// edge_to_edge_system_ui.dart
/// Edge-to-edge system UI utilities for Android.
///
/// Provides a small, typed Dart API backed by a Kotlin plugin to query
/// system insets, enable/disable edge-to-edge behavior, and set system bar
/// colors. See the `example/` folder for a runnable example.
///
/// Version 0.1.0-dev.6 includes:
/// - Centralized brightness computation and stabilized public API
/// - Flutter-friendly parameter types (Color objects, Brightness enum)
/// - Wrapper widgets for automatic configuration and safe areas
/// - Utility functions for Android version mapping
library edge_to_edge_system_ui;

export 'edge_to_edge_system_ui_kotlin.dart';
export 'system_info.dart';
