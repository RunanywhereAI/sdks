# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Which versions are eligible for receiving such patches depends on the CVSS v3.0 Rating:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

The RunAnywhere team takes security bugs seriously. We appreciate your efforts to responsibly disclose your findings, and will make every effort to acknowledge your contributions.

### Where to Report

**Please DO NOT report security vulnerabilities publicly.**

Report security vulnerabilities by emailing the RunAnywhere security team at:

**[security@runanywhere.ai](mailto:security@runanywhere.ai)**

### What to Include

Please include the following information in your report:

- Type of issue (e.g., buffer overflow, SQL injection, cross-site scripting, credential exposure, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### Response Timeline

You should receive a response from us within **48 hours**. If for some reason you do not, please follow up via email to ensure we received your original message.

We will:
1. Confirm receipt of your vulnerability report
2. Provide an estimated timeline for a fix
3. Notify you when the vulnerability is fixed

## Security Measures

### Built-in Security Features

The RunAnywhere SDKs include several security features:

1. **Credential Detection**: Pre-commit hooks using Gitleaks to prevent accidental credential commits
2. **Secure Storage**:
   - iOS: Keychain integration for sensitive data
   - Android: Encrypted SharedPreferences
3. **API Key Validation**: Minimum length and pattern validation
4. **Runtime Security**: Debugger and jailbreak/root detection
5. **Log Redaction**: Automatic removal of sensitive data from logs
6. **Certificate Pinning**: Optional SSL certificate validation

### Security Best Practices

When using RunAnywhere SDKs:

1. **API Key Management**:
   - Never hardcode API keys in your source code
   - Use environment variables or secure configuration files
   - Rotate API keys regularly
   - Use different API keys for development and production

2. **Secure Communication**:
   - Always use HTTPS for API communication
   - Enable certificate pinning in production
   - Validate all inputs and outputs

3. **Data Protection**:
   - Use the SDK's secure storage for sensitive data
   - Enable privacy mode when handling sensitive content
   - Clear sensitive data from memory when no longer needed

4. **Access Control**:
   - Implement proper authentication in your app
   - Use the principle of least privilege
   - Monitor API usage for anomalies

## Development Security

### Pre-commit Hooks

We use pre-commit hooks to prevent security issues:

```bash
# Install pre-commit hooks
pre-commit install

# Run security checks manually
gitleaks detect --config .gitleaks.toml
./scripts/security-check.sh
```

### Dependency Management

- We regularly update dependencies to patch known vulnerabilities
- Use `./gradlew dependencyCheckAnalyze` (Android) to check for vulnerable dependencies
- Use `swift package audit` (iOS) to audit Swift packages

### Code Review

All code changes undergo security review focusing on:
- Input validation
- Authentication and authorization
- Data encryption
- Error handling
- Logging practices

## Security Checklist for Contributors

Before submitting code:

- [ ] No hardcoded credentials or API keys
- [ ] All inputs are validated
- [ ] Sensitive data is encrypted at rest
- [ ] Error messages don't expose sensitive information
- [ ] Logging doesn't include sensitive data
- [ ] Dependencies are up to date
- [ ] Security tests are included for new features

## Vulnerability Disclosure Policy

We follow responsible disclosure practices:

1. Security vulnerabilities are embargoed until a fix is available
2. We coordinate disclosure with affected parties
3. Security advisories are published after fixes are deployed
4. Credit is given to security researchers (unless they prefer to remain anonymous)

## Contact

- Security Team: [security@runanywhere.ai](mailto:security@runanywhere.ai)
- General Support: [support@runanywhere.ai](mailto:support@runanywhere.ai)
- Bug Reports (non-security): [GitHub Issues](https://github.com/RunanywhereAI/runanywhere-sdks/issues)

## Acknowledgments

We would like to thank the following individuals for responsibly disclosing security issues:

- _This list will be updated as security researchers report vulnerabilities_

---

**Remember: Please do NOT file public issues for security vulnerabilities!**
