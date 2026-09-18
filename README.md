# 🚗 AutoDoc AI

An AI-powered automated vehicle inspection system featuring 360° visual damage detection, engine sound audio diagnostics, and verified PDF report generation.

---

## 📌 Features

* **360° Visual Damage Detection:** AI-driven image analysis for vehicle exterior inspection.
* **Engine Audio Diagnostics:** Audio processing to identify engine anomalies.
* **Automated PDF Reports:** Quick generation of verified inspection summaries.
* **Clean Architecture:** Scalable codebase strictly separated into Data, Domain, and Presentation layers.

---

## 🛠️ Tech Stack & Architecture

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **Architecture:** Clean Architecture
* **State Management:** BLoC / Riverpod
* **Routing:** [GoRouter](https://pub.dev/packages/go_router)
* **Dependency Injection:** [GetIt](https://pub.dev/packages/get_it) & [Injectable](https://pub.dev/packages/injectable)

---

## 📂 Project Structure

```text
lib/
├── config/             # App configuration & Dependency Injection
├── core/               # Shared utilities, router, themes, network & errors
│   ├── constants/
│   ├── error/
│   ├── network/
│   ├── router/
│   ├── theme/
│   └── utils/
└── features/           # Feature-based modules (Clean Architecture)
    └── sample_feature/
        ├── data/       # Models, Repositories Implementation, Data Sources
        ├── domain/     # Entities, Use Cases, Repository Interfaces
        └── presentation/ # BLoC/Cubit, Screens, Widgets

## 🚀 Getting Started
Prerequisites
## Ensure you have the following installed: Flutter SDK, Git
## Clone the repository: git clone [https://github.com/SahanRathnaweera/AutoDoc-AI-.git](https://github.com/SahanRathnaweera/AutoDoc-AI-.git)
cd AutoDoc-AI-
## Get dependencies: flutter pub get
## Run code generation (if applicable): flutter pub run build_runner build --delete-conflicting-outputs
## Run the application: flutter run

## 🌿 Git Branching Strategy
## main: Production-ready stable code.
## dev: Active development branch.
## feature/<feature-name>: Individual feature branches created from dev.

Workflow for Contributors
## Pull the latest dev branch: git checkout dev && git pull origin dev
## Create your feature branch: git checkout -b feature/your-feature-name
## Commit and push your changes.
## Open a Pull Request (PR) targeting the dev branch for code review.
