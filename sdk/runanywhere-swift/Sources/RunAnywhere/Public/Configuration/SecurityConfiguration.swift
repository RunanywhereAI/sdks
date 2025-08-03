//
//  SecurityConfiguration.swift
//  RunAnywhere
//
//  Security configuration for the RunAnywhere SDK
//

import Foundation

/// Security configuration options for the RunAnywhere SDK
public struct SecurityConfiguration {

    // MARK: - Properties

    /// Enable API key validation
    public let validateAPIKey: Bool

    /// Minimum API key length requirement
    public let minimumAPIKeyLength: Int

    /// Enable credential scanning in logs
    public let scanLogsForCredentials: Bool

    /// Enable secure storage for sensitive data
    public let useSecureStorage: Bool

    /// Enable certificate pinning for API requests
    public let enableCertificatePinning: Bool

    /// List of allowed certificate fingerprints (SHA256)
    public let pinnedCertificates: Set<String>

    /// Enable runtime security checks
    public let enableRuntimeSecurityChecks: Bool

    /// Redact sensitive information in error messages
    public let redactSensitiveErrors: Bool

    /// Maximum log retention period in days
    public let maxLogRetentionDays: Int

    /// Enable automatic credential rotation warnings
    public let enableCredentialRotationWarnings: Bool

    /// Credential age warning threshold in days
    public let credentialAgeWarningDays: Int

    // MARK: - Initialization

    public init(
        validateAPIKey: Bool = true,
        minimumAPIKeyLength: Int = 32,
        scanLogsForCredentials: Bool = true,
        useSecureStorage: Bool = true,
        enableCertificatePinning: Bool = false,
        pinnedCertificates: Set<String> = [],
        enableRuntimeSecurityChecks: Bool = true,
        redactSensitiveErrors: Bool = true,
        maxLogRetentionDays: Int = 30,
        enableCredentialRotationWarnings: Bool = true,
        credentialAgeWarningDays: Int = 90
    ) {
        self.validateAPIKey = validateAPIKey
        self.minimumAPIKeyLength = minimumAPIKeyLength
        self.scanLogsForCredentials = scanLogsForCredentials
        self.useSecureStorage = useSecureStorage
        self.enableCertificatePinning = enableCertificatePinning
        self.pinnedCertificates = pinnedCertificates
        self.enableRuntimeSecurityChecks = enableRuntimeSecurityChecks
        self.redactSensitiveErrors = redactSensitiveErrors
        self.maxLogRetentionDays = maxLogRetentionDays
        self.enableCredentialRotationWarnings = enableCredentialRotationWarnings
        self.credentialAgeWarningDays = credentialAgeWarningDays
    }

    // MARK: - Default Configurations

    /// Default security configuration with recommended settings
    public static let `default` = SecurityConfiguration()

    /// Strict security configuration for high-security environments
    public static let strict = SecurityConfiguration(
        validateAPIKey: true,
        minimumAPIKeyLength: 64,
        scanLogsForCredentials: true,
        useSecureStorage: true,
        enableCertificatePinning: true,
        pinnedCertificates: [], // Add your certificate fingerprints
        enableRuntimeSecurityChecks: true,
        redactSensitiveErrors: true,
        maxLogRetentionDays: 7,
        enableCredentialRotationWarnings: true,
        credentialAgeWarningDays: 30
    )

    /// Relaxed security configuration for development
    public static let development = SecurityConfiguration(
        validateAPIKey: false,
        minimumAPIKeyLength: 16,
        scanLogsForCredentials: false,
        useSecureStorage: false,
        enableCertificatePinning: false,
        pinnedCertificates: [],
        enableRuntimeSecurityChecks: false,
        redactSensitiveErrors: false,
        maxLogRetentionDays: 90,
        enableCredentialRotationWarnings: false,
        credentialAgeWarningDays: 365
    )
}
