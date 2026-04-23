import Foundation

enum AICleanupProvider: String, CaseIterable {
    case local = "local"
    case openAI = "openai"
    case groq = "groq"

    var displayName: String {
        switch self {
        case .local: return "Local (no API key)"
        case .openAI: return "OpenAI (GPT-4o mini)"
        case .groq: return "Groq (Llama 3)"
        }
    }
}

final class AICleanupService {
    private static let systemPrompt = """
    You are a transcription editor. Clean up this voice transcription:
    - Remove filler words (um, uh, like, you know, sort of, kind of)
    - Fix grammar and punctuation
    - Remove false starts and repeated words
    - Keep the meaning and tone exactly as intended
    Return only the cleaned text, nothing else.
    """

    func cleanup(_ text: String, provider: AICleanupProvider, apiKey: String) async throws -> String {
        switch provider {
        case .local:
            return cleanupLocal(text: text)
        case .openAI:
            return try await callOpenAI(text: text, apiKey: apiKey)
        case .groq:
            return try await callGroq(text: text, apiKey: apiKey)
        }
    }

    private func cleanupLocal(text: String) -> String {
        var result = text
        let fillerWords = [
            "\\bum\\b", "\\buh\\b", "\\bahhh\\b", "\\buhh\\b", "\\bumm\\b",
            "\\blike\\b", "\\byou know\\b", "\\byou know what\\b",
            "\\bsort of\\b", "\\bkind of\\b", "\\bi mean\\b",
            "\\bbasically\\b", "\\bliterally\\b", "\\bactually\\b",
            "\\bor something\\b", "\\bor whatever\\b"
        ]
        for pattern in fillerWords {
            result = result.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        result = result.trimmingCharacters(in: .whitespaces)
        return result
    }

    private func callOpenAI(text: String, apiKey: String) async throws -> String {
        try await callChatAPI(
            url: "https://api.openai.com/v1/chat/completions",
            model: "gpt-4o-mini",
            text: text,
            apiKey: apiKey
        )
    }

    private func callGroq(text: String, apiKey: String) async throws -> String {
        try await callChatAPI(
            url: "https://api.groq.com/openai/v1/chat/completions",
            model: "llama-3.1-8b-instant",
            text: text,
            apiKey: apiKey
        )
    }

    private func callChatAPI(url: String, model: String, text: String, apiKey: String) async throws -> String {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": Self.systemPrompt],
                ["role": "user", "content": text]
            ],
            "max_tokens": 1000,
            "temperature": 0
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw TranscriptionError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        return decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? text
    }
}

private struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String }
        let message: Message
    }
    let choices: [Choice]
}
