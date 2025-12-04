# Elo Copilot Instructions

These guidelines extend the detailed agent playbook in `./.codex/AGENTS.md`. Always consult that file (and the PRD at `docs/01-product/prd-geral.md`) when planning or reviewing work so every change stays aligned with the MVP pillars (Dashboard, Bens, Documentos, Legado Digital, Diretivas, Emergência).

## Product Snapshot

- **Value prop**: “O elo entre o que você construiu e quem você ama” – a zero-knowledge cofre that protects patrimônio, diretivas e protocolos de emergência.
- **Experience bar**: Material 3 “Dark Luxury” theme, AA accessibility, flows instrumented with KPIs/telemetry.
- **Critical requirements**: Supabase Auth with 2FA/step-up, encrypted storage, RLS everywhere, Provider-driven state.

## Architecture & Key Modules

- **Frontend**: Flutter 3, entry in `lib/main.dart` where `AppConfig` pulls Supabase credentials from `--dart-define` and bootstraps Providers.
- **State**: Provider. Controllers/services live in `lib/screens/<feature>/` and `lib/services/` (e.g., `DashboardController`, `AuthService`, `FxService`).
- **Backend**: Supabase (Postgres, Auth, Storage). Schema defined in `supabase/schema.sql` with enums, tables and RLS policies referenced by the dashboard tests.
- **Design tokens**: `lib/theme/app_theme.dart` implements Dark Luxury palette and extensions.
- **Docs**: Setup/instructions in `README.md`, `SETUP.md`, and `docs/04-guides/setup-ambiente.md`.

### Core Files to Know

- `lib/config/app_config.dart` – centralizes runtime secrets via `String.fromEnvironment`.
- `lib/main.dart` – Supabase init + route guard.
- `lib/screens/login_screen.dart` – Auth UI (cadastro, reset, 2FA prompts).
- `lib/screens/dashboard/*` – The Vault widgets, controller, repository.
- `lib/services/auth_service.dart` – wraps Supabase Auth and redirect flows.
- `supabase/schema.sql` – canonical schema; run in Supabase SQL editor before testing dashboard features.

## Development Guidelines

- **Style**: Idiomatic Dart/Flutter; keep logic outside widgets (controllers/services). Use `const` constructors and guard async code with `if (!mounted) return;` patterns.
- **Strings**: User-facing copy in pt-BR per design system; code/comments/tests in English.
- **Providers**: Register new feature controllers/services via `ChangeNotifierProvider`/`Provider` so widgets stay declarative.
- **Security**: Never hardcode Supabase keys. Enforce RLS, zero-knowledge, and step-up auth for sensitive actions as described in the PRD.
- **Accessibility**: Preserve color contrast, semantics, and tap target sizes; add labels to custom widgets.

### Feature Workflow

1. Define scope with PRD IDs (FR/FLX/KPI) and, if needed, log ADRs under `docs/02-architecture/adr/`.
2. Add screens/components under `lib/screens/<pillar>/` and related services in `lib/services/`.
3. Update schema/policies in `supabase/schema.sql` when new tables are required; document changes in docs.
4. Write/extend tests under `test/screens/<pillar>/` plus shared widgets; mirror lib structure.
5. Run `flutter analyze` + `flutter test` before committing.

## Environment & Commands

- Install deps: `flutter pub get`
- Run app: `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=SUPABASE_EMAIL_REDIRECT_URL=...`
- Analyze: `flutter analyze`
- Format: `dart format .`
- Tests: `flutter test` (or targeted files)
- Build artifacts: `flutter build apk | ios | web | windows`

## Supabase Checklist

- Execute `supabase/schema.sql` to create enums, tables, and policies.
- Seed `profiles` rows for each `auth.users` entry (or enable the optional trigger at the end of the script).
- Keep secrets out of source control; rely on launch configs or CI secrets.
- Document any new policies or storage buckets in `docs/02-architecture/supabase_schema.md`.

## Review Expectations

- Every change should reference relevant PRD IDs in commits/PR descriptions.
- Provide test evidence (logs, screenshots) for critical flows like FLX-01 checklist, guardião protocol, uploads, etc.
- Watch for regressions in AppConfig usage, Provider wiring, and Supabase session handling.

## Helpful References

- Product PRD: `docs/01-product/prd-geral.md`
- Setup guide: `docs/04-guides/setup-ambiente.md`
- Design system: `docs/03-design/design-system.md`
- Prompt strategies: `docs/05-prompts/`

Follow these instructions together with `AGENTS.md` to keep the Elo experience cohesive, secure, and PRD-compliant.
