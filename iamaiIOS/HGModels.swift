import Foundation

// MARK: - Hugging Face API Models
struct HuggingFaceRequest: Codable {
    let inputs: String
    let parameters: Parameters?
    
    struct Parameters: Codable {
        let maxNewTokens: Int
        let temperature: Double
        let topP: Double
        let doSample: Bool
        
        enum CodingKeys: String, CodingKey {
            case maxNewTokens = "max_new_tokens"
            case temperature
            case topP = "top_p"
            case doSample = "do_sample"
        }
    }
}

struct HuggingFaceResponse: Codable {
    let generatedText: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case generatedText = "generated_text"
        case error
    }
}
