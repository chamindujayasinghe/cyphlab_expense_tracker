# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Expense Tracker app (Flutter + Firebase) built as a practical task for CyphLab. `project-scope.md` holds the requirements checklist, data model, optional features and submission deliverables. Read it before planning features, and tick items off there as they are completed.

The brief asks for a simple app: judge scope against `project-scope.md` and don't add unrequested complexity. The README must eventually list setup steps, features, packages used, and AI tools used (a submission requirement).

## Architecture

`project-plan.md` lists the build phases. Layers, top to bottom:

- **Screens / widgets** (`lib/screens`, `lib/widgets`) talk only to providers, never to Firebase. `AuthGate` (the app's home route) shows a splash, `LoginScreen` or `HomeScreen` depending on `AuthProvider`.
- **Providers** (`lib/providers`, `ChangeNotifier` + `provider`) hold state and expose actions that return `Future<String?>`: null on success, else a user-facing error message. Screens show that message in a SnackBar; they don't catch exceptions.
- **Services** (`lib/services`) are abstract interfaces (`AuthService`, `ExpenseRepository`) with Firebase implementations. They throw `AuthException` / `ExpenseRepositoryException` carrying friendly messages mapped from Firebase error codes.

Wiring is in `lib/main.dart`: `ExpenseProvider` is a `ChangeNotifierProxyProvider` of `AuthProvider`, and `updateUser(uid)` starts or stops the Firestore subscription on sign-in and sign-out. `updateUser` runs during build, so it must not call `notifyListeners` synchronously. `lib/app.dart` holds `MaterialApp` without providers, so tests can pump it with fakes.

Data flow: `ExpenseProvider` streams one month at a time (`watchExpenses` with a date range, ordered by date, which needs no composite index). The total and any filtering are computed client-side. `deleteExpense` removes the item optimistically (required by `Dismissible`), and undo uses `restoreExpense`, which re-adds with the same id. Repository writes time out after 10s and are treated as queued, because Firestore only resolves writes on server acknowledgement.

Firestore: `users/{uid}/expenses/{id}` holds `title, amount, category (enum name), date, note?, createdAt, updatedAt`. The timestamps are server timestamps added by the repository, not by `Expense.toMap`. `firestore.rules` enforces owner-only access and mirrors `lib/utils/validators.dart` and `AppConstants` limits. Change both sides together, then deploy with `firebase deploy --only firestore:rules`.

Tests use fakes in `test/fakes/` (`FakeAuthService`, `FakeExpenseRepository`), and never touch Firebase.

## Firebase setup

Project `cyphlabs-expense-tracker` (default in `.firebaserc`), configured with `flutterfire configure` for android, web and windows (Windows uses a web app config). The generated files are `lib/firebase_options.dart`, `android/app/google-services.json` and the `flutter` block in `firebase.json`. Re-run `flutterfire configure` rather than hand-editing them. The `flutterfire` executable is at `%LOCALAPPDATA%\Pub\Cache\bin\flutterfire.bat`, which may not be on PATH. Auth is email/password only.

## Commands

```
flutter pub get                       # install dependencies
flutter run -d windows                # or -d chrome, or an Android device/emulator id (see `flutter devices`)
flutter analyze                       # lint (flutter_lints via analysis_options.yaml)
dart format .                         # format
flutter test                          # all tests
flutter test test/widget_test.dart    # single file
flutter test --plain-name "<name>"    # single test by name
flutter build apk --release           # release APK (a deliverable)
```

## Environment notes (Windows)

- Dart SDK constraint is `^3.13.4` (Flutter 3.47.5 stable).
- Flutter lives at `C:\src\flutter`, owned by Administrators; it is registered in git `safe.directory`, which it needs to run.
- Android SDK: `%LOCALAPPDATA%\Android\sdk`. `sdkmanager.bat` is deprecated and forwards to the new Android CLI, but loses semicolons in package ids. Install packages with `cmdline-tools\latest\bin\android.exe sdk install "platforms;android-36"` instead. That tool may exit with a crash code after a successful install; verify by checking the files or running `flutter doctor`.
