# Downloads Dart Integration Map

This records how each Dart file found in `/home/uhtceare-daren/Downloads` was
handled during integration into `BPED-App`.

## Integrated As New App Features

- `admin_dashboard.dart`
  Integrated as [lib/screens/admin_dashboard.dart](/home/uhtceare-daren/Flutter_App/BPED-App/lib/screens/admin_dashboard.dart)
  and adapted to the live `ClassModel`, `AppUser`, and Riverpod providers.
- `admin_provider.dart`
  Integrated as [lib/providers/admin_provider.dart](/home/uhtceare-daren/Flutter_App/BPED-App/lib/providers/admin_provider.dart).
- `soft_delete_service.dart`
  Integrated as [lib/services/soft_delete_service.dart](/home/uhtceare-daren/Flutter_App/BPED-App/lib/services/soft_delete_service.dart).

## Integrated Into Existing App Flow

- `main.dart`
  Merged into [lib/main.dart](/home/uhtceare-daren/Flutter_App/BPED-App/lib/main.dart) for admin role routing.
- `task_screen.dart`
  Soft-delete flow merged into [lib/screens/task_screen.dart](/home/uhtceare-daren/Flutter_App/BPED-App/lib/screens/task_screen.dart).
- `lesson_screen.dart`
  Soft-delete flow merged into [lib/screens/lesson_screen.dart](/home/uhtceare-daren/Flutter_App/BPED-App/lib/screens/lesson_screen.dart).
- `reviewer_screen.dart`
  Soft-delete support merged into [lib/screens/reviewer_screen.dart](/home/uhtceare-daren/Flutter_App/BPED-App/lib/screens/reviewer_screen.dart).
- `download_button.dart`
  Improved offline UX merged into [lib/widgets/download_button.dart](/home/uhtceare-daren/Flutter_App/BPED-App/lib/widgets/download_button.dart).
- `task_repository.dart`
  Missing task fields and soft-delete-aware filtering merged into [lib/repositories/task_repository.dart](/home/uhtceare-daren/Flutter_App/BPED-App/lib/repositories/task_repository.dart).
- `lesson_repository.dart`
  Soft-delete-aware filtering and deduplicated create flow merged into [lib/repositories/lesson_repository.dart](/home/uhtceare-daren/Flutter_App/BPED-App/lib/repositories/lesson_repository.dart).
- `reviewer_repository.dart`
  Soft-delete-aware filtering merged into [lib/repositories/reviewer_repository.dart](/home/uhtceare-daren/Flutter_App/BPED-App/lib/repositories/reviewer_repository.dart).
- `submission_provider.dart`
  Ordering changes were reviewed; the live file already contains the useful `submittedAt` ordering.
- `tasklist_screen.dart`
  Direct Firestore task stream updated to exclude soft-deleted tasks.

## Already Covered By Existing Or Better Local Code

- `app_colors.dart`
- `create_question_screen.dart`
- `instructor_dashboard.dart`
- `login_screen.dart`
- `student_dashboard.dart`
- `submission_screen.dart`

These files already had corresponding app files in `BPED-App`. They were not
copied over wholesale because the local versions had diverged and were already
wired into the running app.

## Intentionally Not Imported Verbatim

- `login_screen_fix.dart`
  This was a patch note, not a complete source file. Its core intent was already
  satisfied by the current login flow.
- `soft_delete_service(1).dart`
  Exact duplicate of `soft_delete_service.dart`.

## Follow-Up Candidates

- Compare the remaining `Downloads` duplicates against the active app one by one
  if you want a second merge pass for UI differences, not just missing features.
- Add targeted tests for admin user creation and soft-delete/restore behavior.
