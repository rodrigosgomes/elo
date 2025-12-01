# Elo Flutter Project - Copilot Instructions

## Project Overview
Elo is a Flutter mobile application with Supabase backend integration. The app provides user authentication and real-time data synchronization.

## Architecture
- **Frontend**: Flutter with Material 3 design
- **Backend**: Supabase (PostgreSQL + Auth)
- **State Management**: Provider package
- **Authentication**: Supabase Auth service

## Key Files
- `lib/main.dart` - Application entry point with Supabase initialization
- `lib/services/auth_service.dart` - Authentication service
- `lib/screens/login_screen.dart` - Auth UI
- `lib/screens/home_screen.dart` - Main app screen
- `pubspec.yaml` - Dependencies configuration

## Development Guidelines

### Code Style
- Follow Dart conventions and Flutter best practices
- Use const constructors where possible
- Implement proper error handling
- Add null safety checks

### Adding Features
1. Create new screens in `lib/screens/`
2. Add services in `lib/services/` for backend logic
3. Update `pubspec.yaml` if new packages are needed
4. Test with `flutter run`

### Supabase Configuration
- Update credentials in `lib/main.dart`
- Set up RLS policies for security
- Use `AuthService` for authentication operations

## Build & Run
- Dependencies: `flutter pub get`
- Development: `flutter run`
- Build APK: `flutter build apk`
- Analysis: `flutter analyze`

## Important Notes
- Replace Supabase credentials before deployment
- Implement RLS policies for database security
- Use Provider for state management
- Test on both Android and iOS
