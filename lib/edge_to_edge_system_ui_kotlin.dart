// edge_to_edge_system_ui_kotlin.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'system_info.dart';

/// A shared [RouteObserver] exported by the package.
///
/// Usage: register this observer on your app's top-level [MaterialApp] (or
/// on the Navigator you want the plugin to track) so the package's
/// RouteAware listeners receive push/pop lifecycle callbacks.
///
/// Example:
///
/// ```dart
/// MaterialApp(
///   // ...
///   navigatorObservers: [routeObserver],
/// )
/// ```
///
/// Why this is required: the plugin attaches `RouteAware` listeners to the
/// `Route` associated with a given BuildContext so it can automatically
/// restore previously-applied system UI styles when a route is popped. Those
/// notifications are only delivered to observers that were registered on the
/// same [Navigator] instance that owns the route. Registering this observer
/// on your app's root navigator is the simplest, most robust way to ensure
/// the plugin receives lifecycle events across typical apps.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

// Internal representation of a system UI style snapshot.
class _SystemUiStyle {
  final int statusBarColor;
  final int navigationBarColor;
  final bool statusBarLight;
  final bool navigationBarLight;

  _SystemUiStyle({
    required this.statusBarColor,
    required this.navigationBarColor,
    required this.statusBarLight,
    required this.navigationBarLight,
  });
}

// (Navigator observer class removed; plugin uses routeObserver + RouteAware listeners)

class _RouteStyleListener with RouteAware {
  final Route<dynamic> route;
  final EdgeToEdgeSystemUIKotlin plugin;

  _RouteStyleListener(this.route, this.plugin);

  @override
  void didPopNext() {
    // Not used here.
  }

  @override
  void didPop() {
    // When the associated route is popped, ask the plugin to restore
    plugin._onRoutePopped();
    // Unsubscribe
    routeObserver.unsubscribe(this);
  }

  @override
  void didPush() {}

