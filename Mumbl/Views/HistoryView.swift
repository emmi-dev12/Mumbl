import SwiftUI
import SwiftData

struct HistoryView: View {
    @EnvironmentObject var historyVM: HistoryViewModel
    @Query(sort: \TranscriptionRecord.date, order: .reverse) private var records: [TranscriptionRecord]
    @State private var searchText = ""
    @State private var copiedID: UUID?

    private var filtered: [TranscriptionRecord] {
        guard !searchText.isEmpty else { return records }
        return records.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            if filtered.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(AppColors.base)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if !records.isEmpty {
                    Button("Clear All", role: .destructive) {
                        historyVM.deleteAll()
                    }
                    .foregroundStyle(AppColors.recording)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textMuted)
            TextField("Search transcriptions…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textPrimary)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColors.surface)
        .overlay(Divider().background(AppColors.border), alignment: .bottom)
    }

    private var list: some View {
        List {
            ForEach(filtered) { record in
                HistoryRow(record: record, isCopied: copiedID == record.id) {
                    copy(record)
                }
                .listRowBackground(AppColors.base)
                .listRowSeparatorTint(AppColors.border)
                .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        historyVM.delete(record)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "waveform")
                .font(.system(size: 36))
                .foregroundStyle(AppColors.textMuted)
            Text(searchText.isEmpty ? "No transcriptions yet" : "No results")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
            if searchText.isEmpty {
                Text("Use your hotkey to start dictating")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textMuted)
            }
            Spacer()
        }
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

struct HistoryRow: View {
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
