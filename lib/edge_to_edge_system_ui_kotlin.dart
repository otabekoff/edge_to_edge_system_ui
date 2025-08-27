import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'system_info.dart';

/// A Dart wrapper around the native Kotlin plugin for controlling Edge-to-Edge
/// system UI on Android.
///
/// This singleton exposes a small, typed API that communicates with the
/// platform implementation using a [MethodChannel]. Use this class to:
/// - Initialize the native plugin and read device capabilities.
/// - Enable/disable edge-to-edge mode at runtime.
/// - Query system insets and platform information via [getSystemInfo()].
/// - Apply status/navigation bar colors and icon brightness.
///
/// Example
/// ```dart
/// await EdgeToEdgeSystemUIKotlin.instance.initialize();
/// final info = await EdgeToEdgeSystemUIKotlin.instance.getSystemInfo();
/// print('Nav height: ${info.navigationBarsHeight}');
/// ```
class EdgeToEdgeSystemUIKotlin {
  static const MethodChannel _channel = MethodChannel('edge_to_edge_system_ui');

  EdgeToEdgeSystemUIKotlin._();

  static final EdgeToEdgeSystemUIKotlin instance = EdgeToEdgeSystemUIKotlin._();

  /// Whether the device supports edge-to-edge (as determined by the plugin).
  bool isEdgeToEdgeSupported = false;

  /// Cached value from the last initialization/refresh indicating whether
  /// edge-to-edge mode is currently enabled.
  bool isEdgeToEdgeEnabled = false;

  /// Whether the OS enforces edge-to-edge (Android 15+). This is separate
  /// from `isEdgeToEdgeEnabled` which represents plugin actions.
  bool isEdgeToEdgeEnforcedBySystem = false;

  /// Cached Android API level (if available from plugin). Used to decide
  /// whether to prefer transparent status bar (Flutter-drawn) or let the
  /// native plugin paint via the overlay on Android 15+.
  int? androidApiLevel;

  /// Initialize the plugin and cache a quick snapshot of supported/enabled.
  ///
  /// This method must be called before using other methods in this class.
  /// It retrieves the current edge-to-edge support and enabled state from the native plugin.
  Future<void> initialize() async {
    final map = await _channel.invokeMapMethod<String, dynamic>('initialize');
    if (map == null) return;
    isEdgeToEdgeSupported = map['isEdgeToEdgeSupported'] ?? false;
    isEdgeToEdgeEnabled = map['isEdgeToEdgeEnabled'] ?? false;
    isEdgeToEdgeEnforcedBySystem = map['isEdgeToEdgeEnforcedBySystem'] ?? false;
    // If the plugin returned an Android API level, cache it for rules below.
    if (map.containsKey('androidVersion')) {
      try {
        final v = map['androidVersion'];
        if (v is int) {
          androidApiLevel = v;
        } else if (v is String) {
          androidApiLevel = int.tryParse(v);
        }
      } catch (_) {}
    }
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
  Future<bool> enableEdgeToEdge() async {
    try {
      final res = await _channel.invokeMethod<bool>('enable');
      final success = res == true;
      if (success) await initialize();
      isEdgeToEdgeEnabled = isEdgeToEdgeEnabled || success;
      return success;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('enableEdgeToEdge failed: ${e.message}');
      return false;
    }
  }

  /// Disable edge-to-edge mode on the device (Android).
  ///
  /// This method restores the default system UI behavior, where the app content
  /// does not extend behind the system bars.
  Future<bool> disableEdgeToEdge() async {
    try {
      final res = await _channel.invokeMethod<bool>('disable');
      final success = res == true;
      if (success) await initialize();
      if (success) isEdgeToEdgeEnabled = false;
      return success;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('disableEdgeToEdge failed: ${e.message}');
      return false;
    }
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
    final color =
        transparent ? Colors.transparent.toARGB32() : Colors.white.toARGB32();
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
    final color =
        transparent ? Colors.transparent.toARGB32() : Colors.black.toARGB32();
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
    // Always send concrete colors to the plugin so the overlay can work properly.
    // The plugin will handle overlay vs window.statusBarColor automatically.
    if (brightness == Brightness.dark) {
      await setDarkSystemUI(transparent: false);
    } else {
      await setLightSystemUI(transparent: false);
    }
  }
}

/// A wrapper widget that automatically configures edge-to-edge mode and safe areas.
///
/// Place this widget near the top of your widget tree (for example as the
/// `home` of your `MaterialApp`) to automatically initialize the native plugin
/// and configure edge-to-edge behavior. `KotlinSystemUIWrapper` will optionally
/// enable edge-to-edge and apply theme-based system UI colors.
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

