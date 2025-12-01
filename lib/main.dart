import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hqitwoutbiasulgaxpoa.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxaXR3b3V0Ymlhc3VsZ2F4cG9hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ1NTI4MTIsImV4cCI6MjA4MDEyODgxMn0.pWVKcGK1v_ZPOOdK2YFN42AFCf-RpLZ-fxPOaNjgvXY',
  );

  runApp(const EloApp());
}

class EloApp extends StatelessWidget {
  const EloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elo',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    final session = Supabase.instance.client.auth.currentSession;
    return session != null ? const HomeScreen() : const LoginScreen();
  }
}
