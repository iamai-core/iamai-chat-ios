import Foundation

// MARK: - Local AI Service
class AIService: ObservableObject {
    private let baseURL = "http://localhost:8090"
    
    func sendMessage(_ message: String) async throws -> String {
        print("🔗 Attempting local API call...")
        print("💬 Message: \(message)")
        print("🌐 Endpoint: \(baseURL)/chat")
        
        guard let url = URL(string: "\(baseURL)/chat") else {
            print("❌ Invalid URL")
            throw AIServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0 // timeout for local processing
        
        let requestBody = ["message": message]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("📤 Request body created successfully")
        } catch {
            print("❌ Encoding error: \(error)")
            throw AIServiceError.encodingError
        }
        
        print("🚀 Making network request...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("📥 Received response")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw AIServiceError.invalidResponse
            }
            
            print("📊 HTTP Status Code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📋 Response data: \(responseString)")
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                
                // parse error message
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["error"] as? String {
                    throw AIServiceError.serverError(errorMessage)
                }
                
                throw AIServiceError.httpError(httpResponse.statusCode)
            }
            
            // parse response
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let aiResponse = jsonResponse["response"] as? String {
                    print("✅ Successfully parsed response")
                    return aiResponse.isEmpty ? "I'm not sure how to respond to that." : aiResponse
                } else {
                    print("❌ Could not parse response")
                    print("Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")
                    throw AIServiceError.decodingError
                }
            } catch {
                print("❌ JSON parsing error: \(error)")
                throw AIServiceError.decodingError
            }
            
        } catch {
            print("❌ Network error: \(error)")
            
            if error.localizedDescription.contains("Could not connect to the server") {
                throw AIServiceError.serverUnavailable
            }
            
            throw error
        }
    }
    
    // health check
    func checkServerHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else { return false }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return false }
            
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = jsonResponse["status"] as? String {
                return status == "healthy"
            }
            
            return false
        } catch {
            print("Health check failed: \(error)")
            return false
        }
    }
}

enum AIServiceError: Error, LocalizedError {
    case invalidURL
    case encodingError
    case decodingError
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case serverUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError:
            return "Failed to encode request"
        case .decodingError:
            return "Failed to decode response"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .serverError(let message):
            return "Server Error: \(message)"
        case .serverUnavailable:
            return "Local AI server is not running. Please start your Python server first."
        }
    }
}
