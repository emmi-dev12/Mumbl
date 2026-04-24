import SwiftUI
import SwiftData

// MARK: - Section

enum AppSection: String, CaseIterable, Identifiable {
    case home, history, models
    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:    return "Home"
        case .history: return "History"
        case .models:  return "Models"
        }
    }

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .history: return "clock"
        case .models:  return "cpu"
        }
    }
}

// MARK: - Main Window

struct MainWindowView: View {
    @State private var selected: AppSection = .home
    @State private var showSettings = false
    @EnvironmentObject var appVM: AppViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var historyVM: HistoryViewModel
    @EnvironmentObject var modelManager: ModelManagerService

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selected: $selected, showSettings: $showSettings)
                .frame(width: 220)

            ZStack(alignment: .topTrailing) {
                Group {
                    switch selected {
                    case .home:    HomeContentView()
                    case .history: HistoryContentView()
                    case .models:  ModelsContentView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                RecordingStatusBadge()
                    .padding(.top, 14)
                    .padding(.trailing, 20)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .background(AppColors.surface)
        .sheet(isPresented: $showSettings) {
            SettingsSheetView()
                .environmentObject(settingsVM)
                .environmentObject(historyVM)
                .environmentObject(modelManager)
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selected: AppSection
    @Binding var showSettings: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 44)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(AppSection.allCases) { section in
                    SidebarNavItem(
                        icon: section.icon,
                        title: section.title,
                        isSelected: selected == section
                    ) {
                        selected = section
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                Divider()
                    .background(AppColors.border)
                    .padding(.bottom, 8)

                SidebarNavItem(icon: "gear", title: "Settings", isSelected: false) {
                    showSettings = true
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 20)
        }
        .background(AppColors.base)
    }
}

// MARK: - Sidebar Nav Item

struct SidebarNavItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppColors.accent)
                            .frame(width: 28, height: 28)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(isSelected ? Color.black : AppColors.textMuted)
                }
                .frame(width: 28, height: 28)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered && !isSelected ? AppColors.surfaceHover : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Recording Status Badge

struct RecordingStatusBadge: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        switch appVM.recordingState {
        case .idle:       EmptyView()
        case .recording:  badge(icon: "circle.fill", text: "Recording", bg: AppColors.recording, fg: .white)
        case .processing: badge(icon: "bolt.fill",   text: "Transcribing…", bg: AppColors.accent, fg: .black)
        case .done:       badge(icon: "checkmark",   text: "Done", bg: AppColors.success, fg: .black)
        case .error:      badge(icon: "exclamationmark", text: "Error", bg: AppColors.warning, fg: .black)
        }
    }

    private func badge(icon: String, text: String, bg: Color, fg: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(fg)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 7).fill(bg))
    }
}

// MARK: - Home Content

struct HomeContentView: View {
    @Query(sort: \TranscriptionRecord.date, order: .reverse) private var allRecords: [TranscriptionRecord]

    var todayCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return allRecords.filter { $0.date >= today }.count
    }

    var totalWordCount: Int {
        allRecords.reduce(0) { $0 + $1.text.split(separator: " ").count }
    }

    var timeSavedMinutes: Int {
        let words = totalWordCount
        let saved = Double(words) / 60.0 - Double(words) / 130.0
        return max(0, Int(saved))
    }

    var groupedRecords: [(label: String, date: Date, records: [TranscriptionRecord])] {
        let cal = Calendar.current
        var map: [Date: [TranscriptionRecord]] = [:]
        for r in allRecords {
            let day = cal.startOfDay(for: r.date)
            map[day, default: []].append(r)
        }
        return map.sorted { $0.key > $1.key }.map { day, recs in
            let label: String
            if cal.isDateInToday(day)     { label = "Today" }
            else if cal.isDateInYesterday(day) { label = "Yesterday" }
            else { label = day.formatted(.dateTime.weekday(.wide)) }
            return (label: label, date: day, records: recs.sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                StatCard(icon: "waveform", label: "TODAY", value: "\(todayCount)", unit: "transcriptions")
                StatCard(icon: "text.word.spacing", label: "TOTAL WORDS", value: "\(totalWordCount)")
                StatCard(icon: "clock.fill", label: "TIME SAVED", value: "\(timeSavedMinutes)m")
            }
            .padding(20)

            sectionHeader("RECENT TRANSCRIPTIONS")
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            if allRecords.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groupedRecords, id: \.label) { group in
                            Section {
                                ForEach(group.records) { record in
                                    HomeRow(record: record)
                                }
                            } header: {
                                DateHeader(label: group.label, date: group.date)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.surface)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "waveform")
                .font(.system(size: 36))
                .foregroundStyle(AppColors.textMuted)
            Text("No transcriptions yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
            Text("Use your hotkey to start dictating")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    var unit: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.accent)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.7)
                    .foregroundStyle(AppColors.textMuted)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.surfaceHigh))
    }
}

struct DateHeader: View {
    let label: String
    let date: Date

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            Text(date.formatted(.dateTime.day().month(.wide).year()))
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textMuted)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(AppColors.surface)
    }
}

