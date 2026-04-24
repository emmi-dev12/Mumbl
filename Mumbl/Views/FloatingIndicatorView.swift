import SwiftUI
import AppKit
import Combine

// MARK: - Controller (singleton, owns the NSPanel)

@MainActor
final class FloatingIndicatorController {
    static let shared = FloatingIndicatorController()
    private var panel: NSPanel?
    private var cancellables: Set<AnyCancellable> = []
    private var settingsVM: SettingsViewModel?

    private init() {}

    func setup(appVM: AppViewModel, settingsVM: SettingsViewModel) {
        self.settingsVM = settingsVM

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 52),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentViewController = NSHostingController(
            rootView: FloatingIndicatorView()
                .environmentObject(appVM)
                .environmentObject(settingsVM)
        )
        self.panel = panel
        updatePosition(position: settingsVM.indicatorPosition)
        observe(appVM: appVM, settingsVM: settingsVM)
    }

    private func observe(appVM: AppViewModel, settingsVM: SettingsViewModel) {
        appVM.$recordingState.sink { [weak self] state in
            Task { @MainActor in
                switch state {
                case .idle:
                    self?.panel?.orderOut(nil)
                default:
                    self?.panel?.orderFrontRegardless()
                    self?.updatePosition(position: settingsVM.indicatorPosition)
                }
            }
        }.store(in: &cancellables)

        settingsVM.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                self?.updatePosition(position: settingsVM.indicatorPosition)
            }
        }.store(in: &cancellables)
    }

    private func updatePosition(position: IndicatorPosition) {
        guard let screen = NSScreen.main, let panel else { return }

        let screenFrame = screen.frame
        let panelSize = panel.frame.size
        let padding: CGFloat = 16

        let point: NSPoint

        switch position {
        case .topLeft:
            point = NSPoint(x: screenFrame.minX + padding, y: screenFrame.maxY - panelSize.height - padding)
        case .topCenter:
            let x = screenFrame.minX + (screenFrame.width - panelSize.width) / 2
            point = NSPoint(x: x, y: screenFrame.maxY - panelSize.height - padding)
        case .topRight:
            let x = screenFrame.maxX - panelSize.width - padding
            point = NSPoint(x: x, y: screenFrame.maxY - panelSize.height - padding)
        case .bottomLeft:
            point = NSPoint(x: screenFrame.minX + padding, y: screenFrame.minY + padding)
        case .bottomCenter:
            let x = screenFrame.minX + (screenFrame.width - panelSize.width) / 2
            point = NSPoint(x: x, y: screenFrame.minY + padding)
        case .bottomRight:
            let x = screenFrame.maxX - panelSize.width - padding
            point = NSPoint(x: x, y: screenFrame.minY + padding)
        case .center:
            let x = screenFrame.minX + (screenFrame.width - panelSize.width) / 2
            let y = screenFrame.minY + (screenFrame.height - panelSize.height) / 2
            point = NSPoint(x: x, y: y)
        case .nearCursor:
            let cursorLocation = NSEvent.mouseLocation
            point = NSPoint(x: cursorLocation.x - panelSize.width / 2, y: cursorLocation.y + 30)
        }

        panel.setFrameOrigin(point)
    }
}

// MARK: - SwiftUI View

struct FloatingIndicatorView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 10) {
            stateIcon
            stateLabel
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(AppColors.surface)
                .stroke(indicatorBorderColor, lineWidth: 1)
        )
        .animation(.spring(response: 0.3), value: appVM.recordingState)
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch appVM.recordingState {
        case .recording:
            ZStack {
                Circle()
                    .fill(AppColors.recording)
                    .frame(width: 10, height: 10)
                Circle()
                    .stroke(AppColors.recording.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 18, height: 18)
                    .scaleEffect(pulse ? 1.4 : 1.0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .onDisappear { pulse = false }

        case .processing:
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.7)
                .tint(AppColors.processing)
                .frame(width: 18, height: 18)

        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.success)
                .font(.system(size: 16, weight: .semibold))

        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(AppColors.warning)
                .font(.system(size: 16, weight: .semibold))

        case .idle:
            EmptyView()
        }
    }

    @ViewBuilder
    private var stateLabel: some View {
        switch appVM.recordingState {
        case .recording:
            WaveformView(level: appVM.audioLevel)
                .frame(width: 60, height: 18)

        case .processing:
            Text("Transcribing…")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.processing)

        case .done(let text):
            if settingsVM.showTranscriptionInIndicator {
                Text(text.prefix(35) + (text.count > 35 ? "…" : ""))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            } else {
                Text("Done")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.success)
            }

        case .error(let msg):
            Text(msg)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColors.warning)
                .lineLimit(1)

        case .idle:
            EmptyView()
        }
    }

    private var indicatorBorderColor: Color {
        switch appVM.recordingState {
        case .recording: return AppColors.recording.opacity(0.5)
        case .processing: return AppColors.processing.opacity(0.4)
        case .done: return AppColors.success.opacity(0.4)
        case .error: return AppColors.warning.opacity(0.4)
        case .idle: return AppColors.border
        }
    }
}

// MARK: - Waveform

struct WaveformView: View {
    let level: Float
    private let barCount = 5

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(AppColors.accent)
                    .frame(width: 3, height: barHeight(index: i))
                    .frame(height: 18, alignment: .bottom)
            }
        }
    }

    private func barHeight(index: Int) -> CGFloat {
        let base: CGFloat = 3
        let maxH: CGFloat = 16
        let normalized = CGFloat(min(max(level * 12, 0), 1))
        let wave = abs(sin(Double(index) * .pi / Double(barCount - 1)))
        return base + (maxH - base) * normalized * CGFloat(wave)
    }
}
