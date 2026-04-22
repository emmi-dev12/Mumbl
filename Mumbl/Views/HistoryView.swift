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
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if !records.isEmpty {
                    Button("Clear All", role: .destructive) {
                        historyVM.deleteAll()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search transcriptions…", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
        .overlay(Rectangle().frame(height: 1).foregroundStyle(.separator), alignment: .bottom)
    }

    private var list: some View {
        List {
            ForEach(filtered) { record in
                HistoryRow(record: record, isCopied: copiedID == record.id) {
                    copy(record)
                }
                .listRowSeparator(.visible)
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
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
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "waveform")
                .font(.system(size: 40))
                .foregroundStyle(.quaternary)
            Text(searchText.isEmpty ? "No transcriptions yet" : "No results")
                .font(.headline)
                .foregroundStyle(.secondary)
            if searchText.isEmpty {
                Text("Use your hotkey to start dictating")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
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
        VStack(alignment: .leading, spacing: 4) {
            Text(record.text)
                .font(.system(size: 13))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text(record.date, style: .relative)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Text("·").foregroundStyle(.quaternary)
                Text(record.engineDisplayName)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Spacer()
                Button(action: onCopy) {
                    Label(isCopied ? "Copied" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundStyle(isCopied ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }
}
