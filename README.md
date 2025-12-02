# Elo Flutter App

A modern Flutter application that pairs Supabase Auth/Realtime with a Material 3 Dark Luxury experience. The MVP focuses on the "The Vault" dashboard plus the Bens, Documentos, Legado, Diretivas e Emergência journeys described in the PRD.

## Features

- Supabase authentication with session-aware routing and logout flows
- Dashboard "The Vault" featuring checklist FLX-01, KPI telemetry, pillar cards, and timeline actions
- Real-time synchronization plus trust/audit event logging
- Material 3 Dark Luxury theme with accessibility-friendly tokens
- Provider-based controllers (e.g., `DashboardController`) orchestrating Supabase queries and telemetry
- Local storage + HTTP FX service for cached currency conversion when summarising assets

## Prerequisites

- Flutter SDK 3.0.0+
- Dart 3.0.0+
- Active Supabase project (URL + anon key)

## Setup Instructions

1. **Configure Supabase**

   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the App**

   ```bash
   flutter run
   ```

4. **Run Dashboard Tests**

   ```bash
   flutter test test/screens/dashboard/dashboard_screen_test.dart
   ```

## Project Structure

```text
lib/
  main.dart                       # App entry point + routing guard
  screens/
    login_screen.dart            # Auth UI
    dashboard/
      dashboard_screen.dart      # The Vault UI & widgets
      dashboard_controller.dart  # Provider/controller + telemetry helpers
      dashboard_repository.dart  # Supabase data access layer
    settings/security_settings_screen.dart
    common/coming_soon_screen.dart
  services/
    auth_service.dart
    fx_service.dart
  theme/app_theme.dart            # Dark Luxury tokens + extensions
```

## Configuration

- Keep Supabase keys outside the repo (`.env` or `--dart-define`).
- Reference `docs/04-guides/setup-ambiente.md` for environment specifics and PRD links.

## Development

- Lint: `flutter analyze`
- Format: `dart format .`
- Tests: `flutter test` (or specific suites as above)
- When adding Supabase tables/policies, align with `docs/05-prompts` and the data-model prompt.

## Deployment

- Android: `flutter build apk` / `flutter build appbundle`
- iOS: `flutter build ios`
- Web/Desktop: `flutter build web` / `flutter build windows` (as needed)

## License

MIT License
