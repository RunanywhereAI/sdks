# SherpaONNX TTS - Team Workflow Guide

## Overview

This document explains how to manage the SherpaONNX TTS module in a team environment, specifically handling the large binary XCFrameworks.

## 🚀 Quick Start for New Team Members

### First Time Setup

```bash
# Clone the repository
git clone [your-repo-url]
cd sdk/runanywhere-swift/Modules/SherpaONNXTTS

# Set up frameworks (one-time setup)
./setup_frameworks.sh

# Build and test
swift build
swift test
```

That's it! The setup script handles everything automatically.

## 📋 Framework Management Strategy

### Current Approach: **Build-on-Demand with Caching**

We've chosen this approach because:
- ✅ **Clean Git repository** - No 300MB+ binaries in version control
- ✅ **Fast for regular development** - Only rebuild when needed
- ✅ **Deterministic builds** - Everyone uses the same source version
- ✅ **CI/CD friendly** - Automated setup scripts

## 🔧 How It Works

### For Developers

1. **First time**: Run `./setup_frameworks.sh` (10-15 minutes)
2. **Regular development**: Frameworks persist locally
3. **Framework updates**: Re-run setup script when needed

### For CI/CD

```yaml
# GitHub Actions example
- name: Setup SherpaONNX Frameworks
  run: |
    cd sdk/runanywhere-swift/Modules/SherpaONNXTTS
    ./setup_frameworks.sh

- name: Build and Test
  run: swift build && swift test
```

## 🎯 Team Scenarios

### Scenario 1: New Developer Joining

```bash
# 1. Clone repo
git clone [repo-url]

# 2. Setup frameworks
cd sdk/runanywhere-swift/Modules/SherpaONNXTTS
./setup_frameworks.sh

# 3. Start developing
swift build  # Works immediately!
```

### Scenario 2: Framework Update Needed

```bash
# When sherpa-onnx updates or you need to rebuild
cd sdk/runanywhere-swift/Modules/SherpaONNXTTS
rm -rf XCFrameworks/  # Force rebuild
./setup_frameworks.sh
```

### Scenario 3: Shared Development Machine

```bash
# Frameworks are built once, shared by all users
# First user runs setup, others can use immediately
./setup_frameworks.sh  # Only first time
```

## 🏗️ Advanced Options

### Option A: Use Pre-built Binaries (Recommended for Teams)

Set up a shared storage location for your team:

```bash
# Upload frameworks to shared storage (one-time)
tar -czf sherpa-frameworks.tar.gz XCFrameworks/
# Upload to AWS S3, Google Drive, or internal file server

# Team members download instead of building
export SHERPA_FRAMEWORKS_URL="https://your-storage.com/sherpa-frameworks.tar.gz"
./setup_frameworks.sh  # Will download instead of building
```

### Option B: Git LFS (If You Prefer Committing Binaries)

```bash
# Install Git LFS
brew install git-lfs
git lfs install

# Track binary files
echo "*.xcframework filter=lfs diff=lfs merge=lfs -text" >> .gitattributes
echo "*.a filter=lfs diff=lfs merge=lfs -text" >> .gitattributes

# Add and commit
git add .gitattributes XCFrameworks/
git commit -m "Add XCFrameworks with Git LFS"
```

### Option C: Package Manager Integration

```bash
# Future consideration: Create SPM binary package
# This would allow automatic framework distribution
```

## 📊 Performance Comparison

| Approach | First Setup | Regular Builds | Git Repo Size | Team Onboarding |
|----------|-------------|----------------|---------------|-----------------|
| **Current (Build-on-demand)** | 10-15 min | Instant | ~10MB | 1 command |
| **Git LFS** | 2-3 min | Instant | ~10MB + LFS | 2 commands |
| **Committed Binaries** | Instant | Instant | ~300MB | 0 commands |

## 🚨 Troubleshooting

### "Framework not found" errors

```bash
# Solution: Re-run setup
./setup_frameworks.sh
```

### "CMake not found"

```bash
# Solution: Install CMake
brew install cmake
```

### Build fails on Apple Silicon

```bash
# Solution: Ensure Xcode Command Line Tools are updated
xcode-select --install
```

### CI/CD timeouts

```bash
# Solution: Cache the EXTERNAL directory
# GitHub Actions example:
- uses: actions/cache@v3
  with:
    path: EXTERNAL/sherpa-onnx
    key: sherpa-onnx-${{ hashFiles('**/setup_frameworks.sh') }}
```

## 🔄 Update Workflow

### When Sherpa-ONNX Updates

1. **Update the setup script** if needed
2. **Test locally**:
   ```bash
   rm -rf XCFrameworks/ EXTERNAL/sherpa-onnx/
   ./setup_frameworks.sh
   swift build && swift test
   ```
3. **Commit the setup script changes**
4. **Notify team**: "Run `./setup_frameworks.sh` to get latest frameworks"

### Versioning Strategy

- **Setup script version**: Track in the script header
- **Framework version**: Logged during build
- **Git tags**: Tag releases for reproducible builds

## 🎉 Benefits for Your Team

1. **Zero Configuration**: New developers just run one script
2. **Clean Git History**: No large binary commits
3. **Always Current**: Latest framework builds
4. **Flexible**: Easy to switch between local builds and shared binaries
5. **CI/CD Ready**: Automated setup for build systems

## 💡 Recommendations

### For Small Teams (2-5 developers)
- ✅ Use the current build-on-demand approach
- ✅ Each developer builds once locally
- ✅ Simple and effective

### For Larger Teams (5+ developers)
- ✅ Set up shared pre-built binaries storage
- ✅ Use the `SHERPA_FRAMEWORKS_URL` environment variable
- ✅ Faster onboarding, less build load

### For Production/Release
- ✅ Pin to specific sherpa-onnx commit/tag
- ✅ Store release frameworks in secure location
- ✅ Use deterministic builds for reproducibility

This workflow ensures your team can collaborate effectively while managing the large binary dependencies efficiently!
