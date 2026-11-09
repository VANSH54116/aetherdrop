import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'models/user_profile.dart';
import 'services/auth_service.dart';
import 'services/signaling_service.dart';
import 'ui/screens/home_radar_screen.dart';
import 'ui/screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop window initialization (macOS, Windows, Linux)
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    try {
      await windowManager.ensureInitialized();
      const WindowOptions windowOptions = WindowOptions(
        size: Size(1180, 820),
        minimumSize: Size(860, 640),
        center: true,
        title: AppConstants.appName,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (e) {
      debugPrint('WindowManager initialization ignored: $e');
    }
  }

  // Initialize authentication service and inspect existing session/cache
  await AuthService.instance.initialize();

  // If user is already authenticated, connect signaling mesh
  if (AuthService.instance.isAuthenticated) {
    SignalingService.instance.connect();
  }

  runApp(const AetherDropApp());
}

/// Root application widget wired with [ThemeProvider] and [AuthService].
class AetherDropApp extends StatefulWidget {
  const AetherDropApp({super.key});

  @override
  State<AetherDropApp> createState() => _AetherDropAppState();
}

class _AetherDropAppState extends State<AetherDropApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        _themeProvider,
        AuthService.instance,
      ]),
      builder: (BuildContext context, _) {
        final bool isAuthenticated = AuthService.instance.isAuthenticated;

        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AetherDropTheme.lightTheme,
          darkTheme: AetherDropTheme.darkTheme,
          themeMode: _themeProvider.themeMode,
          home: isAuthenticated
              ? HomeRadarScreen(themeProvider: _themeProvider)
              : OnboardingScreen(
                  onOnboardingComplete: (UserProfile profile) async {
                    await SignalingService.instance.connect();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
        );
      },
    );
  }
}
