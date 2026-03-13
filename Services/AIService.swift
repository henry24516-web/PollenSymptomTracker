import Foundation
import UIKit

#if canImport(GoogleGenerativeAI)
import GoogleGenerativeAI
#endif

@MainActor
class AIService: ObservableObject {
    @Published var isLoading = false
    @Published var response: String = ""
    @Published var errorMessage: String?

    #if canImport(GoogleGenerativeAI)
    private var model: GenerativeModel?
    #endif

    private let apiKey: String = ""

    init() {
        setupModel()
    }

    private func setupModel() {
        guard !apiKey.isEmpty else {
            errorMessage = "AI not configured"
            return
        }

        #if canImport(GoogleGenerativeAI)
        model = GenerativeModel(name: "gemini-2.0-flash", apiKey: apiKey)
        #else
        errorMessage = "AI SDK not linked"
        #endif
    }

    func generateResponse(prompt: String) async {
        #if canImport(GoogleGenerativeAI)
        guard let model else {
            errorMessage = "AI model not initialized"
            return
        }

        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            let result = try await model.generateContent(prompt)
            response = result.text ?? "No response generated"
        } catch {
            errorMessage = "Generation failed: \(error.localizedDescription)"
        }
        #else
        response = "AI feature unavailable in this build."
        #endif
    }
}

enum ChatRole: Codable {
    case user
    case model
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: ChatRole
    let content: String
    let timestamp: Date

    init(role: ChatRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}
