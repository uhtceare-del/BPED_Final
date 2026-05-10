# ============================================================
# Stage 1: Flutter / Android tooling
# Used for CI, debug web launches, and release builds.
# ============================================================

FROM ubuntu:22.04 AS tooling

# Prevent interactive prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# Flutter version — keep this aligned with the project SDK constraints
ENV FLUTTER_VERSION=3.41.5
ENV FLUTTER_HOME=/opt/flutter
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH="${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# ── System dependencies ──────────────────────────────────────
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    wget \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Flutter SDK ───────────────────────────────────────────────
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
    https://github.com/flutter/flutter.git ${FLUTTER_HOME}

# ── Android SDK ───────────────────────────────────────────────
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
        -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-extracted && \
    mv /tmp/cmdline-tools-extracted/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# Accept licenses and install required SDK packages
RUN yes | sdkmanager --licenses > /dev/null 2>&1 && \
    sdkmanager \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0"

# Pre-cache Flutter artifacts after Android tooling is present
RUN flutter config --no-analytics \
    && flutter config --enable-web \
    && flutter precache --web --android \
    && flutter doctor

WORKDIR /app

# Copy pubspec files first for layer caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the source
COPY . .

# Default command for CI/tooling usage
CMD ["flutter", "analyze"]

# ============================================================
# Stage 2: Build production Flutter web bundle
# ============================================================

FROM tooling AS web-build

RUN test -f .env || (echo "Missing .env. Copy .env.example to .env before building." && exit 1)

RUN flutter build web --release

# ============================================================
# Stage 3: Production runtime for web bundle
# ============================================================

FROM nginx:alpine AS web-prod

COPY --from=web-build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
