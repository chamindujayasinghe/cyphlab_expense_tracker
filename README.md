# Expense Tracker

A clean, simple expense tracker built with **Flutter** and **Firebase**. Sign in, record your spending, and see where your money goes with monthly totals, filters and charts.

- **Download APK:** [Latest release](https://github.com/chamindujayasinghe/cyphlab_expense_tracker/releases/latest)
- **Demo video:** _link to be added_

## Features

### Core
- **Add, edit and delete expenses.** Each expense has a title, amount, category, date and an optional note.
- **Categories:** Food, Transport, Shopping, Bills, Entertainment, Health, Education and Other, each with its own icon and color.
- **Cloud storage:** expenses are stored in **Cloud Firestore** and sync in real time.
- **Monthly total:** the total for the current month, or any earlier month, with a month switcher.
- **Expense history:** grouped by day ("Today", "Yesterday", dates), with a total for each day.
- **Filters:** by one or more categories, and by a custom date range.
- **Form validation:** required fields, a positive amount with up to 2 decimals, no future dates, and length limits. The same rules are enforced on the server by the Firestore security rules.
- **Loading, empty and error states** on every screen, with a retry button on errors.

### Extras
- **Firebase Authentication:** email/password sign-up, login and password reset. Each user sees only their own data.
- **Search** by title or note.
- **Summary tab:** a category donut chart with a breakdown by percentage, and a bar chart of the last 6 months.
- **Dark mode:** System, Light or Dark, remembered between launches.
- **Undo delete:** swipe an expense away (or delete it from the edit screen), then tap **Undo**.
- **Unsaved-changes guard:** leaving a form with edits asks before discarding them.
- **Offline-friendly:** saves made while offline are queued and synced when the connection returns.
- **Responsive:** a bottom navigation bar on phones and a side rail on wide screens. Checked on small phones with large system text.
- Custom app name and launcher icon (including an Android adaptive icon).

## Tech stack

| Package | Purpose |
|---|---|
| [`firebase_core`](https://pub.dev/packages/firebase_core) | Firebase initialization |
| [`firebase_auth`](https://pub.dev/packages/firebase_auth) | Email/password authentication |
| [`cloud_firestore`](https://pub.dev/packages/cloud_firestore) | Expense storage with real-time updates |
| [`provider`](https://pub.dev/packages/provider) | State management (`ChangeNotifier`) |
| [`fl_chart`](https://pub.dev/packages/fl_chart) | Donut and bar charts |
| [`intl`](https://pub.dev/packages/intl) | Currency and date formatting |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Saving the theme choice |

Dev: `flutter_lints`, `fake_cloud_firestore` (repository tests), `flutter_launcher_icons`.

Built with Flutter 3.47 / Dart 3.13 and Material 3.

## Architecture

```
lib/
  main.dart           Firebase init and provider wiring
  app.dart            MaterialApp and themes
  models/             Expense, ExpenseCategory
  services/           AuthService, ExpenseRepository (interfaces + Firebase implementations)
  providers/          AuthProvider, ExpenseProvider, ThemeProvider
  screens/            auth/, home/, expense_form/, summary/, settings/, main_shell.dart
  widgets/            Reusable UI (expense tile, filter bar, total card, state views, ...)
  utils/              Validators, formatters, stats, constants
  theme/              Light and dark Material 3 themes
```

- **Layers:** screens talk only to providers. Providers call services, and services are the only code that touches Firebase. Services are abstract interfaces, so providers and screens are tested with in-memory fakes.
- **Error handling:** services turn Firebase error codes into friendly messages. Provider actions return `null` on success or a message on failure, and screens show that message in a SnackBar.
- **Data flow:** `ExpenseProvider` subscribes to one period at a time (a month or a custom date range) with a single range query. Category and search filters are applied on the device, so no composite Firestore indexes are needed.
- **Auth-driven data:** `ExpenseProvider` is linked to `AuthProvider` with a `ChangeNotifierProxyProvider`. It subscribes to the user's expenses on sign-in and clears them on sign-out.

### Firestore data model

```
users/{uid}/expenses/{expenseId}
  title: string        amount: number       category: string (enum name)
  date: timestamp      note: string | null
  createdAt: timestamp updatedAt: timestamp   (server timestamps)
```

[`firestore.rules`](firestore.rules) allows each user to read and write only their own expenses. It also validates every write: field types, title length, amount range, a known category, and server timestamps.

## Setup

### Prerequisites
- Flutter SDK 3.47+ (`flutter doctor` passing)
- A Firebase project
- Node.js (for the Firebase CLI)

### 1. Clone and install
```bash
git clone https://github.com/chamindujayasinghe/cyphlab_expense_tracker.git
cd cyphlab_expense_tracker
flutter pub get
```

### 2. Connect Firebase
The repo includes the configuration for the original Firebase project, so the app runs as-is. To use your own project instead:

1. In the [Firebase console](https://console.firebase.google.com), create a project.
2. Open **Authentication → Sign-in method** and enable **Email/Password**.
3. Open **Firestore Database** and create a database.
4. Install the CLIs, log in, and generate the config:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure --project=<project-id> --platforms=android,web,windows
   ```
5. Deploy the security rules:
   ```bash
   firebase deploy --only firestore:rules --project <project-id>
   ```

### 3. Run
```bash
flutter run -d chrome        # web
flutter run                  # connected Android device or emulator
flutter run -d windows       # Windows desktop
```

### Build the APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```
The release build is signed with the debug key, which is fine for sideloading and demos but not for publishing to the Play Store.

## Testing

```bash
flutter analyze
flutter test
```

**98 tests** cover:
- **Models, validators, formatters and summary calculations**
- **Providers:** auth, expenses (month and range queries, filters, search, optimistic delete and undo) and theme persistence.
- **The Firestore repository**, run against an in-memory Firestore: user scoping, range query bounds and ordering, server timestamps, and error mapping.
- **Every screen**, including its loading, empty and error states.
- **User flows:** add, edit, delete with undo, swipe to delete, and the unsaved-changes guard.
- **Layout:** every screen rendered on a 320×568 phone with 130% text, in light and dark themes. Any overflow fails the test.

## AI tools used

I used **[Claude Code](https://claude.com/claude-code)** (Anthropic's coding agent, running the Claude Opus model) throughout development, as a pair programmer working in my terminal and editor.

**How it helped:**
- **Planning:** turned the task brief into a requirements checklist ([`project-scope.md`](project-scope.md)) and a phased plan ([`project-plan.md`](project-plan.md)). I built and committed one phase at a time and reviewed each before moving on.
- **Environment setup:** diagnosed Flutter and Android toolchain problems:
  - a git `safe.directory` ownership error blocking Flutter
  - a missing Android SDK platform and a broken, half-finished SDK download
  - `sdkmanager` failing on Windows
  - a missing NDK
- **Firebase:** ran the Firebase and FlutterFire CLIs to connect the app, wrote the Firestore security rules, and deployed them.
- **Implementation:** wrote the code phase by phase. I kept the layers clear (UI → providers → services) so the code stays easy to explain and test.
- **Testing and debugging:** wrote the test suite. The small-screen layout test found real overflow bugs (long amounts, the category dropdown), which were then fixed.
- **UI standards:** I wrote a custom Claude Code skill, [`.claude/skills/flutter-ui-expert`](.claude/skills/flutter-ui-expert/SKILL.md), so the generated UI follows my rules: `const` constructors, disposing controllers, `mounted` checks, handling every UI state, Material 3, dark-mode-aware colors, and keeping Firebase calls out of widgets.

**How I used it:** I reviewed each change, tested every phase by hand in the browser, and asked for changes where the result wasn't right. For example, I found the original chart icon for the summary screen unclear, so we replaced it with labeled bottom navigation tabs. [`CLAUDE.md`](CLAUDE.md) records the project's architecture and conventions for the AI assistant.
