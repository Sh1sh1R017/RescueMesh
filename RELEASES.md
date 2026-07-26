# 📦 RESCUEMESH OFFICIAL RELEASE APKs

**RELEASE VERSION**: v1.0.0-release  
**BUILD DATE**: July 26, 2026  
**TARGET PLATFORM**: Android 7.0+ (API 24 to 36)  
**STATUS**: 🟢 **COMPILED & PUBLISHED TO GITHUB**  

---

## 🚀 DOWNLOAD RELEASE APKs DIRECTLY FROM REPOSITORY

The compiled production APK binaries are committed directly to this GitHub repository in the [`releases/`](releases/) directory:

| Architecture | APK File | Size | Compatible Devices |
|---|---|---|---|
| 📱 **ARM 64-bit** (Standard) | [`RescueMesh-arm64-v8a-release.apk`](releases/RescueMesh-arm64-v8a-release.apk) | **56.7 MB** | 95%+ of modern Android smartphones |
| 💻 **x86_64** (Emulator) | [`RescueMesh-x86_64-release.apk`](releases/RescueMesh-x86_64-release.apk) | **53.8 MB** | Android Studio emulators & x86 tablets |


---

## 📲 HOW TO INSTALL ON YOUR PHONE

### Method A: Direct Download & Install
1. Open this repository on your phone browser.
2. Tap [`RescueMesh-arm64-v8a-release.apk`](releases/RescueMesh-arm64-v8a-release.apk) and tap **Download Raw**.
3. Open your phone's **Downloads** folder and tap the `.apk` file to install.

### Method B: ADB Install via USB
```bash
adb install releases/RescueMesh-arm64-v8a-release.apk
```

---

## 🛠️ REBUILDING FROM SOURCE

To rebuild the APK binaries at any time:
```bash
# Split per architecture (for GitHub tracking)
flutter build apk --release --split-per-abi

# Or via Docker
docker compose up --build
```
