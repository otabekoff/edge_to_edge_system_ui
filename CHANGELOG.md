# Changelog

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