<h1 align="center">💖 VirtualHeart</h1>

<p align="center">
  <em>Hybrid On-Device &amp; Cloud BYOK AI romantic companion powered by Flutter, flutter_edge_ai &amp; Genkit</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.50.1-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter Version"/>
  <img src="https://img.shields.io/badge/Dart-3.14.0-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart Version"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square" alt="Platform"/>
  <img src="https://img.shields.io/badge/AI-On--Device%20%2B%20Cloud%20BYOK-orange?style=flat-square" alt="Hybrid AI"/>
</p>

---

## 📖 About

**VirtualHeart** is a privacy-first AI companion app built with Flutter. Users create a
personalized virtual partner and choose between:

- **Local On-Device AI**: Small Language Models & local speech running offline via
  [`flutter_edge_ai`](https://pub.dev/packages/flutter_edge_ai).
- **Cloud BYOK AI (optional)**: Bring Your Own Key across **Google Gemini**, **Anthropic &
  Anthropic-compatible**, and **OpenAI & OpenAI-compatible** providers (OpenRouter, Groq,
  DeepSeek, xAI, Together, Ollama/LM Studio, custom endpoints), plus Cloud STT & TTS
  (**ElevenLabs**, **OpenAI-compatible / Groq Whisper**, **Google Gemini**) orchestrated via
  [**Genkit Dart/Flutter**](https://pub.dev/packages/genkit) — with full per-profile parameter
  and context freedom.

There is **no VirtualHeart application server, no account, and no telemetry**. In Local mode,
chat, memory, persona, and mood never leave your device. In Cloud BYOK mode, requests go
directly from your device to the provider endpoints you configure, and API keys are stored
encrypted in OS secure storage.

## ✨ Features (current state)

| Area | Status | Notes |
| --- | --- | --- |
| Age gate (13+) | ✅ Implemented | persisted in `AppSettings.isAgeVerified` |
| Onboarding (3 pages) | ✅ Implemented | |
| Persona setup & edit | ✅ Implemented | gender, name, nickname, personality, hobbies, avatar; editing reuses the same form |
| Local model catalog & install | ✅ Implemented | 5 models (`.litertlm`/`.task`), explicit model choice, download with progress + cancel, upload your own file, switch anytime from Settings |
| Cloud BYOK multi-provider (Genkit) | ✅ Implemented | Google Gemini, Anthropic/compat, OpenAI/compat (presets + custom Base URL/headers), multi-profile switch, Test Connection, Fetch Models, encrypted key storage |
| Cloud parameters & context freedom | ✅ Implemented | per-profile temperature, topP, topK, maxOutputTokens (up to 32k), penalties, stop sequences, seed, reasoning/thinking budget, Gemini safety, history up to 200 msgs, memory up to 100 facts, input up to 64k chars, custom system prompt, optional cheaper background model |
| Streaming chat | ✅ Implemented | token streaming (local & cloud multi-turn), typing indicator, stop-generation, dynamic input limit, partial-reply persistence, localized error banner + retry |
| Conversation summary | ✅ Implemented | every 30 messages (optional in Cloud mode), injected as context |
| Memory extraction | ✅ Implemented | facts merged by key, source snippet kept, last-referenced timestamp (optional in Cloud mode) |
| Dynamic mood engine | ✅ Implemented | 5 moods, intensity 0–1, idle decay |
| Content safety | ✅ Implemented | input + output gates with warm in-character deflections |
| Voice input (STT) | ⚠️ Partial | independent backend: System, On-device Moonshine, **ElevenLabs Scribe**, **OpenAI-compatible / Groq Whisper**, **Google Gemini**; transcribing state in input bar; no waveform UI |
| Voice output (TTS) | ⚠️ Partial | independent backend: System, On-device (Inflect/Matcha/Qwen3), **ElevenLabs** (account voices browser + stability/similarity/style/speed/speaker boost), **OpenAI-compatible**, **Google Gemini**; accurate completion callback for Cloud TTS (`audioplayers`), timer-estimated for on-device PCM |
| Persona profile sheet & Hub | ✅ Implemented | Companion Hub (`/hub`) with status, starters, memory snapshot, Local/Cloud engine badge, profile sheet |
| Notifications | ⚠️ Partial | morning message + check-in (1/3/6/12 h), localized copy, permission-aware, tap opens chat; special-day API has no UI |
| Settings | ✅ Implemented | 4 theme presets × light/dark/system, language (ID/EN/mixed), AI engine (Local + Cloud BYOK + quick parameters), independent TTS/STT voice, notifications, data & privacy |
| Data privacy | ✅ Implemented | delete conversations/memory, reset persona, reset all data (clears cloud profiles, encrypted BYOK keys, HF token + exports), in-app hybrid privacy policy, export chat via OS save dialog |

Voice selection is **global**, not per-persona. Known gaps & live-device unverified items are
tracked in [`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md).

## 🏗️ Tech Stack

- **Flutter 3.50.1 / Dart 3.14.0** — SDK version is pinned in `.fvmrc`
- **flutter_edge_ai** family — LiteRT-LM (`.litertlm`), MediaPipe (`.task`), on-device speech
- **Genkit Dart/Flutter** (`genkit`, `genkit_google_genai`, `genkit_anthropic`, `genkit_openai` + custom `ElevenLabsGenkitPlugin`) — Cloud BYOK LLM, TTS & STT orchestration
- **flutter_secure_storage** — OS-encrypted storage for BYOK API keys
- **audioplayers** — accurate Cloud TTS audio playback (MP3/WAV/AAC/Opus)
- **Riverpod 3** — manual `Notifier`/`AsyncNotifier` providers (no codegen)
- **ObjectBox** — local-first storage for chat, memory, persona, mood, settings, cloud profiles, cloud speech config
- **go_router** — declarative routing with a pure redirect guard
- **material_ui** — Material widgets; Multi-Theme Atelier design system (4 themes × light/dark)
- Exact versions and pinned transitive dependencies: [`docs/DEPENDENCIES.md`](docs/DEPENDENCIES.md)

Architecture:

```
lib/
├── main.dart, app.dart        # engine + notifications + DB init, MaterialApp.router
├── core/                      # design system, l10n, router, logger, pure utils
├── models/                    # ObjectBox entities (+ generated bindings)
├── services/                  # ai/ (local + genkit/), database/, mood, notification, stt, tts
└── features/                  # hub, onboarding, persona, model, chat, memory, settings
```

Details: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## 🚀 Getting Started

### Prerequisites

- Flutter **3.50.1** (recommended via [FVM](https://fvm.app))
- JDK 17+ for Android builds
- An Android device/emulator with **arm64-v8a** (minSdk 30), or an iOS 16+ device

### Run

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # generate ObjectBox bindings
fvm flutter run                                                 # or `make apk`
```

Or: `make setup && make gen && make apk`.

### AI Engine Setup (Local or Cloud BYOK)

No local model is bundled. On first launch the AI Engine screen lets you choose either:

1. **Local tab**: download an on-device model from HuggingFace (135 MB – 1.7 GB; offline after install) or upload a local `.litertlm` / `.task` file. Gated models (Gemma 3 1B) accept a HuggingFace token.
2. **Cloud BYOK tab**: add one or more provider profiles (Google Gemini, Anthropic / compatible, OpenAI / compatible presets or custom endpoint), test connection, customize generation & context parameters, and activate immediately without downloading gigabytes of local weights.

Switch between Local and any saved Cloud profile anytime from **Settings → AI Model**. See
[`docs/AI_PIPELINE.md`](docs/AI_PIPELINE.md) and [`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md).

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

Multi-Theme Atelier (Editorial, Romantic, Classic, Botanical — each with Light & Dark palettes
verified ≥ 4.5:1 contrast). Tokens live in `lib/core/design/tokens/` (`AppColors`, `AppEffects`,
`AppSizes`, `AppDurations`, `AppTextStyles`). See [`docs/DESIGN.md`](docs/DESIGN.md).

## 🔐 Privacy

All conversations, memories, persona, mood, settings, and cloud profiles are stored locally in
ObjectBox, while BYOK API keys are stored encrypted via OS secure storage (`flutter_secure_storage`).
There are no VirtualHeart servers, no accounts, and no analytics/telemetry. Outbound network calls
occur only for HuggingFace model downloads, Google Fonts, and — optionally when you opt in to Cloud
BYOK or Cloud Speech — direct device-to-provider requests to the endpoints you configure. Read
[`docs/PRIVACY.md`](docs/PRIVACY.md) for full details.

## 📚 Documentation

Start at [`docs/README.md`](docs/README.md) (index). Working rules for humans and AI agents:
[`AGENTS.md`](AGENTS.md). Contribution guide: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## 🤝 Contributing

Read `AGENTS.md` first, then `docs/WORKFLOW.md` and `docs/TESTING.md`. Every change must pass
`make check`; behavior changes update the relevant doc in the same commit.

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
