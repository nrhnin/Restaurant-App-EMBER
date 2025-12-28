import 'package:flutter/material.dart';
import 'Guest Page/welcome_page.dart';
import 'colors.dart';

class EmberApp extends StatelessWidget {
  const EmberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMBER',
      debugShowCheckedModeBanner: false,
      home: const WelcomePage(),

      theme: _buildEmberTheme(),
    );
  }
}

ThemeData _buildEmberTheme() {
  final ThemeData base = ThemeData(
    fontFamily: 'Rubik',
    useMaterial3: true,
    scaffoldBackgroundColor: white,

    // Define the default ColorScheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: black,
      primary: black,
      secondary: black,
      surface: white,
    ),
  );

  return base.copyWith(

    scaffoldBackgroundColor: white,

    appBarTheme: const AppBarTheme(
      backgroundColor: lightGrey,
      foregroundColor: black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),

    // Ensure text is black
    textTheme: _buildEmberTextTheme(base.textTheme),
  );
}

TextTheme _buildEmberTextTheme(TextTheme base) {
  return base.copyWith(
    headlineSmall: base.headlineSmall?.copyWith(
      fontWeight: FontWeight.w500,
      color: black,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
      color: black,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontWeight: FontWeight.w400,
      fontSize: 14.0,
      color: black,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 16.0,
      color: black,
    ),
  ).apply(
    fontFamily: 'Rubik',
    displayColor: black,
    bodyColor: black, // Enforces black text globally
  );
}