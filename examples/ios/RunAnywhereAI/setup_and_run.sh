#!/bin/bash

echo "📱 Setting up and running RunAnywhereAI on iPhone"
echo ""
echo "⚠️  This script requires sudo access to set Xcode Beta as the active developer directory"
echo ""

# Set Xcode Beta as active developer directory
echo "🔧 Setting Xcode Beta as active developer directory..."
sudo xcode-select -s /Applications/Xcode-beta.app/Contents/Developer

# Verify the change
echo "✅ Current Xcode path: $(xcode-select -p)"

# Build and run
echo "🏗️  Building for iPhone..."
xcodebuild -workspace RunAnywhereAI.xcworkspace \
    -scheme RunAnywhereAI \
    -destination 'platform=iOS,name=iPhone' \
    -allowProvisioningUpdates \
    -allowProvisioningDeviceRegistration \
    build

echo ""
echo "✅ Build complete! Now running on iPhone..."
xcodebuild -workspace RunAnywhereAI.xcworkspace \
    -scheme RunAnywhereAI \
    -destination 'platform=iOS,name=iPhone' \
    -allowProvisioningUpdates \
    -allowProvisioningDeviceRegistration \
    run-without-building

echo ""
echo "🎉 Done! The app should be running on your iPhone."
echo ""
echo "⚠️  If you see 'Untrusted Developer' on your iPhone:"
echo "   1. Go to Settings → General → VPN & Device Management"
echo "   2. Tap on your developer profile"
echo "   3. Tap 'Trust'"