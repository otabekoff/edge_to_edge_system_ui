# edge_to_edge_system_ui

A small Flutter plugin that exposes an Android Kotlin implementation to control edge-to-edge system UI (status/navigation bars) and surface insets. Designed as a lightweight plugin suitable for inclusion on pub.dev.

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
	edge_to_edge_system_ui: ^0.1.0
```

Initialize and query system info:

```dart
await EdgeToEdgeSystemUIKotlin.instance.initialize();
final info = await EdgeToEdgeSystemUIKotlin.instance.getSystemInfo();
print('Navigation bar height: ${info.navigationBarsHeight} dp');
```

See `example/` for a runnable demo.

Publishing
- Update `publish_to` in `pubspec.yaml` to point to `https://pub.dev`.
- Run `flutter pub publish --dry-run` and `flutter pub publish` when ready.

Notes
- The plugin only implements Android in Kotlin currently. iOS and other platforms are no-ops.
- The plugin returns inset sizes in logical pixels (dp) to match Flutter's `MediaQuery`.

Changelog
---------

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
