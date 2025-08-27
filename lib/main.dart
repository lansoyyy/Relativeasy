import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:relativeasy/firebase_options.dart';
import 'package:relativeasy/screens/login_screen.dart'; // Changed to login_screen
import 'package:relativeasy/utils/colors.dart';
import 'package:relativeasy/providers/app_state_provider.dart';
import 'package:relativeasy/services/auth_service.dart'; // Added auth service import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthService.instance.initialize(); // Initialize auth service
  await Firebase.initializeApp(
    name: 'relativeasy',
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        home: const LoginScreen(), // Changed from SplashScreen to LoginScreen
      ),
    );
  }
}
