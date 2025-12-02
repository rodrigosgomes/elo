import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'screens/common/coming_soon_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings/security_settings_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appConfig = AppConfig.fromEnvironment();

  await Supabase.initialize(
    url: appConfig.supabaseUrl,
    anonKey: appConfig.supabaseAnonKey,
  );

  runApp(EloApp(config: appConfig));
}

class EloApp extends StatelessWidget {
  const EloApp({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        Provider<AuthService>(create: (_) => AuthService(config: config)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Elo',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        initialRoute: '/',
        routes: {
          '/': (context) => const _RootRouter(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/settings/security': (context) => const SecuritySettingsScreen(),
          '/bens/novo': (context) => const ComingSoonScreen(
                title: 'Cadastro de Bens',
                description:
                    'Implemente o fluxo FR-BEN-01 para registrar bens com comprovantes e auditoria.',
                requirementId: 'FR-BEN-01',
              ),
          '/documentos': (context) => const ComingSoonScreen(
                title: 'Cofre de Documentos',
                description:
                    'Fluxos FR-DOC-01..05 serão conectados aqui mantendo uploads resilientes.',
                requirementId: 'FR-DOC-01',
              ),
          '/legado': (context) => const ComingSoonScreen(
                title: 'Legado Digital',
                description:
                    'Administre contas e credenciais mestras conforme FR-LEG-01..04.',
                requirementId: 'FR-LEG-01',
              ),
          '/diretivas': (context) => const ComingSoonScreen(
                title: 'Diretivas',
                description:
                    'Centralize Testamento Vital, Funeral e Cápsulas do Tempo (FR-DIR-01..04).',
                requirementId: 'FR-DIR-01',
              ),
          '/guardioes/novo': (context) => const ComingSoonScreen(
                title: 'Novo Guardião',
                description:
                    'Fluxo FR-EME-02 permitirá convites, step-up e auditoria de guardiões.',
                requirementId: 'FR-EME-02',
              ),
        },
      ),
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final session = Supabase.instance.client.auth.currentSession;
      if (!mounted) return;
      if (session == null) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF121212),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
