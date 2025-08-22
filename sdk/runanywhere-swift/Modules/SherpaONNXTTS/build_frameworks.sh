#!/bin/bash

# Build Sherpa-ONNX XCFrameworks for the SherpaONNXTTS module
# This script clones sherpa-onnx, builds the frameworks, and copies them to the module

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/../../../.."
EXTERNAL_DIR="$PROJECT_ROOT/EXTERNAL"
MODULE_DIR="$SCRIPT_DIR"

echo -e "${GREEN}🚀 Sherpa-ONNX XCFramework Builder${NC}"
echo "======================================"
echo "Module directory: $MODULE_DIR"
echo "External directory: $EXTERNAL_DIR"
echo ""

# Create EXTERNAL directory if it doesn't exist
mkdir -p "$EXTERNAL_DIR"

# Step 1: Clone sherpa-onnx if not exists
if [ ! -d "$EXTERNAL_DIR/sherpa-onnx" ]; then
    echo -e "${YELLOW}📥 Cloning sherpa-onnx repository...${NC}"
    cd "$EXTERNAL_DIR"
    git clone https://github.com/k2-fsa/sherpa-onnx.git
    echo -e "${GREEN}✓ Repository cloned${NC}"
else
    echo -e "${GREEN}✓ sherpa-onnx repository already exists${NC}"
    echo -e "${YELLOW}📥 Pulling latest changes...${NC}"
    cd "$EXTERNAL_DIR/sherpa-onnx"
    git pull
fi

# Step 2: Build XCFrameworks
cd "$EXTERNAL_DIR/sherpa-onnx"
echo ""
echo -e "${YELLOW}🔨 Building XCFrameworks for iOS...${NC}"
echo "This may take 10-15 minutes..."
echo ""

# Check if build script exists
if [ ! -f "./build-ios.sh" ]; then
    echo -e "${RED}❌ Error: build-ios.sh not found!${NC}"
    exit 1
fi

# Run the build
./build-ios.sh

# Step 3: Check if build was successful
if [ ! -d "build-ios/sherpa-onnx.xcframework" ]; then
    echo -e "${RED}❌ Error: sherpa-onnx.xcframework was not created!${NC}"
    exit 1
fi

if [ ! -d "build-ios/onnxruntime.xcframework" ]; then
    echo -e "${RED}❌ Error: onnxruntime.xcframework was not created!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ XCFrameworks built successfully${NC}"

# Step 4: Copy frameworks to module
echo ""
echo -e "${YELLOW}📦 Copying XCFrameworks to module...${NC}"

# Create XCFrameworks directory
mkdir -p "$MODULE_DIR/XCFrameworks"

# Remove old frameworks if they exist
rm -rf "$MODULE_DIR/XCFrameworks/sherpa-onnx.xcframework"
rm -rf "$MODULE_DIR/XCFrameworks/onnxruntime.xcframework"

# Copy new frameworks
cp -r "build-ios/sherpa-onnx.xcframework" "$MODULE_DIR/XCFrameworks/"
cp -r "build-ios/onnxruntime.xcframework" "$MODULE_DIR/XCFrameworks/"

echo -e "${GREEN}✓ Frameworks copied${NC}"

# Step 5: Verify installation
echo ""
echo -e "${YELLOW}🔍 Verifying installation...${NC}"

if [ -d "$MODULE_DIR/XCFrameworks/sherpa-onnx.xcframework" ] && [ -d "$MODULE_DIR/XCFrameworks/onnxruntime.xcframework" ]; then
    echo -e "${GREEN}✅ SUCCESS! XCFrameworks are ready to use${NC}"
    echo ""
    echo "📍 Frameworks installed at:"
    echo "   $MODULE_DIR/XCFrameworks/"
    echo ""
    echo "Next steps:"
    echo "1. The Package.swift is already configured to use these frameworks"
    echo "2. You can now build the SherpaONNXTTS module"
    echo "3. Add the module to your app in Xcode as a local package"
    echo ""

    # Show framework sizes
    echo "📊 Framework sizes:"
    du -sh "$MODULE_DIR/XCFrameworks/sherpa-onnx.xcframework"
    du -sh "$MODULE_DIR/XCFrameworks/onnxruntime.xcframework"
else
    echo -e "${RED}❌ Error: Frameworks were not properly installed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Build complete!${NC}"