  @override
  void didPushNext() {}
}

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
  ///
  /// Call this early during app startup (for example in `main()` before
  /// `runApp`) to ensure the plugin's cached properties such as
  /// [isEdgeToEdgeSupported], [isEdgeToEdgeEnabled], and
  /// [isEdgeToEdgeEnforcedBySystem] are populated. This method queries the
  /// native Kotlin implementation via the method channel and stores a local
  /// snapshot used by convenience helpers in this class.
  ///
  /// Errors from the platform are propagated as [PlatformException]. If the
  /// plugin is not available the returned map may be null and the method
  /// will return without mutating state.
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
  /// The returned [SystemInfo] contains the status/navigation bar heights
  /// (in logical pixels), Android API level (when available), and flags such
  /// as whether edge-to-edge is supported and currently enabled. Use this
  /// to adapt UI layout or feature gating in your app.
  Future<SystemInfo> getSystemInfo() async {
    final map =
        await _channel.invokeMapMethod<String, dynamic>('getSystemInfo');
    return SystemInfo.fromMap(
        map?.cast<String, dynamic>() ?? <String, dynamic>{});
  }

  /// Enable edge-to-edge mode on the device (Android).
  ///
  /// When enabled, app content will render edge-to-edge (behind the status
  /// and navigation bars). The plugin will attempt to set the appropriate
  /// window flags and notify the native implementation to update system
  /// insets. On success this method updates [isEdgeToEdgeEnabled].
  ///
  /// Returns `true` when the native platform successfully changed the
  /// edge-to-edge state. Callers should refresh any layout or insets after a
  /// successful transition (for example by re-reading [getSystemInfo]).
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
  /// Restores default window behavior so app content no longer extends under
  /// system bars. On success [isEdgeToEdgeEnabled] will be updated to `false`.
  ///
  /// Returns `true` when the native platform successfully changed the
  /// edge-to-edge state.
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
  /// Parameters:
  /// - [statusBarColor]: ARGB color value for the status bar background.
  /// - [navigationBarColor]: ARGB color value for the navigation bar background.
  /// - [statusBarLight]: when `true` the status bar content (icons/text)
  ///   will be rendered light; when `false` dark content is used. Note that
  ///   platform semantics may invert this flag depending on the Android API
  ///   level and the plugin will convert booleans to platform-appropriate
  ///   calls internally.
  /// - [navigationBarLight]: same semantics as [statusBarLight] but for the
  ///   navigation bar.
  ///
  /// This is a low-level API; higher-level convenience methods are provided
  /// that accept Flutter [Color]s or compute icon brightness automatically.
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

  // Internal stack to remember styles applied by the app/plugin so we can
  // restore previous styles when routes are popped.
  final List<_SystemUiStyle> _styleStack = [];

  // Track listeners per route so we can unsubscribe when restored.
  final Map<Route<dynamic>, _RouteStyleListener> _routeListeners = {};

  // Apply and push a style to the internal stack. If [push] is false, the
  // style will be applied but not pushed (transient).
  // Internal helper: apply a style and optionally push it on the stack.
  // This is private to avoid exposing the private [_SystemUiStyle] in a
  // public API surface.
  Future<void> _applyAndPushStyle(_SystemUiStyle style,
      {bool push = true}) async {
    if (push) _styleStack.add(style);
    await setSystemUIStyle(
      statusBarColor: style.statusBarColor,
      navigationBarColor: style.navigationBarColor,
      statusBarLight: style.statusBarLight,
      navigationBarLight: style.navigationBarLight,
    );
  }

  /// Apply a system UI style associated with the [ModalRoute] for [context].
  ///
  /// The plugin will automatically restore the previous style when that
  /// route is popped. This keeps route lifecycle handling inside the package
  /// instead of requiring every page to implement [RouteAware].
  ///
  /// How it works:
  /// - If this is the first pushed style a base snapshot is captured from the
  ///   current theme and saved on the internal style stack. The base snapshot
  ///   is not applied immediately — the merged style is applied next.
  /// - Missing parameters are merged with the last applied style (or base
  ///   snapshot) so partial updates (for example changing only the
  ///   navigation bar color) are supported.
  /// - If both colors and explicit brightness flags are omitted, the method
  ///   will return without changing anything (so pages that do not set any
  ///   style won't affect the existing system UI state).
  ///
  /// Brightness resolution order:
  /// 1. Explicit [statusBarIconBrightness]/[navigationBarIconBrightness] (if supplied).
  /// 2. Brightness derived from the provided color's luminance (if brightness
  ///    args are omitted).
  /// 3. Previously-applied style on the stack.
  ///
  /// IMPORTANT: For automatic restoration to work the app must register the
  /// package-provided `routeObserver` on the `MaterialApp` (see
  /// `routeObserver` documentation and README). Example:
  ///
  /// ```dart
  /// MaterialApp(navigatorObservers: [routeObserver], ...)
  /// ```
  ///
  /// Parameters are optional; omit an argument to inherit from the base style.
  Future<void> pushStyleForRoute(
    BuildContext context, {
    Color? statusBarColor,
    Color? navigationBarColor,
    Brightness? statusBarIconBrightness,
    Brightness? navigationBarIconBrightness,
  }) async {
    final route = ModalRoute.of(context);
    if (route == null) return;

    // If caller didn't provide any style, don't push — this avoids
    // reapplying a page's (non-existent) style when navigating back.
    if (statusBarColor == null &&
        navigationBarColor == null &&
        statusBarIconBrightness == null &&
        navigationBarIconBrightness == null) {
      return;
    }

    // Start from the last applied style if present so we can merge partial
    // updates. If there are no styles on the stack, capture a base style
    // derived from the current theme and push it (saved only) so we can
    // restore it when the newly pushed style is popped. We don't apply the
    // base immediately because the merged style will be applied next.
    _SystemUiStyle base;
    if (_styleStack.isNotEmpty) {
      base = _styleStack.last;
    } else {
      final brightness = Theme.of(context).brightness;
      final isDark = brightness == Brightness.dark;
      base = _SystemUiStyle(
        statusBarColor: (isDark ? Colors.black : Colors.white).toARGB32(),
        navigationBarColor: (isDark ? Colors.black : Colors.white).toARGB32(),
        statusBarLight: isDark,
        navigationBarLight: isDark,
      );
      // Save base onto stack so it will be restored after the pushed style is popped.
      _styleStack.add(base);
    }

    // Resolve colors
    final resolvedStatusColor = statusBarColor ?? Color(base.statusBarColor);
    final resolvedNavColor =
        navigationBarColor ?? Color(base.navigationBarColor);

    // If caller didn't provide explicit brightness, derive it from color luminance.
    final derivedStatusBrightness = resolvedStatusColor.computeLuminance() > 0.5
        ? Brightness.dark
        : Brightness.light;
    final derivedNavBrightness = resolvedNavColor.computeLuminance() > 0.5
        ? Brightness.dark
        : Brightness.light;

    final merged = _SystemUiStyle(
      statusBarColor: resolvedStatusColor.toARGB32(),
      navigationBarColor: resolvedNavColor.toARGB32(),
      statusBarLight: statusBarIconBrightness == null
          ? (base.statusBarLight)
          : (statusBarIconBrightness == Brightness.light),
      navigationBarLight: navigationBarIconBrightness == null
          ? (base.navigationBarLight)
          : (navigationBarIconBrightness == Brightness.light),
    );

    // If either brightness was not provided, replace with derived brightness
    // computed from the resolved color. This keeps explicit args highest priority,
    // then color-derived behavior, then the previously applied base style.
    final finalMerged = _SystemUiStyle(
      statusBarColor: merged.statusBarColor,
      navigationBarColor: merged.navigationBarColor,
      statusBarLight: statusBarIconBrightness == null
          ? (derivedStatusBrightness == Brightness.light)
          : merged.statusBarLight,
      navigationBarLight: navigationBarIconBrightness == null
          ? (derivedNavBrightness == Brightness.light)
          : merged.navigationBarLight,
    );

    // Apply and push to stack
    await _applyAndPushStyle(finalMerged, push: true);

    // Subscribe a listener that will restore when the route is popped.
    final listener = _RouteStyleListener(route, this);
    _routeListeners[route] = listener;
    routeObserver.subscribe(listener, route);
  }

  // Pop the last style and reapply the previous one (if any).
  Future<void> _onRoutePopped() async {
    if (_styleStack.isNotEmpty) {
      _styleStack.removeLast();
    }
    if (_styleStack.isNotEmpty) {
      final s = _styleStack.last;
      await setSystemUIStyle(
        statusBarColor: s.statusBarColor,
        navigationBarColor: s.navigationBarColor,
        statusBarLight: s.statusBarLight,
        navigationBarLight: s.navigationBarLight,
      );
    } else {
      // No styles left: fall back to theme mapping if possible.
      // We can't read Theme.of(context) here; caller should call
      // setSystemUIForTheme if needed. Do nothing here.
    }
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

  /// Convenience helper: provide only background [Color]s and let the package
  /// compute an appropriate icon/text [Brightness] automatically using
  /// luminance. Callers who don't want to compute brightness themselves can
  /// use this method.
  ///
  /// This helper is the recommended API for most apps: pass Flutter
  /// `Color` objects for the status and navigation background and the
  /// package will compute an appropriate icon/text brightness using
  /// `Color.computeLuminance()` (simple and robust heuristic). This avoids
  /// callers duplicating luminance logic and keeps appearance decisions
  /// centralized in one place.
  Future<void> setSystemUIStyleForColors({
    required Color statusBarColor,
    required Color navigationBarColor,
  }) async {
    final statusIconBrightness = statusBarColor.computeLuminance() > 0.5
        ? Brightness.dark
        : Brightness.light;
    final navIconBrightness = navigationBarColor.computeLuminance() > 0.5
        ? Brightness.dark
        : Brightness.light;
    await setSystemUIStyleWithBrightness(
      statusBarColor: statusBarColor,
      navigationBarColor: navigationBarColor,
      statusBarIconBrightness: statusIconBrightness,
      navigationBarIconBrightness: navIconBrightness,
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

// Compatibility helper: convert a Color to ARGB int for plugin calls
// Avoid using the deprecated `.value` getter; compose ARGB explicitly.
// Reserved helper for future use. Keep it available without analyzer warnings.
// ignore: unused_element
int _colorToInt(Color c) {
  // Use the modern API when available.
  return c.toARGB32();
}
