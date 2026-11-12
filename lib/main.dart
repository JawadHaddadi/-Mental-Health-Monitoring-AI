import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'ai/diagnostic_service.dart';

/// Global theme notifier — toggle between light and dark mode from anywhere.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite FFI for Windows, Linux, and macOS desktop.
  // On Android/iOS, sqflite uses native channels and this is not needed.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Pre-initialize the AI model in the background so it's ready
  // when the user opens the chat or journal screen.
  _initializeAIModel();

  runApp(const MentalHealthApp());
}

/// Initializes the ONNX model asynchronously in the background.
/// This is fire-and-forget — the app starts immediately while the
/// model loads. The ChatService and JournalScreen will wait for
/// readiness before running inference.
Future<void> _initializeAIModel() async {
  try {
    final service = MentalHealthDiagnosticService();
    await service.initialize();
    debugPrint('AI model initialized successfully');
  } catch (e) {
    debugPrint('AI model pre-initialization failed (will retry on use): $e');
  }
}

class MentalHealthApp extends StatelessWidget {
  const MentalHealthApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, _) {
          return MaterialApp(
            title: 'Mental Health App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: currentMode,
            
            // RTL / Arabic Support 
            /// This sets up localization (Arabic supported with RTL layout),
            /// but the app currently uses English only.
            /// Default language is English (en).
            /// Do not remove — some Material components may depend on it.
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), 
              Locale('ar', ''),
            ],
            // Switch to ar for Arabic layout testing: locale: const Locale('ar', ''),

            home: Consumer<AuthProvider>(
              builder: (context, auth, child) {
                if (auth.isLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
  