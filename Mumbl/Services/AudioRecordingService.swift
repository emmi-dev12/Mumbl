import AVFoundation
import Foundation

@MainActor
final class AudioRecordingService: ObservableObject {
    @Published var isRecording = false
    @Published var audioLevel: Float = 0

    private var audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var converter: AVAudioConverter?
    private var outputURL: URL?

    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 16000,
        channels: 1,
        interleaved: false
    )!

    func startRecording() throws {
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioError.converterFailed
        }
        self.converter = converter

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        outputURL = tempURL

        audioFile = try AVAudioFile(forWriting: tempURL, settings: targetFormat.settings)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }

        try audioEngine.start()
        isRecording = true
    }

    func stopRecording() -> URL? {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioFile = nil
        converter = nil
        isRecording = false
        audioLevel = 0
        return outputURL
    }

    private func processBuffer(_ inputBuffer: AVAudioPCMBuffer) {
        updateAudioLevel(inputBuffer)
        amplifyBuffer(inputBuffer)

        guard let converter, let audioFile else { return }

        let inputFrameCount = AVAudioFrameCount(inputBuffer.frameLength)
        let outputFrameCapacity = AVAudioFrameCount(
            Double(inputFrameCount) * targetFormat.sampleRate / inputBuffer.format.sampleRate + 1
        )
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else { return }

        var conversionError: NSError?
        var isDone = false
        converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
            if isDone {
                outStatus.pointee = .noDataNow
                return nil
            }
            isDone = true
            outStatus.pointee = .haveData
            return inputBuffer
        }

        if conversionError == nil, outputBuffer.frameLength > 0 {
            try? audioFile.write(from: outputBuffer)
        }
    }

    private func updateAudioLevel(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }
        var sum: Float = 0
        for i in 0..<frameLength { sum += channelData[i] * channelData[i] }
        let rms: Float = sqrt(sum / Float(frameLength))
        Task { @MainActor in self.audioLevel = min(rms * 8, 1.0) }
    }

    // Boost quiet audio (whispers) before conversion — multiplies gain up to 4x
    private func amplifyBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        for ch in 0..<channelCount {
            var rms: Float = 0
            for i in 0..<frameLength { rms += channelData[ch][i] * channelData[ch][i] }
            rms = sqrt(rms / Float(max(frameLength, 1)))
            let gain: Float = rms < 0.01 ? min(0.05 / max(rms, 0.001), 4.0) : 1.0
            if gain > 1.01 {
                for i in 0..<frameLength { channelData[ch][i] *= gain }
            }
        }
    }
}

enum AudioError: Error {
    case converterFailed
}
