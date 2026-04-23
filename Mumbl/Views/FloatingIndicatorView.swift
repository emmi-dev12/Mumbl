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
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 60),
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
        // Watch recording state changes
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
        
        // Watch position changes
        settingsVM.$indicatorPosition.sink { [weak self] position in
            Task { @MainActor in
                self?.updatePosition(position: position)
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
            point = NSPoint(x: cursorLocation.x - panelSize.width / 2,
                           y: cursorLocation.y + 30)
        }
        
        panel.setFrameOrigin(point)
    }
}

// MARK: - SwiftUI View

struct FloatingIndicatorView: View {
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var pulse = false
    @State private var glow = false

    var body: some View {
        HStack(spacing: 12) {
            stateIcon
            stateLabel
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(CyberpunkColors.darkBg)
                .stroke(borderGradient, lineWidth: 1.5)
        )
        .neonGlow(borderGlowColor, radius: 10)
        .animation(.spring(response: 0.3), value: appVM.recordingState)
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch appVM.recordingState {
        case .recording:
            ZStack {
                Circle()
                    .fill(CyberpunkColors.recordingRed)
                    .frame(width: 12, height: 12)
                
                Circle()
                    .stroke(CyberpunkColors.recordingRed.opacity(0.5), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .scaleEffect(pulse ? 1.4 : 1.0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            .onDisappear { pulse = false }
            
        case .processing:
            ZStack {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
                    .tint(CyberpunkColors.processingBlue)
            }
            .frame(width: 20, height: 20)
            
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(CyberpunkColors.successGreen)
                .font(.system(size: 18, weight: .bold))
            
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(CyberpunkColors.accentYellow)
                .font(.system(size: 18, weight: .bold))
            
        case .idle:
            EmptyView()
        }
    }

    @ViewBuilder
    private var stateLabel: some View {
        switch appVM.recordingState {
        case .recording:
            NeonWaveformView(level: appVM.audioLevel)
                .frame(width: 70, height: 20)
                
        case .processing:
            Text("Transcribing…")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CyberpunkColors.processingBlue)
                
        case .done(let text):
            if settingsVM.showTranscriptionInIndicator {
                Text(text.prefix(35) + (text.count > 35 ? "…" : ""))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(CyberpunkColors.textSecondary)
                    .lineLimit(1)
            } else {
                Text("Done")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CyberpunkColors.successGreen)
            }
            
        case .error(let msg):
            Text(msg)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(CyberpunkColors.accentYellow)
                .lineLimit(1)
                
        case .idle:
            EmptyView()
        }
    }

    private var borderGradient: any ShapeStyle {
        switch appVM.recordingState {
        case .recording:
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [CyberpunkColors.recordingRed, CyberpunkColors.neonPink]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .processing:
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [CyberpunkColors.processingBlue, CyberpunkColors.neonCyan]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .done:
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [CyberpunkColors.successGreen, CyberpunkColors.accentGreen]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .error:
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [CyberpunkColors.accentYellow, CyberpunkColors.neonPink]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .idle:
            return AnyShapeStyle(CyberpunkColors.textMuted)
        }
    }
    
    private var borderGlowColor: Color {
        switch appVM.recordingState {
        case .recording: return CyberpunkColors.recordingRed
        case .processing: return CyberpunkColors.processingBlue
        case .done: return CyberpunkColors.successGreen
        case .error: return CyberpunkColors.accentYellow
        case .idle: return CyberpunkColors.neonPink
        }
    }
}

// MARK: - Animated Neon Waveform

struct NeonWaveformView: View {
    let level: Float
    private let barCount = 5

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { i in
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    CyberpunkColors.neonPink,
                                    CyberpunkColors.neonMagenta
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 3, height: barHeight(index: i))
                        .neonGlow(CyberpunkColors.neonPink, radius: 3)
                }
                .frame(height: 20, alignment: .bottom)
            }
        }
    }

    private func barHeight(index: Int) -> CGFloat {
        let base: CGFloat = 3
        let maxH: CGFloat = 18
        let normalized = CGFloat(min(max(level * 12, 0), 1))
        let wave = abs(sin(Double(index) * .pi / Double(barCount - 1)))
        return base + (maxH - base) * normalized * CGFloat(wave)
    }
}
