import 'package:digital_family_vault/core/notifications/notification_service.dart';
import 'package:digital_family_vault/features/onboarding/presentation/onboarding_screen.dart';
import 'package:digital_family_vault/features/settings/presentation/settings_provider.dart';
import 'package:digital_family_vault/features/home/presentation/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_family_vault/theme/app_theme.dart';
import 'package:digital_family_vault/features/auth/presentation/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService().init();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  bool _isLocked = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock the app when it goes to the background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final settings = ref.read(settingsNotifierProvider).value;
      // Only lock if biometric is enabled. Default to locking if settings not loaded yet.
      if (settings?.isBiometricEnabled ?? true) {
        if (mounted) {
          setState(() {
            _isLocked = true;
          });
        }
      }
    }
  }

  void _unlock() {
    if (mounted) {
      setState(() {
        _isLocked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    // This is a bit of a workaround to get the theme mode before the full settings object is loaded
    // It avoids a flash of the wrong theme.
    final isDarkMode = ref.watch(settingsNotifierProvider.select((s) => s.value?.isDarkMode ?? false));

    return MaterialApp(
      title: 'Digital Family Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: settingsAsync.when(
        data: (settings) => _getHome(settings),
        // A branded loading screen that feels more integrated.
        loading: () => const VaultInitializingScreen(),
        error: (e, st) => Scaffold(
          body: Center(child: Text('Initialization Error: $e')),
        ),
      ),
    );
  }

  Widget _getHome(dynamic settings) {
    if (settings.isFirstRun) {
      return const OnboardingScreen();
    }
    
    // If biometrics are on and the app is locked, show the LockScreen
    if (settings.isBiometricEnabled && _isLocked) {
      return LockScreen(onAuthenticated: _unlock);
    }
    
    // Otherwise, show the main content.
    return const MainScreen();
  }
}

// A loading screen that feels like part of the app
class VaultInitializingScreen extends StatelessWidget {
  const VaultInitializingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.security_rounded, size: 64, color: Colors.deepPurple),
            SizedBox(height: 24),
            Text(
              'Digital Family Vault',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Securing your vault...'),
          ],
        ),
      ),
    );
  }
}
