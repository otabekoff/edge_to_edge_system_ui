# edge_to_edge_system_ui

> [!NOTE]
> This package is currently in active development and not intended for general public use. Dev releases are provided for contributors and testers only. Once the package is stable, it will be published with standard versioning and this notice will be removed.

A small Flutter plugin that exposes an Android Kotlin implementation to control edge-to-edge system UI (status/navigation bars) and surface insets. Designed as a lightweight plugin suitable for inclusion on pub.dev.

This package offers a unified approach to managing the status bar and system navigation bar across all major Android versions (5 through 15+). It automatically applies the appropriate edge-to-edge techniques for each platform version, ensuring consistent system UI behavior and appearance, including support for new features introduced in Android 15 and above.

The plugin adapts its handling of the status bar and navigation bar based on the Android version:

- **Android 5–9:** Uses legacy system UI flags and manual inset management for immersive effects.
- **Android 10–14:** Applies modern APIs for improved navigation bar styling and consistent appearance.
- **Android 15+:** Edge-to-edge mode is enabled by default, leveraging the latest system UI features and platform behaviors.

This ensures optimal system UI integration and appearance across all supported Android versions.

Features
- Query system inset sizes and whether edge-to-edge mode is enabled
- Enable/disable edge-to-edge at runtime
- Apply status/navigation bar colors and icon brightness

Usage
1. Add the plugin to your pubspec (local or on pub.dev)
2. Call `EdgeToEdgeSystemUIKotlin.instance.initialize()` on app startup
3. Use `getSystemInfo()`, `enableEdgeToEdge()`, `disableEdgeToEdge()` and `setSystemUIStyle(...)` as needed.

Example code is included in the `example/` folder.

Quick start
-----------

Add the package to `pubspec.yaml` (when published):

```yaml
dependencies:
	edge_to_edge_system_ui: ^0.1.0-dev.4
```

Initialize and query system info:

```dart
await EdgeToEdgeSystemUIKotlin.instance.initialize();
final info = await EdgeToEdgeSystemUIKotlin.instance.getSystemInfo();
print('Navigation bar height: ${info.navigationBarsHeight} dp');
```

See `example/` for a runnable demo.

## Navigator observer requirement

To enable automatic per-route style restoration (so the plugin can restore
previous system UI settings when a route is popped) your app must register
the package-provided `routeObserver` on the top-level `MaterialApp` (or the
root `Navigator`) using the `navigatorObservers` parameter. This is a single
explicit line added to your `MaterialApp`:

```dart
MaterialApp(
  // ... other properties ...
  navigatorObservers: [routeObserver],
)
```

This is required because route lifecycle callbacks are delivered only to
observers registered on the same `Navigator` that owns the route. Registering
the observer ensures the package's `RouteAware` listeners receive push/pop
notifications and can automatically reapply or restore styles.

Publishing
- Update `publish_to` in `pubspec.yaml` to point to `https://pub.dev`.
- Run `flutter pub publish --dry-run` and `flutter pub publish` when ready.

Notes
- The plugin only implements Android in Kotlin currently. iOS and other platforms are no-ops.
- The plugin returns inset sizes in logical pixels (dp) to match Flutter's `MediaQuery`.

## Changelog

See `CHANGELOG.md` for recent changes and version history.

### Optional Debugging Flag

During development, you may want to prevent the screen from turning off. Add the following code to your `MainActivity`:

```kotlin
val isDebuggable = (application?.applicationInfo?.flags ?: 0) and
    android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE != 0
if (isDebuggable) {
    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
}
```

This ensures the screen stays on while the app is running in debug mode.

### AndroidManifest Configuration

To ensure proper edge-to-edge functionality and compatibility with Android 13+ features, you may need to update your `AndroidManifest.xml` file.

1. **Edge-to-Edge Enforcement (Android 13+):**
   Add the following attribute to the `<application>` tag to ensure edge-to-edge behavior is enforced:
   ```xml
   android:windowOptOutEdgeToEdgeEnforcement="false"
   ```

2. **Back Navigation Compatibility (Android 13+):**
   Add the following attribute to the `<application>` tag to enable the new back navigation behavior:
   ```xml
   android:enableOnBackInvokedCallback="true"
   ```

3. **Optional Permission for System Overlays:**
   If your app requires system-level overlays (e.g., floating windows), add the following permission before the `<application>` tag:
   ```xml
   <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
   ```

These configurations are optional but recommended for apps targeting Android 13+ to ensure consistent behavior and compatibility.

## Compatibility with previous in-app implementation

If you migrated from the older in-app implementation (where the plugin lived under `android/app/src`), the package exposes legacy helpers to make migration easier:

- Static registration helper: `EdgeToEdgeSystemUiPlugin.registerWithEngine(flutterEngine, activity)` — call from `MainActivity.configureFlutterEngine` if you registered explicitly before.
- Legacy method names are supported by the plugin channel: `setSystemUIStyle`, `setNavigationBarStyle`, `setStatusBarStyle`.

Preferred usage (new package API)

Use numeric ARGB color values and the compact `setStyle` method from Dart:

```dart
await EdgeToEdgeSystemUIKotlin.instance.setStyle(
  statusBarColor: 0xFF112233, // ARGB int
  navigationBarColor: 0xFF112233,
  statusBarLight: true, // true => light icons in our Dart API (plugin inverts for Android)
  navigationBarLight: true,
);
```

Legacy string-based example (supported for backwards-compatibility):

```dart
await EdgeToEdgeSystemUIKotlin.instance.invokeLegacy(
  method: 'setSystemUIStyle',
  args: {
    'statusBarColor': '#112233',
    'navigationBarColor': '#112233',
    'statusBarIconBrightness': 'dark', // 'dark' means dark icons in legacy API
    'navigationBarIconBrightness': 'dark',
  }
);

## 0.1.0-dev.4 (2025-08-27)

This is a development release containing example improvements and bugfixes:

- Added a "Deep Customize" section in the example app allowing separate control of status bar and navigation bar backgrounds and content brightness.
- Fixed Color -> ARGB compatibility in the example across Flutter SDKs.
- Improved example flow and documentation prior to a dev publish.
```
