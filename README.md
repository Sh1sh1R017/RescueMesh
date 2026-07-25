<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-success?style=for-the-badge"/>
<img src="https://img.shields.io/badge/License-MIT-red?style=for-the-badge"/>
<img src="https://img.shields.io/badge/AI-100%25%20Offline-blueviolet?style=for-the-badge&logo=brain"/>

<br/><br/>

# 🚨 RescueMesh

### _Disaster-Ready. Mesh-Connected. AI-Powered. 100% Offline._

> A cross-platform Flutter application for disaster response, protest safety, and emergency coordination — with on-device AI triage, BLE mesh networking, offline maps, and a zero-cloud architecture.

</div>

---

## ⚡ Why RescueMesh?

When infrastructure fails — cell towers go down, internet is cut, power is out — **RescueMesh keeps working**. It is built for the moments when everything else fails:

- 🔴 **Natural disasters** (earthquakes, floods, wildfires)
- 🟠 **Civil unrest & protests** (tear gas, crowd crush, arrest)
- 🟡 **Remote expeditions** (zero connectivity environments)
- 🟢 **Mass-casualty events** (triage, SOS broadcast, FEMA reporting)

No Firebase. No cloud. No accounts. **Just pure, life-saving capability on the device in your pocket.**

---

## 🏗️ Architecture Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                         RescueMesh App                             │
│                                                                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ Dashboard│  │Offline   │  │  Mesh    │  │  Safety AI       │  │
│  │  (SOS)   │  │  Map     │  │  Feed    │  │  (LLM + KB)      │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────────┘  │
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                  Domain / Service Layer                    │   │
│  │  HardwareProfiler │ ModelDownload │ LlmInference │ BLE     │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │            State Management: flutter_riverpod v2           │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐    │
│  │  SQLite DB   │  │  BLE Mesh    │  │  llama.cpp (fllama)   │    │
│  │  (SQFlite)   │  │  (BLE + ADV) │  │  GGUF on-device LLM  │    │
│  └──────────────┘  └──────────────┘  └──────────────────────┘    │
└────────────────────────────────────────────────────────────────────┘
```

**State Management:** Riverpod v2 (`AsyncNotifier`, `StreamProvider`, `FutureProvider`)  
**Data Layer:** SQLite via SQFlite · No cloud database · No analytics  
**AI Layer:** llama.cpp via `fllama` + pure-Dart keyword Knowledge Base  
**Network Layer:** Bluetooth Low Energy (BLE) peripheral + scanner mesh  

---

## 🧠 Edge AI — Local LLM Triage Assistant

The crown feature: a **fully offline LLM inference engine** running Qwen2.5 GGUF models directly on the device, with a multi-tier architecture that adapts to available RAM.

### Base Guarantee Architecture

| Device RAM | Model Tier | File Size | Always Available |
|:----------:|:----------:|:---------:|:----------------:|
| Any | Knowledge Base (KB) | 0 MB | ✅ Yes — instant |
| ≥ 4 GB | 0.5B GGUF (Qwen2.5) | ~490 MB | After download |
| ≥ 6 GB | 1.5B GGUF (Qwen2.5) | ~1.1 GB | After download |
| ≥ 8 GB | 3B GGUF (Qwen2.5) | ~1.9 GB | After download |

**Failsafe cascade:** `3B → 1.5B → 0.5B → Knowledge Base`  
If a model runs out of memory or fails to load, it **automatically falls back** to the next tier. The Knowledge Base (14 comprehensive medical/safety topics, ~200ms response) is always the last resort.

### How Model Downloads Work

Models are served from a **local mesh router or peer device** — not the internet. The app connects to a configurable mesh IP (e.g. `http://192.168.4.1:8080/models/`) and performs **HTTP Range-header resumable downloads**, so a connection drop mid-download never loses progress.

```
Field Device ──BLE──▶ Mesh Router ◀──WiFi──▶ RescueMesh App
                      (serves GGUF)           (downloads + runs)
```

### Prompt Engineering

All tiers use the **Qwen2.5 chat template** for structured, concise medical guidance:

```
<|im_start|>system
You are an offline disaster medical triage assistant.
Provide a concise, bulleted list of actionable steps...
<|im_end|>
<|im_start|>user
{query}
<|im_end|>
<|im_start|>assistant
```

Stop tokens (`<|im_end|>`, `<|endoftext|>`) prevent infinite generation loops on resource-constrained devices.

---

## 📡 BLE Mesh Network

RescueMesh builds a **peer-to-peer Bluetooth mesh** without any infrastructure:

- Every device acts as both **peripheral** (advertising) and **central** (scanning)
- Messages carry a `TTL` field and `hopCount` — packets relay across multiple hops
- **Priority levels:** `0=NORMAL`, `1=HIGH`, `2=URGENT`, `3=CRITICAL (SOS)`
- SOS packets broadcast your GPS coordinates with 24-hour TTL
- Incoming high-priority messages trigger foreground alerts with a **VIEW** action

```dart
MeshPacket(
  msgId: 'sos_${timestamp}',
  type: 1,        // SOS
  priority: 3,    // CRITICAL
  ttl: 86400000,  // 24 hours
  payload: locationString,
)
```

---

## 🗺️ Offline Map

Built on `flutter_map` + `latlong2` with **local tile providers** — no Mapbox, no Google Maps API key required. Tiles can be bundled in-app or served from a local mesh device.

---

## 🚑 Knowledge Base — 14 Offline Safety Topics

The built-in, always-available Knowledge Base covers:

