#!/bin/bash

# Security check script for RunAnywhere SDK
# This script performs various security checks before allowing commits

set -e

echo "🔒 Running security checks..."

# Check if gitleaks is installed
if ! command -v gitleaks &> /dev/null; then
    echo "❌ gitleaks is not installed. Please install it with: brew install gitleaks"
    exit 1
fi

# Run gitleaks scan
echo "🔍 Scanning for credentials and secrets..."
if ! gitleaks detect --source . --config .gitleaks.toml; then
    echo "❌ Credentials or secrets detected! Please remove them before committing."
    exit 1
fi

# Check for common sensitive file patterns
echo "🔍 Checking for sensitive files..."
SENSITIVE_PATTERNS=(
    "*.pem"
    "*.key"
    "*.p12"
    "*.pfx"
    "*.jks"
    "*.keystore"
    "*_api_key*"
    "*_token*"
    "*.secret"
    "secrets.*"
    "credentials.*"
    ".env*"
    "google-services.json"
    "GoogleService-Info.plist"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if find . -name "$pattern" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./build/*" | grep -q .; then
        echo "❌ Found sensitive files matching pattern: $pattern"
        echo "   Please add these to .gitignore or remove them"
        find . -name "$pattern" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./build/*"
        exit 1
    fi
done

# Check for hardcoded API endpoints in Swift files
echo "🔍 Checking for hardcoded API endpoints..."
if grep -r "https://api\." sdk/runanywhere-swift --include="*.swift" | grep -v "api.runanywhere.ai" | grep -q .; then
    echo "⚠️  Warning: Found hardcoded API endpoints that might contain credentials:"
    grep -r "https://api\." sdk/runanywhere-swift --include="*.swift" | grep -v "api.runanywhere.ai"
fi

# Check for console.log or print statements with potential sensitive data
echo "🔍 Checking for debug logging of sensitive data..."
if grep -r "apiKey\|password\|token\|secret" sdk/ --include="*.swift" --include="*.kt" | grep -E "(print|NSLog|os_log|println|Log\.[vdiewf])" | grep -q .; then
    echo "⚠️  Warning: Found potential logging of sensitive data:"
    grep -r "apiKey\|password\|token\|secret" sdk/ --include="*.swift" --include="*.kt" | grep -E "(print|NSLog|os_log|println|Log\.[vdiewf])"
fi

echo "✅ Security checks passed!"
exit 0
