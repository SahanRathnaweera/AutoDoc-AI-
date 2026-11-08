# 🚗 AutoDoc AI

AutoDoc AI is a Flutter-based vehicle inspection application concept focused on AI-assisted damage assessment, diagnostics, and report generation. The current repository is the foundational app shell for a clean-architecture Flutter project, including routing, dependency injection, and a ready-to-expand structure.

---

## ✨ Core Idea

The long-term goal is to build a complete inspection workflow that can:

- detect visual damage from vehicle images,
- analyze engine audio for abnormal sounds,
- generate structured inspection reports,
- and present the results through a clean mobile app experience.

---

## 📌 Current Project Status

This repository currently contains the starter foundation for the app, including:

- Flutter app bootstrap
- GoRouter-based navigation
- GetIt dependency injection setup
- a clean architecture-ready folder structure
- a sample inspection report with PDF sharing
- base project configuration for future feature development

---

## 🛠️ Tech Stack

- Framework: [Flutter](https://flutter.dev/)
- Language: Dart
- Routing: [GoRouter](https://pub.dev/packages/go_router)
- Dependency Injection: [GetIt](https://pub.dev/packages/get_it)
- Code Generation: [Injectable](https://pub.dev/packages/injectable)
- State Management: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- Functional utilities: [dartz](https://pub.dev/packages/dartz)

---

## 📁 Project Structure

```text
AutoDoc-AI-
├── android/
├── ios/
├── lib/
│   ├── config/
│   │   └── injection.dart
│   ├── core/
│   │   ├── error/
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   └── utils/
│   ├── main.dart
│   └── ... future feature modules
├── test/
├── web/
├── windows/
├── analysis_options.yaml
├── pubspec.yaml
├── README.md
└── .gitignore
```

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

- Flutter SDK
- Git
- An IDE such as VS Code or Android Studio

### Install and run

```bash
git clone https://github.com/SahanRathnaweera/AutoDoc-AI-.git
cd AutoDoc-AI-
flutter pub get
flutter run -d chrome
```

The app defaults to `http://127.0.0.1:8000` on web, Windows desktop, and iOS
simulator, and `http://10.0.2.2:8000` on Android emulators. Set
`--dart-define=API_BASE_URL=<backend URL>` to override this (for example, use
the development computer's LAN IP for a physical device).

The report screen submits vehicle details and 1-6 JPEG/PNG photos to the
FastAPI `/api/v1/inspection` endpoint. An optional 10-15 second engine recording
in a common format (for example WAV, MP3, M4A/AAC, FLAC, or OGG) is classified
only when a compatible audio model is installed. Format support depends on the
backend's installed audio decoders. Start the backend and configure any models/API keys you need;
see [backend/README.md](./backend/README.md). For a physical device, replace
`10.0.2.2` with the development computer's LAN IP. For Windows desktop or an
iOS simulator, use `http://127.0.0.1:8000`.

Live inspection reports available analyses and marks missing model outputs
unavailable; it does not invent a valuation or audio diagnosis. With the car
damage model installed, photo analysis can run even if price/audio models are
missing. Engine audio is optional when no audio model is installed.

To test the report and PDF screens without trained models, enable **Demo mode
(simulated output)** on the report form. It generates random placeholder
valuation/audio values and clearly marks the report and PDF as simulated; it
does not analyze uploaded media and must not be used for real vehicle decisions.

### Optional code generation

If more generated files are introduced later, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🌿 Suggested Git Workflow

- main: production-ready stable branch
- dev: active development branch
- feature/<feature-name>: feature-specific work branches

Typical workflow:

```bash
git checkout dev
git pull origin dev
git checkout -b feature/your-feature-name
```

Then commit, push, and open a pull request targeting the dev branch.

---

## 🧩 Roadmap

Planned evolution of this project includes:

- vehicle image capture and upload flow,
- AI-powered damage classification,
- audio diagnostics integration,
- connecting report generation and PDF export to live inspection results,
- authentication and inspection history,
- production-ready architecture and testing coverage.

---

## 📘 Notes

This project is currently a structured starter and not yet a finished AI inspection product. The base app shell is ready for feature development and follows a scalable Flutter architecture foundation.
