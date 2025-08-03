# Contributing to RunAnywhere SDKs

First off, thank you for considering contributing to RunAnywhere SDKs! It's people like you that make RunAnywhere such a great tool for developers building on-device AI applications.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Style Guidelines](#style-guidelines)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Security](#security)

## Code of Conduct

This project and everyone participating in it is governed by the [RunAnywhere Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [conduct@runanywhere.ai](mailto:conduct@runanywhere.ai).

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Set up the development environment (see [Development Setup](#development-setup))
4. Create a branch for your changes
5. Make your changes
6. Run tests and ensure they pass
7. Submit a pull request

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

**Bug Report Template:**
- **Description**: A clear and concise description of what the bug is
- **To Reproduce**: Steps to reproduce the behavior
- **Expected behavior**: What you expected to happen
- **Screenshots**: If applicable
- **Environment**:
  - SDK Version:
  - OS: [e.g. iOS 17.0, Android 14]
  - Device: [e.g. iPhone 15, Pixel 8]
  - Xcode/Android Studio version:

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use case**: Explain why this enhancement would be useful
- **Proposed solution**: Describe the solution you'd like
- **Alternatives**: Describe alternatives you've considered

### Your First Code Contribution

Unsure where to begin? You can start by looking through these issues:

- Issues labeled `good first issue` - should only require a few lines of code
- Issues labeled `help wanted` - more involved but still accessible

## Development Setup

### Prerequisites

1. **For all platforms**:
   ```bash
   brew install pre-commit gitleaks
   pre-commit install
   ```

2. **For Android development**:
   - Android Studio Arctic Fox or later
   - JDK 11 or later
   - Android SDK with API level 24+

3. **For iOS development**:
   - Xcode 15.0 or later
   - Swift 5.9+
   - SwiftLint: `brew install swiftlint`

### Building the SDKs

#### Android SDK
```bash
cd sdk/runanywhere-android/
./gradlew build
./gradlew test
./gradlew lint
```

#### iOS SDK
```bash
cd sdk/runanywhere-swift/
swift build
swift test
swiftlint
```

### Running Tests

Always ensure tests pass before submitting a PR:

```bash
# Android
./gradlew test

# iOS
swift test --enable-code-coverage
```

## Style Guidelines

### Kotlin Style Guide (Android)

We follow the [official Kotlin coding conventions](https://kotlinlang.org/docs/coding-conventions.html) with these additions:

- Use 4 spaces for indentation
- Maximum line length: 120 characters
- Always use explicit types for public APIs
- Document all public APIs with KDoc

Example:
```kotlin
/**
 * Generates text using the loaded model
 * @param prompt The input prompt
 * @param options Generation options
 * @return Generated text result with metrics
 */
suspend fun generate(
    prompt: String,
    options: GenerationOptions = GenerationOptions()
): GenerationResult {
    // Implementation
}
```

### Swift Style Guide (iOS)

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with SwiftLint enforcement:

- Use 4 spaces for indentation
- Maximum line length: 120 characters
- Use `// MARK: -` comments to organize code
- Document all public APIs with documentation comments

Example:
```swift
/// Generates text using the loaded model
/// - Parameters:
///   - prompt: The input prompt
///   - options: Generation options
/// - Returns: Generated text result with metrics
/// - Throws: `SDKError` if generation fails
public func generate(
    prompt: String,
    options: GenerationOptions = GenerationOptions()
) async throws -> GenerationResult {
    // Implementation
}
```

### TODO Comments

All TODO comments MUST reference a GitHub issue:

```swift
// TODO: #123 - Implement retry logic for failed requests
```

## Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only changes
- `style:` Code style changes (formatting, missing semicolons, etc)
- `refactor:` Code change that neither fixes a bug nor adds a feature
- `perf:` Performance improvement
- `test:` Adding missing tests
- `chore:` Changes to build process or auxiliary tools

Examples:
```
feat: add streaming support for text generation
fix: resolve memory leak in model loading
docs: update installation instructions for SPM
```

## Pull Request Process

1. **Before submitting**:
   - Update the README.md with details of changes if needed
   - Run all tests and ensure they pass
   - Run lint checks: `pre-commit run --all-files`
   - Update documentation for any API changes

2. **PR Title**: Follow the commit message format (e.g., `feat: add streaming support`)

3. **PR Description**: Use the PR template and include:
   - What changes were made and why
   - Link to any relevant issues
   - Screenshots/recordings for UI changes
   - Test results

4. **Review Process**:
   - At least one maintainer approval required
   - All CI checks must pass
   - No merge conflicts
   - Conversations resolved

5. **After merge**:
   - Delete your branch
   - Close related issues

## Security

### Security Checks

Before submitting code:

1. **Run security scan**:
   ```bash
   gitleaks detect --config .gitleaks.toml
   ./scripts/security-check.sh
   ```

2. **Never commit**:
   - API keys or tokens
   - Passwords or secrets
   - Private keys or certificates
   - Personal information

3. **Use secure storage**:
   - iOS: Use the provided `SecureStorage` class
   - Android: Use encrypted SharedPreferences

### Reporting Security Vulnerabilities

Please DO NOT report security vulnerabilities through public GitHub issues. Instead, please report them to [security@runanywhere.ai](mailto:security@runanywhere.ai). See our [Security Policy](SECURITY.md) for more details.

## Questions?

Feel free to:
- Open a [GitHub Discussion](https://github.com/RunanywhereAI/runanywhere-sdks/discussions)
- Join our [Discord Community](https://discord.gg/runanywhere)
- Contact the team at [support@runanywhere.ai](mailto:support@runanywhere.ai)

Thank you for contributing! 🎉
