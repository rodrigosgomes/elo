# Flutter Elo App - Development Setup Checklist

## Project Configuration

- [x] Supabase backend with Auth + RLS policies
- [x] `AppConfig` wired to `--dart-define` for secrets management
- [x] Authentication flows (login, cadastro, reset, logout)
- [x] Dashboard module (`DashboardController`, repository, widgets)
- [x] Widget/integration tests for login and dashboard

## Dependencies Installed

- `supabase_flutter` - Backend integration
- `provider` - State management
- `shared_preferences` - Local storage
- `intl` - Internationalization support

## Next Steps

1. **Configure Supabase Credentials**

   Do **not** edit `lib/main.dart`. Pass credentials via `--dart-define` so `AppConfig` can read them at runtime:

   ```bash
   flutter run \
       --dart-define=SUPABASE_URL=https://xyzcompany.supabase.co \
       --dart-define=SUPABASE_ANON_KEY=your-anon-key \
       --dart-define=SUPABASE_EMAIL_REDIRECT_URL=https://xyzcompany.supabase.co/auth/v1/callback
   ```

   The VS Code launch profile (`.vscode/launch.json`) is already prefilled for local dev.

2. **Install Flutter Dependencies**

   ```bash
   flutter pub get
   ```

3. **Bootstrap Supabase Schema**

   - Open `supabase/schema.sql` in the Supabase SQL editor and run it to create tables, enums, and RLS policies used by the dashboard.
   - Seed at least one row in `profiles` (matching an auth user) or add the optional trigger at the bottom of the script.

4. **Run the Application**

   ```bash
   flutter run
   ```

5. **Execute the Test Suite**

   ```bash
   flutter test
   ```

## File Structure

```text
Elo/
 lib/
    config/app_config.dart
    main.dart
    screens/
       login_screen.dart
       home_screen.dart
       dashboard/
          dashboard_screen.dart
          dashboard_controller.dart
          dashboard_repository.dart
       settings/security_settings_screen.dart
    services/
       auth_service.dart
       fx_service.dart
    theme/app_theme.dart
 supabase/
    schema.sql
 .vscode/
    launch.json
    tasks.json
    extensions.json
 docs/
    04-guides/setup-ambiente.md
 test/
    screens/
       login/login_screen_test.dart
       dashboard/dashboard_screen_test.dart
    widget_test.dart
```

## Useful Commands

- `flutter pub get` - Install dependencies
- `flutter run` - Run the app
- `flutter analyze` - Check code quality
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
