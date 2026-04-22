import SwiftUI
import AppKit

// MARK: - Controller (singleton, owns the NSPanel)

@MainActor
final class FloatingIndicatorController {
    static let shared = FloatingIndicatorController()
    private var panel: NSPanel?
    private var cancellable: AnyCancellable?

    private init() {}

    func setup(appVM: AppViewModel) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 54),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentViewController = NSHostingController(
            rootView: FloatingIndicatorView().environmentObject(appVM)
        )
        self.panel = panel
        updatePosition()
        observe(appVM: appVM)
    }

    private func observe(appVM: AppViewModel) {
        cancellable = appVM.$recordingState.sink { [weak self] state in
            Task { @MainActor in
                switch state {
                case .idle:
                    self?.panel?.orderOut(nil)
                default:
                    self?.panel?.orderFrontRegardless()
                    self?.updatePosition()
                }
            }
        }
    }

    private func updatePosition() {
        guard let screen = NSScreen.main, let panel else { return }
        let sw = screen.frame.width
        let pw = panel.frame.width
        let x = screen.frame.minX + (sw - pw) / 2
        let y = screen.frame.maxY - 80
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

// MARK: - SwiftUI View

struct FloatingIndicatorView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 10) {
            stateIcon
            stateLabel
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
        )
        .overlay(
            Capsule()
                .strokeBorder(borderColor, lineWidth: 1.5)
        )
        .animation(.spring(response: 0.3), value: appVM.recordingState)
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch appVM.recordingState {
        case .recording:
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .scaleEffect(pulse ? 1.3 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                }
                .onDisappear { pulse = false }
        case .processing:
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.7)
                .frame(width: 16, height: 16)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 16))
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 16))
        case .idle:
            EmptyView()
        }
    }

    @ViewBuilder
    private var stateLabel: some View {
        switch appVM.recordingState {
        case .recording:
            WaveformView(level: appVM.audioLevel)
                .frame(width: 60, height: 20)
        case .processing:
            Text("Transcribing…")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
        case .done(let text):
            Text(text.prefix(40) + (text.count > 40 ? "…" : ""))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        case .error(let msg):
            Text(msg)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        case .idle:
            EmptyView()
        }
    }

    private var borderColor: Color {
        switch appVM.recordingState {
        case .recording: return .red.opacity(0.4)
        case .done: return .green.opacity(0.4)
        case .error: return .orange.opacity(0.4)
        default: return .white.opacity(0.15)
        }
    }
}

// MARK: - Animated waveform

struct WaveformView: View {
    let level: Float
    private let barCount = 5

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(.red)
                    .frame(width: 4, height: barHeight(index: i))
                    .animation(.easeInOut(duration: 0.15), value: level)
            }
        }
    }

    private func barHeight(index: Int) -> CGFloat {
        let base: CGFloat = 4
        let maxH: CGFloat = 20
        let normalized = CGFloat(min(max(level * 10, 0), 1))
        let wave = sin(Double(index) * .pi / Double(barCount - 1))
        return base + (maxH - base) * normalized * CGFloat(wave)
    }
}

// Make FloatingIndicatorController work with Combine
import Combine
