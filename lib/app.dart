import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/firebase_setup_screen.dart';
import 'screens/task_home_page.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';

class DailyTasksApp extends StatefulWidget {
  const DailyTasksApp({super.key});

  @override
  State<DailyTasksApp> createState() => _DailyTasksAppState();
}

class _DailyTasksAppState extends State<DailyTasksApp> {
  late final AuthService _authService = AuthService();
  late final Future<void> _appInitialization = _initializeApp();

  Future<void> _initializeApp() {
    if (kIsWeb) {
      return Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    return Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF2F6B45);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Tasks',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F1E8),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          scrolledUnderElevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
        ),
      ),
      home: FutureBuilder<void>(
        future: _appInitialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _AppLoadingScreen();
          }

          if (snapshot.hasError) {
            return FirebaseSetupScreen(errorMessage: snapshot.error.toString());
          }

          return StreamBuilder<User?>(
            stream: _authService.authStateChanges(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const _AppLoadingScreen();
              }

              final user = authSnapshot.data;
              if (user == null) {
                return AuthScreen(authService: _authService);
              }

              final taskService = FirebaseTaskService(userId: user.uid);
              return TaskHomePage(
                taskService: taskService,
                currentUser: user,
                onSignOut: _authService.signOut,
              );
            },
          );
        },
      ),
    );
  }
}

class _AppLoadingScreen extends StatelessWidget {
  const _AppLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4EDE0), Color(0xFFE6F0E4), Color(0xFFD7E3D4)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(strokeWidth: 4),
              ),
              SizedBox(height: 18),
              Text(
                'Preparing your daily planner...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
