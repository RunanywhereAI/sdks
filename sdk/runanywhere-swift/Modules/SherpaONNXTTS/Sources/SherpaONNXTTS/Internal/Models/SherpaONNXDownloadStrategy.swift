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

    public func download(
        model: ModelInfo,
        to destination: URL,
        progressHandler: ((Double) -> Void)?
    ) async throws -> URL {
        logger.info("Starting download for model: \(model.id)")

        let modelDir = destination.appendingPathComponent(model.id)
        try FileManager.default.createDirectory(at: modelDir, withIntermediateDirectories: true)

        let totalFiles = 1 + (model.alternativeDownloadURLs?.count ?? 0)
        var completedFiles = 0

        // Download main model file
        guard let mainURL = model.downloadURL else {
            throw SherpaONNXError.invalidConfiguration("No download URL for model \(model.id)")
        }

        let (mainData, mainResponse) = try await URLSession.shared.data(from: mainURL)
        guard let httpResponse = mainResponse as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SherpaONNXError.invalidConfiguration("Failed to download \(mainURL.lastPathComponent)")
        }

        let mainDestination = modelDir.appendingPathComponent(mainURL.lastPathComponent)
        try mainData.write(to: mainDestination)
        completedFiles += 1
        progressHandler?(Double(completedFiles) / Double(totalFiles))

        // Download additional files (voices, tokens, config)
        if let altURLs = model.alternativeDownloadURLs {
            for altURL in altURLs {
                do {
                    let (data, response) = try await URLSession.shared.data(from: altURL)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        logger.warning("Failed to download \(altURL.lastPathComponent), skipping")
                        continue
                    }

                    let fileDestination = modelDir.appendingPathComponent(altURL.lastPathComponent)
                    try data.write(to: fileDestination)
                    completedFiles += 1
                    progressHandler?(Double(completedFiles) / Double(totalFiles))
                } catch {
                    logger.warning("Failed to download \(altURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }

        // Mark as complete
        let markerPath = modelDir.appendingPathComponent(".download_complete")
        try Data().write(to: markerPath)

        logger.info("Download completed for model: \(model.id)")
        return modelDir
    }

    public func downloadModel(
        _ model: ModelInfo,
        using downloadManager: DownloadManager,
        to destination: URL
    ) async throws -> DownloadTask {
        logger.info("Using SDK download manager for model: \(model.id)")

        // Use the SDK's download manager directly
        return try await downloadManager.downloadModel(model)
    }

    /// Check if model is fully downloaded (all required files present)
    public func isModelComplete(_ model: ModelInfo, at path: URL) -> Bool {
        let modelDir = path.appendingPathComponent(model.id)
        let markerPath = modelDir.appendingPathComponent(".download_complete")

        return FileManager.default.fileExists(atPath: markerPath.path)
    }
}
