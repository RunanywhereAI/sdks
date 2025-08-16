#!/bin/bash

# Test script for Foundation Models integration
# This script builds and runs the sample app with Foundation Models

set -e

echo "🧪 Testing Foundation Models Integration"
echo "========================================"

# Navigate to project directory
cd "$(dirname "$0")/.."

echo ""
echo "1️⃣ Building SDK with Foundation Models support..."
cd ../../sdk/runanywhere-swift
swift build
echo "✅ SDK built successfully"

echo ""
echo "2️⃣ Building sample app..."
cd ../../examples/ios/RunAnywhereAI

# Check if we need to run pod install
if [ ! -d "Pods" ]; then
    echo "📦 Installing CocoaPods dependencies..."
    pod install
    ./fix_pods_sandbox.sh
fi

echo ""
echo "3️⃣ Building app with xcodebuild..."
xcodebuild build \
    -workspace RunAnywhereAI.xcworkspace \
    -scheme RunAnywhereAI \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -configuration Debug \
    ONLY_ACTIVE_ARCH=YES

echo ""
echo "✅ Build completed successfully!"
echo ""
echo "📱 To test Foundation Models in the app:"
echo "   1. Open RunAnywhereAI.xcworkspace in Xcode"
echo "   2. Run the app on iOS 17.0+ simulator"
echo "   3. Go to Models tab"
echo "   4. Select 'Apple Foundation Model'"
echo "   5. Try generating text in the Chat tab"
echo ""
echo "Note: Foundation Models require iOS 17.0+ to run"