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

**VirtualHeart** is a privacy-first AI companion app built with Flutter. It lets users create and interact with a personalized virtual partner — fully powered by an on-device Small Language Model (SLM). No data is ever sent to external servers; all AI inference runs locally on the device using [MediaPipe](https://ai.google.dev/edge/mediapipe/solutions/guide) via the [`flutter_gemma`](https://pub.dev/packages/flutter_gemma) package.

The AI companion adapts its personality, remembers past conversations, expresses dynamic moods, and can speak and listen — all without an internet connection.

---

## ✨ Features

### 🎯 Personalized Companion Setup
- Choose companion gender (girlfriend / boyfriend)
- Set a custom name and a nickname for yourself
- Pick a **personality preset**: Gentle, Cheerful, Mature, or Mysterious
- Add hobbies that shape the AI's conversational style
- Select from 6 avatar options per gender
- Choose a voice for text-to-speech responses

### 💬 Rich Chat Experience
- **Streaming AI responses** — tokens rendered as they are generated
- **Voice input** via Speech-to-Text (microphone button in chat)
- **Voice output** via Text-to-Speech with play / stop controls
- **Typing indicator** animation while the AI processes a response
- **Mood indicator** chip showing the companion's current emotional state
- **Persona profile sheet** — swipe up to view companion details
- Full **chat history** persisted in a local database

### 🧠 Memory System
- Automatically extracts facts from conversations
- Four memory categories: **Personal**, **Events**, **Preferences**, **Important Dates**
- Dedicated **Memory Screen** to browse, search, and delete stored facts
- AI actively references memories to make responses feel personal

### 🎭 Dynamic Mood Engine
- Five mood types: **Happy**, **Longing**, **Playful**, **Sad**, **Excited**
- Mood intensity on a continuous 0.0 – 1.0 scale
- Mood state evolves naturally based on conversation content
- Current mood is injected into the AI's system prompt

### 🛡️ Content Safety
- **Input gate** — blocks harmful user messages (explicit content, self-harm, hate speech, violence)
- **Output gate** — validates AI-generated responses before displaying
- Warm, in-character deflection messages when content is filtered

### 🔔 Smart Notifications
- **Morning greeting** notification at a user-configured time
- **Check-in reminder** to keep the relationship active
- Built with `flutter_local_notifications` + timezone support

### ⚙️ Comprehensive Settings
- **Appearance**: Toggle Dark / Light theme
- **Language**: Switch system and AI response language (Indonesian, English, or Mixed)
- **Voice**: Enable / disable TTS and auto-play AI responses
- **Persona**: Edit companion profile and preferences at any time
- **Data Privacy**: Clear chat history or wipe memory completely
- View privacy policy

### 🔒 Privacy-First Architecture
- All AI inference runs **100% on-device** (no cloud calls)
- Chat history and memory stored only in a **local ObjectBox database**
- No analytics, no telemetry, no account required

---

## 🏗️ Architecture

```text
lib/
├── main.dart                  # Entry point — initializes Gemma & ObjectBox
├── app.dart                   # Root widget — MaterialApp, Riverpod, GoRouter
│
├── core/
│   ├── constants/             # Colors, sizes, text styles
│   ├── theme/                 # Light & dark ThemeData
│   └── utils/                 # Date formatters, Dart extensions
│
├── data/
│   ├── database/              # ObjectBox service (init, box access)
│   └── models/                # ObjectBox entities (Message, MemoryFact, MoodState, etc.)
│
├── providers/                 # Riverpod providers & notifiers
│   ├── app_settings_provider.dart
│   ├── model_ready_provider.dart
│   ├── mood_provider.dart
│   ├── notification_provider.dart
│   ├── objectbox_provider.dart
│   ├── router_provider.dart   # GoRouter with navigation guards
│   └── theme_provider.dart
│
├── screens/
│   ├── splash/                # Animated splash with floating hearts
│   ├── age_gate/              # Age verification (13+)
│   ├── onboarding/            # 3-page feature introduction
│   ├── persona_setup/         # Create virtual companion
│   ├── model_download/        # Installs LLM to device storage
│   ├── chat/                  # Main chat interface + widgets
│   ├── memory/                # View & manage memory facts
│   └── settings/              # App preferences structured by sections
│
└── services/
    ├── ai/                    # Integrates LLM memory, safety, and prompt building
    ├── mood_service.dart      # Mood state transitions logic
    ├── notification_service.dart # Schedule morning & check-in alerts
    ├── tts_service.dart       # Text-to-Speech wrapper
    └── stt_service.dart       # Speech-to-Text wrapper
```

### Navigation Flow

```text
Splash → Age Gate → Onboarding → Persona Setup → Model Installation → Chat
```

GoRouter guards redirect the user back to the appropriate screen if a required setup step has not been completed (age verification, persona creation, model installation).

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.47.1 / Dart 3.13.1 |
| **State Management** | Riverpod 3.4.2 |
| **Navigation** | GoRouter 18.0.0 with route guards |
| **Local Database** | ObjectBox 5.3.2 (embedded NoSQL) |
| **On-Device AI** | flutter_gemma 1.6.5 + flutter_gemma_mediapipe 1.0.5 (MediaPipe LLM — Qwen2.5-1.5B-Instruct) |
| **Text-to-Speech** | flutter_tts 4.2.5 |
| **Speech-to-Text** | speech_to_text 7.4.0 |
| **Notifications** | flutter_local_notifications 22.3.0 |
| **Typography** | Google Fonts — Playfair Display + Nunito |
| **Animations** | flutter_animate 4.5.2 + Lottie 3.5.1 |
| **Markdown Rendering** | gpt_markdown 1.2.1 |
| **Code Generation** | build_runner + objectbox_generator |

---

## ⚙️ Prerequisites

Before running VirtualHeart, make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.47.1** (use [FVM](https://fvm.app/) — see `.fvmrc`)
- Dart **3.13.1+**
- Android Studio / Xcode (for mobile targets)
- A physical device with **sufficient RAM** (the 1.5B model requires ~2 GB free RAM to run smoothly)

### Install FVM (recommended)

```bash
dart pub global activate fvm
fvm install         # reads .fvmrc and installs the correct Flutter version
fvm use             # sets this project to use the pinned version
```

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/Reinvy/flutter-virtual-heart.git
cd flutter-virtual-heart
```

### 2. Install dependencies

```bash
flutter pub get
# or, if using FVM:
fvm flutter pub get
```

### 3. Run code generation

ObjectBox and Riverpod use code generation. Run this once before building:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
# or:
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Setup the AI Model (Required)

Due to its large size (~1.5 GB), the LLM model is **not** included in the repository by default (it is ignored via `.gitignore`). This app uses the heavily optimized Qwen model adapted for MediaPipe (`Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.task`).

1. Download the correct quantized `.task` file supported by `flutter_gemma`.
2. Determine if the `assets/models/` directory already exists in your root folder. If not, create it.
3. Place the downloaded `.task` file into the `assets/models/` directory and ensure its name matches exactly what is required in `lib/services/ai/model_service.dart`.

> **Important:** The app's `ModelDownloadScreen` does **not** download the model from the internet! It unpacks and installs this local `.task` asset directly to the smartphone's internal memory during the very first launch. **It requires no internet connection**, but ensures the device has at least 2 GB of free storage.

### 5. Run the app

```bash
flutter run
# or:
fvm flutter run
```

---

## 📱 Supported Platforms

| Platform | Status |
|---|---|
| Android | ✅ Supported |
| iOS | ✅ Supported |
| macOS | ⚠️ Experimental |
| Linux | ⚠️ Experimental |
| Windows | ⚠️ Experimental |
| Web | ⚠️ Experimental |

> **Note:** On-device LLM inference via MediaPipe is officially supported on **Android** and **iOS**. Desktop/web platforms may have limited AI functionality and require different underlying implementations depending on the MediaPipe plugin's capabilities.

---

## 🎨 Design System

### Color Palette

| Token | Dark Mode | Light Mode |
|---|---|---|
| Background | `#0D0A0E` | `#FDF6F9` |
| Surface | `#1A1320` | `#FFFFFF` |
| Primary (Rose Pink) | `#C2507A` | `#C2507A` |
| Secondary (Mauve) | `#7B5EA7` | `#7B5EA7` |
| Accent (Heart Red) | `#E8506A` | `#E8506A` |
| Text Primary | `#F5EEF8` | `#1A0A2E` |

### Typography
- **Headings:** Playfair Display (serif — romantic, elegant)
- **Body / UI:** Nunito (rounded sans-serif — friendly, readable)

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Commit your changes following [Conventional Commits](https://www.conventionalcommits.org/)
4. Push to your fork and open a Pull Request

Please make sure your code passes the linter before submitting:

```bash
flutter analyze
```

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

© 2025 [Bahrul Ulumul Haq](https://github.com/Reinvy)
