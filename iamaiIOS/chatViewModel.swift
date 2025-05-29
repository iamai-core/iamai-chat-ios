import Foundation

// MARK: - Chat View Model
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentMessage = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let aiService = AIService()
    
    init() {
        // welcome message
        messages.append(Message(content: "Hello! I'm your AI assistant. How can I help you today?", isFromUser: false))
    }
    
    func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: currentMessage, isFromUser: true)
        messages.append(userMessage)
        
        let messageToSend = currentMessage
        currentMessage = ""
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await aiService.sendMessage(messageToSend)
                
                await MainActor.run {
                    let aiMessage = Message(content: response, isFromUser: false)
                    messages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    func clearChat() {
        messages.removeAll()
        messages.append(Message(content: "Hello! I'm your AI assistant. How can I help you today?", isFromUser: false))
    }
}
