import 'dart:async';
import 'package:flutter/material.dart';
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

  /// Convenience method to set light system UI with optional transparency.
  ///
  /// [transparent] determines whether to use transparent colors or solid colors.
  Future<void> setLightSystemUI({bool transparent = false}) async {
    final color = transparent ? Colors.transparent.toARGB32() : Colors.white.toARGB32();
    await setSystemUIStyle(
      statusBarColor: color,
      navigationBarColor: color,
      statusBarLight: false, // Dark icons on light background
      navigationBarLight: false,
    );
  }

  /// Convenience method to set dark system UI with optional transparency.
  ///
  /// [transparent] determines whether to use transparent colors or solid colors.
  Future<void> setDarkSystemUI({bool transparent = false}) async {
    final color = transparent ? Colors.transparent.toARGB32() : Colors.black.toARGB32();
    await setSystemUIStyle(
      statusBarColor: color,
      navigationBarColor: color,
      statusBarLight: true, // Light icons on dark background
      navigationBarLight: true,
    );
  }

  /// Convenience method with Flutter-style brightness parameters.
  ///
  /// [statusBarColor] and [navigationBarColor] can be Flutter Color objects.
  /// [statusBarIconBrightness] and [navigationBarIconBrightness] use Flutter's Brightness enum.
  Future<void> setSystemUIStyleWithBrightness({
    required Color statusBarColor,
    required Color navigationBarColor,
    required Brightness statusBarIconBrightness,
    required Brightness navigationBarIconBrightness,
  }) async {
    await setSystemUIStyle(
      statusBarColor: statusBarColor.toARGB32(),
      navigationBarColor: navigationBarColor.toARGB32(),
      statusBarLight: statusBarIconBrightness == Brightness.light,
      navigationBarLight: navigationBarIconBrightness == Brightness.light,
    );
  }

  /// Set system UI colors based on the current theme brightness.
  ///
  /// [brightness] should be the current theme brightness from Theme.of(context).brightness.
  Future<void> setSystemUIForTheme(Brightness brightness) async {
    if (brightness == Brightness.dark) {
      await setDarkSystemUI(transparent: isEdgeToEdgeEnabled);
    } else {
      await setLightSystemUI(transparent: isEdgeToEdgeEnabled);
    }
  }
}

/// A wrapper widget that automatically configures edge-to-edge mode and safe areas.
///
/// This widget should wrap your app's content and will automatically handle
/// edge-to-edge setup based on the device capabilities and your preferences.
class KotlinSystemUIWrapper extends StatefulWidget {
  /// The child widget to wrap.
  final Widget child;

  /// Whether to enable edge-to-edge mode automatically.
  final bool enableEdgeToEdge;

  /// Whether to enforce contrast between system bars and content.
  final bool enforceContrast;

  const KotlinSystemUIWrapper({
    super.key,
    required this.child,
    this.enableEdgeToEdge = true,
    this.enforceContrast = true,
  });

  @override
  State<KotlinSystemUIWrapper> createState() => _KotlinSystemUIWrapperState();
}

class _KotlinSystemUIWrapperState extends State<KotlinSystemUIWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _configureSystemUI();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    _configureSystemUI();
  }

  Future<void> _configureSystemUI() async {
    final plugin = EdgeToEdgeSystemUIKotlin.instance;

    if (widget.enableEdgeToEdge && plugin.isEdgeToEdgeSupported) {
      await plugin.enableEdgeToEdge();
    }

    if (widget.enforceContrast && mounted) {
      final brightness = MediaQuery.of(context).platformBrightness;
      await plugin.setSystemUIForTheme(brightness);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A safe area widget that accounts for system UI insets in edge-to-edge mode.
///
/// This widget provides padding to ensure content is not obscured by
/// system bars when in edge-to-edge mode.
class KotlinEdgeToEdgeSafeArea extends StatelessWidget {
  /// The child widget to provide safe area padding for.
  final Widget child;

  /// Whether to apply top padding (for status bar).
  final bool top;

  /// Whether to apply bottom padding (for navigation bar).
  final bool bottom;

  /// Whether to apply left padding.
  final bool left;

  /// Whether to apply right padding.
  final bool right;

  /// Minimum padding to apply even when not in edge-to-edge mode.
  final EdgeInsets minimum;

  const KotlinEdgeToEdgeSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimum = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final plugin = EdgeToEdgeSystemUIKotlin.instance;

    // If not in edge-to-edge mode, use standard SafeArea
    if (!plugin.isEdgeToEdgeEnabled) {
      return SafeArea(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        minimum: minimum,
        child: child,
      );
    }

    // In edge-to-edge mode, use MediaQuery padding
    return Padding(
      padding: EdgeInsets.only(
        top: top ? (mediaQuery.padding.top + minimum.top) : minimum.top,
        bottom: bottom ? (mediaQuery.padding.bottom + minimum.bottom) : minimum.bottom,
        left: left ? (mediaQuery.padding.left + minimum.left) : minimum.left,
        right: right ? (mediaQuery.padding.right + minimum.right) : minimum.right,
      ),
      child: child,
    );
  }
}

/// Utility function to get Android version name from API level.
String whenSdk(int apiLevel) {
  switch (apiLevel) {
    case 34:
      return 'Android 14 (API 34)';
    case 33:
      return 'Android 13 (API 33)';
    case 32:
      return 'Android 12L (API 32)';
    case 31:
      return 'Android 12 (API 31)';
    case 30:
      return 'Android 11 (API 30)';
    case 29:
      return 'Android 10 (API 29)';
    case 28:
      return 'Android 9 (API 28)';
    case 27:
      return 'Android 8.1 (API 27)';
    case 26:
      return 'Android 8.0 (API 26)';
    case 25:
      return 'Android 7.1 (API 25)';
    case 24:
      return 'Android 7.0 (API 24)';
    case 23:
      return 'Android 6.0 (API 23)';
    default:
      if (apiLevel >= 35) {
        return 'Android ${((apiLevel - 21) / 1) + 5} (API $apiLevel)';
      }
      return 'Android API $apiLevel';
  }
}