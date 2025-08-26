// File: example/lib/main.dart - Fixed for v0.1.0-dev.3

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: plugin.isEdgeToEdgeSupported
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                    backgroundColor: Colors.white70,
                  ),
                  child: const Text(
                    'Light Transparent',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => EdgeToEdgeSystemUIKotlin.instance
                      .setDarkSystemUI(transparent: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                  ),
                  child: const Text(
                    'Dark Transparent',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => EdgeToEdgeSystemUIKotlin.instance
                      .setLightSystemUI(transparent: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
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
                    backgroundColor: Colors.black,
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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

  Future<void> _toggleEdgeToEdge() async {
    final plugin = EdgeToEdgeSystemUIKotlin.instance;

    if (plugin.isEdgeToEdgeEnabled) {
      await plugin.disableEdgeToEdge();
    } else {
      await plugin.enableEdge