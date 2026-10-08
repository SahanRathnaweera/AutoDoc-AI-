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
flutter run
```

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
- PDF report export,
- authentication and inspection history,
- production-ready architecture and testing coverage.

---

## 📘 Notes

This project is currently a structured starter and not yet a finished AI inspection product. The base app shell is ready for feature development and follows a scalable Flutter architecture foundation.