struct HomeRow: View {
    let record: TranscriptionRecord
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.surfaceHigh)
                    .frame(width: 36, height: 36)
                Image(systemName: engineIcon(record.engineID))
                    .font(.system(size: 15))
                    .foregroundStyle(AppColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(record.text)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                Text(record.engineDisplayName)
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textMuted)
            }

            Spacer()

            Text(record.date, style: .time)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .background(isHovered ? AppColors.surfaceHover : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(record.text, forType: .string)
        }
    }
}

private func engineIcon(_ id: String) -> String {
    switch EngineID(rawValue: id) {
    case .whisperKit: return "waveform"
    case .openAI:     return "brain"
    case .groq:       return "bolt.fill"
    case .deepgram:   return "ear.fill"
    case nil:         return "waveform"
    }
}

private func sectionHeader(_ text: String) -> some View {
    Text(text)
        .font(.system(size: 10, weight: .semibold))
        .tracking(0.7)
        .foregroundStyle(AppColors.textMuted)
}

// MARK: - History Content

struct HistoryContentView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    @Query(sort: \TranscriptionRecord.date, order: .reverse) private var records: [TranscriptionRecord]
    @State private var searchText = ""
    @State private var copiedID: UUID?

    private var filtered: [TranscriptionRecord] {
        guard !searchText.isEmpty else { return records }
        return records.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                sectionHeader("HISTORY")
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textMuted)
                    TextField("Search…", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .frame(width: 160)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.surfaceHigh))

                if !records.isEmpty {
                    Button("Clear All") { historyVM.deleteAll() }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.recording)
                        .padding(.leading, 10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            if filtered.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "clock")
                        .font(.system(size: 36))
                        .foregroundStyle(AppColors.textMuted)
                    Text(searchText.isEmpty ? "No transcriptions yet" : "No results")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(filtered) { record in
                        HistoryListRow(record: record, isCopied: copiedID == record.id) {
                            copy(record)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(AppColors.border)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { historyVM.delete(record) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.surface)
    }

    private func copy(_ record: TranscriptionRecord) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(record.text, forType: .string)
        copiedID = record.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedID == record.id { copiedID = nil }
        }
    }
}

struct HistoryListRow: View {
    let record: TranscriptionRecord
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(record.text)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Text(record.date, style: .relative)
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textMuted)
                Text("·").foregroundStyle(AppColors.textMuted)
                Text(record.engineDisplayName)
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textMuted)
                Spacer()
                Button(action: onCopy) {
                    Label(isCopied ? "Copied" : "Copy",
                          systemImage: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundStyle(isCopied ? AppColors.success : AppColors.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Models Content

struct ModelsContentView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var modelManager: ModelManagerService
    @State private var downloadError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader("TRANSCRIPTION ENGINE")
                    HStack(spacing: 10) {
                        ForEach(EngineID.allCases, id: \.rawValue) { engine in
                            EngineCard(
                                engine: engine,
                                isSelected: settingsVM.selectedEngineID == engine.rawValue
                            ) {
                                settingsVM.selectedEngineID = engine.rawValue
                            }
                        }
                    }
                }

                if settingsVM.selectedEngineID == EngineID.whisperKit.rawValue {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader("LOCAL MODEL")
                        VStack(spacing: 0) {
                            ForEach(Array(WhisperModelSize.allCases.enumerated()), id: \.element) { idx, size in
                                if idx > 0 {
                                    Divider()
                                        .background(AppColors.border)
                                        .padding(.horizontal, 16)
                                }
                                ModelRow(
                                    size: size,
                                    isSelected: settingsVM.selectedModelSize == size,
                                    isDownloaded: modelManager.isDownloaded(size),
                                    isDownloading: modelManager.downloadProgress[size.rawValue] != nil,
                                    progress: modelManager.downloadProgress[size.rawValue] ?? 0,
                                    onSelect: { settingsVM.selectedModelSize = size },
                                    onDownload: { download(size) }
                                )
                                .padding(16)
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.surfaceHigh))
                    }

                    if let error = downloadError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(AppColors.warning)
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AppColors.surface)
        .onAppear { modelManager.refreshDownloaded() }
    }

    private func download(_ size: WhisperModelSize) {
        downloadError = nil
        Task {
            do {
                try await modelManager.download(size)
                settingsVM.selectedModelSize = size
            } catch {
                downloadError = "Download failed: \(error.localizedDescription)"
            }
        }
    }
}

struct EngineCard: View {
    let engine: EngineID
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: engineIcon(engine.rawValue))
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppColors.accent : AppColors.textSecondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(engine.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    if isSelected {
                        Text("Active")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.accent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.surfaceHigh)
                    .stroke(isSelected ? AppColors.accent.opacity(0.4) : AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ModelRow: View {
    let size: WhisperModelSize
    let isSelected: Bool
    let isDownloaded: Bool
    let isDownloading: Bool
    let progress: Double
    let onSelect: () -> Void
    let onDownload: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(size.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                if isDownloading {
                    ProgressView(value: progress)
                        .frame(width: 120)
                        .tint(AppColors.accent)
                }
            }
            Spacer()
            if isDownloading {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textSecondary)
            } else if isDownloaded {
                if isSelected {
                    Text("Active")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(AppColors.accentDim))
                        .foregroundStyle(AppColors.accent)
                } else {
                    Button("Use", action: onSelect)
                        .buttonStyle(.bordered)
                }
            } else {
                Button("Download", action: onDownload)
                    .buttonStyle(.bordered)
            }
        }
    }
}
