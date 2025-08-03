//
//  SecurityValidator.swift
//  RunAnywhere
//
//  Security validation service for credential and API key validation
//

import Foundation
import CryptoKit

/// Service responsible for security validation
public final class SecurityValidator {

    // MARK: - Properties

    private let configuration: SecurityConfiguration
    private let logger: SDKLogger

    // Common credential patterns to detect
    private let credentialPatterns: [(pattern: String, type: String)] = [
        // API Keys
        ("(?i)(api[_-]?key|apikey|api_token)\\s*[:=]\\s*[\"']?([a-zA-Z0-9_-]{20,})[\"']?", "API Key"),
        ("(?i)(secret[_-]?key|secret_token)\\s*[:=]\\s*[\"']?([a-zA-Z0-9_-]{20,})[\"']?", "Secret Key"),
        ("(?i)(access[_-]?token)\\s*[:=]\\s*[\"']?([a-zA-Z0-9_-]{20,})[\"']?", "Access Token"),

        // Cloud Provider Keys
        ("AKIA[0-9A-Z]{16}", "AWS Access Key"),
        ("(?i)aws_secret_access_key\\s*[:=]\\s*[\"']?([a-zA-Z0-9/+=]{40})[\"']?", "AWS Secret Key"),
        ("AIza[0-9A-Za-z\\-_]{35}", "Google API Key"),

        // Private Keys
        ("-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----", "Private Key"),
        ("-----BEGIN PGP PRIVATE KEY BLOCK-----", "PGP Private Key"),

        // Passwords and Auth
        ("(?i)(password|passwd|pwd)\\s*[:=]\\s*[\"']?([^\"'\\s]{8,})[\"']?", "Password"),
        ("(?i)bearer\\s+[a-zA-Z0-9_-]+\\.[a-zA-Z0-9_-]+\\.[a-zA-Z0-9_-]+", "JWT Token"),

        // Database
        ("(?i)(mongodb://|postgres://|mysql://|redis://)[^\\s]+", "Database URL"),

        // RunAnywhere specific
        ("(?i)(runanywhere[_-]?api[_-]?key|RA_API_KEY)\\s*[:=]\\s*[\"']?([a-zA-Z0-9_-]{20,})[\"']?", "RunAnywhere API Key")
    ]

    // MARK: - Initialization

    public init(configuration: SecurityConfiguration, logger: SDKLogger) {
        self.configuration = configuration
        self.logger = logger
    }

    // MARK: - API Key Validation

    /// Validates an API key according to security configuration
    public func validateAPIKey(_ apiKey: String) throws {
        guard configuration.validateAPIKey else { return }

        // Check minimum length
        guard apiKey.count >= configuration.minimumAPIKeyLength else {
            throw SDKError.invalidConfiguration(
                "API key must be at least \(configuration.minimumAPIKeyLength) characters long"
            )
        }

        // Check for common weak patterns
        let weakPatterns = [
            "test", "demo", "example", "sample", "default",
            "12345", "00000", "11111", "password", "secret"
        ]

        let lowercaseKey = apiKey.lowercased()
        for pattern in weakPatterns {
            if lowercaseKey.contains(pattern) {
                logger.warning("API key contains weak pattern: \(pattern)")
                if configuration.enableRuntimeSecurityChecks {
                    throw SDKError.invalidConfiguration(
                        "API key appears to be a test/demo key. Please use a production API key."
                    )
                }
            }
        }

        // Check character diversity
        let hasUppercase = apiKey.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = apiKey.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumbers = apiKey.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = apiKey.range(of: "[_-]", options: .regularExpression) != nil

        let diversityScore = [hasUppercase, hasLowercase, hasNumbers, hasSpecial]
            .filter { $0 }.count

        if diversityScore < 2 && configuration.enableRuntimeSecurityChecks {
            logger.warning("API key has low character diversity")
        }
    }

    // MARK: - Credential Scanning

    /// Scans text for potential credentials
    public func scanForCredentials(_ text: String) -> [(type: String, match: String)] {
        guard configuration.scanLogsForCredentials else { return [] }

        var findings: [(type: String, match: String)] = []

        for (pattern, type) in credentialPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let matches = regex.matches(
                    in: text,
                    options: [],
                    range: NSRange(text.startIndex..., in: text)
                )

                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let matchedText = String(text[range])
                        // Redact the actual value
                        let redactedMatch = redactMatch(matchedText, type: type)
                        findings.append((type: type, match: redactedMatch))
                    }
                }
            } catch {
                logger.error("Failed to compile regex for \(type): \(error)")
            }
        }

        return findings
    }

    /// Redacts sensitive information from logs
    public func redactSensitiveInfo(from text: String) -> String {
        guard configuration.scanLogsForCredentials else { return text }

        var redactedText = text

        for (pattern, type) in credentialPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                redactedText = regex.stringByReplacingMatches(
                    in: redactedText,
                    options: [],
                    range: NSRange(redactedText.startIndex..., in: redactedText),
                    withTemplate: "[\(type) REDACTED]"
                )
            } catch {
                logger.error("Failed to redact \(type): \(error)")
            }
        }

        return redactedText
    }

    // MARK: - Runtime Security Checks

    /// Performs runtime security checks
    public func performRuntimeSecurityChecks() {
        guard configuration.enableRuntimeSecurityChecks else { return }

        // Check for debugger
        if isDebuggerAttached() {
            logger.warning("Debugger detected - this may be a security risk in production")
        }

        // Check for jailbreak (iOS specific)
        #if os(iOS)
        if isJailbroken() {
            logger.warning("Device appears to be jailbroken - security may be compromised")
        }
        #endif
    }

    // MARK: - Helper Methods

    private func redactMatch(_ match: String, type: String) -> String {
        // Show only first few characters for debugging
        let visibleChars = 4
        if match.count > visibleChars {
            let prefix = String(match.prefix(visibleChars))
            return "\(prefix)...[\(type) REDACTED]"
        }
        return "[\(type) REDACTED]"
    }

    private func isDebuggerAttached() -> Bool {
        #if DEBUG
        return true
        #else
        // Check for debugger attachment
        var info = kinfo_proc()
        var size = MemoryLayout.stride(ofValue: info)
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]

        let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
        return result == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
        #endif
    }

    #if os(iOS)
    private func isJailbroken() -> Bool {
        // Check for common jailbreak paths
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/usr/bin/ssh"
        ]

        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // Check if we can write to system directories
        let testPath = "/private/test_\(UUID().uuidString).txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true // If we can write, device is jailbroken
        } catch {
            // Expected behavior on non-jailbroken devices
        }

        return false
    }
    #endif

    // MARK: - Certificate Pinning

    /// Validates a certificate against pinned certificates
    public func validateCertificate(_ certificate: SecCertificate) -> Bool {
        guard configuration.enableCertificatePinning,
              !configuration.pinnedCertificates.isEmpty else {
            return true
        }

        // Get certificate data
        guard let certData = SecCertificateCopyData(certificate) as Data? else {
            logger.error("Failed to get certificate data")
            return false
        }

        // Calculate SHA256 fingerprint
        let fingerprint = SHA256.hash(data: certData)
            .compactMap { String(format: "%02x", $0) }
            .joined()

        let isValid = configuration.pinnedCertificates.contains(fingerprint)

        if !isValid {
            logger.error("Certificate validation failed - fingerprint not in pinned list")
        }

        return isValid
    }
}