| Category | Topics |
|----------|--------|
| **Protest / Civil Unrest** | Tear Gas & Pepper Spray, Rubber Bullet Wounds, Police Arrest & Rights, Crowd Crush |
| **Medical Emergencies** | Severe Bleeding, CPR & Cardiac Arrest, Heat Stroke & Dehydration, Fractures & Sprains |
| **Environmental** | Burns, Electrical Injuries, Drowning & Near-Drowning |
| **Psychological** | Panic Attack, Trauma & Shock |
| **Field Improvisation** | Improvised Materials Guide (sanitary pads, cling wrap, plastic bags) |

Search uses **multi-keyword weighted scoring** (exact match +3, partial +2, keyword-in-phrase +1) for fast, relevant results with no internet.

---

## 🔋 Battery & Performance

- Thread count is capped at `physicalCores - 1` to leave headroom for the UI
- `useMlock: false` on budget devices to avoid OOM crashes
- `EnergyOptimizer` service manages background scan intervals based on battery level
- Model context size: `2048 tokens` — tuned for edge hardware

---

## 📁 Project Structure

```
lib/
├── core/
│   └── theme/              # Dark + light theme system
├── data/
│   └── mesh/               # BLE sync engine, packet routing
├── domain/
│   ├── models/             # MeshPacket, data models
│   └── services/
│       ├── hardware_profiler_service.dart   # RAM profiling, model tier routing
│       ├── model_download_service.dart      # Resumable mesh downloads
│       ├── llm_inference_service.dart       # fllama GGUF inference engine
│       ├── first_aid_llm_service.dart       # Offline knowledge base
│       ├── energy_optimizer.dart            # Battery management
│       ├── location_service.dart            # GPS for SOS
│       └── vision_analyzer_service.dart     # MLKit image analysis
├── presentation/
│   ├── ai_chat/
│   │   ├── ai_chat_screen.dart             # Dual-mode chat UI
│   │   └── llm_settings_screen.dart        # Model download & settings
│   ├── dashboard/                          # Home + SOS button
│   ├── feed/                               # Mesh message feed
│   ├── map/                                # Offline map view
│   ├── resources/                          # First-aid resources
│   └── widgets/                            # Shared widgets (SOS button)
└── providers/
    ├── llm_provider.dart                   # All LLM Riverpod state
    ├── mesh_provider.dart                  # BLE mesh state
    ├── message_provider.dart               # Message feed state
    └── device_identity_provider.dart       # Node ID management
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.x |
| Dart | ≥ 3.0.0 |
| Android SDK | 35+ |
| Android NDK | 28.0.12433566 |
| CMake | 3.31.0+ |

> **Note:** The NDK and CMake versions are required by `fllama` (llama.cpp) to compile native GGUF inference code.

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/Sh1sh1R017/RescueMesh.git
cd RescueMesh

# 2. Install Flutter dependencies
flutter pub get

# 3. Run on Android device (emulator will not run LLM efficiently)
flutter run --release
```

### Setting Up LLM Models

1. Launch the app → tap **Safety AI** tab
2. Tap the **⚙ Settings** button in the top-right
3. Enter your mesh server URL (e.g. `http://192.168.4.1:8080/models/`)
4. Download the **Base Model (0.5B)** — always the first step
5. Tap **Load Best Available Model**
6. Toggle to 🔵 **Local LLM Mode** in the chat screen

> **Serving models locally:** Any HTTP server hosting the GGUF files works. You can use Python's built-in server: `python -m http.server 8080` in the folder containing the GGUF files.

### Model Download Links (GGUF Q4_K_M)

| Model | HuggingFace Link | Size |
|-------|-----------------|------|
| Qwen2.5-0.5B-Instruct | [Download](https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF) | ~490 MB |
| Qwen2.5-1.5B-Instruct | [Download](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF) | ~1.1 GB |
| Qwen2.5-3B-Instruct | [Download](https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF) | ~1.9 GB |

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management (v2 AsyncNotifier API) |
| `fllama` | llama.cpp Flutter binding for GGUF inference |
| `flutter_blue_plus` | BLE central (scanning) |
| `flutter_ble_peripheral` | BLE peripheral (advertising) |
| `flutter_map` | Offline tile-based mapping |
| `dio` | HTTP downloads with Range header (resumable) |
| `sqflite` | Local SQLite database |
| `device_info_plus` | Device model identification |
| `path_provider` | Local file storage paths |
| `geolocator` | GPS for SOS broadcast |
| `battery_plus` | Battery-aware power management |
| `permission_handler` | Runtime permissions |
| `google_mlkit_image_labeling` | On-device image analysis |

---

## 🛡️ Privacy & Security

- ✅ **Zero telemetry** — no analytics, no crash reporting to external servers
- ✅ **Zero cloud** — no Firebase, no AWS, no external APIs
- ✅ **Zero accounts** — no login, no signup, no data collection
- ✅ **Local-first** — all AI inference runs on-device
- ✅ **Mesh-only networking** — BLE packets never touch the internet

---

## 🤝 Contributing

Contributions are welcome! Areas where help is most needed:

- 🗺️ **Offline map tiles** — bundling regional tile sets
- 📡 **Mesh protocol** — improving multi-hop routing reliability  
- 🧠 **Knowledge Base** — expanding medical/safety topics
- 🌐 **Localisation** — translating to local languages for disaster zones
- 🔋 **Battery optimization** — aggressive power management on BLE scans

Please open an issue before submitting a large PR so we can discuss the approach.

---

## 📄 License

```
MIT License

Copyright (c) 2025 Sh1sh1R017

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

<div align="center">

**Built for the moments when everything else fails.**

*If this project saves even one life, it was worth building.*

⭐ Star this repo if you believe in offline-first, privacy-respecting emergency tools.

</div>
