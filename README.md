<div align="center">

# 🚨 RescueMesh

### *Zero-Connectivity. BLE Mesh Network. On-Device Edge AI Triage.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-7.0%2B-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
[![License](https://img.shields.io/badge/License-MIT-red.svg?style=for-the-badge)](LICENSE)

<br/><br/>

### 📲 **Direct Release APK Downloads**

[<img src="https://img.shields.io/badge/📲_DOWNLOAD_APK-ARM64--v8a_(56.7_MB)-2e7d32?style=for-the-badge&logo=android&logoColor=white" height="42"/>](https://github.com/Sh1sh1R017/RescueMesh/raw/main/releases/RescueMesh-arm64-v8a-release.apk)
[<img src="https://img.shields.io/badge/💻_DOWNLOAD_APK-x86__64_Emulator_(53.8_MB)-1565c0?style=for-the-badge&logo=android&logoColor=white" height="42"/>](https://github.com/Sh1sh1R017/RescueMesh/raw/main/releases/RescueMesh-x86_64-release.apk)


<br/><br/>

**RescueMesh** is an open-source, emergency disaster response platform designed to operate in zero-connectivity environments where cellular towers, internet infrastructure, and power grids have failed.

It combines **peer-to-peer Bluetooth Low Energy (BLE) store-and-forward mesh networking** with an **on-device neural AI triage engine (llama.cpp / Qwen2.5)**, interactive offline maps, and automated **FEMA ICS-213 Incident Command System report generation**.

[Features](#-core-capabilities) • [Architecture](#%EF%B8%8F-system-architecture) • [Edge AI](#-on-device-edge-ai-engine) • [Installation & APK](#-installation--apk-deployment) • [Docker](#-docker-environment) • [FEMA Reporting](#-fema-ics-213-compliance)

</div>

---

## ⚡ Core Capabilities

- 📡 **Off-Grid P2P BLE Mesh Networking**: Continuous multi-hop store-and-forward packet relay across nearby mobile nodes with zero central infrastructure.
- 🧠 **On-Device Edge AI Triage**: Quantized neural LLM inference (`fllama` / `llama.cpp` C++ engine running Qwen2.5 GGUF) streaming up to 25 tokens/sec completely offline.
- 🚑 **Rule-Based Emergency Knowledge Base**: Instant ($<10\text{ms}$) multi-weighted search across 15+ first-aid and survival protocols (bleeding control, tear gas, hypothermia, low oxygen, legal rights).
- 🗺️ **Offline Map & Dynamic GPS Localization**: Full offline vector tile mapping with live device GPS auto-centering, hazard pinning, and resource location tracking.
- 📋 **Automated FEMA ICS-213 Report Engine**: Compiles emergency alerts into standard Incident Command System reports for official responder handovers.
- 🛡️ **Zero-Cloud Sovereign Privacy**: Zero telemetry, zero analytics, zero external API dependencies, and zero accounts.

---

## 🏗️ System Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                             RESCUEMESH APP                                  │
│                                                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │  Home / SOS  │   │  Offline Map │   │  Mesh Feed   │   │  Safety AI   │  │
│  │  Dashboard   │   │  (Tile Cache)│   │  (Relay Log) │   │  (LLM / KB)  │  │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘   └──────┬───────┘  │
│         │                  │                  │                  │          │
│  ┌──────┴──────────────────┴──────────────────┴──────────────────┴───────┐  │
│  │                   Domain & Application Logic Layer                    │  │
│  │   HardwareProfiler  •  SyncEngine  •  LlmInference  •  LocationService│  │
│  └──────┬──────────────────┬──────────────────┬──────────────────┬───────┘  │
│         │                  │                  │                  │          │
│  ┌──────┴───────┐   ┌──────┴───────┐   ┌──────┴───────┐   ┌──────┴───────┐  │
│  │  SQLite DB   │   │   BLE Mesh   │   │  llama.cpp   │   │  FEMA ICS    │  │
│  │  (WAL Mode)  │   │  (P2P Relay) │   │ (C++ Native) │   │ (213 Engine) │  │
│  └──────────────┘   └──────────────┘   └──────────────┘   └──────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🧠 On-Device Edge AI Engine

RescueMesh hosts a **multi-tiered neural triage architecture** powered by GGUF quantization. Inference runs natively on-device via C++ bindings without internet access.

### Hardware Tier Allocation

| Tier | Target Model | Model Size | RAM Requirement | Execution Speed |
|:---:|:---:|:---:|:---:|:---:|
| **Base Failsafe** | `First-Aid Knowledge Base` | 0 MB | Any ($\ge 2\text{ GB}$) | Instant ($< 10\text{ ms}$) |
| **Tier 0** | `Qwen2.5-0.5B-Instruct` | ~490 MB | $\ge 4\text{ GB}$ | $\approx 25\text{ tok/s}$ |
| **Tier 1** | `Qwen2.5-1.5B-Instruct` | ~1.1 GB | $\ge 6\text{ GB}$ | $\approx 18\text{ tok/s}$ |
| **Tier 2** | `Qwen2.5-3B-Instruct` | ~1.9 GB | $\ge 8\text{ GB}$ | $\approx 12\text{ tok/s}$ |

- **Thermal Thread Capping**: Thread count is bounded to physical CPU performance cores to eliminate thermal throttling during extended field operations.
- **Resumable GGUF Transfers**: Range-header HTTP support allows seamless model synchronization across mesh gateway nodes.

---

## 📡 Peer-to-Peer BLE Mesh Protocol

The custom BLE mesh protocol enables decentralized store-and-forward packet transmission:

```json
{
  "msgId": "sos_1784633335412",
  "originNodeId": "e3f1a8b9",
  "type": 1,
  "priority": 3,
  "timestamp": 1784633335412,
  "ttl": 86400000,
  "hopCount": 0,
  "payload": "[CRITICAL SOS] LAT: 27.7172, LNG: 85.3240"
}
```

- **Packet Priorities**: `0 = NORMAL`, `1 = HIGH`, `2 = URGENT`, `3 = CRITICAL (SOS)`.
- **$O(1)$ LRU Deduplication**: Bounded in-memory hash verification rejects duplicate packet broadcasts before touching storage.
- **SQLite WAL Storage**: SQLite WAL mode (`PRAGMA journal_mode = WAL;`) ensures zero-lock concurrency during simultaneous scanning and UI reads.

---

## 📋 FEMA ICS-213 Compliance

RescueMesh includes an integrated **FEMA Incident Command System (ICS-213) Generator** that formats field alerts, SOS distress calls, and hazard reports into standard incident logs.

- **Markdown Document Preview**: Renders clean Markdown document tables directly within the application preview.
- **Official HTML Markup Export**: One-tap copy for HTML code export, suitable for printing or submitting to emergency command centers.

---

## 📲 Installation & APK Deployment

### Direct Release APK Installation
Pre-compiled production binaries are available in the [`releases/`](RELEASES.md) directory:

1. Download [`releases/RescueMesh-arm64-v8a-release.apk`](releases/RescueMesh-arm64-v8a-release.apk).
2. Transfer to your Android device via USB or ADB:
   ```bash
   adb install releases/RescueMesh-arm64-v8a-release.apk
   ```

### Building from Source

```bash
# 1. Clone repository
git clone https://github.com/Sh1sh1R017/RescueMesh.git
cd RescueMesh

# 2. Fetch dependencies
flutter pub get

# 3. Build Production Release APK
flutter build apk --release
```

---

## 🐳 Docker Environment

RescueMesh provides a containerized build environment with pre-configured Android SDK 36, NDK 28, and Flutter toolchains.

Build the release APK using **Docker Compose**:

```bash
docker compose up --build
```

The compiled APK will be output automatically to:
`./build/app/outputs/flutter-apk/app-release.apk`

---

## 📁 Repository Structure

```text
RescueMesh/
├── android/                    # Android native Gradle configuration & C++ NDK setup
├── lib/
│   ├── core/                   # Design system tokens, dark theme, time utilities
│   ├── data/
│   │   ├── database/           # SQLite database schema, WAL mode configuration
│   │   ├── knowledge_base/     # 15+ offline medical & survival protocols
│   │   ├── mesh/               # BLE advertisement, scanning, GATT 133 connection lock
│   │   └── repository/         # Message & hazard data repositories
│   ├── domain/
│   │   ├── models/             # MeshPacket, FirstAidTopic domain models
│   │   └── services/           # HardwareProfiler, LlmInference, FemaReportGenerator
│   ├── presentation/
│   │   ├── ai_chat/            # Dual-mode AI Triage screen & GGUF model manager
│   │   ├── dashboard/          # SOS button, quick actions, FEMA ICS-213 preview
│   │   ├── feed/               # Off-grid live mesh feed
│   │   ├── map/                # Offline Map screen & dynamic GPS tracker
│   │   └── resources/          # Shared field resource stream
│   └── providers/              # Riverpod state providers
├── Dockerfile                  # Containerized Android + NDK + Flutter build context
├── docker-compose.yml          # One-command Docker build configuration
└── RELEASES.md                 # Production APK deployment guide
```

---

## 🛡️ License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for details.

---

<div align="center">

**Built for extreme off-grid emergency conditions when infrastructure fails.**

</div>
