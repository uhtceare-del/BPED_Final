# BPED-App

Flutter application for the LNU BPED management workflow. It supports:

- Firebase authentication with email/password and Google sign-in
- Instructor-managed classes, courses, lessons, tasks, reviewers, and submissions
- Student enrollment by six-character class code
- Offline reviewer downloads backed by Hive
- File uploads backed by Supabase storage

## Setup

1. Install Flutter and project dependencies with `flutter pub get`.
2. Provide Firebase platform configuration files for the target platforms.
3. Copy `.env.example` to `.env`.
4. Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env`.
5. Optionally set `ADMIN_EMAIL`, `EMAILJS_SERVICE_ID`, `EMAILJS_TEMPLATE_ID`, and `EMAILJS_PUBLIC_KEY` in `.env`.

## Runtime Config

- The app uses `.env` as the single client configuration source.
- `--dart-define` is no longer used for app runtime configuration.
- `.env` is bundled as a Flutter asset, so create it before `flutter run`, `flutter build`, or Docker/compose builds.

## Notes

- Google mobile sign-in uses `google_sign_in` and is initialized in `main.dart`.
- New classes receive a generated invitation code stored as `classCode` in Firestore.
- The checked-in tests focus on app-specific logic instead of the default Flutter counter sample.

## CI

- GitHub Actions runs automatically on pushes and pull requests targeting `main` and `develop`.
- The workflow runs module-level test suites for `models`, `services`, `config`, `providers`, and `widgets`.
- If the following repository secrets are configured, the workflow also emails a pass/fail summary after push runs:
  - `SMTP_SERVER`
  - `SMTP_PORT`
  - `SMTP_USERNAME`
  - `SMTP_PASSWORD`
  - `CI_EMAIL_TO`
  - `CI_EMAIL_FROM`
