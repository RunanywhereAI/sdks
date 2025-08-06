import Foundation
import Moya
import Combine
import Combine

/// API Client implementation using Moya
/// This wraps the Moya provider and provides async/await interface
public class MoyaAPIClient {

    private let provider: MoyaProvider<RunAnywhereAPI>
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let logger: SDKLogger

    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()

    internal init(
        provider: MoyaProvider<RunAnywhereAPI>,
        decoder: JSONDecoder,
        encoder: JSONEncoder,
        logger: SDKLogger
    ) {
        self.provider = provider
        self.decoder = decoder
        self.encoder = encoder
        self.logger = logger

        // Configure decoder
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Configure encoder
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Configuration

    public func fetchConfiguration() async throws -> ConfigurationDTO {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.fetchConfiguration(apiKey: "")) { result in
                switch result {
                case .success(let response):
                    do {
                        let config = try self.decoder.decode(ConfigurationDTO.self, from: response.data)
                        continuation.resume(returning: config)
                    } catch {
                        continuation.resume(throwing: self.mapError(error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: self.mapError(error))
                }
            }
        }
    }

    public func updateConfiguration(_ configuration: ConfigurationDTO) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.updateConfiguration(configuration)) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: self.mapError(error))
                }
            }
        }
    }

    // MARK: - Model Metadata

    public func fetchModelList() async throws -> [ModelMetadataDTO] {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.fetchModelList) { result in
                switch result {
                case .success(let response):
                    do {
                        let modelList = try self.decoder.decode(ModelListResponse.self, from: response.data)
                        continuation.resume(returning: modelList.models)
                    } catch {
                        continuation.resume(throwing: self.mapError(error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: self.mapError(error))
                }
            }
        }
    }

    public func fetchModelMetadata(modelId: String) async throws -> ModelMetadataDTO {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.fetchModelMetadata(modelId: modelId)) { result in
                switch result {
                case .success(let response):
                    do {
                        let metadata = try self.decoder.decode(ModelMetadataDTO.self, from: response.data)
                        continuation.resume(returning: metadata)
                    } catch {
                        continuation.resume(throwing: self.mapError(error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: self.mapError(error))
                }
            }
        }
    }

    // MARK: - Telemetry

    public func sendTelemetry(_ telemetry: TelemetryDTO) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.sendTelemetry(telemetry)) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: self.mapError(error))
                }
            }
        }
    }

    public func sendTelemetryBatch(_ batch: [TelemetryDTO]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.sendBatch(batch)) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: self.mapError(error))
                }
            }
        }
    }

    // MARK: - Cloud Inference

    public func generateText(request: CloudInferenceRequest) async throws -> GenerationResult {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.generateText(request: request)) { result in
                switch result {
                case .success(let response):
                    // TODO: Implement proper response parsing
                    // For now, return a placeholder result
                    let result = GenerationResult(
                        text: "Placeholder response",
                        tokensUsed: 0,
                        modelUsed: "unknown",
                        latencyMs: 0,
                        executionTarget: .cloud,
                        savedAmount: 0,
                        framework: nil,
                        hardwareUsed: .cpu,
                        memoryUsed: 0,
                        tokenizerFormat: nil,
                        performanceMetrics: PerformanceMetrics(),
                        metadata: nil
                    )
                    continuation.resume(returning: result)
                case .failure(let error):
                    continuation.resume(throwing: self.mapError(error))
                }
            }
        }
    }

    /// Stream generation using Combine publisher
    /// Note: This requires CombineMoya which is not included in our dependencies
    /// Implementing as a placeholder for now
    public func streamGeneration(request: CloudInferenceRequest) -> AnyPublisher<GenerationChunk, Error> {
        // TODO: Implement streaming with CombineMoya or alternative approach
        return Fail(error: RunAnywhereError.invalidConfiguration("Streaming not yet implemented"))
            .eraseToAnyPublisher()
    }

    // MARK: - Error Mapping

    private func mapError(_ error: Error) -> RunAnywhereError {
        if let moyaError = error as? MoyaError {
            switch moyaError {
            case .statusCode(let response):
                return mapStatusCodeError(response.statusCode)
            case .underlying(let underlyingError, _):
                return .requestFailed(underlyingError)
            case .requestMapping, .parameterEncoding, .jsonMapping, .objectMapping:
                return .requestFailed(error)
            default:
                return .requestFailed(error)
            }
        }

        return .requestFailed(error)
    }

    private func mapStatusCodeError(_ statusCode: Int) -> RunAnywhereError {
        switch statusCode {
        case 400:
            return .invalidConfiguration("Bad request")
        case 401:
            return .invalidAPIKey
        case 403:
            return .invalidAPIKey
        case 404:
            return .modelNotFound("Resource not found")
        case 429:
            return .generationFailed("Rate limit exceeded")
        case 500...599:
            return .requestFailed(NSError(domain: "HTTPError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(statusCode)"]))
        default:
            return .requestFailed(NSError(domain: "HTTPError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(statusCode)"]))
        }
    }
}

// MARK: - Response Models

private struct ModelListResponse: Decodable {
    let models: [ModelMetadataDTO]
}

/// Generation chunk for streaming
public struct GenerationChunk: Decodable {
    public let token: String
    public let isComplete: Bool
    public let metadata: ChunkMetadata?

    public struct ChunkMetadata: Decodable {
        public let tokenIndex: Int
        public let probability: Double?
    }
}
