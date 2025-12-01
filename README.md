# Elo Flutter App

A modern Flutter mobile application with Supabase backend integration for real-time data and authentication.

## Features

- User authentication (Sign In / Sign Up) via Supabase
- Real-time database synchronization
- Material 3 design with dark mode support
- State management with Provider
- Local storage support

## Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart 3.0.0 or higher
- Active Supabase project

## Setup Instructions

### 1. Configure Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Get your project URL and Anon Key from the project settings
3. Update `lib/main.dart` with your credentials:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart              # App entry point
├── screens/
│   ├── login_screen.dart  # Authentication UI
│   └── home_screen.dart   # Home page
└── services/
    └── auth_service.dart  # Supabase authentication service
```

## Configuration

### Environment Variables

Create a `.env` file for sensitive configuration (not included in version control):

```
SUPABASE_URL=your_url_here
SUPABASE_ANON_KEY=your_key_here
```

## Development

- Use `flutter analyze` for linting
- Use `flutter test` for unit tests
- Use `flutter pub upgrade` to update dependencies

## Deployment

- For iOS: `flutter build ios`
- For Android: `flutter build apk` or `flutter build appbundle`
- For Web: `flutter build web`

## License

MIT License
