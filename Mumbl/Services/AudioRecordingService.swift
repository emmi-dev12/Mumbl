import AVFoundation
import Foundation
import os.log

@MainActor
final class AudioRecordingService: ObservableObject {
    @Published var isRecording = false
    @Published var audioLevel: Float = 0
    
    private let logger = Logger(subsystem: "com.mumbl.audio", category: "AudioRecording")

    private var audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var converter: AVAudioConverter?
    private var outputURL: URL?
    private var recordingStartTime: Date?
    private var bufferWriteErrors = 0
    private let maxBufferErrors = 10

    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 16000,
        channels: 1,
        interleaved: false
    )!

    func startRecording() throws {
        // Clean up any previous state
        cleanupAudioEngine()
        
        logger.info("Starting audio recording")
        recordingStartTime = Date()
        bufferWriteErrors = 0
        
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        
        guard let inputFormat = inputNode.outputFormat(forBus: 0) else {
            logger.error("Failed to get input format")
            throw AudioError.inputFormatFailed
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            logger.error("Failed to create audio converter")
            throw AudioError.converterFailed
        }
        self.converter = converter

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        
        do {
            audioFile = try AVAudioFile(forWriting: tempURL, settings: targetFormat.settings)
            outputURL = tempURL
            logger.info("Audio file created at: \(tempURL.lastPathComponent)")
        } catch {
            logger.error("Failed to create audio file: \(error.localizedDescription)")
            throw AudioError.audioFileCreationFailed(error)
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }

        do {
            try audioEngine.start()
            isRecording = true
            logger.info("Audio engine started successfully")
        } catch {
            logger.error("Failed to start audio engine: \(error.localizedDescription)")
            throw AudioError.engineStartFailed(error)
        }
    }

    func stopRecording() -> URL? {
        defer { cleanupAudioEngine() }
        
        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        logger.info("Stopping audio recording after \(String(format: "%.2f", duration))s, buffer errors: \(bufferWriteErrors)")
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioFile = nil
        converter = nil
        isRecording = false
        audioLevel = 0
        
        let result = outputURL
        outputURL = nil
        return result
    }
    
    private func cleanupAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
        audioFile = nil
        converter = nil
    }

    private func processBuffer(_ inputBuffer: AVAudioPCMBuffer) {
        updateAudioLevel(inputBuffer)
        amplifyBuffer(inputBuffer)

        guard let converter, let audioFile, audioFile.processingFormat.channelCount > 0 else {
            return
        }

        let inputFrameCount = AVAudioFrameCount(inputBuffer.frameLength)
        let outputFrameCapacity = AVAudioFrameCount(
            Double(inputFrameCount) * targetFormat.sampleRate / inputBuffer.format.sampleRate + 1
        )
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
            bufferWriteErrors += 1
            if bufferWriteErrors == 1 {
                logger.warning("Failed to allocate output buffer")
            }
            return
        }

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

        if let error = conversionError {
            bufferWriteErrors += 1
            if bufferWriteErrors == 1 {
                logger.error("Audio conversion error: \(error.localizedDescription)")
            }
        }
        
        if conversionError == nil, outputBuffer.frameLength > 0 {
            do {
                try audioFile.write(from: outputBuffer)
            } catch {
                bufferWriteErrors += 1
                if bufferWriteErrors <= 3 {
                    logger.warning("Failed to write audio buffer: \(error.localizedDescription)")
                } else if bufferWriteErrors == 4 {
                    logger.error("Multiple buffer write failures - suppressing further logs")
                }
            }
        }
        
        // Stop recording if we have too many errors
        if bufferWriteErrors > maxBufferErrors {
            logger.error("Too many buffer write errors, stopping recording")
            DispatchQueue.main.async {
                self.audioEngine.stop()
                self.isRecording = false
            }
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

enum AudioError: Error, LocalizedError {
    case converterFailed
    case inputFormatFailed
    case audioFileCreationFailed(Error)
    case engineStartFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .converterFailed:
            return "Failed to create audio converter"
        case .inputFormatFailed:
            return "Failed to get input audio format"
        case .audioFileCreationFailed(let error):
            return "Failed to create audio file: \(error.localizedDescription)"
        case .engineStartFailed(let error):
            return "Failed to start audio engine: \(error.localizedDescription)"
        }
    }
}
