# Ollama GUI

A desktop chat client and model manager for Ollama, built with Flutter for Linux, macOS, and Windows.

## Quick Start

### Prerequisites

- [Ollama](https://ollama.com)
- [Flutter SDK](https://flutter.dev) (version 3.24 or later)

On Linux, install the desktop build dependencies:

```bash
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libayatana-appindicator3-dev
```

### Installation and Run

Clone the repository and install dependencies:

```bash
git clone https://github.com/Ahmedarain111/ollama-gui.git
cd ollama-gui
flutter pub get
```

Launch the application:

```bash
# Linux
flutter run -d linux

# macOS
flutter run -d macos

# Windows
flutter run -d windows
```

If the local Ollama daemon is not running, the application attempts to launch `ollama serve` automatically on startup if `ollama` is in your PATH.

## Usage

- **Chat with models:** Select an installed model, enter a prompt, and view streaming responses. Attach image files (`.jpg`, `.png`, `.webp`) to chat with vision-capable models.
- **Manage models:** In the Models view, browse local models or the catalog library. Download new models or delete existing ones from disk.
- **Tune inference parameters:** Open the parameters drawer from any active chat to configure the system prompt, temperature, context size (`num_ctx`), top-p, and repetition penalty.
- **Build custom models:** In Modelfile Studio, choose a base model, specify directives and parameters, and compile the new model into Ollama.
- **Export conversations:** Use the chat toolbar menu to export the active conversation and its generation metrics to a Markdown file.

## Configuration

Settings are accessible from the Settings view within the app and persist across launches in local storage.

| Setting | Default | Description |
|---|---|---|
| Ollama Server URL | `http://localhost:11434` | Endpoint of the Ollama server |
| Theme Mode | Dark | Application theme (Dark or Light) |

## Features

- Token streaming with generation speed (tokens/second) and token counter metrics.
- Image input support for multimodal vision models.
- Per-conversation system prompt and parameter controls.
- Modelfile Studio for compiling custom model variants from local base models.
- Model catalog browser with category filters (Reasoning, Coding, Vision, General, Embedding).
- Top-bar hardware monitor for CPU, GPU, RAM, and Ollama VRAM allocation, with one-click model unloading.

## Project Structure

```
lib/
├── core/         # API client, process manager, and system usage monitors
├── database/     # Drift SQLite schema, migrations, and providers
├── features/
│   ├── chat/     # Chat workspace, message list, input bar, and tuning drawer
│   ├── modelfile/# Modelfile Studio builder and compiler
│   ├── models/   # Model inventory and catalog browser
│   ├── settings/ # Server connection and theme configuration
│   └── shell/    # App shell, navigation rail, and hardware status bar
└── shared/       # Reusable UI widgets
```

## Development

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Regenerate database code after schema changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Build production executables:

```bash
# Linux
flutter build linux --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release
```

## Troubleshooting

- **Ollama server unreachable:** Verify that `ollama serve` is running. If Ollama runs on a different port or a remote machine, update the server URL in Settings.
- **GPU or VRAM usage not detected:** On Linux, GPU utilization reads from `nvidia-smi` (NVIDIA) or `/sys/class/drm` sysfs entries (AMD and Intel). When unsupported hardware or drivers are present, the monitor displays active model VRAM reported by the Ollama API instead.
