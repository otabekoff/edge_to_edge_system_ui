import 'package:flutter/material.dart';
import 'package:edge_to_edge_system_ui/edge_to_edge_system_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EdgeToEdgeSystemUIKotlin.instance.initialize();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edge-to-Edge Plugin Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Edge-to-Edge Example')),
        body: const Center(child: ExampleBody()),
      ),
    );
  }
}

class ExampleBody extends StatefulWidget {
  const ExampleBody({super.key});

  @override
  State<ExampleBody> createState() => _ExampleBodyState();
}

class _ExampleBodyState extends State<ExampleBody> {
  SystemInfo? _info;

  Future<void> _refresh() async {
    final info = await EdgeToEdgeSystemUIKotlin.instance.getSystemInfo();
    setState(() {
      _info = info;
    });
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(onPressed: _refresh, child: const Text('Refresh')),
        const SizedBox(height: 12),
        if (_info != null) ...[
          Text('Edge-to-Edge: ${_info!.isEdgeToEdgeEnabled}'),
          Text('Nav height: ${_info!.navigationBarsHeight} dp'),
        ] else ...[
          const Text('Loading...')
        ]
      ],
    );
  }
}
