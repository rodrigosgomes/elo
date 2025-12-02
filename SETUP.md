# Flutter Elo App - Development Setup Checklist

## Project Configuration

- [x] Supabase backend integrated
- [x] Flutter `pubspec.yaml` configured with dependencies
- [x] Authentication service implemented
- [x] Login and Home screens created

## Dependencies Installed

- `supabase_flutter` - Backend integration
- `provider` - State management
- `shared_preferences` - Local storage
- `intl` - Internationalization support

## Next Steps

1. **Configure Supabase Credentials**

   - Do **not** edit `lib/main.dart`. Instead, pass credentials via `--dart-define` so `AppConfig` can read them at runtime:

     ```bash
     flutter run \
         --dart-define=SUPABASE_URL=https://xyzcompany.supabase.co \
         --dart-define=SUPABASE_ANON_KEY=your-anon-key \
         --dart-define=SUPABASE_EMAIL_REDIRECT_URL=https://xyzcompany.supabase.co/auth/v1/callback
     ```

   - Set up authentication tables in your Supabase project.

2. **Install Flutter Dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the Application**

   ```bash
   flutter run
   ```

4. **Configure Database Schema** (in Supabase Dashboard)

- Set up user profiles table
- Configure Row Level Security (RLS) policies

## File Structure

```text
Elo/
 lib/
    main.dart
    screens/
       login_screen.dart
       home_screen.dart
    services/
        auth_service.dart
 pubspec.yaml
 README.md
 .vscode/
     launch.json
     tasks.json
     extensions.json
```

## Useful Commands

- `flutter pub get` - Install dependencies
- `flutter run` - Run the app
- `flutter analyze` - Check code quality
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
