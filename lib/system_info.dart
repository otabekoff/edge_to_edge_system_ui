// system_info.dart
/// System inset and platform information returned by the plugin.
///
/// The [SystemInfo] object is returned by [EdgeToEdgeSystemUIKotlin.getSystemInfo]
/// and provides a structured snapshot of the platform state relevant to
/// edge-to-edge UI handling. Fields are expressed in logical pixels (dp)
/// where appropriate to match Flutter's conventions.
class SystemInfo {
  /// Whether edge-to-edge mode is currently enabled on the device.
  final bool isEdgeToEdgeEnabled;

  /// Whether the device supports edge-to-edge mode.
  final bool isEdgeToEdgeSupported;

  /// Android API level (e.g. 33) when available.
  final int? androidVersion;

  /// Android release string when available (e.g. '13').
  final String? androidRelease;

  /// Logical pixels (dp) for the top system inset.
  final int systemBarsTop;

  /// Logical pixels (dp) for the bottom system inset.
  final int systemBarsBottom;

  /// Logical pixels (dp) for the left system inset.
  final int systemBarsLeft;

  /// Logical pixels (dp) for the right system inset.
  final int systemBarsRight;

  /// Logical pixels (dp) of the status bar height.
  final int statusBarsHeight;

  /// Logical pixels (dp) of the navigation bar height.
  final int navigationBarsHeight;

  /// Whether the device configuration exposes a navigation bar.
  final bool hasNavigationBar;

  const SystemInfo({
    required this.isEdgeToEdgeEnabled,
    required this.isEdgeToEdgeSupported,
    this.androidVersion,
    this.androidRelease,
    required this.systemBarsTop,
    required this.systemBarsBottom,
    required this.systemBarsLeft,
    required this.systemBarsRight,
    required this.statusBarsHeight,
    required this.navigationBarsHeight,
    required this.hasNavigationBar,
  });

  /// Construct from a dynamic map returned by the platform plugin.
  factory SystemInfo.fromMap(Map<String, dynamic> m) {
    return SystemInfo(
      isEdgeToEdgeEnabled: m['isEdgeToEdgeEnabled'] as bool? ?? false,
      isEdgeToEdgeSupported: m['isEdgeToEdgeSupported'] as bool? ?? false,
      androidVersion: m['androidVersion'] as int?,
      androidRelease: m['androidRelease'] as String?,
      systemBarsTop: (m['systemBarsTop'] as int?) ?? 0,
      systemBarsBottom: (m['systemBarsBottom'] as int?) ?? 0,
      systemBarsLeft: (m['systemBarsLeft'] as int?) ?? 0,
      systemBarsRight: (m['systemBarsRight'] as int?) ?? 0,
      statusBarsHeight: (m['statusBarsHeight'] as int?) ?? 0,
      navigationBarsHeight: (m['navigationBarsHeight'] as int?) ?? 0,
      hasNavigationBar: m['hasNavigationBar'] as bool? ?? false,
    );
  }

  /// Convert back to a map (useful for tests/examples).
  Map<String, dynamic> toMap() => {
        'isEdgeToEdgeEnabled': isEdgeToEdgeEnabled,
        'isEdgeToEdgeSupported': isEdgeToEdgeSupported,
        'androidVersion': androidVersion,
        'androidRelease': androidRelease,
        'systemBarsTop': systemBarsTop,
        'systemBarsBottom': systemBarsBottom,
        'systemBarsLeft': systemBarsLeft,
        'systemBarsRight': systemBarsRight,
        'statusBarsHeight': statusBarsHeight,
        'navigationBarsHeight': navigationBarsHeight,
        'hasNavigationBar': hasNavigationBar,
      };
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
