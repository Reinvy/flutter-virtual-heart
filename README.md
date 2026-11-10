<h1 align="center">💖 VirtualHeart</h1>

<p align="center">
  <em>On-device AI romantic companion powered by a Small Language Model (SLM)</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.47.1-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter Version"/>
  <img src="https://img.shields.io/badge/Dart-3.13.1-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart Version"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square" alt="Platform"/>
  <img src="https://img.shields.io/badge/AI-On--Device-orange?style=flat-square" alt="On-Device AI"/>
</p>

---

## 📖 About

**VirtualHeart** is a privacy-first AI companion app built with Flutter. Users create a
personalized virtual partner and talk to it while a Small Language Model runs **on the device**
via [`flutter_edge_ai`](https://pub.dev/packages/flutter_edge_ai) — no application server, no
account, no telemetry.

Network is used for exactly two things: downloading the model file from HuggingFace (once) and
fetching Google Fonts at runtime. Chat, memory, persona, and mood never leave the device.

## ✨ Features (current state)

| Area | Status | Notes |
| --- | --- | --- |
| Age gate (13+) | ✅ Implemented | persisted in `AppSettings.isAgeVerified` |
| Onboarding (3 pages) | ✅ Implemented | |
| Persona setup & edit | ✅ Implemented | gender, name, nickname, personality, hobbies, avatar; editing reuses the same form |
| Model catalog & install | ✅ Implemented | 5 models (`.litertlm`/`.task`), explicit model choice, download with progress + cancel, upload your own file, switch anytime from Settings |
| Streaming chat | ✅ Implemented | token streaming, typing indicator, stop-generation, partial-reply persistence, localized error banner + retry |
| Conversation summary | ✅ Implemented | every 30 messages, injected as context |
| Memory extraction | ✅ Implemented | facts merged by key, source snippet kept, last-referenced timestamp |
| Dynamic mood engine | ✅ Implemented | 5 moods, intensity 0–1, idle decay |
| Content safety | ✅ Implemented | input + output gates with warm in-character deflections |
| Voice input (STT) | ⚠️ Partial | on-device Moonshine or OS dictation; no waveform UI |
| Voice output (TTS) | ⚠️ Partial | on-device (Inflect/Matcha/Qwen3) or OS voice; completion estimated by timer |
| Persona profile sheet | ✅ Implemented | avatar, mood, hobbies, personality, edit |
| Notifications | ⚠️ Partial | morning message + check-in (1/3/6/12 h), localized copy, permission-aware, tap opens chat; special-day API has no UI |
| Settings | ✅ Implemented | theme light/dark/system, language (ID/EN/mixed), AI model, voice, notifications, data & privacy |
| Data privacy | ✅ Implemented | delete conversations/memory, reset persona, reset all data (also clears HF token + exports), in-app privacy policy, export chat via the OS save dialog |

Voice selection is **global**, not per-persona. Known gaps are tracked in
[`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md).

## 🏗️ Tech Stack

- **Flutter 3.47.1 / Dart 3.13.1** — SDK version is pinned in `.fvmrc`
- **flutter_edge_ai** family — LiteRT-LM (`.litertlm`), MediaPipe (`.task`), on-device speech
- **Riverpod 3** — manual `Notifier`/`AsyncNotifier` providers (no codegen)
- **ObjectBox** — local-first storage for chat, memory, persona, mood, settings
- **go_router** — declarative routing with a pure redirect guard
- **material_ui** — Material widgets; custom Sakura Dusk design system
- Exact versions and pinned transitive dependencies: [`docs/DEPENDENCIES.md`](docs/DEPENDENCIES.md)

Architecture:

```
lib/
├── main.dart, app.dart        # engine + notifications + DB init, MaterialApp.router
├── core/                      # design system, l10n, router, logger, pure utils
├── models/                     # ObjectBox entities (+ generated bindings)
├── services/                   # ai/, database/, mood, notification, stt, tts
└── features/                   # onboarding, persona, model, chat, memory, settings
```

Details: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## 🚀 Getting Started

### Prerequisites

- Flutter **3.47.1** (recommended via [FVM](https://fvm.app))
- JDK 17+ for Android builds
- An Android device/emulator with **arm64-v8a** (minSdk 30), or an iOS 16+ device

### Run

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # generate ObjectBox bindings
fvm flutter run                                                 # or `make apk`
```

Or: `make setup && make gen && make apk`.

### Model

The model is **not bundled**. On first launch the app opens the model screen and either:

1. downloads a model from HuggingFace (135 MB – 1.7 GB; internet required once), or
2. installs a local `.litertlm` / `.task` file you provide.

Gated models (Gemma 3 1B) need a HuggingFace token entered on that screen. After installation,
inference is fully offline. Make sure you have enough free storage and RAM — see
[`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md).

## 🖥️ Platform Support

| Platform | Status |
| --- | --- |
| Android (arm64-v8a, minSdk 30) | ✅ Supported |
| iOS (16.0+) | ✅ Supported by design — not verified in CI |
| macOS (14.0+) | 🧪 Experimental |
| Linux / Windows | 🧪 Experimental |
| Web | ❌ Not supported (`dart:io` dependencies, no on-device speech) |

Setup details per platform: [`docs/PLATFORM_SETUP.md`](docs/PLATFORM_SETUP.md).

## 🎨 Design System

Sakura Dusk: warm ivory paper, plum ink, rose + lavender accents, Fraunces headings and Plus
Jakarta Sans body text, light/dark/system modes. Tokens live in
`lib/core/design/tokens/` (`AppColors`, `AppGradients`, `AppShadows`, `AppSizes`,
`AppDurations`, `AppTextStyles`). Every screen shares `AppScaffold`/`AppBackground`.
See [`docs/DESIGN.md`](docs/DESIGN.md).

## 🔐 Privacy

All data is stored locally (ObjectBox). The only outbound requests are model downloads from
HuggingFace and Google Fonts at runtime. There is no analytics, no account, and no server-side
processing. Read [`docs/PRIVACY.md`](docs/PRIVACY.md) for permissions, data deletion, and
limitations.

## 📚 Documentation

Start at [`docs/README.md`](docs/README.md) (index). Working rules for humans and AI agents:
[`AGENTS.md`](AGENTS.md). Contribution guide: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## 🤝 Contributing

Read `AGENTS.md` first, then `docs/WORKFLOW.md` and `docs/TESTING.md`. Every change must pass
`make check`; behavior changes update the relevant doc in the same commit.

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
