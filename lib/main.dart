import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:relativeasy/screens/splash_screen.dart';
import 'package:relativeasy/screens/login_screen.dart';
import 'package:relativeasy/screens/signup_screen.dart';
import 'package:relativeasy/screens/main_screen.dart';
import 'package:relativeasy/utils/colors.dart';
import 'package:relativeasy/providers/app_state_provider.dart';
import 'package:relativeasy/services/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    name: 'relativeasy',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: MaterialApp(
        title: 'Relativeasy - Master Special Relativity',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(
            primary: accent,
            secondary: secondary,
            surface: surface,
            background: background,
            onPrimary: textOnPrimary,
            onSecondary: textOnAccent,
            onSurface: textPrimary,
            onBackground: textPrimary,
          ),
          scaffoldBackgroundColor: background,
          appBarTheme: const AppBarTheme(
            backgroundColor: primary,
            foregroundColor: textPrimary,
            elevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: surface,
            selectedItemColor: accent,
            unselectedItemColor: textSecondary,
            type: BottomNavigationBarType.fixed,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: textOnAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          cardTheme: CardTheme(
            color: surface,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          fontFamily: 'Regular',
          useMaterial3: true,
        ),
        home: const AuthWrapper(), // Use AuthWrapper to handle auto-login
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}

// Wrapper widget to handle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // If user is authenticated, show main screen
        if (snapshot.hasData) {
          return const MainScreen();
        }

        // If not authenticated, show login screen
        return const LoginScreen();
      },
    );
  }
}
