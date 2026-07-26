import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/ble_service.dart';
import 'screens/dashboard_screen.dart';
import 'services/mode_service.dart';
import 'services/reports_service.dart';
import 'services/theme_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleService()),
        ChangeNotifierProvider(create: (_) => ReportsService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => ModeService()),
      ],
      child: const AquaMaxApp(), // ✅ تم التعديل
    ),
  );
}

class AquaMaxApp extends StatelessWidget {
  const AquaMaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ بنراقب الـ ThemeService عشان لما يتغير الـ theme يعمل rebuild للتطبيق كله
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      title: 'AquaMax', // ✅ تم التعديل
      debugShowCheckedModeBanner: false,
      themeMode: themeService.themeMode, // ✅ يتحكم في light/dark/system
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(), // ✅ الـ dark theme الكامل
      home: const DashboardScreen(),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF185FA5),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF4F7F6),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.black87, fontSize: 14),
        labelLarge: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
      ).apply(bodyColor: Colors.black87, displayColor: Colors.black),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF185FA5),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      cardColor: const Color(0xFF161B22),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.white70, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white60, fontSize: 14),
        labelLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      ).apply(bodyColor: Colors.white70, displayColor: Colors.white),
    );
  }
}