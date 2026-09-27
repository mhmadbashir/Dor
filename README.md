# Dor (دور)

Helps households in Jordan follow their weekly rotating water supply ("dor"),
confirm when water actually arrives, and order fairly priced water tankers.

- `app/`: Flutter app (Android, iOS, web). Arabic-first with full RTL, English second.
- `supabase/`: Postgres migrations, RLS policies, seed data, pgTAP tests, and the `send-notifications` Edge Function.

## Build status

| Phase | Scope | Status |
|---|---|---|
| 1 | Project setup, phone OTP auth, neighborhood selection (GPS auto-detect + manual), weekly schedule | ✅ Done |
| 2 | Crowd reports, live status by home elevation, push notifications, Arabic font | ✅ Done |
| 3 | Tanker ordering, driver mode, live tracking | ⏳ |
| 4 | Admin dashboard (Flutter web) | ⏳ |

## Local development

Prerequisites: Flutter (stable), Docker, and the [Supabase CLI](https://supabase.com/docs/guides/cli).

```bash
# 1. Backend: Postgres + Auth + REST, with migrations and seed data applied
cp supabase/.env.example supabase/.env
cp supabase/functions/.env.example supabase/functions/.env
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
| 0790000001 | Household | Tla' Al-Ali (high) |
| 0790000002 | Household | Khalda (low) |
| 0790000003 | Household | Marka |
| 0790000006 / 07 / 08 | Household | Khalda (low / middle / high) |
| 0790000004, 0790000005 | New users (sign-up flow) | none |
| 0790000101 – 0790000103 | Driver | none |
| 0790000900 | Admin | none |

### Trying crowd reports locally

Water shows as "flowing" once 3 neighbors confirm it. Sign in as 0790000008 (Khalda, on a
hill), then have 0790000006 and 0790000007 report "Water arrived" from another browser or
device. The status card updates live. Queued push notifications are processed every
minute. Until Firebase is configured, the `send-notifications` function runs in
**dry-run** mode and logs each push instead (`docker logs supabase_edge_runtime_dor`).

Edge Function tests: `deno test --allow-env supabase/functions/send-notifications/`.

## Water status and home elevation

Water in the rotation reaches low-lying homes first and homes on hills last. Each
household sets where its home sits (low ground / middle / on a hill / not sure). During
onboarding the app can suggest this from GPS altitude, using per-neighborhood thresholds
set by admins. Live status is computed per level:

- Only each user's latest report from the last 12 hours counts, and a user can report once
  every 6 hours per neighborhood.
- A level is **flowing** at ≥ 3 "arrived" reports that also outnumber "no water" reports.
  The threshold is `app_settings.crowd_reports.min_reports`.
- Gravity rules: "arrived" from a higher home also counts for lower homes; "no water" from
  a lower home also counts for higher homes. "Not sure" counts as middle.
- Alerts: "water arrived" goes to homes at the level that just started flowing (not to
  the people who reported it). "Water reached lower homes, yours usually later" goes to
  higher levels that are still dry. Each is sent at most once per 12 hours per level.
- Schedule reminders: at 20:00 the evening before a water day ("water day tomorrow, starts
  at 8:00 AM"), and at the scheduled start time ("your water day starts now, per the
  schedule"). The start reminder skips homes whose level is already confirmed flowing.
  Each notification type has its own switch in Settings.
- Suspicious reports are flagged for admin review, not blocked: a report for a
  neighborhood other than the user's home, a brand-new account, many neighborhoods in a
  day, or contradicting ≥ 80% of 10+ reports at the same level. Admin-rejected reports
  stop counting.

## Push notifications (Firebase) setup

The app runs without Firebase; push just stays off. To turn it on:

1. Create a Firebase project and add an Android app (`jo.dor.dor`) and an iOS app
   (`jo.dor.dor`). The easiest way is `flutterfire configure` from `app/`.
2. Put `google-services.json` in `app/android/app/` and `GoogleService-Info.plist` in
   `app/ios/Runner/` (add it to the Runner target in Xcode).
3. iOS: in Xcode enable **Push Notifications** and **Background Modes → Remote
   notifications**, and upload an APNs key in Firebase → Project settings → Cloud Messaging.
4. Server: create a service account key (Firebase → Project settings → Service accounts),
   then:
   ```bash
   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat service-account.json)" NOTIFY_CRON_SECRET=<random>
   supabase functions deploy send-notifications --no-verify-jwt
   ```
   In the SQL editor:
   ```sql
   select vault.create_secret('https://<project-ref>.supabase.co', 'project_url');
   select vault.create_secret('<same random secret>', 'notify_cron_secret');
   ```

Push text lives in the ARB files (`push*` keys). After editing it, run
`dart run tool/push_strings.dart` in `app/` to regenerate the Edge Function copy; a test
fails if you forget.

## Architecture

Feature-first clean architecture. Each feature in `app/lib/features/<name>/` has:

- `domain/`: entities, repository interfaces, pure business logic (unit-tested)
- `data/`: Supabase implementations and row ↔ entity mapping
- `presentation/`: Riverpod providers/controllers and widgets (no business logic)

Cross-cutting code lives in `app/lib/core/` (router, l10n, theme, errors, time).

Key conventions:
- **Font and digits**: the app bundles Cairo (OFL, `app/assets/fonts/cairo`) and shows
  Western digits in both languages.
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
