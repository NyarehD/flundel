# AGENT.md

This document serves as the primary guidance for AI agents and developers working on the **Flundel** Flutter application codebase.

---

## 🚀 Project Overview

- **App Name:** Flundel
- **Framework:** Flutter / Dart (SDK `^3.13.2`)
- **Description:** A generative soundscape and focus tracking application leveraging procedural audio synthesis, DSP engines, and customizable focus sessions.

---

## 🛠 Core Guidelines & Best Practices

### 1. Package Imports
- **Always use package imports** over relative imports.
  - ✅ **Correct:** `import 'package:flundel/domain/models/focus_session.dart';`
  - ❌ **Incorrect:** `import '../../domain/models/focus_session.dart';`
- Import ordering convention:
  1. Dart SDK imports (`dart:async`, `dart:math`, etc.)
  2. Flutter & 3rd-party package imports (`package:flutter/...`, `package:flutter_riverpod/...`, etc.)
  3. Internal package imports (`package:flundel/...`)

---

### 2. Dependency Injection & State Management (Riverpod)
- Use **Riverpod** (`flutter_riverpod` / `riverpod_annotation`) for dependency injection and application state management.
- Expose services, repositories, and audio engines via global Riverpod providers:
  ```dart
  final localStorageRepositoryProvider = Provider<LocalStorageRepository>((ref) {
    return HiveLocalStorageRepository();
  });
  ```
- Use `Notifier` / `NotifierProvider` (or `AsyncNotifier` / `AsyncNotifierProvider`) for managing UI and business logic state in ViewModels:
  ```dart
  final sessionViewModelProvider =
      NotifierProvider<SessionViewModel, SessionState>(SessionViewModel.new);

  class SessionViewModel extends Notifier<SessionState> {
    LocalStorageRepository get _storage => ref.read(localStorageRepositoryProvider);
    AudioEngine get _audioEngine => ref.read(audioEngineProvider);

    @override
    SessionState build() { ... }
  }
  ```
- Consume providers in UI widgets using `ConsumerWidget` or `ConsumerStatefulWidget` with `WidgetRef`.

---

### 3. Data Classes (Freezed)
- Use **Freezed** (`freezed_annotation`, `freezed`) for creating immutable data models, unions, and JSON serialization.
- Annotate model classes with `@freezed` and include necessary `part` files (`.freezed.dart` and `.g.dart` if JSON serializable or Hive compatible):
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'soundscape_config.freezed.dart';
  part 'soundscape_config.g.dart';

  @freezed
  abstract class SoundscapeConfig with _$SoundscapeConfig {
    const factory SoundscapeConfig({
      required String id,
      @Default(0.5) double volume,
      @Default([]) List<String> activeLayers,
    }) = _SoundscapeConfig;

    factory SoundscapeConfig.fromJson(Map<String, dynamic> json) =>
        _$SoundscapeConfigFromJson(json);
  }
  ```
- After adding or modifying any `@freezed` models, generate the required code using:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```

---

## 📂 Project Structure

```
lib/
├── app/                  # Application initialization, theme, router (go_router)
├── audio/                # Audio engine, DSP (digital signal processing), procedural audio generators
│   ├── dsp/              # Low-level audio nodes (noise, binaural beats, pad synth, filters)
│   └── procedural/       # Procedural harmony, piano scheduler, variation controller
├── domain/               # Domain entities, Freezed models, mappers (auto_mappr)
├── features/             # UI screens and feature components
│   ├── debug/            # Audio DSP debug tool screens
│   ├── focus/            # Focus session UI & timers
│   └── home/             # Main dashboard & soundscape selection
├── session/              # Session state, phase calculations, and SessionViewModel
├── storage/              # Local storage abstractions & Hive persistence
├── visualization/        # Canvas painters and audio visualization engine
└── main.dart             # Application entry point
```

---

## ⚡ Code Generation Command

Whenever `@freezed`, `@HiveType`, or `@AutoMappr` annotations are created or updated, execute code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## ✅ Quality Standards

- Maintain strict static typing and clean architecture boundaries.
- Ensure audio engine lifecycles and background timers are properly disposed (`ref.onDispose`).
- Prefer `const` constructors for immutable UI widgets.
- Keep business logic inside ViewModels and services, keeping UI widgets purely presentational.
