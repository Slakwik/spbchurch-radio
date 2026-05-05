import SwiftUI

struct LogsView: View {
    @ObservedObject private var log = LogManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var filter: LogEntry.Level? = nil
    @State private var showClearConfirm = false

    private var filteredEntries: [LogEntry] {
        let base: [LogEntry]
        if let f = filter {
            base = log.entries.filter { $0.level == f }
        } else {
            base = log.entries
        }
        // Newest first.
        return base.reversed()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    controlsBlock

                    if log.entries.isEmpty {
                        emptyState
                    } else if filteredEntries.isEmpty {
                        Spacer()
                        Text("Нет записей выбранного уровня")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                    } else {
                        logList
                    }
                }
            }
            .navigationTitle("Журнал")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") {
                        HapticManager.lightImpact()
                        dismiss()
                    }
                    .foregroundStyle(AppColors.accentAdaptive)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let url = log.exportFileURL() {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(AppColors.accentAdaptive)
                        }
                        .simultaneousGesture(TapGesture().onEnded { HapticManager.lightImpact() })
                    }
                }
            }
            .alert("Очистить журнал?", isPresented: $showClearConfirm) {
                Button("Отмена", role: .cancel) { }
                Button("Очистить", role: .destructive) {
                    HapticManager.mediumImpact()
                    log.clear()
                }
            } message: {
                Text("Все записи будут удалены без возможности восстановления.")
            }
        }
    }

    // MARK: - Controls — toggle + clear + filter

    private var controlsBlock: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Toggle(isOn: $log.isEnabled) {
                    HStack(spacing: 8) {
                        Image(systemName: log.isEnabled ? "circle.fill" : "circle")
                            .font(.system(size: 9))
                            .foregroundStyle(log.isEnabled ? AppColors.success : AppColors.textSecondary)
                        Text(log.isEnabled ? "Журналирование включено" : "Журналирование выключено")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
                .tint(AppColors.accentAdaptive)
                .onChange(of: log.isEnabled) { _, _ in HapticManager.selection() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .auroraGlass(cornerRadius: 14)

            HStack(spacing: 10) {
                Picker("Уровень", selection: $filter) {
                    Text("Все").tag(LogEntry.Level?.none)
                    ForEach(LogEntry.Level.allCases) { lvl in
                        Text(lvl.label).tag(LogEntry.Level?.some(lvl))
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    HapticManager.lightImpact()
                    showClearConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.error)
                        .frame(width: 36, height: 36)
                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(AppColors.surface)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(AppColors.stroke)
                                }
                        }
                }
                .buttonStyle(.plain)
                .disabled(log.entries.isEmpty)
                .opacity(log.entries.isEmpty ? 0.4 : 1)
            }
            .padding(.horizontal, 4)

            HStack {
                Text("\(filteredEntries.count) записей · из \(log.entries.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text("буфер до 500")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.7))
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    // MARK: - List

    private var logList: some View {
        List(filteredEntries) { entry in
            LogRow(entry: entry)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "doc.text")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            Text("Журнал пуст")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            Text(log.isEnabled
                ? "Записи появятся при активности приложения\n(загрузки, эфир, ошибки)"
                : "Включите журналирование выше, чтобы\nначать записывать события")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

// MARK: - Row

private struct LogRow: View {
    let entry: LogEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.level.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(entry.level.swiftUIColor)
                .frame(width: 18, height: 18)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if let src = entry.source {
                        Text(src)
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer(minLength: 0)
                    Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.85))
                }
                Text(entry.message)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .auroraSolid(cornerRadius: 12)
        .contextMenu {
            Button {
                UIPasteboard.general.string = "\(entry.timestamp) [\(entry.level.rawValue.uppercased())] \(entry.source ?? "-"): \(entry.message)"
            } label: {
                Label("Скопировать", systemImage: "doc.on.doc")
            }
        }
    }
}
