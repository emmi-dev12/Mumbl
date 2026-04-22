import Foundation

final class OpenAIEngine: TranscriptionEngine, @unchecked Sendable {
    let id = EngineID.openAI.rawValue
    let displayName = EngineID.openAI.displayName
    let requiresAPIKey = true

    private let apiKey: () -> String?

    init(apiKey: @escaping () -> String?) {
        self.apiKey = apiKey
    }

    func transcribe(audioURL: URL) async throws -> String {
        guard let key = apiKey(), !key.isEmpty else { throw TranscriptionError.noAPIKey }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let audioData = try Data(contentsOf: audioURL)
        var body = Data()
        body.appendFormField("model", value: "whisper-1", boundary: boundary)
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

extension Data {
    mutating func appendFormField(_ name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }

    mutating func appendFileField(_ name: String, filename: String, mimeType: String, data: Data, boundary: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
