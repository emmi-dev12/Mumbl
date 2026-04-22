import Foundation

final class GroqEngine: TranscriptionEngine, @unchecked Sendable {
    let id = EngineID.groq.rawValue
    let displayName = EngineID.groq.displayName
    let requiresAPIKey = true

    private let apiKey: () -> String?

    init(apiKey: @escaping () -> String?) {
        self.apiKey = apiKey
    }

    func transcribe(audioURL: URL) async throws -> String {
        guard let key = apiKey(), !key.isEmpty else { throw TranscriptionError.noAPIKey }

        var request = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let audioData = try Data(contentsOf: audioURL)
        var body = Data()
        body.appendFormField("model", value: "whisper-large-v3", boundary: boundary)
        body.appendFormField("response_format", value: "text", boundary: boundary)
        body.appendFileField("file", filename: "audio.wav", mimeType: "audio/wav", data: audioData, boundary: boundary)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw TranscriptionError.invalidResponse
            }
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch let error as TranscriptionError {
            throw error
        } catch {
            throw TranscriptionError.networkError(error)
        }
    }
}
