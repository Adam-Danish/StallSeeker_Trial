import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/last_tab.dart';
import 'core/utils/stall_share_link.dart';
import 'features/auth/auth_wrapper.dart';
import 'features/auth/resume_navigation.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'core/widgets/web_page_navigation.dart';
import 'features/customer/vendor_details/shared_stall_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() {
  final initialUri = kIsWeb ? Uri.base : null;
  if (kIsWeb) usePathUrlStrategy();
  return _start(initialUri);
}

Future<void> _start(Uri? initialUri) async {
  WidgetsFlutterBinding.ensureInitialized();

  // The app's background is light (white/cream), so the status bar's
  // time/battery/signal icons need to render dark to stay visible --
  // otherwise they default to light and blend into the light
  // background, becoming nearly invisible. Set globally here so it
  // applies even on screens that override AppBar styling directly.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  try {
    // Initialize before querying apps: the web SDK is loaded by this call.
    // Reading Firebase.apps first relies on browser-specific TypeError text.
    await Future.wait([
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      loadLastTabs(),
    ], eagerError: true);
  } catch (e) {
    debugPrint('StallSeeker startup failed: $e');
    runApp(MaterialApp(
        home: Scaffold(
            body: Center(
                child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text(
            'StallSeeker could not start. Check your connection and retry.'),
        TextButton(
            onPressed: () => _start(initialUri), child: const Text('Retry')),
        ExpansionTile(
          title: const Text('Error details'),
          children: [SelectableText(e.toString())],
        ),
      ]),
    )))));
    return;
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  runApp(StallSeekerApp(initialUri: initialUri));
  unawaited(NotificationService.instance
      .initialize(navigatorKey, initialUri: initialUri)
      .catchError((Object error) {
    debugPrint('Notifications are currently unavailable.');
  }));
}

class StallSeekerApp extends StatelessWidget {
  const StallSeekerApp({super.key, this.initialUri});

  final Uri? initialUri;

  Route<void>? _sharedStallRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '');
    if (uri == null || !isSharedStallPath(uri)) return null;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => SharedStallPage(stallId: sharedStallId(uri)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uri = initialUri;
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [resumeNavigation, if (kIsWeb) webPageNavigation],
      title: 'StallSeeker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
      },
      onGenerateRoute: kIsWeb ? _sharedStallRoute : null,
      onGenerateInitialRoutes:
          uri != null ? (_) => _initialWebRoutes(uri) : null,
    );
  }

  List<Route<dynamic>> _initialWebRoutes(Uri uri) {
    final settings = RouteSettings(name: uri.path.isEmpty ? '/' : uri.path);
    final stall = _sharedStallRoute(settings);
    if (stall != null) return [stall];

    final authPage = switch (uri.path) {
      '/login' => const LoginScreen(),
      '/register' => const RegisterScreen(),
      '/forgot-password' => const ForgotPasswordScreen(),
      _ => null,
    };
    return [
      MaterialPageRoute<void>(
        settings: authPage == null ? settings : const RouteSettings(name: '/'),
        builder: (_) => AuthWrapper(initialUri: uri),
      ),
      if (authPage != null)
        MaterialPageRoute<void>(settings: settings, builder: (_) => authPage),
    ];
  }
}
