import 'package:flutter/material.dart';
import 'package:edge_to_edge_system_ui/edge_to_edge_system_ui.dart';
import 'debug_info_page.dart';

// DebugInfoPage2 extracted to its own file
class DebugInfoPage2 extends StatefulWidget {
  const DebugInfoPage2({super.key});

  @override
  State<DebugInfoPage2> createState() => _DebugInfoPage2State();
}

class _DebugInfoPage2State extends State<DebugInfoPage2> {
  SystemInfo? _info;
  bool? _pluginIsEnabled;
  bool? _pluginIsSupported;
  bool? _pluginIsEnforced;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final brightness = Theme.of(context).brightness;
      if (brightness == Brightness.light) {
        // Light mode: status red, nav orange
        await EdgeToEdgeSystemUIKotlin.instance.pushStyleForRoute(
          context,
          statusBarColor: Colors.red,
          navigationBarColor: Colors.orange,
        );
      } else {
        // Dark mode: status blue, nav purple
        await EdgeToEdgeSystemUIKotlin.instance.pushStyleForRoute(
          context,
          statusBarColor: Colors.blue,
          navigationBarColor: Colors.purple,
        );
      }

      _loadDebugInfo();
    });
  }

  @override
  void dispose() {
    // Plugin restores previous styles when route is popped.
    super.dispose();
  }

  Future<void> _loadDebugInfo() async {
    try {
      final plugin = EdgeToEdgeSystemUIKotlin.instance;
      final info = await plugin.getSystemInfo();
      setState(() {
        _info = info;
        _pluginIsEnabled = plugin.isEdgeToEdgeEnabled;
        _pluginIsSupported = plugin.isEdgeToEdgeSupported;
        _pluginIsEnforced = plugin.isEdgeToEdgeEnforcedBySystem;
      });
    } catch (e) {
      debugPrint('DebugInfoPage2._loadDebugInfo error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Info 2')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug information (page 2)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Plugin: isEnabled=${_pluginIsEnabled ?? 'loading...'}, isSupported=${_pluginIsSupported ?? 'loading...'}, isEnforced=${_pluginIsEnforced ?? 'loading...'}',
            ),
            const SizedBox(height: 8),
            if (_info != null) ...[
              Text('Android API: ${_info!.androidVersion ?? 'unknown'}'),
              Text('Android Release: ${_info!.androidRelease ?? 'unknown'}'),
              Text('Edge-to-Edge Supported: ${_info!.isEdgeToEdgeSupported}'),
              Text(
                'Edge-to-Edge Enabled (info): ${_info!.isEdgeToEdgeEnabled}',
              ),
            ] else ...[
              const Text('SystemInfo: loading...'),
            ],
            const SizedBox(height: 12),
            Wrap(
              children: [
                ElevatedButton.icon(
                  onPressed: _loadDebugInfo,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DebugInfoPage()),
                    );
                  },
                  icon: const Icon(Icons.navigate_before),
                  label: const Text('Open Debug Info 1'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _info != null
                      ? _info!.toMap().toString()
                      : 'No system info loaded.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
