# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Expense Tracker app (Flutter + Firebase) built as a practical task for CyphLab. `project-scope.md` holds the requirements checklist, data model, optional features and submission deliverables. Read it before planning features, and tick items off there as they are completed.

The brief asks for a simple app: judge scope against `project-scope.md` and don't add unrequested complexity. The README must eventually list setup steps, features, packages used, and AI tools used (a submission requirement).

## Current state

Freshly generated with `flutter create` (org `com.cyphlab`). `lib/main.dart` initializes Firebase, then still shows the default counter demo; `test/widget_test.dart` is the default test. Update this file once the app architecture is in place.

Firebase: project `cyphlabs-expense-tracker`, configured with `flutterfire configure` for android, web and windows (Windows uses a web app config). Generated files are `lib/firebase_options.dart`, `android/app/google-services.json` and `firebase.json`. Re-run `flutterfire configure` rather than hand-editing them. The `flutterfire` executable is at `%LOCALAPPDATA%\Pub\Cache\bin\flutterfire.bat`, which may not be on PATH. Packages: `firebase_core`, `cloud_firestore`.

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
