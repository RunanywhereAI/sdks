import Foundation
import Moya

/// Main API definition for RunAnywhere service endpoints
public enum RunAnywhereAPI {
    // MARK: - Configuration
    case fetchConfiguration(apiKey: String)
    case updateConfiguration(ConfigurationDTO)

    // MARK: - Model Metadata
    case fetchModelList
    case fetchModelMetadata(modelId: String)
    case reportModelUsage(ModelUsageDTO)

    // MARK: - Telemetry
    case sendTelemetry(TelemetryDTO)
    case sendBatch([TelemetryDTO])

    // MARK: - Cloud Inference
    case generateText(request: CloudInferenceRequest)
    case streamGeneration(request: CloudInferenceRequest)

    // MARK: - Model Downloads
    case downloadModel(modelId: String)
    case getDownloadURL(modelId: String)

    // MARK: - Analytics
    case sendAnalytics(AnalyticsEventDTO)
    case fetchAnalyticsSummary(startDate: Date, endDate: Date)
}

// MARK: - TargetType Implementation

extension RunAnywhereAPI: TargetType {

    public var baseURL: URL {
        // This can be configured through environment settings
        return URL(string: ProcessInfo.processInfo.environment["RUNANYWHERE_API_BASE_URL"] ?? "https://api.runanywhere.ai/v1")!
    }

    public var path: String {
        switch self {
        // Configuration
        case .fetchConfiguration:
            return "/configuration"
        case .updateConfiguration:
            return "/configuration"

        // Model Metadata
        case .fetchModelList:
            return "/models"
        case .fetchModelMetadata(let modelId):
            return "/models/\(modelId)"
        case .reportModelUsage:
            return "/models/usage"

        // Telemetry
        case .sendTelemetry:
            return "/telemetry"
        case .sendBatch:
            return "/telemetry/batch"

        // Cloud Inference
        case .generateText:
            return "/inference/generate"
        case .streamGeneration:
            return "/inference/stream"

        // Model Downloads
        case .downloadModel(let modelId):
            return "/models/\(modelId)/download"
        case .getDownloadURL(let modelId):
            return "/models/\(modelId)/download-url"

        // Analytics
        case .sendAnalytics:
            return "/analytics/event"
        case .fetchAnalyticsSummary:
            return "/analytics/summary"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .fetchConfiguration, .fetchModelList, .fetchModelMetadata, .getDownloadURL, .fetchAnalyticsSummary:
            return .get
        case .updateConfiguration, .reportModelUsage, .sendTelemetry, .sendBatch,
             .generateText, .streamGeneration, .downloadModel, .sendAnalytics:
            return .post
        }
    }

    public var task: Task {
        switch self {
        case .fetchConfiguration, .fetchModelList:
            return .requestPlain

        case .fetchModelMetadata(let modelId):
            return .requestParameters(
                parameters: ["model_id": modelId],
                encoding: URLEncoding.queryString
            )

        case .updateConfiguration(let config):
            return .requestJSONEncodable(config)

        case .reportModelUsage(let usage):
            return .requestJSONEncodable(usage)

        case .sendTelemetry(let telemetry):
            return .requestJSONEncodable(telemetry)

        case .sendBatch(let batch):
            return .requestJSONEncodable(["events": batch])

        case .generateText(let request), .streamGeneration(let request):
            return .requestJSONEncodable(request)

        case .downloadModel(let modelId):
            return .requestParameters(
                parameters: ["model_id": modelId],
                encoding: JSONEncoding.default
            )

        case .getDownloadURL(let modelId):
            return .requestParameters(
                parameters: ["model_id": modelId],
                encoding: URLEncoding.queryString
            )

        case .sendAnalytics(let event):
            return .requestJSONEncodable(event)

        case .fetchAnalyticsSummary(let startDate, let endDate):
            let formatter = ISO8601DateFormatter()
            return .requestParameters(
                parameters: [
                    "start_date": formatter.string(from: startDate),
                    "end_date": formatter.string(from: endDate)
                ],
                encoding: URLEncoding.queryString
            )
        }
    }

    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]

        // Add SDK-specific headers
        headers["X-SDK-Version"] = SDKConstants.version
        headers["X-SDK-Platform"] = "iOS"  // Or determine platform dynamically
        headers["X-SDK-Language"] = "Swift"

        return headers
    }

    public var sampleData: Data {
        switch self {
        case .fetchModelList:
            return """
            {
                "models": [
                    {
                        "id": "llama-3.2-1b",
                        "name": "Llama 3.2 1B",
                        "size": 1073741824,
                        "format": "gguf",
                        "quantization": "q4_k_m"
                    },
                    {
                        "id": "phi-3.5-mini",
                        "name": "Phi 3.5 Mini",
                        "size": 2147483648,
                        "format": "onnx",
                        "quantization": "int8"
                    }
                ]
            }
            """.data(using: .utf8)!

        case .fetchConfiguration:
            return """
            {
                "routing_policy": "cost_optimized",
                "privacy_mode": "standard",
                "telemetry_enabled": true,
                "max_context_length": 4096
            }
            """.data(using: .utf8)!

        case .fetchModelMetadata:
            return """
            {
                "id": "llama-3.2-1b",
                "name": "Llama 3.2 1B",
                "description": "Compact language model optimized for mobile",
                "size": 1073741824,
                "format": "gguf",
                "quantization": "q4_k_m",
                "supported_frameworks": ["llamacpp", "mlx"],
                "hardware_requirements": {
                    "min_memory": 2147483648,
                    "recommended_memory": 4294967296
                }
            }
            """.data(using: .utf8)!

        default:
            return Data()
        }
    }
}

// MARK: - Supporting Types

/// Request structure for cloud inference
public struct CloudInferenceRequest: Encodable {
    let prompt: String
    let maxTokens: Int
    let temperature: Double
    let topP: Double?
    let stream: Bool
    let modelId: String?

    enum CodingKeys: String, CodingKey {
        case prompt
        case maxTokens = "max_tokens"
        case temperature
        case topP = "top_p"
        case stream
        case modelId = "model_id"
    }
}

/// Model usage reporting
public struct ModelUsageDTO: Encodable {
    let modelId: String
    let tokensGenerated: Int
    let inferenceTime: TimeInterval
    let executionTarget: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case modelId = "model_id"
        case tokensGenerated = "tokens_generated"
        case inferenceTime = "inference_time"
        case executionTarget = "execution_target"
        case timestamp
    }
}

/// Analytics event
public struct AnalyticsEventDTO: Encodable {
    let eventType: String
    let properties: [String: String]
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case properties
        case timestamp
    }
}
