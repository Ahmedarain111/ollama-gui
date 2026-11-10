# 🦙 Ollama GUI

> **A minimal, modern, and lightweight native desktop GUI for [Ollama](https://ollama.ai)** — built with Flutter Desktop (Linux, macOS, Windows). Pure native performance without the bundle bloat and memory footprint of Electron.

---

## ✨ Features at a Glance

### 🖥️ Real-time System Usage & VRAM Monitor
- **Top-Bar Hardware Meters:** Live monitoring of **CPU %**, **GPU %**, **RAM (used / total GB)**, and **VRAM**.
- **Auto-Detects Graphics Cards:** Compatible with NVIDIA (`nvidia-smi`), Intel i915/Xe sysfs frequency scaling, and AMD ROCm sysfs.
- **Ollama Active VRAM Tracking:** Automatically reads memory allocated to loaded models via `/api/ps`.
- **One-Click VRAM Unloader (`Eject`):** Eject loaded models immediately from memory (`keep_alive: 0`) with a single click.

### 💬 Editorial Chat Experience
- **Live Streaming:** Low-latency token streaming with live tokens/second generation speed and total token count indicators.
- **Document-Style Markdown:** Editorial prose typography with syntax-highlighted code blocks (Atom One theme), copy-to-clipboard buttons, and math rendering.
- **Stop Generation:** Immediate response cancellation without UI lockups.
- **Persistent Local Database:** Fast embedded SQLite persistence via [Drift](https://drift.simonbinder.eu/) with foreign key cascades and instant restore.

### 🎛️ Inference Parameters & System Prompt Tuning
- **Slide-out Tuning Panel:** Adjust inference settings per conversation without cluttering the chat view.
- **Controls:**
  - **System Prompt:** Root directive guiding role, tone, and formatting.
  - **Temperature Slider:** 0.00 – 2.00 (from deterministic logic to creative brainstorming).
  - **Context Window (`num_ctx`):** 2,048, 4,096, 8,192, 16,384, 32,768, or 65,536 tokens.
  - **Top-P (Nucleus Sampling):** 0.05 – 1.00.
  - **Repeat Penalty:** 1.00 – 2.00.
- **SQLite Persistence & Reset:** Settings automatically save to the database and can be reset to defaults at any time.

### 🖼️ Multimodal Vision Support
- **Image Attachments:** Select and attach `jpg`, `jpeg`, `png`, and `webp` images directly into the chat prompt.
- **Thumbnail Strip:** Preview attached images with click-to-remove badges above the prompt input.
- **Multimodal Models:** Full compatibility with vision models like `llama3.2-vision`, `llava`, `minicpm-v`, and `moondream`.
- **User Bubble Previews:** Displays attached thumbnails directly inside user message bubbles.

### 🔍 Conversation Search & Markdown Export
- **Live Title Search:** Instant fuzzy filtering of past conversations in the sidebar.
- **Markdown Export:** Export complete chats (with metadata, role headers, token stats, and image references) to `.md` files via desktop file picker or clipboard.

### 📦 Local Models & 30+ Model Catalog Browser
- **Dual-View Model Manager:**
  - **Installed Models:** Grid of downloaded models showing disk size, quantization level, family, and VRAM residency.
  - **Explore Library:** Curated catalog of 30+ popular and official Ollama models across 5 categories (**Reasoning**, **Coding**, **Vision**, **General**, and **Embedding**).
- **Search & Category Filtering:** Search models by name, publisher, category, or parameter size (e.g. `1.5b`, `7b`, `14b`, `70b`).
- **One-Click Pull:** Check install status at a glance (`Installed ✓` vs `Pull`) with pre-filled download dialogs and streaming progress bars.

### 🛠️ Modelfile Studio
- **Visual Model Variant Builder:**
  - Select base model from local inventory (`FROM`).
  - Configure target model tag (e.g. `my-assistant:latest`).
  - Set custom system prompts, temperature, context size, and stop tokens.
- **Reactive Modelfile Preview:** Live Dockerfile-syntax-highlighted code block reflecting parameters in real time with a copy button.
- **Build Console:** Live streaming build output from `/api/create`.
- **Direct Launch:** Instant *"Start Chat"* button upon successful compilation.

### 🎨 Modern Minimal Aesthetic & Smooth Ergonomics
- **Soft Slate Dark Theme:** Carefully balanced `#18191E` slate surfaces and hairline `#343642` borders designed to eliminate eye strain.
- **Interactive Navigation Rail:** Collapses to 56px to maximize workspace, expanding smoothly to 168px on hover to reveal descriptive labels.
- **Consistent Pointer Cursors & Hover Highlights:** Hand cursors (`SystemMouseCursors.click`) and subtle hover glows across all buttons, dropdowns, and cards.

---

## 🏗 Tech Stack

| Component | Library / Technology |
|---|---|
| **Framework** | [Flutter Desktop](https://flutter.dev/multi-platform/desktop) (Dart 3.x) |
| **State Management** | [Flutter Riverpod](https://riverpod.dev) |
| **Database** | [Drift](https://drift.simonbinder.eu/) + SQLite |
| **Networking & Streaming** | [Dio](https://pub.dev/packages/dio) (NDJSON stream decoding) |
| **Navigation** | [GoRouter](https://pub.dev/packages/go_router) |
| **Markdown & Code** | [flutter_markdown](https://pub.dev/packages/flutter_markdown) + [flutter_highlight](https://pub.dev/packages/flutter_highlight) |
| **File Handling** | [file_picker](https://pub.dev/packages/file_picker) |
| **Desktop Windowing** | [window_manager](https://pub.dev/packages/window_manager) |

---

## 📂 Project Structure

```
lib/
├── app.dart                          # App root with GoRouter configuration
├── core/
│   ├── models.dart                   # API data models (OllamaModel, ChatMessage, etc.)
│   ├── ollama_client.dart            # Dio client for Ollama REST & streaming endpoints
│   ├── providers.dart                # Global Riverpod providers
│   ├── system_usage.dart             # Real-time CPU, GPU, RAM, VRAM monitor service
│   └── theme.dart                    # Modern soft slate theme definitions
├── database/
│   ├── database.dart                 # Drift SQLite database schema and queries
│   └── database_provider.dart        # Riverpod database singleton
├── features/
│   ├── chat/                         # Chat workspace, sidebar, message list, input bar,
│   │                                 # media helper, and inference parameters drawer
│   ├── modelfile/                    # Modelfile Studio (visual builder & compiler)
│   ├── models/                       # Local model cards, 30+ model library, pull dialog
│   ├── settings/                     # Server configuration & appearance preferences
│   └── shell/                        # App shell, expanding nav rail, and top bar
└── shared/widgets/                   # Reusable UI widgets (SystemUsageBar, HoverIconButton,
                                      # StatusDot, EmptyState)
```

---

## 🚀 Getting Started

### Prerequisites

1. Install and launch **[Ollama](https://ollama.com)**:
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ollama serve
   ```
2. Install the **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (version 3.24+ recommended).

### Installation & Run

```bash
# 1. Clone the repository
git clone https://github.com/Ahmedarain111/ollama-gui.git
cd ollama-gui

# 2. Install dependencies
flutter pub get

# 3. (Optional) Run tests to verify setup
flutter test

# 4. Launch the application
flutter run -d linux   # Linux Desktop
flutter run -d macos   # macOS Desktop
flutter run -d windows # Windows Desktop
```

### Production Build

```bash
# Build Linux release bundle
flutter build linux --release

# Build macOS app bundle
flutter build macos --release

# Build Windows executable
flutter build windows --release
```

---

## 🧪 Testing & Code Quality

The project maintains 100% green test coverage on core features:

```bash
# Run static analysis
flutter analyze

# Run unit and widget test suite
flutter test
```

---

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
