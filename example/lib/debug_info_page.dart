import 'package:flutter/material.dart';
import 'package:edge_to_edge_system_ui/edge_to_edge_system_ui.dart';
import 'debug_info_page2.dart';

class DebugInfoPage extends StatefulWidget {
  const DebugInfoPage({super.key});

  @override
  State<DebugInfoPage> createState() => _DebugInfoPageState();
}

class _DebugInfoPageState extends State<DebugInfoPage> {
  SystemInfo? _info;
  bool? _pluginIsEnabled;
  bool? _pluginIsSupported;
  bool? _pluginIsEnforced;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await EdgeToEdgeSystemUIKotlin.instance.pushStyleForRoute(
        context,
        statusBarColor: Colors.orange,
        navigationBarColor: Colors.red,
      );
      _loadDebugInfo();
    });
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
      debugPrint('DebugInfoPage._loadDebugInfo error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug information',
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
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadDebugInfo,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DebugInfoPage2()),
                    );
                  },
                  icon: const Icon(Icons.navigate_next),
                  label: const Text('Open Debug Info 2'),
                ),
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
