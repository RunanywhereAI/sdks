//
//  SecureStorage.swift
//  RunAnywhere
//
//  Secure storage implementation using Keychain for sensitive data
//

import Foundation
import Security

/// Secure storage service for sensitive data like API keys
public final class SecureStorage {

    // MARK: - Properties

    private let serviceName: String
    private let accessGroup: String?
    private let logger: SDKLogger

    // MARK: - Initialization

    public init(
        serviceName: String = "com.runanywhere.sdk",
        accessGroup: String? = nil,
        logger: SDKLogger
    ) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
        self.logger = logger
    }

    // MARK: - Public Methods

    /// Stores data securely in the keychain
    public func store(_ data: Data, for key: String) throws {
        let query = createQuery(for: key)

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        var newQuery = query
        newQuery[kSecValueData as String] = data

        #if os(iOS) || os(tvOS) || os(watchOS)
        // Use secure accessibility option
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        #endif

        let status = SecItemAdd(newQuery as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw SDKError.storageError("Failed to store data in keychain: \(status)")
        }

        logger.debug("Securely stored data for key: \(key)")
    }

    /// Stores a string securely
    public func storeString(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw SDKError.storageError("Failed to convert string to data")
        }
        try store(data, for: key)
    }

    /// Retrieves data from secure storage
    public func retrieve(key: String) throws -> Data {
        var query = createQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw SDKError.storageError("Item not found for key: \(key)")
            }
            throw SDKError.storageError("Failed to retrieve data from keychain: \(status)")
        }

        guard let data = result as? Data else {
            throw SDKError.storageError("Retrieved data is not in expected format")
        }

        logger.debug("Retrieved secure data for key: \(key)")
        return data
    }

    /// Retrieves a string from secure storage
    public func retrieveString(key: String) throws -> String {
        let data = try retrieve(key: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SDKError.storageError("Failed to convert data to string")
        }
        return string
    }

    /// Deletes data from secure storage
    public func delete(key: String) throws {
        let query = createQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SDKError.storageError("Failed to delete item from keychain: \(status)")
        }

        logger.debug("Deleted secure data for key: \(key)")
    }

    /// Checks if a key exists in secure storage
    public func exists(key: String) -> Bool {
        var query = createQuery(for: key)
        query[kSecReturnData as String] = false
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Deletes all items for this service
    public func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SDKError.storageError("Failed to delete all items: \(status)")
        }

        logger.debug("Deleted all secure storage items")
    }

    // MARK: - Private Methods

    private func createQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }
}

// MARK: - Secure API Key Storage Extension

public extension SecureStorage {

    /// Stores the API key securely
    func storeAPIKey(_ apiKey: String) throws {
        // Add timestamp for rotation tracking
        let metadata = APIKeyMetadata(
            key: apiKey,
            storedAt: Date(),
            lastRotated: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)
        try store(data, for: "runanywhere_api_key")
    }

    /// Retrieves the API key from secure storage
    func retrieveAPIKey() throws -> String {
        let data = try retrieve(key: "runanywhere_api_key")
        let decoder = JSONDecoder()
        let metadata = try decoder.decode(APIKeyMetadata.self, from: data)

        // Check if rotation warning is needed
        checkRotationWarning(for: metadata)

        return metadata.key
    }

    /// Updates the last rotation date for the API key
    func updateAPIKeyRotation() throws {
        let currentKey = try retrieveAPIKey()
        let metadata = APIKeyMetadata(
            key: currentKey,
            storedAt: Date(),
            lastRotated: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)
        try store(data, for: "runanywhere_api_key")
    }

    private func checkRotationWarning(for metadata: APIKeyMetadata) {
        let daysSinceRotation = Calendar.current.dateComponents(
            [.day],
            from: metadata.lastRotated,
            to: Date()
        ).day ?? 0

        if daysSinceRotation > 90 {
            logger.warning("API key has not been rotated in \(daysSinceRotation) days. Consider rotating for security.")
        }
    }
}

// MARK: - Supporting Types

private struct APIKeyMetadata: Codable {
    let key: String
    let storedAt: Date
    let lastRotated: Date
}
