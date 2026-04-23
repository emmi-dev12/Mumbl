import AVFoundation
import Foundation

@MainActor
final class AudioRecordingService: ObservableObject {
    @Published var isRecording = false
    @Published var audioLevel: Float = 0

    private var audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var outputURL: URL?
    private var levelTimer: Timer?

    func startRecording() throws {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        outputURL = tempURL

        audioFile = try AVAudioFile(forWriting: tempURL, settings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ])

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }

        try audioEngine.start()
        isRecording = true
    }

    func stopRecording() -> URL? {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioFile = nil
        isRecording = false
        audioLevel = 0
        return outputURL
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let audioFile else { return }
        do {
            try audioFile.write(from: buffer)
        } catch {}

        updateAudioLevel(buffer)
    }

    private func updateAudioLevel(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        let rms = sqrt(channelData[0..<frameLength].map { $0 * $0 }.reduce(0, +) / Float(frameLength))
        Task { @MainActor in self.audioLevel = rms }
    }
}
