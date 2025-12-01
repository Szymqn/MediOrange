import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';

class AppColors {
  static const Color primary = Color(0xFFFF992B);
  static const Color userMessage = Color(0xFFFF992B);
  static const Color inputBackground = Color(0xFFF5F5F5);
  static const Color sendButton = Color(0xFFFF992B);
  static const Color textOnPrimary = Colors.white;
}

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediOrange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary, // MediOrange
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI', // Good default for Windows, system font usually better
      ),
      home: const MedAssistHomePage(),
    );
  }
}

