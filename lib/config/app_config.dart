class AppConfig {
  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.emailRedirectUrl,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String emailRedirectUrl;

  static const String supabaseUrlKey = 'SUPABASE_URL';
  static const String supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';
  static const String supabaseEmailRedirectKey = 'SUPABASE_EMAIL_REDIRECT_URL';

  factory AppConfig.fromEnvironment() {
    const supabaseUrl = String.fromEnvironment(
      supabaseUrlKey,
      defaultValue: '',
    );
    const supabaseAnonKey = String.fromEnvironment(
      supabaseAnonKeyKey,
      defaultValue: '',
    );
    const redirectOverride = String.fromEnvironment(
      supabaseEmailRedirectKey,
      defaultValue: '',
    );

    if (supabaseUrl.isEmpty) {
      throw StateError(
        'Missing $supabaseUrlKey. Pass it via --dart-define.',
      );
    }

    if (supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing $supabaseAnonKeyKey. Pass it via --dart-define.',
      );
    }

    final redirectUrl = redirectOverride.isNotEmpty
        ? redirectOverride
        : '$supabaseUrl/auth/v1/callback';

    return AppConfig(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      emailRedirectUrl: redirectUrl,
    );
  }
}
