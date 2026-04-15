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
3. Update `lib/config/local_config.dart` or pass `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
4. Optionally pass `EMAILJS_SERVICE_ID`, `EMAILJS_TEMPLATE_ID`, and `EMAILJS_PUBLIC_KEY` if enrollment emails should be sent.

## Notes

- Google mobile sign-in uses `google_sign_in` and is initialized in `main.dart`.
- New classes receive a generated invitation code stored as `classCode` in Firestore.
- The checked-in tests focus on app-specific logic instead of the default Flutter counter sample.

- use flutter run --dart-define=DEV_ADMIN_ENABLED=true -d chrome for admin access
