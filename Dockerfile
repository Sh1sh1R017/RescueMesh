# ==============================================================================
# RescueMesh Production Docker Builder
# Builds zero-connectivity Flutter Android APK & runs automated analysis
# Automatically accepts all Android SDK & NDK (28.0.12433566) licenses
# ==============================================================================

FROM ubuntu:22.04 AS builder

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set environment variables
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools/bin:/opt/flutter/bin"
ENV FLUTTER_SUPPRESS_ANALYTICS=true

# Install system dependencies & OpenJDK 17
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk-headless \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Android Command-line tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
    && curl -sS https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -o /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip

# Auto-accept all Android SDK & NDK licenses and install build components
RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" "ndk;28.0.12433566" "cmake;3.31.0"

# Install Flutter SDK (Stable Channel)
RUN git clone --depth 1 -b stable https://github.com/flutter/flutter.git /opt/flutter \
    && flutter config --no-analytics \
    && flutter doctor

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Run Flutter pub get & analysis
RUN flutter pub get \
    && flutter analyze

# Build Release APK
CMD ["flutter", "build", "apk", "--release"]
