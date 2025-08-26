import 'dart:async';
import 'package:flutter/services.dart';
import 'system_info.dart';

/// A small wrapper around the Kotlin plugin exposed via MethodChannel.
///
/// Example usage:
/// ```dart
/// await EdgeToEdgeSystemUIKotlin.instance.initialize();
/// final info = await EdgeToEdgeSystemUIKotlin.instance.getSystemInfo();
/// print('Nav height: ${info.navigationBarsHeight}');
/// ```
/// A singleton class that provides methods to control edge-to-edge system UI.
///
/// This class communicates with the native Android plugin via a MethodChannel.
/// It provides methods to initialize the plugin, enable/disable edge-to-edge mode,
/// retrieve system information, and customize the system UI style.
class EdgeToEdgeSystemUIKotlin {
  static const MethodChannel _channel = MethodChannel('edge_to_edge_system_ui');

  EdgeToEdgeSystemUIKotlin._();

  static final EdgeToEdgeSystemUIKotlin instance = EdgeToEdgeSystemUIKotlin._();

  /// Whether the device supports edge-to-edge (as determined by the plugin).
  bool isEdgeToEdgeSupported = false;

  /// Cached value from the last initialization/refresh indicating whether
  /// edge-to-edge mode is currently enabled.
  bool isEdgeToEdgeEnabled = false;

  /// Initialize the plugin and cache a quick snapshot of supported/enabled.
  ///
  /// This method must be called before using other methods in this class.
  /// It retrieves the current edge-to-edge support and enabled state from the native plugin.
  Future<void> initialize() async {
    final map = await _channel.invokeMapMethod<String, dynamic>('initialize');
    if (map == null) return;
    isEdgeToEdgeSupported = map['isEdgeToEdgeSupported'] ?? false;
    isEdgeToEdgeEnabled = map['isEdgeToEdgeEnabled'] ?? false;
  }

  /// Returns a typed [SystemInfo] object describing system insets and
  /// platform details.
  ///
  /// Returns a [SystemInfo] object containing details about the system UI insets,
  /// Android version, and other platform-specific information.
  Future<SystemInfo> getSystemInfo() async {
    final map =
        await _channel.invokeMapMethod<String, dynamic>('getSystemInfo');
    return SystemInfo.fromMap(
        map?.cast<String, dynamic>() ?? <String, dynamic>{});
  }

  /// Enable edge-to-edge mode on the device (Android).
  ///
  /// This method makes the app content extend behind the system bars (status and navigation bars).
  Future<void> enableEdgeToEdge() async {
    await _channel.invokeMethod('enable');
    isEdgeToEdgeEnabled = true;
  }

  /// Disable edge-to-edge mode on the device (Android).
  ///
  /// This method restores the default system UI behavior, where the app content
  /// does not extend behind the system bars.
  Future<void> disableEdgeToEdge() async {
    await _channel.invokeMethod('disable');
    isEdgeToEdgeEnabled = false;
  }

  /// Apply colors and appearance to the status and navigation bars.
  ///
  /// Colors are ARGB integers (same format as `Color.value`).
  ///
  /// [statusBarColor] and [navigationBarColor] are ARGB integers representing the colors.
  /// [statusBarLight] and [navigationBarLight] determine whether the icons are light or dark.
  Future<void> setSystemUIStyle({
    required int statusBarColor,
    required int navigationBarColor,
    required bool statusBarLight,
    required bool navigationBarLight,
  }) async {
    await _channel.invokeMethod('setStyle', {
      'statusBarColor': statusBarColor,
      'navigationBarColor': navigationBarColor,
      'statusBarLight': statusBarLight,
      'navigationBarLight': navigationBarLight,
    });
  }
}
