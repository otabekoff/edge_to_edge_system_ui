// File: edge_test/lib/main.dart - Testing the plugin in another project file
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:edge_to_edge_system_ui/edge_to_edge_system_ui.dart';
import 'home_page.dart';
import 'app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Kotlin plugin
  final plugin = EdgeToEdgeSystemUIKotlin.instance;
  await plugin.initialize();

  final info = await EdgeToEdgeSystemUIKotlin.instance.getSystemInfo();
  debugPrint('Plugin SystemInfo: ${info.toMap()}');

  // To get rid of external screen mirroring tool exceptions from output
  // FlutterError and PlatformDispatchers are not required
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains("PointerAddedEvent")) {
      // Ignore MouseTracker assertion
      return;
    }
    FlutterError.presentError(details);
  };

  // Catch async / platform / gesture errors
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (error.toString().contains("PointerAddedEvent")) {
      // Ignore MouseTracker assertion
      return true; // handled
    }
    return false; // let Flutter handle others
  };

  // Run the demo app. Note: the app registers the package-provided
  // `routeObserver` on the MaterialApp (see `navigatorObservers` below).
  // This lets the package attach RouteAware listeners and automatically
  // restore previously-applied system UI styles when routes are popped.
  runApp(const MyKotlinApp());
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
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
          themeMode: mode,
          // Register the package-provided route observer so the plugin can
          // receive push/pop lifecycle events. This single line is required
          // for the plugin's per-route automatic style restoration to work.
          navigatorObservers: [routeObserver],
          // Explicitly avoid auto-enabling edge-to-edge on app startup for
          // Android 14 and below. The package will respect OS-enforced
          // edge-to-edge on Android 15+. Call
          // `EdgeToEdgeSystemUIKotlin.instance.enableEdgeToEdge()` from your
          // app when you want to enable it on older Android releases.
          home: const KotlinSystemUIWrapper(
            enableEdgeToEdge: false,
            enforceContrast: true,
            child: KotlinHomePage(),
          ),
        );
      },
    );
  }
}
