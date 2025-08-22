#!/bin/bash

# SherpaONNX TTS Framework Setup Script
# This script handles downloading or building the required XCFrameworks

set -e  # Exit on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XCFRAMEWORKS_DIR="$SCRIPT_DIR/XCFrameworks"
EXTERNAL_DIR="$SCRIPT_DIR/../../../EXTERNAL"

echo "🚀 Setting up SherpaONNX TTS Frameworks..."

# Check if XCFrameworks already exist
if [ -d "$XCFRAMEWORKS_DIR/sherpa-onnx.xcframework" ] && [ -d "$XCFRAMEWORKS_DIR/onnxruntime.xcframework" ]; then
    echo "✅ XCFrameworks already exist. Verifying integrity..."

    # Quick integrity check
    if [ -f "$XCFRAMEWORKS_DIR/sherpa-onnx.xcframework/Info.plist" ] &&
       [ -f "$XCFRAMEWORKS_DIR/onnxruntime.xcframework/Info.plist" ]; then
        echo "✅ Framework integrity verified. Setup complete!"
        exit 0
    else
        echo "⚠️  Framework integrity check failed. Rebuilding..."
        rm -rf "$XCFRAMEWORKS_DIR"
    fi
fi

# Create XCFrameworks directory
mkdir -p "$XCFRAMEWORKS_DIR"

# Option 1: Try to download pre-built frameworks (if available)
echo "🔍 Checking for pre-built frameworks..."

# Check if we have a download URL or shared storage
DOWNLOAD_URL="${SHERPA_FRAMEWORKS_URL:-}"
if [ -n "$DOWNLOAD_URL" ]; then
    echo "📥 Downloading pre-built frameworks from: $DOWNLOAD_URL"
    # Download and extract frameworks
    curl -L "$DOWNLOAD_URL" | tar -xz -C "$XCFRAMEWORKS_DIR"

    if [ $? -eq 0 ]; then
        echo "✅ Successfully downloaded pre-built frameworks!"
        exit 0
    else
        echo "❌ Download failed. Falling back to local build..."
    fi
fi

# Option 2: Build from source
echo "🔨 Building frameworks from source..."

# Check prerequisites
if ! command -v cmake &> /dev/null; then
    echo "❌ CMake not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install cmake
    else
        echo "❌ Please install CMake manually: https://cmake.org/download/"
        exit 1
    fi
fi

# Create EXTERNAL directory if it doesn't exist
mkdir -p "$EXTERNAL_DIR"

# Clone sherpa-onnx if not already present
if [ ! -d "$EXTERNAL_DIR/sherpa-onnx" ]; then
    echo "📦 Cloning sherpa-onnx repository..."
    cd "$EXTERNAL_DIR"
    git clone --recursive https://github.com/k2-fsa/sherpa-onnx.git
else
    echo "📦 Using existing sherpa-onnx repository..."
    cd "$EXTERNAL_DIR/sherpa-onnx"
    git pull origin master
    git submodule update --recursive
fi

# Build iOS frameworks
echo "🔨 Building iOS XCFrameworks (this may take 10-15 minutes)..."
cd "$EXTERNAL_DIR/sherpa-onnx"

# Clean previous builds
rm -rf build-ios/

# Build frameworks
./build-ios.sh

# Copy frameworks to our module
echo "📋 Copying frameworks to module..."
cp -R "build-ios/sherpa-onnx.xcframework" "$XCFRAMEWORKS_DIR/"
cp -R "build-ios/ios-onnxruntime/1.17.1/onnxruntime.xcframework" "$XCFRAMEWORKS_DIR/"

# Verify frameworks
echo "✅ Verifying framework installation..."
if [ -f "$XCFRAMEWORKS_DIR/sherpa-onnx.xcframework/Info.plist" ] &&
   [ -f "$XCFRAMEWORKS_DIR/onnxruntime.xcframework/Info.plist" ]; then
    echo "✅ Framework setup completed successfully!"

    # Show framework sizes
    echo "📊 Framework sizes:"
    du -sh "$XCFRAMEWORKS_DIR"/*

    echo ""
    echo "🎉 SherpaONNX TTS is ready to use!"
    echo "   You can now build the Swift module with: swift build"
else
    echo "❌ Framework verification failed!"
    exit 1
fi
