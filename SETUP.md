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

   - Update your Supabase URL and Anon Key in `lib/main.dart`.
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
