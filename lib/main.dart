import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:relativeasy/screens/main_screen.dart';
import 'package:relativeasy/utils/colors.dart';
import 'package:relativeasy/providers/app_state_provider.dart';

void main() {
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
        home: const MainScreen(),
      ),
    );
  }
}
