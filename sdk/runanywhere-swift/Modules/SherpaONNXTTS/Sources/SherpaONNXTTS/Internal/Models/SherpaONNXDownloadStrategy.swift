import Foundation
import RunAnywhereSDK
import os

/// Custom download strategy for Sherpa-ONNX models
/// Handles multi-file downloads (model + voices + tokens + config)
final class SherpaONNXDownloadStrategy: DownloadStrategy {

    public var identifier: String { "sherpa-onnx-tts" }

    private let logger = Logger(
        subsystem: "com.runanywhere.sdk",
        category: "SherpaONNXDownload"
    )

    public func canHandle(model: ModelInfo) -> Bool {
        return model.id.hasPrefix("sherpa-")
    }

    public func downloadModel(
        _ model: ModelInfo,
        using downloadManager: DownloadManager,
        to destination: URL
    ) async throws -> DownloadTask {

        logger.info("Starting download for model: \(model.id)")

        // Create model-specific directory
        let modelDir = destination.appendingPathComponent(model.id)
        try FileManager.default.createDirectory(
            at: modelDir,
            withIntermediateDirectories: true
        )

        // Download main model file
        guard let mainURL = model.downloadURL else {
            throw SherpaONNXError.invalidConfiguration("No download URL for model")
        }

        let mainFileName = mainURL.lastPathComponent
        let mainDestination = modelDir.appendingPathComponent(mainFileName)

        logger.debug("Downloading main model to: \(mainDestination.path)")
        let mainTask = try await downloadManager.downloadFile(
            from: mainURL,
            to: mainDestination
        )

        // Download additional files if present
        if let additionalURLs = model.alternativeDownloadURLs {
            for url in additionalURLs {
                let fileName = url.lastPathComponent
                let fileDestination = modelDir.appendingPathComponent(fileName)

                logger.debug("Downloading additional file: \(fileName)")

                // Handle compressed files
                if fileName.hasSuffix(".tar.gz") {
                    let tempDestination = modelDir.appendingPathComponent("\(fileName).tmp")
                    _ = try await downloadManager.downloadFile(
                        from: url,
                        to: tempDestination
                    )

                    // Extract tar.gz file
                    try await extractTarGZ(from: tempDestination, to: modelDir)
                    try FileManager.default.removeItem(at: tempDestination)
                } else {
                    _ = try await downloadManager.downloadFile(
                        from: url,
                        to: fileDestination
                    )
                }
            }
        }

        // Create a marker file to indicate successful download
        let markerPath = modelDir.appendingPathComponent(".download_complete")
        try "".write(to: markerPath, atomically: true, encoding: .utf8)

        logger.info("Successfully downloaded all files for model: \(model.id)")

        return mainTask
    }

    /// Extract tar.gz file
    private func extractTarGZ(from source: URL, to destination: URL) async throws {
        logger.debug("Extracting: \(source.lastPathComponent)")

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        task.arguments = ["-xzf", source.path, "-C", destination.path]

        try task.run()
        task.waitUntilExit()

        guard task.terminationStatus == 0 else {
            throw SherpaONNXError.invalidConfiguration("Failed to extract tar.gz file")
        }

        logger.debug("Extraction complete")
    }

    /// Check if model is fully downloaded (all required files present)
    public func isModelComplete(_ model: ModelInfo, at path: URL) -> Bool {
        let modelDir = path.appendingPathComponent(model.id)
        let markerPath = modelDir.appendingPathComponent(".download_complete")

        return FileManager.default.fileExists(atPath: markerPath.path)
    }
}