    // Ensure we have an up-to-date snapshot from the platform before using flags
    await plugin.initialize();

    if (widget.enableEdgeToEdge && plugin.isEdgeToEdgeSupported) {
      await plugin.enableEdgeToEdge();
    }

    if (widget.enforceContrast && mounted) {
      final brightness = MediaQuery.of(context).platformBrightness;
      await plugin.setSystemUIForTheme(brightness);
    }
  }

  /// Public helper to refresh plugin state and reapply theme. Call this from
  /// the UI after toggling enable/disable so the wrapper reflects the new state.
  Future<void> refresh() async {
    await _configureSystemUI();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A safe area widget that accounts for system UI insets in edge-to-edge mode.
///
/// Use `KotlinEdgeToEdgeSafeArea` instead of `SafeArea` when your app may run
/// in edge-to-edge mode. This widget will automatically switch between using
/// `SafeArea` (when not in edge-to-edge or when `forceSafeArea` is true) and
/// applying `MediaQuery` padding when the plugin reports edge-to-edge is active.
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

  /// Force using Flutter's `SafeArea` even when edge-to-edge is active.
  ///
  /// Some apps prefer the platform-safe-area semantics provided by the
  /// `SafeArea` widget instead of manually applying MediaQuery padding.
  /// Set this to `true` to always wrap the child with `SafeArea` when
  /// content should avoid system bars.
  final bool forceSafeArea;

  const KotlinEdgeToEdgeSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimum = EdgeInsets.zero,
    this.forceSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final plugin = EdgeToEdgeSystemUIKotlin.instance;

    // Treat either plugin-enabled or OS-enforced edge-to-edge as edge-to-edge mode
    final inEdgeToEdgeMode =
        plugin.isEdgeToEdgeEnabled || plugin.isEdgeToEdgeEnforcedBySystem;

    // If we're not in edge-to-edge mode, or the caller requested a SafeArea
    // explicitly, use Flutter's SafeArea wrapper.
    if (!inEdgeToEdgeMode || forceSafeArea) {
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
        bottom: bottom
            ? (mediaQuery.padding.bottom + minimum.bottom)
            : minimum.bottom,
        left: left ? (mediaQuery.padding.left + minimum.left) : minimum.left,
        right:
            right ? (mediaQuery.padding.right + minimum.right) : minimum.right,
      ),
      child: child,
    );
  }
}

/// Utility function to get Android version name from API level.
///
/// Returns a human-friendly Android name for well-known API levels and falls
/// back to a generic string for unknown or future versions.
String whenSdk(int apiLevel) {
  switch (apiLevel) {
    case 36:
      return '16 Baklava';
    case 35:
      return '15 Vanilla Ice Cream';
    case 34:
      return '14 Upside Down Cake';
    case 33:
      return '13 Tiramisu';
    case 32:
      return '12L Snow Cone V2';
    case 31:
      return '12 Snow Cone';
    case 30:
      return '11 Red Velvet Cake';
    case 29:
      return '10 Quince Tart';
    case 28:
      return '9 Pie';
    case 27:
      return '8.1 Oreo MR1';
    case 26:
      return '8.0 Oreo';
    case 25:
      return '7.1 Nougat MR1';
    case 24:
      return '7.0 Nougat';
    case 23:
      return '6.0 Marshmallow';
    case 22:
      return '5.1 Lollipop MR1';
    case 21:
      return '5.0 Lollipop';
    default:
      if (apiLevel > 36) {
        return 'Android (Unknown future version, API $apiLevel)';
      }
      return 'Android API $apiLevel';
  }
}
