import 'package:flutter/material.dart';
import 'package:edge_to_edge_system_ui/edge_to_edge_system_ui.dart';
import 'debug_info_page.dart';
import 'debug_info_page2.dart';
import 'app_state.dart';

// A self-contained widget that fetches and displays system info
class SystemInfoCardWidget extends StatefulWidget {
  const SystemInfoCardWidget({super.key});

  @override
  SystemInfoCardWidgetState createState() => SystemInfoCardWidgetState();
}

class SystemInfoCardWidgetState extends State<SystemInfoCardWidget> {
  SystemInfo? _info;
  bool _loading = true;

  // Public read-only access to the fetched SystemInfo for external widgets.
  SystemInfo? get systemInfo => _info;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() {
      _loading = true;
    });

    try {
      final info = await EdgeToEdgeSystemUIKotlin.instance.getSystemInfo();
      setState(() {
        _info = info;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _info = null;
        _loading = false;
      });
      debugPrint('SystemInfoCardWidget.refresh error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_info != null) ...[
                    _buildInfoRow(
                      'Edge-to-Edge Supported',
                      _info!.isEdgeToEdgeSupported,
                    ),
                    _buildInfoRow(
                      'Edge-to-Edge Enabled',
                      _info!.isEdgeToEdgeEnabled,
                    ),
                    if (_info!.androidVersion != null) ...[
                      _buildInfoRow(
                        'Android API Level',
                        _info!.androidVersion!,
                      ),
                      _buildInfoRow(
                        'Android Name',
                        whenSdk(_info!.androidVersion!),
                      ),
                      if (_info!.androidRelease != null)
                        _buildInfoRow(
                          'Android Release',
                          _info!.androidRelease!,
                        ),
                    ],
                    _buildInfoRow(
                      'Has Navigation Bar',
                      _info!.hasNavigationBar,
                    ),
                    _buildInfoRow(
                      'Navigation Bar Height',
                      '${_info!.navigationBarsHeight}px',
                    ),
                  ] else ...[
                    const Text('Unable to load system info.'),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class KotlinHomePage extends StatefulWidget {
  const KotlinHomePage({super.key});

  @override
  State<KotlinHomePage> createState() => _KotlinHomePageState();
}

class _KotlinHomePageState extends State<KotlinHomePage> {
  final GlobalKey<SystemInfoCardWidgetState> _systemInfoKey =
      GlobalKey<SystemInfoCardWidgetState>();

  // Deep customize state
  Color _deepStatusBarBg = Colors.blue;
  Color _deepNavBarBg = Colors.black;

  @override
  void initState() {
    super.initState();
    // Listen to theme changes and apply system UI colors accordingly
    appThemeModeNotifier.addListener(_onThemeModeChanged);
    // Apply initial theme-based system UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemUIForCurrentTheme();
    });
  }

  @override
  void dispose() {
    appThemeModeNotifier.removeListener(_onThemeModeChanged);
    super.dispose();
  }

  void _onThemeModeChanged() {
    _updateSystemUIForCurrentTheme();
  }

  void _updateSystemUIForCurrentTheme() {
    final themeMode = appThemeModeNotifier.value;
    final platformBrightness = MediaQuery.of(context).platformBrightness;

    Brightness effectiveBrightness;
    switch (themeMode) {
      case ThemeMode.light:
        effectiveBrightness = Brightness.light;
        break;
      case ThemeMode.dark:
        effectiveBrightness = Brightness.dark;
        break;
      case ThemeMode.system:
        effectiveBrightness = platformBrightness;
        break;
    }

    // Apply theme-based system UI colors
    if (effectiveBrightness == Brightness.dark) {
      // Dark theme - use dark backgrounds
      EdgeToEdgeSystemUIKotlin.instance.setSystemUIStyleForColors(
        statusBarColor: Colors.black,
        navigationBarColor: Colors.black,
      );
    } else {
      // Light theme - use light backgrounds
      EdgeToEdgeSystemUIKotlin.instance.setSystemUIStyleForColors(
        statusBarColor: Colors.white,
        navigationBarColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kotlin Home'),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.purple
            : Colors.blue,
      ),
      body: SingleChildScrollView(
        // Add bottom padding to avoid being covered by system UI (navigation bar)
        padding: EdgeInsets.fromLTRB(
          16.0,
          16.0,
          16.0,
          16.0 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SystemInfoCardWidget(key: _systemInfoKey),
            const SizedBox(height: 12),
            _buildControlsCard(),
            const SizedBox(height: 12),
            _buildPresetColorsCard(),
            const SizedBox(height: 12),
            _buildCustomColorCard(),
            const SizedBox(height: 12),
            _buildDeepCustomizeCard(),
          ],
        ),
      ),
    );
  }

  // Add a method to reset to current theme (useful for after custom colors)
  void _resetToCurrentTheme() {
    _updateSystemUIForCurrentTheme();
  }

  // Update the existing _resetToTheme method to use the new logic
  void _resetToTheme() {
    _resetToCurrentTheme();
  }

  // Rest of your existing methods remain the same...
  Widget _buildControlsCard() {
    final plugin = EdgeToEdgeSystemUIKotlin.instance;
    final info = _systemInfoKey.currentState?.systemInfo;

    debugPrint(
      'Controls debug - androidVersion: ${info?.androidVersion}, '
      'isEdgeToEdgeSupported: ${plugin.isEdgeToEdgeSupported}, '
      'isEdgeToEdgeEnforcedBySystem: ${plugin.isEdgeToEdgeEnforcedBySystem}',
    );

    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controls',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [Text('Theme:'), SizedBox(width: 12)],
                ),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: appThemeModeNotifier,
                  builder: (context, mode, _) {
                    return RadioGroup<ThemeMode>(
                      groupValue: mode,
                      onChanged: (v) =>
                          appThemeModeNotifier.value = v ?? ThemeMode.system,
                      child: const Column(
                        children: [
                          RadioListTile<ThemeMode>(
                            title: Text('Auto'),
                            value: ThemeMode.system,
                          ),
                          RadioListTile<ThemeMode>(
                            title: Text('Light'),
                            value: ThemeMode.light,
                          ),
                          RadioListTile<ThemeMode>(
                            title: Text('Dark'),
                            value: ThemeMode.dark,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Debug: supported=${plugin.isEdgeToEdgeSupported}, android=${info?.androidVersion ?? 'unknown'}, enforced=${plugin.isEdgeToEdgeEnforcedBySystem}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            const SizedBox.shrink(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _refreshSystemInfo,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Info'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DebugInfoPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Show Debug Info'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DebugInfoPage2(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report_outlined),
                    label: const Text('Show Debug Info 2'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Rest of your existing methods...
  Widget _buildPresetColorsCard() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preset Styles',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => EdgeToEdgeSystemUIKotlin.instance
                      .setLightSystemUI(transparent: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white24,
                  ),
                  child: const Text(
                    'Light Transparent',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => EdgeToEdgeSystemUIKotlin.instance
                      .setLightSystemUI(transparent: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white70,
                  ),
                  child: const Text(
                    'Light Solid',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => EdgeToEdgeSystemUIKotlin.instance
                      .setDarkSystemUI(transparent: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                  child: const Text(
                    'Dark Transparent',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => EdgeToEdgeSystemUIKotlin.instance
                      .setDarkSystemUI(transparent: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                  ),
                  child: const Text(
                    'Dark Solid',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomColorCard() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Colors',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildColorButton('Blue', Colors.blue),
                _buildColorButton('Red', Colors.red),
                _buildColorButton('Green', Colors.green),
                _buildColorButton('Purple', Colors.purple),
                _buildColorButton('Orange', Colors.orange),
                _buildColorButton('Teal', Colors.teal),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetToTheme,
                    child: const Text('Reset to Theme'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeepCustomizeCard() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deep Customize',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Status bar background'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _swatchButton(
                  Colors.blue,
                  () => _applyDeepColors(statusBg: Colors.blue),
                ),
                _swatchButton(
                  Colors.white,
                  () => _applyDeepColors(statusBg: Colors.white),
                ),
                _swatchButton(
                  Colors.black,
                  () => _applyDeepColors(statusBg: Colors.black),
                ),
                _swatchButton(
                  Colors.green,
                  () => _applyDeepColors(statusBg: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Status & navigation bar icon color is computed automatically from the chosen backgrounds.',
            ),
            const SizedBox(height: 12),
            const Text('Navigation bar background'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _swatchButton(
                  Colors.black,
                  () => _applyDeepColors(navBg: Colors.black),
                ),
                _swatchButton(
                  Colors.white,
                  () => _applyDeepColors(navBg: Colors.white),
                ),
                _swatchButton(
                  Colors.blue,
                  () => _applyDeepColors(navBg: Colors.blue),
                ),
                _swatchButton(
                  Colors.grey,
                  () => _applyDeepColors(navBg: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _swatchButton(Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(48, 36),
      ),
      child: const SizedBox.shrink(),
    );
  }

  void _applyDeepColors({Color? statusBg, Color? navBg}) {
    if (statusBg != null) _deepStatusBarBg = statusBg;
    if (navBg != null) _deepNavBarBg = navBg;

    // Let the package compute icon/text brightness from the provided colors.
    EdgeToEdgeSystemUIKotlin.instance.setSystemUIStyleForColors(
      statusBarColor: _deepStatusBarBg,
      navigationBarColor: _deepNavBarBg,
    );

    setState(() {});
  }

  Widget _buildColorButton(String name, Color color) {
    return ElevatedButton(
      onPressed: () => _setCustomColor(color),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: _getContrastingTextColor(color),
      ),
      child: Text(name),
    );
  }

  Color _getContrastingTextColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Future<void> _refreshSystemInfo() async {
    _systemInfoKey.currentState?.refresh();
  }

  void _setCustomColor(Color color) {
    EdgeToEdgeSystemUIKotlin.instance.setSystemUIStyleForColors(
      statusBarColor: color,
      navigationBarColor: color,
    );
  }

  // Toggle removed: manual enable/disable UI has been removed. Use
  // EdgeToEdgeSystemUIKotlin.instance.enableEdgeToEdge()/disableEdgeToEdge()
  // directly if needed.
}
