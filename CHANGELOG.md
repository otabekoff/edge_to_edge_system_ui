# Changelog

## 0.1.0-dev.6 - 2025-08-28
- Development release: patch/dev increment with example/docs and init behavior tweaks.
- Centralized system UI brightness computation in the Dart wrapper so apps
	only pass background colors and the package derives icon/text brightness.
- Prevent automatic enablement of edge-to-edge on Android 14 and below during
	initialization; Android 15+ (OS-enforced) is still respected.
- Example and test apps: removed manual enable/disable toggle, improved
	theme controls, and tidied example documentation.

## 0.1.0-dev.5 - 2025-08-28
 - Added `doc/getting_started.md` documenting initialization, APIs and the
		`routeObserver` requirement for automatic per-route style restoration.
 - Added `example/README.md` so the example shows up on pub.dev and documents
		example usage and entry points.
 - Cleaned up example and app comments to clarify `navigatorObservers` usage.

## 0.1.0-dev.4 - 2025-08-27
- Added "Deep Customize" controls to the example app allowing separate control of:
	- status bar background color
	- status bar content (icon/text) brightness
	- navigation bar background color
	- navigation bar content (icon/text) brightness
- Fixed example compatibility issues with Color -> ARGB conversion across SDKs
- Hid edge-to-edge toggle on Android 15+ where the OS enforces edge-to-edge behavior
- Various example and documentation improvements

## 0.1.0-dev.3 - 2025-08-26
- Added convenience methods `setLightSystemUI()` and `setDarkSystemUI()` with transparency options
- Added `setSystemUIStyleWithBrightness()` method that accepts Flutter Color objects and Brightness enum
- Added `setSystemUIForTheme()` method for automatic theme-based system UI styling
- Added `KotlinSystemUIWrapper` widget for automatic edge-to-edge configuration
- Added `KotlinEdgeToEdgeSafeArea` widget for proper safe area handling in edge-to-edge mode
- Added `whenSdk()` utility function to convert Android API levels to version names
- Enhanced API with Flutter-friendly parameter types
- Fixed compatibility issues with comprehensive example usage

## 0.1.0-dev.2 - 2025-08-26
- Add typed `SystemInfo` model and dartdoc comments
- Improve public API documentation and examples
- Bump version for stable release
- Added DartDoc comments to public API elements.
- Improved pub.dev score by documenting the API.

## 0.1.0-dev.1 - 2025-08-26
- Initial skeleton
- Android Kotlin implementation
- Dart wrapper and example
- Automatic edge-to-edge setup in the plugin.
- Added documentation for optional debugging flag.