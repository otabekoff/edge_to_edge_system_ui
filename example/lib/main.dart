// File: example/lib/main.dart - Fixed for v0.1.0-dev.3

import 'package:flutter/material.dart';
import 'package:edge_to_edge_system_ui/edge_to_edge_system_ui.dart';

// App-wide theme mode notifier (Auto/System, Light, Dark)
final ValueNotifier<ThemeMode> appThemeModeNotifier = ValueNotifier(
  ThemeMode.system,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Kotlin plugin
  final plugin = EdgeToEdgeSystemUIKotlin.instance;
  await plugin.initialize();

  final info = await EdgeToEdgeSystemUIKotlin.instance.getSystemInfo();
  debugPrint('Plugin SystemInfo: ${info.toMap()}');
  runApp(const MyKotlinApp());
}

// A self-contained widget that fetches and displays system info
class SystemInfoCardWidget extends StatefulWidget {
  const SystemInfoCardWidget({super.key});

  @override
  SystemInfoCardWidgetState createState() => SystemInfoCardWidgetState();
}

class SystemInfoCardWidgetState extends State<SystemInfoCardWidget> {
  SystemInfo? _info;
  bool _loading = true;

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
                      'Status Bar Height',
                      '${_info!.statusBarsHeight}px',
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

class MyKotlinApp extends StatelessWidget {
  const MyKotlinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Edge-to-Edge Kotlin Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
          themeMode: mode,
          home: const KotlinSystemUIWrapper(
            enableEdgeToEdge: true,
            enforceContrast: true,
            child: KotlinHomePage(),
          ),
        );
      },
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
  Brightness _deepStatusIconBrightness = Brightness.light;
  Brightness _deepNavIconBrightness = Brightness.light;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Kotlin Edge-to-Edge'),
        backgroundColor: Colors.blue.withValues(alpha: 0.9),
        elevation: 0,
      ),
      body: KotlinEdgeToEdgeSafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80), // Space for app bar

              SystemInfoCardWidget(key: _systemInfoKey),
              const SizedBox(height: 20),

              _buildControlsCard(),
              const SizedBox(height: 20),

              _buildPresetColorsCard(),
              const SizedBox(height: 20),

              _buildCustomColorCard(),
              const SizedBox(height: 20),

              _buildDeepCustomizeCard(),
              const SizedBox(height: 100), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsCard() {
    final plugin = EdgeToEdgeSystemUIKotlin.instance;

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

            // Theme mode selection
            Row(
              children: [
                const Text('Theme:'),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: appThemeModeNotifier,
                    builder: (context, mode, _) {
                      return Wrap(
                        spacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          InkWell(
                            onTap: () =>
                                appThemeModeNotifier.value = ThemeMode.system,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<ThemeMode>(
                                  value: ThemeMode.system,
                                  groupValue: mode,
                                  onChanged: (v) => appThemeModeNotifier.value =
                                      v ?? ThemeMode.system,
                                ),
                                const Text('Auto'),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                appThemeModeNotifier.value = ThemeMode.light,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<ThemeMode>(
                                  value: ThemeMode.light,
                                  groupValue: mode,
                                  onChanged: (v) => appThemeModeNotifier.value =
                                      v ?? ThemeMode.system,
                                ),
                                const Text('Light'),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                appThemeModeNotifier.value = ThemeMode.dark,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Radio<ThemeMode>(
                                  value: ThemeMode.dark,
                                  groupValue: mode,
                                  onChanged: (v) => appThemeModeNotifier.value =
                                      v ?? ThemeMode.system,
                                ),
                                const Text('Dark'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Hide the enable/disable control on Android 15+ where the OS
            // enforces edge-to-edge behavior.
            (plugin.androidApiLevel != null && plugin.androidApiLevel! >= 15)
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (plugin.isEdgeToEdgeSupported &&
                                  !plugin.isEdgeToEdgeEnforcedBySystem)
                              ? () => _toggleEdgeToEdge()
                              : null,
                          icon: Icon(
                            plugin.isEdgeToEdgeEnabled
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                          ),
                          label: Text(
                            plugin.isEdgeToEdgeEnabled
                                ? 'Disable Edge-to-Edge'
                                : 'Enable Edge-to-Edge',
                          ),
                        ),
                      ),
                    ],
                  ),

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
          ],
        ),
      ),
    );
  }

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
                      .setDarkSystemUI(transparent: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                  ),
                  child: const Text(
                    'Dark Solid',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      EdgeToEdgeSystemUIKotlin.instance.setSystemUIStyle(
                    statusBarColor: _colorToInt(Colors.white),
                    navigationBarColor: _colorToInt(Colors.white),
                    statusBarLight: false,
                    navigationBarLight: false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'White',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      EdgeToEdgeSystemUIKotlin.instance.setSystemUIStyle(
                    statusBarColor: _colorToInt(Colors.black),
                    navigationBarColor: _colorToInt(Colors.black),
                    statusBarLight: true,
                    navigationBarLight: true,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Black',
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
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Status bar background picker (simple swatches)
            const Text('Status bar background'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _swatchButton(
                    Colors.blue, () => _applyDeepColors(statusBg: Colors.blue)),
                _swatchButton(Colors.white,
                    () => _applyDeepColors(statusBg: Colors.white)),
                _swatchButton(Colors.black,
                    () => _applyDeepColors(statusBg: Colors.black)),
                _swatchButton(Colors.green,
                    () => _applyDeepColors(statusBg: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),

            // Status bar content color (Light/Dark)
            Row(
              children: [
                const Text('Status bar content:'),
                const SizedBox(width: 12),
                ToggleButtons(
                  isSelected: [
                    _deepStatusIconBrightness == Brightness.light,
                    _deepStatusIconBrightness == Brightness.dark,
                  ],
                  onPressed: (i) {
                    setState(() {
                      _deepStatusIconBrightness =
                          i == 0 ? Brightness.light : Brightness.dark;
                    });
                    _applyDeepColors(statusIcon: _deepStatusIconBrightness);
                  },
                  children: const [Text('Light'), Text('Dark')],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Nav bar background picker
            const Text('Navigation bar background'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _swatchButton(
                    Colors.black, () => _applyDeepColors(navBg: Colors.black)),
                _swatchButton(
                    Colors.white, () => _applyDeepColors(navBg: Colors.white)),
                _swatchButton(
                    Colors.blue, () => _applyDeepColors(navBg: Colors.blue)),
                _swatchButton(
                    Colors.grey, () => _applyDeepColors(navBg: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            // Nav bar content color (Light/Dark)
            Row(
              children: [
                const Text('Navigation bar content:'),
                const SizedBox(width: 12),
                ToggleButtons(
                  isSelected: [
                    _deepNavIconBrightness == Brightness.light,
                    _deepNavIconBrightness == Brightness.dark,
                  ],
                  onPressed: (i) {
                    setState(() {
                      _deepNavIconBrightness =
                          i == 0 ? Brightness.light : Brightness.dark;
                    });
                    _applyDeepColors(navIcon: _deepNavIconBrightness);
                  },
                  children: const [Text('Light'), Text('Dark')],
                ),
              ],
            ),
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

  void _applyDeepColors({
    Color? statusBg,
    Color? navBg,
    Brightness? statusIcon,
    Brightness? navIcon,
  }) {
    if (statusBg != null) _deepStatusBarBg = statusBg;
    if (navBg != null) _deepNavBarBg = navBg;
    if (statusIcon != null) _deepStatusIconBrightness = statusIcon;
    if (navIcon != null) _deepNavIconBrightness = navIcon;

    // Call plugin with explicit values and brightness
    EdgeToEdgeSystemUIKotlin.instance.setSystemUIStyleWithBrightness(
      statusBarColor: _deepStatusBarBg,
      navigationBarColor: _deepNavBarBg,
      statusBarIconBrightness: _deepStatusIconBrightness,
      navigationBarIconBrightness: _deepNavIconBrightness,
    );

    setState(() {});
  }

  // Compatibility helper: convert a Color to ARGB int for plugin calls
  // Avoid using the deprecated `.value` getter; compose ARGB explicitly.
  int _colorToInt(Color c) {
    // Use the modern API when available.
    return c.toARGB32();
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

  void _resetToTheme() {
    final brightness = MediaQuery.of(context).platformBrightness;
    EdgeToEdgeSystemUIKotlin.instance.setSystemUIForTheme(brightness);
  }

  void _setCustomColor(Color color) {
    EdgeToEdgeSystemUIKotlin.instance.setSystemUIStyleWithBrightness(
      statusBarColor: color,
      navigationBarColor: color,
      statusBarIconBrightness: Brightness.light,
      navigationBarIconBrightness: Brightness.light,
    );
  }

  Future<void> _toggleEdgeToEdge() async {
    final plugin = EdgeToEdgeSystemUIKotlin.instance;

    bool success = false;
    if (plugin.isEdgeToEdgeEnabled) {
      success = await plugin.disableEdgeToEdge();
    } else {
      success = await plugin.enableEdgeToEdge();
    }

    // Refresh info card and rebuild controls so button reflects new state
    await _refreshSystemInfo();
    if (mounted) setState(() {});

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to toggle edge-to-edge')),
      );
    }
  }
}

// Ensure DebugInfoPage is defined or imported
class DebugInfoPage extends StatelessWidget {
  const DebugInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Info')),
      body: const Center(child: Text('Debug information goes here.')),
    );
  }
}
