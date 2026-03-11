# Android aarch64 Build Guide

This guide explains how to build OpenFang for Android aarch64 (ARM64) architecture.

## Prerequisites

- Docker installed and running
- Sufficient disk space for Docker images and build artifacts

## Quick Start

### Windows (PowerShell)

```powershell
# Run the extraction script
.\scripts\extract-android-binaries.ps1

# Or skip the Docker build if you already have the image
.\scripts\extract-android-binaries.ps1 -SkipBuild

# Specify a custom output directory
.\scripts\extract-android-binaries.ps1 -OutputDir ".\my-build-output"
```

### Linux/Mac (Bash)

```bash
# Make the script executable
chmod +x scripts/extract-android-binaries.sh

# Run the extraction script
./scripts/extract-android-binaries.sh

# Or skip the Docker build if you already have the image
SKIP_BUILD=true ./scripts/extract-android-binaries.sh

# Specify a custom output directory
OUTPUT_DIR="./my-build-output" ./scripts/extract-android-binaries.sh
```

## Manual Build Steps

If you prefer to build manually:

### 1. Build the Docker Image

```bash
docker build -f Dockerfile.android-build -t openfang-android-build:latest .
```

### 2. Extract Binaries

```bash
# Create a temporary container
CONTAINER_ID=$(docker create openfang-android-build:latest)

# Copy binaries
docker cp $CONTAINER_ID:/usr/local/bin/openfang ./openfang
docker cp $CONTAINER_ID:/usr/local/bin/openfang-api ./openfang-api

# Cleanup
docker rm $CONTAINER_ID
```

### 3. Verify Binaries

```bash
# Check file type (may show "unknown" for cross-compiled binaries)
file openfang
file openfang-api

# Create checksums
sha256sum openfang openfang-api > checksums.txt
```

## Using the Binaries on Android

1. **Transfer to Device**
   ```bash
   adb push openfang /data/local/tmp/
   adb push openfang-api /data/local/tmp/
   ```

2. **Make Executable**
   ```bash
   adb shell
   cd /data/local/tmp
   chmod +x openfang openfang-api
   ```

3. **Run**
   ```bash
   # Run OpenFang CLI
   ./openfang --help

   # Run OpenFang API
   ./openfang-api --help
   ```

## Dockerfile Structure

The `Dockerfile.android-build` uses a multi-stage build:

- **Stage 1 (builder)**: Compiles the project using cross-rs for aarch64-linux-android
- **Stage 2 (export)**: Minimal scratch stage for binary extraction
- **Stage 3 (final)**: Alpine-based image with utilities for verification

## Troubleshooting

### Build Failures

If the build fails, check:
1. Docker is running properly
2. You have sufficient disk space
3. The project files are correctly copied

### Binary Not Found

If binaries are not extracted:
1. Verify the build completed successfully
2. Check the Docker container logs
3. Ensure the binary names match what's being copied

### Permission Denied on Android

If you get permission errors:
```bash
adb shell
su  # or use termux without su
cd /data/local/tmp
chmod +x openfang openfang-api
```

## Build Artifacts

The following files will be created in the output directory:

- `openfang` - Main CLI binary
- `openfang-api` - API server binary
- `checksums.txt` - SHA256 checksums of the binaries

## Architecture Information

- **Target**: aarch64-linux-android
- **Compiler**: cross-rs with ghcr.io/cross-rs/aarch64-linux-android:main image
- **TLS**: rustls (no OpenSSL dependency)
- **Dependencies**: All dependencies are cross-compiled for Android

## Additional Resources

- [cross-rs Documentation](https://github.com/cross-rs/cross)
- [Android NDK](https://developer.android.com/ndk)
- [OpenFang Documentation](https://github.com/RightNow-AI/openfang)