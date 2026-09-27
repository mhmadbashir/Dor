# Dor (دور)

Helps households in Jordan follow their weekly rotating water supply ("dor"),
confirm when water actually arrives, and order fairly priced water tankers.

- `app/`: Flutter app (Android, iOS, web). Arabic-first with full RTL, English second.
- `supabase/`: Postgres migrations, RLS policies, seed data, pgTAP tests (Edge Functions come in Phase 2).

## Build status

| Phase | Scope | Status |
|---|---|---|
| 1 | Project setup, phone OTP auth, neighborhood selection (GPS auto-detect + manual), weekly schedule | ✅ Done |
| 2 | Crowd reports, live neighborhood status, push notifications | ⏳ |
| 3 | Tanker ordering, driver mode, live tracking | ⏳ |
| 4 | Admin dashboard (Flutter web) | ⏳ |

## Local development

Prerequisites: Flutter (stable), Docker, and the [Supabase CLI](https://supabase.com/docs/guides/cli).

```bash
# 1. Backend: Postgres + Auth + REST, with migrations and seed data applied
cp supabase/.env.example supabase/.env
supabase start
supabase test db            # RLS / constraint tests

# 2. App
cd app
cp env/local.example.json env/local.json   # paste the PUBLISHABLE_KEY printed by `supabase start`
flutter pub get
flutter test
flutter run --dart-define-from-file=env/local.json
```

On an Android emulator, use `http://10.0.2.2:54321` as `SUPABASE_URL`. On a physical
device, use your machine's LAN IP.

### Test accounts (local only)

Phone OTP codes are fixed in `supabase/config.toml` (`[auth.sms.test_otp]`), so no SMS
provider is needed. The code is always **123456**.

| Phone | Role | Neighborhood |
|---|---|---|
| 0790000001 | Household | Tla' Al-Ali |
| 0790000002 | Household | Khalda |
| 0790000003 | Household | Marka |
| 0790000004, 0790000005 | New users (sign-up flow) | none |
| 0790000101 – 0790000103 | Driver | none |
| 0790000900 | Admin | none |

## Architecture

Feature-first clean architecture. Each feature in `app/lib/features/<name>/` has:

- `domain/`: entities, repository interfaces, pure business logic (unit-tested)
- `data/`: Supabase implementations and row ↔ entity mapping
- `presentation/`: Riverpod providers/controllers and widgets (no business logic)

Cross-cutting code lives in `app/lib/core/` (router, l10n, theme, errors, time).

Key conventions:
- **Strings** live only in `app/lib/core/l10n/app_{ar,en}.arb`. A test enforces that both
  files have the same keys and placeholders.
- **Errors**: repositories throw `Failure(FailureKind)`. Widgets show
  `l10n.errorMessage(error)` and never show raw backend messages.
- **Time**: schedules are in Amman local time. Jordan is on fixed UTC+3 (no DST), see
  `core/time/amman_time.dart`.
- **Weekdays** are ISO (1 = Monday … 7 = Sunday) in both the DB and Dart. The UI shows
  the Jordanian week, Saturday → Friday.
- **Location**: during onboarding the app asks for location permission and suggests the
  nearest served neighborhood (`nearest_neighborhood()` RPC, up to 5 km from a neighborhood
  center). The user confirms it, and the manual picker always stays available. Coordinates
  are never stored.
- **Security**: RLS is enabled on every table. Users can't change their own `role` or
  `phone` (a trigger enforces this).
