# Project Plan — CyphLab Expense Tracker

## Context

CyphLab practical task: build a clean Flutter + Firebase expense tracker (requirements in `project-scope.md`). Setup is done and committed (`09ba75c`): Flutter 3.47.5 scaffold, FlutterFire configured for project `cyphlabs-expense-tracker` (android/web/windows), `firebase_core` + `cloud_firestore` added, Firebase initialized in `lib/main.dart`. `lib/main.dart` still contains the counter demo.

Decisions: **Provider** for state management. Optional features in scope: **Firebase Auth, chart + summary, search, dark mode**. Priority is quality and early submission, so each phase ends in a working, committed app.

## Architecture

```
lib/
  main.dart               # Firebase init, MultiProvider, MaterialApp, AuthGate
  models/                 # Expense (toMap/fromFirestore/copyWith), ExpenseCategory enum (label, icon, color)
  services/               # AuthService (firebase_auth), ExpenseRepository (Firestore CRUD + streams)
  providers/              # AuthProvider, ExpenseProvider (month, filters, derived totals), ThemeProvider
  screens/                # auth/, home/, expense_form/, summary/
  widgets/                # ExpenseTile, MonthSelector, TotalCard, FilterBar, EmptyState, ErrorState
  utils/                  # validators, formatters (currency/date via intl), constants
  theme/                  # light + dark ThemeData (Material 3, seeded color scheme)
```

Data: `users/{uid}/expenses/{expenseId}` with `title, amount, category, date (Timestamp), note?, createdAt, updatedAt`.
Query strategy: Firestore streams the **selected month's** expenses (date range query, ordered by date). Category/search filtering happens client-side in `ExpenseProvider`, so no composite indexes are needed. A custom date range uses the same range query.

New packages: `firebase_auth`, `provider`, `intl`, `fl_chart`, `shared_preferences`.

## Phases

### Phase 1: Foundation
- Add packages; create folder structure; remove counter demo.
- `Expense` model + `ExpenseCategory` enum (Food, Transport, Shopping, Bills, Entertainment, Health, Education, Other).
- Light/dark themes, currency/date formatters (single currency constant, default LKR), form validators.
- **Done when:** app launches to a placeholder home, `flutter analyze` is clean, model unit tests pass.

### Phase 2: Authentication
- **User action:** enable Email/Password sign-in in Firebase Console → Authentication.
- `AuthService` + `AuthProvider`; login and register screens with validation, loading and friendly error messages (mapped `FirebaseAuthException` codes); `AuthGate` switches on `authStateChanges()`; sign-out.
- **Done when:** can register, log in, restart app and stay logged in, log out.

### Phase 3: Data layer + security rules
- `ExpenseRepository`: `watchExpenses(uid, start, end)`, `add`, `update`, `delete`.
- `ExpenseProvider`: selected month, stream subscription, loading/error state, derived total.
- `firestore.rules`: users read/write only `users/{their uid}/**`, with field validation (title non-empty, amount > 0). Register in `firebase.json`, deploy with `firebase deploy --only firestore:rules`.
- **Done when:** rules deployed; data written from the app appears in the console under the user's uid.

### Phase 4: Core UI (all core requirements)
- Home: month selector, total-for-month card, expense list grouped by day.
- Add/edit form (same screen): title, amount, category dropdown, date picker, optional note, full validation, save loading state.
- Delete via swipe or menu with confirmation plus an undo SnackBar.
- Loading, empty ("No expenses this month"), and error (with retry) states.
- **Done when:** every core checklist item in `project-scope.md` works on Android and web.

### Phase 5: Filters + search
- Filter bar: category chips, date-range picker, clear filters; search field matching title/note.
- Total card reflects the active filters, and the empty state distinguishes "no results" from "no expenses".
- **Done when:** combining filters and search gives correct lists and totals.

### Phase 6: Summary + chart
- Summary screen: category pie chart (`fl_chart`), per-category totals and percentages, and a bar chart of the last 6 months (separate range query).
- **Done when:** chart numbers match the list totals.

### Phase 7: Dark mode + polish
- `ThemeProvider` (system/light/dark) persisted with `shared_preferences`; toggle in the app bar or settings.
- Responsiveness: constrain content width on web/desktop, test small phones; app name and launcher icon; consistent spacing.
- **Done when:** both themes look right and the layout holds at phone and desktop widths.

### Phase 8: Tests
- Unit: model serialization, validators, provider filtering/total logic (repository behind an interface, faked in tests).
- Widget: form validation messages, empty state rendering.
- **Done when:** `flutter test` and `flutter analyze` are clean.

### Phase 9: Delivery
- README: setup (incl. `flutterfire configure` and rules deploy), features, packages, AI tools used and how, screenshots.
- `flutter build apk --release`; attach the APK to a GitHub Release.
- Push to a public GitHub repo (user creates it, or install `gh`).
- **User action:** record a demo (register → add/edit/delete → filters/search → summary → dark mode) and upload unlisted to YouTube or to Drive.
- Update the `project-scope.md` checklist and `CLAUDE.md` architecture section.

## Working approach
- One commit per phase (or smaller), `flutter analyze` before each.
- Phases 1–4 deliver a submittable core app; 5–7 add the optional features; 8–9 finish it.

## Verification
- Per phase: `flutter analyze`, `flutter test`, then `flutter run -d chrome` or on an Android device/emulator, exercising that phase's "Done when" items.
- Firebase: check documents and rules in the console; confirm a second account cannot see the first account's expenses.
- Final: full demo flow on a release APK on a real Android device.
