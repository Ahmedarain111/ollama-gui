# 🦙 Ollama GUI

> A lightweight, cross-platform desktop GUI for [Ollama](https://ollama.ai) built with Flutter and Material 3.

---

## ⚡ Highlights

- **Lightweight & Fast**: Pure native desktop UI without the memory and bundle bloat of Electron.
- **Cross-Platform**: Designed for Linux, macOS, and Windows.
- **Streaming Tokens**: Real-time token streaming with live tokens/second metrics.
- **Model Management**: Browse local models, pull new models from the registry with live progress, inspect Modelfiles, and monitor VRAM usage.
- **Markdown & Code Highlighting**: Syntax-highlighted code blocks with quick-copy support.
- **Persistent Local History**: Fast, embedded SQLite storage via Drift.
- **Customizable**: Dark, Light, and System Material 3 themes with connection health indicators.

---

## 🏗 Tech Stack

- **Framework**: [Flutter Desktop](https://flutter.dev/multi-platform/desktop)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Local Database**: [Drift](https://drift.simonbinder.eu/) (SQLite)
- **HTTP & Streaming**: [Dio](https://pub.dev/packages/dio) (SSE streaming)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Window Management**: [window_manager](https://pub.dev/packages/window_manager)

---

## 🚀 Getting Started

### Prerequisites

1. Ensure **[Ollama](https://ollama.com)** is installed and running (`http://localhost:11434`).
2. Ensure **Flutter 3.x+** is installed on your system.

### Running the App

```bash
# Clone the repository
git clone https://github.com/Ahmedarain111/ollama-gui.git
cd ollama-gui

# Fetch dependencies
flutter pub get

# Generate database and serialization code (if needed)
dart run build_runner build --delete-conflicting-outputs

# Run on your desktop platform
flutter run -d linux   # On Linux
flutter run -d windows # On Windows
flutter run -d macos   # On macOS
```

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
