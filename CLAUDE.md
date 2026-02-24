# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Flutter plugin** (`alarm`, v5.2.1) providing a cross-platform alarm manager for iOS and Android. It is published to pub.dev and used as a dependency by other apps—not a standalone app itself.

## Common Commands

```bash
# Get dependencies + run all code generation + format
flutter pub get
dart run pigeon --input pigeons/alarm_api.dart
dart run build_runner build --delete-conflicting-outputs
dart fix --apply
dart format --line-length 120 .
dart run import_sorter:main

# Static analysis (CI runs this)
flutter analyze

# Format only
dart format --line-length 120 .

# Sort imports only
dart run import_sorter:main

# Regenerate Pigeon bindings (after editing pigeons/alarm_api.dart)
dart run pigeon --input pigeons/alarm_api.dart

# Regenerate json_serializable (after editing lib/model/*.dart)
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

### Public API (`lib/alarm.dart`)

The `Alarm` class is the single entry point consumers use. All methods are static:

- `init()` — must be called once in `main()` before any other call
- `set(alarmSettings:)` / `stop(id)` / `stopAll()`
- `getAlarm(id)` / `getAlarms()` / `hasAlarm()` / `isRinging([id])`
- `scheduled` / `ringing` — `ValueStream<AlarmSet>` reactive streams via `rxdart`

### Platform Communication Layer

Uses **Pigeon** for type-safe platform channels. The source of truth is `pigeons/alarm_api.dart`, which generates:

- `lib/src/generated/platform_bindings.g.dart` — Dart bindings (excluded from analysis)
- `ios/Classes/generated/FlutterBindings.g.swift` — Swift bindings
- `android/.../generated/FlutterBindings.g.kt` — Kotlin bindings

Two Pigeon APIs:

- `AlarmApi` (`@HostApi`) — Flutter → Native: `setAlarm`, `stopAlarm`, `stopAll`, `isRinging`, `setWarningNotificationOnKill`
- `AlarmTriggerApi` (`@FlutterApi`) — Native → Flutter: `alarmRang`, `alarmStopped`

### Platform Classes (`lib/src/`)

- `BaseAlarm` — common logic; holds the singleton `AlarmApi` instance; delegates to `PlatformTimers`
- `IOSAlarm extends BaseAlarm` — iOS-specific extensions (currently thin)
- `AndroidAlarm extends BaseAlarm` — Android-specific (`disableWarningNotificationOnKill`)
- `AlarmTriggerApiImpl` — handles native callbacks and updates the `Alarm` state streams
- `PlatformTimers` — Dart-side fallback: a 200ms periodic timer fires while the app is in foreground; pauses on background via `flutter_fgbg`

### Models (`lib/model/`)

Three models annotated with `@JsonSerializable` and `Equatable`:

- `AlarmSettings` — main alarm config; handles v4 → v5 JSON migration in `fromJson`
- `NotificationSettings`
- `VolumeSettings` (including `VolumeFadeStep`)

All have `.g.dart` generated counterparts and a `toWire()` method that converts to Pigeon wire types.

### Storage (`lib/service/alarm_storage.dart`)

`AlarmStorage` uses `SharedPreferences` with key prefix `__alarm_id__<id>`. It reloads preferences on foreground events to pick up modifications made by native notification actions.

### Native Implementations

- **Android** (`android/src/main/kotlin/com/gdelataillade/alarm/`): `AlarmPlugin`, `AlarmReceiver`, `BootReceiver`, `AlarmApiImpl`, `AlarmStorage`, `NotificationService`, `VibrationService`, `NotificationOnKillService` — uses `AlarmManager` + foreground `Service`
- **iOS** (`ios/Classes/`): `AlarmConfiguration`, `BackgroundTaskManager` — uses `AVAudioPlayer` silent background audio + Background App Refresh

## Code Style

- **Line width**: 120 characters (`dart format --line-length 120`; also set in `analysis_options.yaml`)
- **Imports**: sorted by `import_sorter` into four sections with emoji prefixes: `🎯 Dart imports`, `🐦 Flutter imports`, `📦 Package imports`, `🌎 Project imports`
- **Package imports**: use `package:alarm/...` (never relative imports)
- **Linting**: `flutter_lints` base with strict analyzer settings (`strict-casts`, `strict-inference`, `strict-raw-types`); unused elements, fields, and imports are errors
- `lib/src/generated/platform_bindings.g.dart` is excluded from analysis — never edit it manually

## Code Generation Rules

- After editing `pigeons/alarm_api.dart`: run Pigeon, then format. Both Kotlin and Swift outputs are generated simultaneously.
- After editing any `lib/model/*.dart` model: run `build_runner`. Only files in `lib/model/` are targeted (see `build.yaml`).
- Generated files (`*.g.dart`, `FlutterBindings.g.swift`, `FlutterBindings.g.kt`) are committed to the repo.
