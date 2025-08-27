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
