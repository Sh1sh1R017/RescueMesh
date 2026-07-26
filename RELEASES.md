# 📦 RESCUEMESH RELEASE ARTIFACTS & INSTALLATION GUIDE

**RELEASE VERSION**: v1.0.0-release  
**BUILD DATE**: July 26, 2026  
**TARGET PLATFORM**: Android 7.0+ (API 24 to 36)  
**ARCHITECTURE**: `arm64-v8a`, `armeabi-v7a`, `x86_64`  
**APK FILE SIZE**: ~127.3 MB (Includes native `llama.cpp` Edge AI engine & C++ libraries)  
**STATUS**: 🟢 **COMPILED & VERIFIED SUCCESSFUL**  

---

## 🚀 LOCAL RELEASE APK LOCATION

The compiled production release APK is stored locally at:
```text
d:\RescueMesh-main\releases\RescueMesh-v1.0.0-release.apk
d:\RescueMesh-main\build\app\outputs\flutter-apk\app-release.apk
```

---

## 📲 HOW TO INSTALL ON YOUR PHONE

### Option A: Transfer via USB Cable
1. Connect your Android phone to your PC via USB cable.
2. Select **File Transfer** on your phone notification bar.
3. Copy `d:\RescueMesh-main\releases\RescueMesh-v1.0.0-release.apk` to your phone's **Download** folder.
4. On your phone, open **Files / Downloads**, tap `RescueMesh-v1.0.0-release.apk`, and tap **Install**.

### Option B: Install via ADB (Command Line)
With USB Debugging enabled on your phone:
```bash
adb install releases/RescueMesh-v1.0.0-release.apk
```

---

## 🛠️ RE-BUILDING THE RELEASE APK

To rebuild the APK at any time on your machine:
```bash
# Method 1: Using Flutter
flutter build apk --release

# Method 2: Using Docker (Containerized Build)
docker compose up --build
```
