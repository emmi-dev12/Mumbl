import Foundation

final class DeepgramEngine: TranscriptionEngine, @unchecked Sendable {
    let id = EngineID.deepgram.rawValue
    let displayName = EngineID.deepgram.displayName
    let requiresAPIKey = true

    private let apiKey: () -> String?

    init(apiKey: @escaping () -> String?) {
        self.apiKey = apiKey
    }

    func transcribe(audioURL: URL) async throws -> String {
        guard let key = apiKey(), !key.isEmpty else { throw TranscriptionError.noAPIKey }

        let url = URL(string: "https://api.deepgram.com/v1/listen?model=nova-2&smart_format=true&filler_words=false")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Data(contentsOf: audioURL)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw TranscriptionError.invalidResponse
            }

            let decoded = try JSONDecoder().decode(DeepgramResponse.self, from: data)
            return decoded.results.channels.first?.alternatives.first?.transcript
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch let error as TranscriptionError {
            throw error
        } catch {
            throw TranscriptionError.networkError(error)
        }
    }
}

private struct DeepgramResponse: Decodable {
    struct Results: Decodable {
        struct Channel: Decodable {
            struct Alternative: Decodable {
                let transcript: String
            }
            let alternatives: [Alternative]
        }
        let channels: [Channel]
    }
    let results: Results
}
